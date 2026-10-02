const express = require("express");
const pool = require("../db");
const { hashRefreshToken } = require("../utils/refreshTokens");

const router = express.Router();

router.post("/", async (req, res) => {
  const refreshToken = req.cookies?.refresh_token;
  res.clearCookie("refresh_token", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict"
  });

  if (!refreshToken) {
    return res.status(200).json({ message: "Logged out successfully" });
  }

  try {
    await pool.query("DELETE FROM refresh_tokens WHERE token_hash = $1", [
      hashRefreshToken(refreshToken)
    ]);
    return res.status(200).json({ message: "Logged out successfully" });
  } catch (error) {
    console.error("Logout error:", error);
    return res.status(500).json({ error: "Unable to end session" });
  }
});

module.exports = router;