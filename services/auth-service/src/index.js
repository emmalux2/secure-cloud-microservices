const express = require("express");
const helmet = require("helmet");
const client = require("prom-client");
const registerRoute = require("./routes/register");
const loginRoute = require("./routes/login");
const refreshRoute = require("./routes/refresh");
const { rateLimiter } = require("./middleware/rateLimiter");
const app = express();
app.use(express.json({ limit: "10kb" }));
app.use(helmet());
app.disable("x-powered-by");

client.collectDefaultMetrics();
const httpRequests = new client.Counter({
  name: "http_requests_total",
  help: "Total HTTP requests",
  labelNames: ["route", "status"]
});

app.use((req, res, next) => {
  res.on("finish", () => {
    httpRequests.inc({ route: req.path, status: res.statusCode });
  });
  next();
});

// Root endpoint (Fixes "Cannot GET /" on http://localhost:4000)
app.get("/", (req, res) => {
  res.status(200).json({ status: "ok", service: "auth-service" });
});

// Prometheus metrics endpoint
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});

// Health check endpoint
app.get("/healthz", (req, res) => res.status(200).json({ status: "ok" }));

// Auth routes
app.use("/auth/register", rateLimiter, registerRoute);
app.use("/auth/login", rateLimiter, loginRoute);
app.use("/auth/refresh", refreshRoute);

const PORT = process.env.PORT || 4000;

if (require.main === module) {
  app.listen(PORT, () => console.log(`auth-service listening on ${PORT}`));
}

module.exports = app;