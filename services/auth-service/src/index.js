const express = require("express");
const cookieParser = require("cookie-parser");
const helmet = require("helmet");
const client = require("prom-client");
const registerRoute = require("./routes/register");
const loginRoute = require("./routes/login");
const refreshRoute = require("./routes/refresh");
const logoutRoute = require("./routes/logout");
const { rateLimiter } = require("./middleware/rateLimiter");
const app = express();
app.use(express.json({ limit: "10kb" }));
app.use(cookieParser());
app.use(helmet());
app.disable("x-powered-by");

client.collectDefaultMetrics();
const httpRequests = new client.Counter({
  name: "http_requests_total",
  help: "Total HTTP requests",
  labelNames: ["route", "status"]
});
const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration in seconds",
  labelNames: ["route", "method", "status"],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]
});
const metricRoutes = new Set([
  "/",
  "/healthz",
  "/metrics",
  "/auth/register",
  "/auth/login",
  "/auth/refresh",
  "/auth/logout"
]);

app.use((req, res, next) => {
  const endTimer = httpRequestDuration.startTimer();
  res.on("finish", () => {
    const requestPath = req.originalUrl.split("?")[0];
    const route = metricRoutes.has(requestPath) ? requestPath : "unmatched";
    httpRequests.inc({ route, status: res.statusCode });
    endTimer({ route, method: req.method, status: res.statusCode });
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
app.use("/auth/logout", logoutRoute);

const PORT = process.env.PORT || 4000;

if (require.main === module) {
  app.listen(PORT, () => console.log(`auth-service listening on ${PORT}`));
}

module.exports = app;