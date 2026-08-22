const jwt = require("jsonwebtoken");
const { getSecret } = require("./secrets");

function signAccessToken(payload) {
  return jwt.sign(payload, getSecret("JWT_ACCESS_SECRET"), {
    expiresIn: "15m",
    algorithm: "HS256"
  });
}

function signRefreshToken(payload) {
  return jwt.sign(payload, getSecret("JWT_REFRESH_SECRET"), {
    expiresIn: "7d",
    algorithm: "HS256"
  });
}

module.exports = { signAccessToken, signRefreshToken };
