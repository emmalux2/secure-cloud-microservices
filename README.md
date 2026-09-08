<img width="574" height="553" alt="image" src="https://github.com/user-attachments/assets/3839af65-e129-4517-aa5a-b52cc5b39ee9" />WEEK 1
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








WEEEK 3: Database Persistence and User Authentication Service

Project Overview

During Week 3, we transitioned our authentication service away from temporary in-memory storage to a permanent PostgreSQL database. We also added secure account registration using password hashing powered by bcrypt.

To help non-technical team members picture how this works, think of a secure office building:

•	The Registration Desk (/auth/register): When new visitors sign up, we verify their information and log them into our official guest ledger. We never store raw building keys or passwords. Instead, we scramble them into a unique digital fingerprint called a bcrypt hash.

•	The Master Vault (PostgreSQL): This is our permanent database. It holds user profiles and security records safely so that account information stays intact even if the server restarts.

•	The Verification Pipeline (db.js): This acts as an automated connection manager. It opens and closes fast pipelines to the database whenever the application needs to create or verify user accounts.
System Architecture


+-----------------------------------+
|            Client / UI            |
+-----------------------------------+
                  |
        HTTP Requests (JSON)
                  v
+-----------------------------------+
|   Auth Service (Node.js/Express)  |
+-----------------------------------+
                  |
      Database Driver (pg.Pool)
                  v
+-----------------------------------+
|        PostgreSQL Database        |
|  - users                          |
|  - refresh_tokens                 |
+-----------------------------------+

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



