const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const DEFAULT_AUTH_STORE_PATH = path.join(__dirname, '..', 'data', 'users.json');
const HASH_ITERATIONS = 120000;
const HASH_KEY_LENGTH = 32;
const HASH_DIGEST = 'sha256';

function normalizePhone(phone) {
  return typeof phone === 'string' ? phone.trim() : '';
}

function validatePhone(phone) {
  return /^1\d{10}$/.test(phone);
}

function validatePassword(password) {
  return typeof password === 'string' && password.length >= 6 && password.length <= 64;
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.pbkdf2Sync(password, salt, HASH_ITERATIONS, HASH_KEY_LENGTH, HASH_DIGEST).toString('hex');
  return `${HASH_ITERATIONS}:${salt}:${hash}`;
}

function verifyPassword(password, storedHash) {
  const parts = typeof storedHash === 'string' ? storedHash.split(':') : [];
  if (parts.length !== 3) {
    return false;
  }
  const iterations = Number(parts[0]);
  const salt = parts[1];
  const expected = parts[2];
  if (!Number.isFinite(iterations) || salt.length === 0 || expected.length === 0) {
    return false;
  }
  const actual = crypto.pbkdf2Sync(password, salt, iterations, HASH_KEY_LENGTH, HASH_DIGEST).toString('hex');
  return crypto.timingSafeEqual(Buffer.from(actual), Buffer.from(expected));
}

function createToken() {
  return crypto.randomBytes(32).toString('hex');
}

function publicUser(user) {
  return {
    id: user.id,
    phone: user.phone,
    createdAt: user.createdAt
  };
}

class FileUserStore {
  constructor(filePath = DEFAULT_AUTH_STORE_PATH) {
    this.filePath = filePath;
  }

  loadUsers() {
    try {
      if (!fs.existsSync(this.filePath)) {
        return [];
      }
      const content = fs.readFileSync(this.filePath, 'utf8');
      const parsed = JSON.parse(content);
      return Array.isArray(parsed.users) ? parsed.users : [];
    } catch (error) {
      return [];
    }
  }

  saveUsers(users) {
    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    fs.writeFileSync(this.filePath, JSON.stringify({ users }, null, 2), 'utf8');
  }
}

class MemoryUserStore {
  constructor(users = []) {
    this.users = users;
  }

  loadUsers() {
    return this.users.slice();
  }

  saveUsers(users) {
    this.users = users.slice();
  }
}

class AuthService {
  constructor(userStore = new FileUserStore()) {
    this.userStore = userStore;
  }

  register(body = {}) {
    const phone = normalizePhone(body.phone);
    const password = typeof body.password === 'string' ? body.password : '';
    if (!validatePhone(phone)) {
      return { statusCode: 400, payload: { error: 'INVALID_PHONE' } };
    }
    if (!validatePassword(password)) {
      return { statusCode: 400, payload: { error: 'INVALID_PASSWORD' } };
    }
    const users = this.userStore.loadUsers();
    if (users.some((user) => user.phone === phone)) {
      return { statusCode: 409, payload: { error: 'PHONE_ALREADY_REGISTERED' } };
    }
    const now = new Date().toISOString();
    const user = {
      id: crypto.randomUUID ? crypto.randomUUID() : crypto.randomBytes(16).toString('hex'),
      phone,
      passwordHash: hashPassword(password),
      createdAt: now
    };
    users.push(user);
    this.userStore.saveUsers(users);
    return {
      statusCode: 200,
      payload: {
        token: createToken(),
        user: publicUser(user)
      }
    };
  }

  login(body = {}) {
    const phone = normalizePhone(body.phone);
    const password = typeof body.password === 'string' ? body.password : '';
    if (!validatePhone(phone) || !validatePassword(password)) {
      return { statusCode: 401, payload: { error: 'INVALID_CREDENTIALS' } };
    }
    const users = this.userStore.loadUsers();
    const user = users.find((item) => item.phone === phone);
    if (!user || !verifyPassword(password, user.passwordHash)) {
      return { statusCode: 401, payload: { error: 'INVALID_CREDENTIALS' } };
    }
    return {
      statusCode: 200,
      payload: {
        token: createToken(),
        user: publicUser(user)
      }
    };
  }
}

module.exports = {
  AuthService,
  FileUserStore,
  MemoryUserStore,
  hashPassword,
  validatePassword,
  validatePhone,
  verifyPassword
};
