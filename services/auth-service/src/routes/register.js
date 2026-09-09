const express = require("express");
const bcrypt = require("bcryptjs");
const { z } = require("zod");
const pool = require("../db");

const router = express.Router();

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(12, "Password must be at least 12 characters"),
  role: z.enum(["user", "admin"]).default("user")
});

router.post("/", async (req, res) => {
  try {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid input" });
    }

    const { email, password, role } = parsed.data;
    const existing = await pool.query("SELECT id FROM users WHERE email = $1", [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: "Registration failed" });
    }

    const hash = await bcrypt.hash(password, 12);
    await pool.query(
      "INSERT INTO users (email, password_hash, role) VALUES ($1, $2, $3)",
      [email, hash, role]
    );

    return res.status(201).json({ message: "Account created" });
  } catch (err) {
    console.error("Register error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;