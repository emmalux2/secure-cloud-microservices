const express = require("express");
const jwt = require("jsonwebtoken");
const { getSecret } = require("../utils/secrets");
const { signAccessToken } = require("../utils/jwt");

const router = express.Router();

router.post("/", (req, res) => {
  const refreshToken = req.cookies?.refresh_token;
  if (!refreshToken) return res.status(401).json({ error: "Refresh token missing" });

  try {
    const payload = jwt.verify(refreshToken, getSecret("JWT_REFRESH_SECRET"));
    const accessToken = signAccessToken({ sub: payload.sub });
    return res.json({ accessToken });
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired refresh token" });
  }
});

module.exports = router;
