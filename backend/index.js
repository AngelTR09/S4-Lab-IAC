const http = require('http');

const databaseUrl = process.env.DATABASE_URL || 'not-set';

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ service: 'iac-lab04-api', databaseConfigured: databaseUrl !== 'not-set' }));
});

server.listen(3000, () => {
  console.log(`API escuchando en :3000 (DATABASE_URL=${databaseUrl})`);
});
