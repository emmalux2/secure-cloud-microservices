import os
import jwt
from fastapi import FastAPI, Depends, Header, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

app = FastAPI(title="SecureCloud Resource Service")

# Reads JWT_ACCESS_SECRET or falls back to JWT_SECRET / supersecretkey
JWT_SECRET = os.getenv("JWT_ACCESS_SECRET", os.getenv("JWT_SECRET", "supersecretkey"))
ALGORITHM = "HS256"

security = HTTPBearer(auto_error=False)

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    x_user_id: str = Header(None),
    x_user_email: str = Header(None),
    x_user_role: str = Header(None)
):
    # Plain English: First check if NGINX API Gateway already validated the identity headers
    if x_user_id:
        return {
            "user_id": x_user_id,
            "email": x_user_email,
            "role": x_user_role or "user"
        }

    # Plain English: Fallback direct JWT validation if request bypassed Gateway
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization credentials"
        )

    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        user_id = payload.get("sub") or payload.get("userId")
        email: str = payload.get("email")
        role: str = payload.get("role", "user")

        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload: missing sub or userId"
            )
        return {"user_id": user_id, "email": email, "role": role}

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Access token has expired"
        )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

class RoleChecker:
    def __init__(self, allowed_roles: list[str]):
        self.allowed_roles = allowed_roles

    def __call__(self, current_user: dict = Depends(get_current_user)):
        if current_user["role"] not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: requires one of roles {self.allowed_roles}"
            )
        return current_user

@app.get("/health")
@app.get("/healthz")
def health_check():
    return {"status": "healthy", "service": "resource-service"}

@app.get("/resources/dashboard")
def get_dashboard(current_user: dict = Depends(RoleChecker(["user", "admin"]))):
    return {
        "message": "Access granted to secure dashboard",
        "user": current_user,
        "data": ["Confidential Report A", "Secure Cloud Analytics"]
    }

@app.get("/resources/admin")
def get_admin_panel(current_user: dict = Depends(RoleChecker(["admin"]))):
    return {
        "message": "Access granted to Admin Panel",
        "user": current_user,
        "admin_metrics": {"system_health": "100%", "active_sessions": 42}
    }