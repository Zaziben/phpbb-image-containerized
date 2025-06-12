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

// Route to get messages
const path = require('path');

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
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

app.listen(port, () => {
  console.log(`DND Forum app listening on port ${port}`);
});

