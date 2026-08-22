function getSecret(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required secret: ${name}`);
  }
  return value;
}

module.exports = { getSecret };
