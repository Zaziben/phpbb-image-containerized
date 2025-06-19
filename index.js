//
const express = require('express');
const { Pool } = require('pg');
const path = require('path');
const app = express();
const port = 8080;
// Middleware to parse JSON bodies
app.use(express.json());

//paths for login and admin
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(port, () => {
  console.log(`DND Forum app listening on port ${port}`);
});

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin.html'));
});

app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'login.html'));
});

// Middleware to verify JWT
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, async (err, user) => {
    if (err) return res.sendStatus(403);

    try {
      const result = await pool.query('SELECT * FROM users WHERE username = $1', [user.username]);
      const dbUser = result.rows[0];

      if (!dbUser) return res.sendStatus(404);

      // NEW: Only enforce `invited = true` for non-admins
      if (!dbUser.is_admin && !dbUser.invited) {
        return res.status(403).json({ error: 'Not invited' });
      }

      req.user = dbUser;
      next();
    } catch (err) {
      console.error(err);
      res.sendStatus(500);
    }
  });
}

// Configure Postgres connection
const pool = new Pool({
  host: process.env.POSTGRES_HOST,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
  port: 5432,
  ssl: {
    rejectUnauthorized: false // For RDS; this skips cert validation
  },
});

app.use(express.static(__dirname));

app.get('/messages', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM messages ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error querying database');
  }
});
// invitations cont
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'supersecret'; // store securely in prod
const transporter = nodemailer.createTransport({
  host: 'smtp.example.com', // e.g., smtp.gmail.com
  port: 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});
app.post('/admin/send-invite', async (req, res) => {
  const { email } = req.body;

  // TODO: check if admin is logged in

  const code = crypto.randomBytes(20).toString('hex');
  const inviteLink = `https://yourforum.com/register?code=${code}`;

  try {
    await pool.query(
      'INSERT INTO invites (email, code) VALUES ($1, $2)',
      [email, code]
    );

    await transporter.sendMail({
      from: '"DND Forum" <your@email.com>',
      to: 'email',
      subject: 'You are invited to join the DND forum',
      text: `Click the link to register: ${inviteLink}`,
      html: `<p>Click <a href="${inviteLink}">here</a> to register.</p>`
    });

    res.status(200).json({ message: 'Invite sent' });
  } catch (err) {
    console.error(err);
    res.status(500).send('Failed to send invite');
  }
});

// registration route
app.post('/register', async (req, res) => {
  const { username, password, inviteCode } = req.body;

  if (!username || !password || !inviteCode) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    // 1. Validate invite code
    const inviteResult = await pool.query(
      'SELECT * FROM invitations WHERE code = $1 AND used = false',
      [inviteCode]
    );
    if (inviteResult.rows.length === 0) {
      return res.status(403).json({ error: 'Invalid or already used invite code' });
    }

    // 2. Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // 3. Insert user into the users table
    const userResult = await pool.query(
      'INSERT INTO users (username, password) VALUES ($1, $2) RETURNING id',
      [username, hashedPassword]
    );

    const userId = userResult.rows[0].id;

    // 4. Mark invite as used
    await pool.query(
      'UPDATE invitations SET used = true, used_by = $1 WHERE code = $2',
      [userId, inviteCode]
    );

    // 5. (Optional) Send back a token or redirect to login
    const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '2h' });
    res.json({ message: 'Registration successful', token });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
// login route
app.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password)
    return res.status(400).json({ error: 'Username and password are required' });

  try {
    const result = await pool.query('SELECT * FROM users WHERE username = $1', [username]);
    const user = result.rows[0];

    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, {
      expiresIn: '1h'
    });

    res.json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  }
});

// ��� NEW: Route to post a message
app.post('/messages', async (req, res) => {
  const { author, message } = req.body;

  if (!author || !message) {
    return res.status(400).json({ error: 'Author and message are required' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO messages (author, message, created_at) VALUES ($1, $2, NOW()) RETURNING *',
      [author, message]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error inserting message');
  }
});

app.get('/threads', authenticateToken, async (req, res) => {
  const result = await pool.query('SELECT * FROM threads ORDER BY created_at DESC');
  res.json(result.rows);
});

app.get('/threads/:id', async (req, res) => {
  const threadId = req.params.id;
  const thread = await pool.query('SELECT * FROM threads WHERE id = $1', [threadId]);
  const messages = await pool.query('SELECT * FROM messages WHERE thread_id = $1 ORDER BY created_at ASC', [threadId]);

  res.json({
    thread: thread.rows[0],
    messages: messages.rows
  });
});

app.post('/threads', async (req, res) => {
  const { title, author, message } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO threads (title, author) VALUES ($1, $2) RETURNING id',
      [title, author]
    );
    const threadId = result.rows[0].id;

    await pool.query(
      'INSERT INTO messages (author, message, thread_id) VALUES ($1, $2, $3)',
      [author, message, threadId]
    );

    res.status(201).json({ threadId });
  } catch (err) {
    console.error(err);
    res.status(500).send('Error creating thread');
  }
});

app.post('/threads/:id/messages', async (req, res) => {
  const { author, message } = req.body;
  const threadId = req.params.id;

  try {
    await pool.query(
      'INSERT INTO messages (author, message, thread_id) VALUES ($1, $2, $3)',
      [author, message, threadId]
    );
    res.status(201).send('Message added');
  } catch (err) {
    console.error(err);
    res.status(500).send('Error posting message');
  }
});



