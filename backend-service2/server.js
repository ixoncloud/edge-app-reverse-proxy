const express = require('express');
const app = express();
const port = 8082;

app.get('/', (req, res) => {
  res.json({
    service: 'Backend Service 2',
    message: 'Hello from Service 2!',
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Backend Service 2 listening at http://0.0.0.0:${port}`);
});
