/* eslint-disable no-console */
const express = require('express');
const cors = require('cors');
const path = require('path');
const bodyParser = require('body-parser');
const { Store } = require('./persistence');
const { makeToken, verifyToken } = require('./utils/jwt');

const app = express();

const NODE_ENV = process.env.NODE_ENV || 'development';
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'secret';
const DATA_DIR = process.env.DATA_DIR || './data';
const ALLOWED_ORIGIN = (process.env.ALLOWED_ORIGIN || '').split(',').map(s => s.trim()).filter(Boolean);

const store = new Store({ dataDir: DATA_DIR });

// CORS
app.use(cors({
  origin: function(origin, cb) {
    // Allow no-origin (curl, mobile apps) and same-origin
    if (!origin) return cb(null, true);
    if (NODE_ENV !== 'production') return cb(null, true);
    // In production, enforce allowlist
    if (ALLOWED_ORIGIN.includes(origin)) return cb(null, true);
    return cb(new Error('CORS: origin not allowed'), false);
  },
  credentials: true
}));

app.use(bodyParser.json({ limit: '1mb' }));

// Auth middleware
function auth(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });
  const decoded = verifyToken(token, JWT_SECRET);
  if (!decoded || !decoded.email) return res.status(401).json({ error: 'Invalid token' });
  req.user = { email: decoded.email };
  next();
}

// Health check
app.get('/api/healthz', (req, res) => {
  const version = process.env.npm_package_version || '0.0.0';
  res.json({
    status: 'ok',
    version,
    node: process.version,
    uptime: process.uptime(),
    dataDir: path.resolve(DATA_DIR),
    usersCount: Object.keys(store.db.users || {}).length
  });
});

// Auth
app.post('/api/auth/register', (req, res) => {
  const { email } = req.body || {};
  if (!email) return res.status(400).json({ error: 'email required' });
  // No password for this demo; in real life, hash passwords!
  store.ensureUser(email);
  store.save();
  const token = makeToken({ email }, JWT_SECRET);
  res.json({ token, email });
});

app.post('/api/auth/login', (req, res) => {
  const { email } = req.body || {};
  if (!email) return res.status(400).json({ error: 'email required' });
  // Accept any email that exists (or create it for demo)
  store.ensureUser(email);
  const token = makeToken({ email }, JWT_SECRET);
  res.json({ token, email });
});

// Generic CRUD factory for lists
function listRouter(key) {
  const router = express.Router();
  // Read all
  router.get('/', auth, (req, res) => {
    const user = store.getUser(req.user.email);
    res.json(user[key] || []);
  });
  // Create
  router.post('/', auth, (req, res) => {
    const user = store.getUser(req.user.email);
    const item = { id: req.body.id || String(Date.now()), ...req.body };
    user[key] = user[key] || [];
    user[key].push(item);
    store.save();
    res.status(201).json(item);
  });
  // Update
  router.put('/:id', auth, (req, res) => {
    const user = store.getUser(req.user.email);
    const id = req.params.id;
    const arr = user[key] || [];
    const idx = arr.findIndex(x => String(x.id) === String(id));
    if (idx === -1) return res.status(404).json({ error: 'not found' });
    arr[idx] = { ...arr[idx], ...req.body, id };
    store.save();
    res.json(arr[idx]);
  });
  // Delete
  router.delete('/:id', auth, (req, res) => {
    const user = store.getUser(req.user.email);
    const id = req.params.id;
    const arr = user[key] || [];
    const next = arr.filter(x => String(x.id) !== String(id));
    user[key] = next;
    store.save();
    res.status(204).end();
  });
  return router;
}

app.use('/api/budgets', listRouter('budgets'));
app.use('/api/debts', listRouter('debts'));
app.use('/api/goals', listRouter('goals'));
app.use('/api/obligations', listRouter('obligations'));
app.use('/api/bnpl', listRouter('bnpl'));

app.listen(PORT, () => {
  console.log(`[server] listening on http://localhost:${PORT} (${NODE_ENV})`);
});
