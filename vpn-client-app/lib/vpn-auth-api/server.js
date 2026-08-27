// vpn-auth-api/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Path to vpn-ui database (adjust as needed)
const DB_PATH = '/usr/local/vpn-ui/db/vpn-ui.db'; // Or wherever it is

function getDb() {
  return new sqlite3.Database(DB_PATH, sqlite3.OPEN_READONLY);
}

// Login endpoint
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  
  const db = getDb();
  
  // Adjust SQL based on your vpn-ui schema
  // This is a generic example - inspect your actual DB schema
  db.get(
    `SELECT u.*, c.download, c.upload, c.total, c.expiry_time, c.status 
     FROM users u 
     LEFT JOIN client_traffics c ON u.username = c.email 
     WHERE u.username = ? AND u.password = ?`,
    [username, password],
    (err, row) => {
      db.close();
      
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      if (!row) {
        return res.status(401).json({ success: false, error: 'Invalid credentials' });
      }
      
      res.json({
        success: true,
        user: {
          username: row.username,
          status: row.status || 'Active',
          expiry: row.expiry_time,
          download: row.download,
          upload: row.upload,
          total_used: row.total,
          total_quota: row.total_quota || 'Unlimited',
        }
      });
    }
  );
});

// Stats endpoint
app.get('/api/user/stats', (req, res) => {
  const { username } = req.query;
  const db = getDb();
  
  db.get(
    `SELECT * FROM client_traffics WHERE email = ?`,
    [username],
    (err, row) => {
      db.close();
      if (err || !row) return res.status(404).json({ error: 'Not found' });
      
      res.json({
        username: row.email,
        status: row.status || 'Active',
        expiry: row.expiry_time,
        download: row.download,
        upload: row.upload,
        total_used: row.total,
        total_quota: row.total_quota || 'Unlimited',
      });
    }
  );
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Auth API running on port 3000');
});
