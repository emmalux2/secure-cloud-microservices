WEEK 1
# SecureCloud — Microservices Architecture

A microservices project showing how to build, secure, and containerize a modern cloud application.

---

## What is Built in Week 1?

* auth-service: Node.js and Express application handling identity management and server health checks.
* postgres-db: Relational database storing user records and hashed session tokens with persistent Docker volume storage.
* Private Bridge Network: Isolated Docker container network that lets microservices communicate securely without exposing database ports to the outside world.

---

## Run It Locally (No Cloud Account Needed)

1. Install Docker Desktop on your machine.
2. Clone this repository 
3. Copy the example environment file to set up local variables:
cp .env.example .env
4. Start the services:
docker compose up -d --build

---

## Verification & Testing Guide

You can verify that the Week 1 infrastructure, container network, and database connection are working properly with these commands.

1. Check Running Containers
Confirm that both services are running:
docker compose ps
Expected result: Both auth-service and postgres-db display state as Up.
2. Verify App & Database Health
Test that the Node.js app can connect to PostgreSQL:
curl -i http://localhost:4000/health
Expected response:
HTTP/1.1 200 OK
{"status":"healthy","db":"connected"}
3. Inspect Database Tables
Check that the database schema initialized correctly on boot:
docker compose exec postgres-db psql -U postgres -d securecloud -c "\dt"
Expected result: A list showing the users and refresh_tokens tables.
4. Teardown
To stop the containers and clear local data volumes:
docker compose down -v



WEEK 2 — Authentication Service & Session Security
Week 2 focused on building a secure, production-ready authentication service (auth-service) using Node.js, Express, and PostgreSQL. The service follows OWASP guidelines to prevent common web vulnerabilities like XSS, CSRF, and token theft.

BANKING CREDENTIALS ANALOGY: Logging into your bank account is like receiving a temporary 15-minute VIP wristband to enter the vault, while your permanent access key is safely sealed inside a tamper-proof steel briefcase that bad actors cannot steal.
When your 15-minute wristband expires, the bank exchanges your sealed key for a brand-new one, ensuring you never use the same key twice.
If a thief ever tries to use a stolen or old key, the bank immediately triggers an alarm and invalidates every active key linked to your account.
Your original password is never saved directly; instead, it is permanently shredded into a secure cryptographic pattern that can never be reversed.
Logging out completely destroys your active key from the bank's ledger, ensuring no one can access your account after you leave.



What Was Implemented
•	Dual-Token System: 15-minute access tokens returned in JSON payloads for API access, paired with 7-day refresh tokens stored in secure cookies.

•	Token Rotation: Every refresh request invalidates the old refresh token and issues a new pair, preventing stale credentials from lingering.

•	OWASP Token Reuse Detection: If a revoked or replayed refresh token hits the server, all active sessions for that user are immediately deleted from PostgreSQL.

•	Hardened Cookie Security: Refresh tokens are sent using HttpOnly and SameSite=Strict flags to block client-side JavaScript theft and cross-site requests.

•	Brute-Force Defense: Enforced IP-based rate limiting on login attempts and hashed passwords with bcrypt (cost factor 12).

API Endpoints Built
1.	Register User
POST /auth/register
Validates inputs using Zod, hashes the password, and creates a new user record in PostgreSQL.

2.	Login
POST /auth/login
Verifies credentials, generates an access token, and attaches the HttpOnly refresh token cookie.

3.	Refresh Token
POST /auth/refresh
Consumes the active refresh cookie, rotates the token pair in the database, and returns a new 15-minute access token.

4.	Logout
POST /auth/logout
Deletes the active refresh token record from PostgreSQL and clears the cookie on the client.

Verification & Testing Steps
You can test the entire authentication lifecycle using curl commands in your terminal.


1.	Register a New Account
curl -i -X POST http://localhost:4000/auth/register

-H "Content-Type: application/json"

-d '{"email":"secuser@example.com","password":"SecurePassword123!"}'

2.	Log In & Store Cookies
curl -i -c cookies.txt -X POST http://localhost:4000/auth/login

-H "Content-Type: application/json"

-d '{"email":"secuser@example.com","password":"SecurePassword123!"}'

Check the output to ensure you received an accessToken JSON object and a Set-Cookie header.

3.	Rotate Refresh Token
curl -i -b cookies.txt -c cookies.txt -X POST http://localhost:4000/auth/refresh

Verify that a new access token is returned and a new refresh token cookie is set.

4.	Test Session Logout
curl -i -b cookies.txt -c cookies.txt -X POST http://localhost:4000/auth/logout

Expected response: 200 OK with message "Logged out successfully" and an expired cookie header.

Status and way forward
Week 2 is complete and verified. The authentication service is containerized, stable, and ready to issue access tokens for the FastAPI resource service in Week 3.
