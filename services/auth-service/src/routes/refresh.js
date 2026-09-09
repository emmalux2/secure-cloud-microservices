const express = require("express");
const router = express.Router();
const { refreshTokenHandler } = require("../controllers/authController");

// Mount the controller method that includes Redis blacklisting & rotation
router.post("/", refreshTokenHandler);

module.exports = router;