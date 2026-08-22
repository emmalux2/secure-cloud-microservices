const express = require("express");
const bcrypt = require("bcryptjs");
const { z } = require("zod");
const pool = require("../db");

const router = express.Router();
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(12, "Password must be at least 12 characters")
});

router.post("/", async (req, res) => {
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "Invalid input" });
  }

  const { email, password } = parsed.data;
  const existing = await pool.query("SELECT id FROM users WHERE email = $1", [email]);
  if (existing.rows.length > 0) {
    return res.status(409).json({ error: "Registration failed" });
  }

  const hash = await bcrypt.hash(password, 12);
  await pool.query("INSERT INTO users (email, password_hash) VALUES ($1, $2)", [email, hash]);

  return res.status(201).json({ message: "Account created" });
});

module.exports = router;
