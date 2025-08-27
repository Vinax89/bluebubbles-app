const fs = require('fs');
const path = require('path');

const DEFAULT_STRUCTURE = () => ({
  users: {}
});

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function getDataPaths(dataDir) {
  const dir = path.resolve(process.cwd(), dataDir || './data');
  ensureDir(dir);
  return {
    dir,
    dbFile: path.join(dir, 'db.json'),
    tmpFile: path.join(dir, 'db.tmp.json'),
  };
}

function loadDB(dataDir) {
  const { dbFile } = getDataPaths(dataDir);
  if (!fs.existsSync(dbFile)) {
    return DEFAULT_STRUCTURE();
  }
  try {
    const raw = fs.readFileSync(dbFile, 'utf-8');
    const parsed = JSON.parse(raw);
    // Basic shape check
    if (!parsed || typeof parsed !== 'object' || !parsed.users) {
      return DEFAULT_STRUCTURE();
    }
    return parsed;
  } catch (e) {
    console.error('[persistence] Failed to load DB, starting fresh:', e.message);
    return DEFAULT_STRUCTURE();
  }
}

function atomicWrite(filePath, tmpPath, data) {
  fs.writeFileSync(tmpPath, JSON.stringify(data, null, 2), 'utf-8');
  fs.renameSync(tmpPath, filePath);
}

class Store {
  constructor(opts = {}) {
    this.dataDir = opts.dataDir || './data';
    const paths = getDataPaths(this.dataDir);
    this.paths = paths;
    this.db = loadDB(this.dataDir);
  }

  save() {
    const { dbFile, tmpFile } = this.paths;
    atomicWrite(dbFile, tmpFile, this.db);
  }

  ensureUser(email) {
    if (!this.db.users[email]) {
      this.db.users[email] = {
        budgets: [],
        debts: [],
        goals: [],
        obligations: [],
        bnpl: []
      };
    }
  }

  getUser(email) {
    this.ensureUser(email);
    return this.db.users[email];
  }

  setUser(email, userData) {
    this.db.users[email] = userData;
    this.save();
  }
}

module.exports = { Store };
