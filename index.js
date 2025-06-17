const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = 8080;

// Middleware to parse JSON bodies
app.use(express.json());

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

app.get('/threads', async (req, res) => {
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

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(port, () => {
  console.log(`DND Forum app listening on port ${port}`);
});

