const jwt = require("jsonwebtoken");
const { getSecret } = require("./secrets");

function signAccessToken(payload) {
  // Ensure the token payload explicitly contains sub, email, and role
  const tokenPayload = {
    ...payload,
    role: payload.role || "user"
  };

  return jwt.sign(tokenPayload, getSecret("JWT_ACCESS_SECRET"), {
    expiresIn: "15m",
    algorithm: "HS256"
  });
}

function signRefreshToken(payload) {
  return jwt.sign(payload, getSecret("JWT_REFRESH_SECRET"), {
    expiresIn: "7d",
    algorithm: "HS256"
  });
}

module.exports = { signAccessToken, signRefreshToken };