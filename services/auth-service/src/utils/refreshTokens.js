const crypto = require("crypto");

const REFRESH_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;

function hashRefreshToken(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

async function storeRefreshToken(queryable, userId, token) {
  const expiresAt = new Date(Date.now() + REFRESH_TOKEN_TTL_MS);
  await queryable.query(
    "INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)",
    [userId, hashRefreshToken(token), expiresAt]
  );
}

module.exports = { hashRefreshToken, storeRefreshToken };