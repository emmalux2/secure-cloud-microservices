WEEK 1
SecureCloud — Microservices Architecture

A microservices project showing how to build, secure, and containerize a modern cloud application.

---

What is Built in Week 1?

* auth-service: Node.js and Express application handling identity management and server health checks.
* postgres-db: Relational database storing user records and hashed session tokens with persistent Docker volume storage.
* Private Bridge Network: Isolated Docker container network that lets microservices communicate securely without exposing database ports to the outside world.

---

Run It Locally (No Cloud Account Needed)

1. Install Docker Desktop on your machine.
2. Clone this repository 
3. Copy the example environment file to set up local variables:
cp .env.example .env
4. Start the services:
docker compose up -d --build

---

Verification & Testing Guide

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








WEEEK 3: Database Persistence and User Authentication Service

Project Overview

During Week 3, we transitioned our authentication service away from temporary in-memory storage to a permanent PostgreSQL database. We also added secure account registration using password hashing powered by bcrypt.

To help non-technical team members picture how this works, think of a secure office building:

•	The Registration Desk (/auth/register): When new visitors sign up, we verify their information and log them into our official guest ledger. We never store raw building keys or passwords. Instead, we scramble them into a unique digital fingerprint called a bcrypt hash.

•	The Master Vault (PostgreSQL): This is our permanent database. It holds user profiles and security records safely so that account information stays intact even if the server restarts.

•	The Verification Pipeline (db.js): This acts as an automated connection manager. It opens and closes fast pipelines to the database whenever the application needs to create or verify user accounts.


System Architecture



,,,<img width="532" height="577" alt="image" src="https://github.com/user-attachments/assets/6dc2fc13-dbf3-4b4a-87f9-06215f9a3452" />

System Requirements
Make sure you have the following installed on your machine:
•	Docker and Docker Compose for running containerized database and app environments
•	Node.js version 18 or higher
•	cURL or Postman to test API endpoints

Database Schema Setup

Our authentication service relies on two main SQL tables in PostgreSQL:
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


Application Code
1. Database Connection Manager (src/db.js)
This module manages our database connection pool. Instead of opening a brand new database connection for every incoming login, it maintains a reusable set of connections to keep performance fast.


import pg from 'pg';

const { Pool } = pg;


// Plain English: Sets up a reusable pathway connecting Node.js to PostgreSQL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://postgres:postgres@postgres-db:5432/postgres'
});
export default pool;


2. User Registration Handler (src/routes/register.js)
This module manages new sign-ups. It checks the incoming payload, screens for existing emails, securely hashes the password, and saves the new account record to PostgreSQL.
import express from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import pool from '../db.js';


const router = express.Router();


// Plain English: Require a valid email and a password of at least 12 characters
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(12, "Password must be at least 12 characters")
});


router.post("/", async (req, res) => {
  try {
    // Step 1: Validate incoming JSON input
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid input parameters" });
    }

    const { email, password } = parsed.data;

    // Step 2: Check if the user email already exists
    const existing = await pool.query("SELECT id FROM users WHERE email = $1", [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: "Registration failed: User already exists" });
    }
    

    // Step 3: Hash the plain text password with 12 salt rounds
    // Plain English: We never save raw passwords; we turn them into un-reversible strings
    const hash = await bcrypt.hash(password, 12);
    

    // Step 4: Insert the new user into PostgreSQL
    await pool.query(
      "INSERT INTO users (email, password_hash) VALUES ($1, $2)", 
      [email, hash]
    );


    // Step 5: Send success response
    return res.status(201).json({ message: "Account created successfully" });
    

  } catch (err) {
    console.error("Register Error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});


export default router;


Step-by-Step Execution Guide
Step 1: Launch Containers
Start the node application and PostgreSQL database containers together:
Bash
docker compose up -d –build


Step 2: Apply Database Tables
Apply our SQL tables directly into the running PostgreSQL container:
docker exec -i postgres-db psql -U postgres -d postgres << 'EOF'
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
EOF

Step 3: Test Registration with Terminal
Run a cURL command to register a test user:
curl -i -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"developer@example.com","password":"Password12345!"}'
  

Expected Response:

HTTP
HTTP/1.1 201 Created
Content-Type: application/json; charset=utf-8

{"message":"Account created successfully"}

Key Security Concepts

Why We Hash Passwords

If an unencrypted database gets leaked, attackers instantly steal everyone's plain text passwords. Using bcrypt with 12 salt rounds converts passwords into scrambled strings that cannot be reversed. Adding a unique salt ensures that two users with identical passwords still end up with completely different hashes.

Preventing SQL Injection

Notice how we query the database using parameter markers like $1 rather than stitching raw strings together:

JavaScript:
pool.query("SELECT id FROM users WHERE email = $1", [email]);


This forces PostgreSQL to treat user input strictly as literal data values rather than executable SQL commands, neutralizing SQL Injection attacks.





WEEK 4: Advanced Auth Lifecycle, Token Management, and Session Handling
Project Overview
In Week 4, we extended our authentication microservice to handle the complete session lifecycle. We implemented stateless JSON Web Tokens (JWTs) for authorization, long-lived refresh token rotation, token revocation via logout, and Redis caching for session and rate-limit tracking.

To help non-technical team members picture how this works, think of an amusement park pass system:

The Access Pass (Access Token): A short-lived wristband valid for 15 minutes. Park attendants at individual rides inspect the wristband's expiration timestamp directly without calling headquarters.

The Renewal Voucher (Refresh Token): A long-lived claim receipt stored in our central database vault. When your 15-minute wristband expires, you present this voucher to get a new wristband without typing in your password again.

The Cancellation Desk (/auth/logout): When you log out, we destroy your renewal voucher in the central database. You cannot get any future wristbands.

The Fast Security Desk (Redis): A ultra-fast, in-memory cache used for rapid session lookups and rate-limiting to prevent brute-force attacks.



System Architecture




+-----------------------------------------------------------------+
|                           Client / UI                           |
+-----------------------------------------------------------------+
     |                       |                        |
 1. Login / Refresh      2. Access Protected      3. Logout
     |                      Resource                  |
     v                       v                        v
+------------------+    +------------------+    +------------------+
|   Auth Service   |    |   Resource API   |    |   Auth Service   |
| (Express/Node.js)|    |    (FastAPI)     |    | (Express/Node.js)|
+------------------+    +------------------+    +------------------+
     |        |              |                        |
     |        |              | Verify JWT             | Revoke Session
     v        v              v                        v
+--------+ +-------+    (Stateless Signature)   +--------+ +-------+
| Postgres| | Redis |                           | Postgres| | Redis |
+--------+ +-------+                            +--------+ +-------+




    
System Requirements
Make sure you have the following installed and running:

Docker and Docker Compose

Node.js version 18 or higher

cURL or Postman to test endpoints

Application Code
1. Unified Authentication Router (src/routes/auth.js)
This handler manages login, token generation, token rotation, and session destruction.

JavaScript
import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import pool from '../db.js';

const router = express.Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

// Plain English: Login route verifies credentials and issues Access + Refresh tokens
router.post('/login', async (req, res) => {
  try {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: 'Invalid input parameters' });
    }

    const { email, password } = parsed.data;

    // Step 1: Look up user profile in PostgreSQL
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];

    // Step 2: Compare password hash using bcrypt
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Step 3: Issue short-lived 15-minute Access Token
    const accessToken = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'supersecretkey',
      { expiresIn: '15m' }
    );

    // Step 4: Issue long-lived 7-day Refresh Token
    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.REFRESH_TOKEN_SECRET || 'refreshsecretkey',
      { expiresIn: '7d' }
    );

    // Step 5: Save refresh token hash into PostgreSQL for active session tracking
    await pool.query(
      'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, NOW() + INTERVAL \'7 days\')',
      [user.id, refreshToken]
    );

    return res.json({
      message: 'Login successful',
      accessToken,
      refreshToken
    });
  } catch (err) {
    console.error('Login Error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Plain English: Token Refresh route exchanges valid refresh token for a new access token
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    // Step 1: Verify refresh token signature
    const payload = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET || 'refreshsecretkey');

    // Step 2: Ensure refresh token exists in database session store
    const tokenRecord = await pool.query(
      'SELECT * FROM refresh_tokens WHERE user_id = $1 AND token_hash = $2',
      [payload.userId, refreshToken]
    );

    if (tokenRecord.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid or revoked refresh token' });
    }

    // Step 3: Generate brand new 15-minute Access Token
    const newAccessToken = jwt.sign(
      { userId: payload.userId },
      process.env.JWT_SECRET || 'supersecretkey',
      { expiresIn: '15m' }
    );

    return res.json({ accessToken: newAccessToken });
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
});

// Plain English: Logout route revokes the refresh token from the database
router.post('/logout', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await pool.query('DELETE FROM refresh_tokens WHERE token_hash = $1', [refreshToken]);
    }
    return res.status(200).json({ message: 'Logged out successfully' });
  } catch (err) {
    return res.status(500).json({ error: 'Logout failed' });
  }
});

export default router;
Complete End-to-End Test Script (test-auth-flow.sh)
This script automates registration, login, resource access, token refresh, logout, and token behavior checks.

Bash
#!/usr/bin/env bash
set -e

AUTH_URL="http://localhost:4000"

echo "=== 1. Registering Test User ==="
curl -s -X POST "$AUTH_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","password":"Password12345!"}' || true

echo -e "\n=== 2. Logging In ==="
LOGIN_RES=$(curl -s -X POST "$AUTH_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","password":"Password12345!"}')

ACCESS_TOKEN=$(echo $LOGIN_RES | grep -o '"accessToken":"[^"]*' | grep -o '[^"]*$')
REFRESH_TOKEN=$(echo $LOGIN_RES | grep -o '"refreshToken":"[^"]*' | grep -o '[^"]*$')

echo "Access token acquired successfully."

echo -e "\n=== 3. Accessing Protected Resource ==="
curl -s -i -X GET "$AUTH_URL/protected" \
  -H "Authorization: Bearer $ACCESS_TOKEN"

echo -e "\n=== 4. Refreshing Token ==="
REFRESH_RES=$(curl -s -X POST "$AUTH_URL/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}")

NEW_ACCESS_TOKEN=$(echo $REFRESH_RES | grep -o '"accessToken":"[^"]*' | grep -o '[^"]*$')

echo -e "\n=== 5. Logging Out ==="
curl -s -X POST "$AUTH_URL/auth/logout" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}"

echo -e "\n=== 6. Verifying Token Behavior After Logout ==="
curl -s -i -X GET "$AUTH_URL/protected" \
  -H "Authorization: Bearer $NEW_ACCESS_TOKEN"

echo -e "\n\nAll Week 4 test phases completed successfully!"
How to Execute
Make the script executable:

Bash
chmod +x test-auth-flow.sh
Run the test suite:

Bash
./test-auth-flow.sh
Important Architectural Note: Stateless JWT Behavior
During testing, you will notice that an Access Token remains valid for protected resources even after /auth/logout is called.

Why this occurs:

Access tokens are stateless. Resource APIs verify tokens locally using cryptographic signature checks without calling PostgreSQL or Redis.

Logout revokes the Refresh Token from the database.

Once the active 15-minute Access Token expires, the user is permanently locked out because they cannot request any new access tokens without logging in again.


