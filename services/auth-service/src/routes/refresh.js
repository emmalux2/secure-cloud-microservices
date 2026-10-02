const express = require("express");
const jwt = require("jsonwebtoken");
const pool = require("../db");
const router = express.Router();
const { getSecret } = require("../utils/secrets");
const { signAccessToken, signRefreshToken } = require("../utils/jwt");
const { hashRefreshToken, storeRefreshToken } = require("../utils/refreshTokens");

router.post("/", async (req, res) => {
	const currentToken = req.cookies?.refresh_token;
	if (!currentToken) {
		return res.status(401).json({ error: "Missing refresh token" });
	}

	let payload;
	try {
		payload = jwt.verify(currentToken, getSecret("JWT_REFRESH_SECRET"), {
			algorithms: ["HS256"]
		});
	} catch {
		res.clearCookie("refresh_token", {
			httpOnly: true,
			secure: process.env.NODE_ENV === "production",
			sameSite: "strict"
		});
		return res.status(401).json({ error: "Invalid refresh token" });
	}

	if (!payload.sub) {
		return res.status(401).json({ error: "Invalid refresh token" });
	}

	const client = await pool.connect();
	try {
		await client.query("BEGIN");
		const deleted = await client.query(
			"DELETE FROM refresh_tokens WHERE token_hash = $1 AND expires_at > NOW() RETURNING user_id",
			[hashRefreshToken(currentToken)]
		);

		if (deleted.rows.length === 0) {
			await client.query("DELETE FROM refresh_tokens WHERE user_id = $1", [payload.sub]);
			await client.query("COMMIT");
			res.clearCookie("refresh_token", {
				httpOnly: true,
				secure: process.env.NODE_ENV === "production",
				sameSite: "strict"
			});
			return res.status(401).json({ error: "Refresh token is no longer valid" });
		}

		const userId = deleted.rows[0].user_id;
		const tokenPayload = {
			sub: userId,
			email: payload.email,
			role: payload.role || "user"
		};
		const accessToken = signAccessToken(tokenPayload);
		const nextRefreshToken = signRefreshToken(tokenPayload);
		await storeRefreshToken(client, userId, nextRefreshToken);
		await client.query("COMMIT");

		res.cookie("refresh_token", nextRefreshToken, {
			httpOnly: true,
			secure: process.env.NODE_ENV === "production",
			sameSite: "strict",
			maxAge: 7 * 24 * 60 * 60 * 1000
		});
		return res.json({ accessToken });
	} catch (error) {
		await client.query("ROLLBACK");
		console.error("Refresh token error:", error);
		return res.status(500).json({ error: "Unable to refresh session" });
	} finally {
		client.release();
	}
});

module.exports = router;