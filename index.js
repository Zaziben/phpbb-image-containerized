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

// Route to get messages
app.get('/messages', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM messages ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error querying database');
  }
});

// í´§ NEW: Route to post a message
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

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(port, () => {
  console.log(`DND Forum app listening on port ${port}`);
});

