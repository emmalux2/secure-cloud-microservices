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
