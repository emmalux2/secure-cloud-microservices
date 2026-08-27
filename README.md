# SecureCloud
A two-microservice project that shows how to build, secure, deploy, and monitor a real cloud application written so a beginner can follow every step[cite: 1].

## What's iinside?h
- **auth-service**: logs users in/out and hands out digital "wristbands" (JWT tokens) that prove who you are[cite: 1].
- **resource-service**: a small notes API that only lets you in if you have a valid wristband[cite: 1].

## Run it on your laptop (no cloud account needed)
1. Install Docker Desktop[cite: 1].
2. Clone this repo[cite: 1].
3. Run: `docker compose up --build`[cite: 1]
4. auth-service: `http://localhost:4000` | resource-service: `http://localhost:8000`[cite: 1]

## Try it
1. Create an account[cite: 1]:
   `curl -X POST localhost:4000/auth/register -H "Content-Type: application/json" -d '{"email":"me@example.com","password":"correct-horse-battery-staple"}'`[cite: 1]
2. Log in, get a token[cite: 1]:
   `curl -X POST localhost:4000/auth/login -H "Content-Type: application/json" -d '{"email":"me@example.com","password":"correct-horse-battery-staple"}'`[cite: 1]
3. Use token to create a note[cite: 1]:
   `curl -X POST localhost:8000/notes/ -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" -d '{"text":"my first secure note"}'`[cite: 1]
#end for now 
kk