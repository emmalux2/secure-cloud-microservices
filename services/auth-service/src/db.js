const pg = require("pg");
const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://postgres:postgres@postgres-db:5432/postgres'
});

module.exports = pool;