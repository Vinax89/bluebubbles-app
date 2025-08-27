const jwt = require('jsonwebtoken');

function makeToken(payload, secret, expiresIn='7d') {
  return jwt.sign(payload, secret, { expiresIn });
}

function verifyToken(token, secret) {
  try {
    return jwt.verify(token, secret);
  } catch (e) {
    return null;
  }
}

module.exports = { makeToken, verifyToken };
