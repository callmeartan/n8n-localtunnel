# Quick Start Guide

Get up and running in 3 steps!

## Step 1: Install Dependencies

Make sure you have:
- ✅ Docker installed and running
- ✅ Node.js (v14+) installed
- ✅ npm installed

## Step 2: Install Project Dependencies

```bash
npm install
```

## Step 3: Run the Script

```bash
./start.sh
```

## That's It! 🎉

You'll see output like this:

```
========================================
  n8n Automation Setup with Localtunnel
========================================

✓ All dependencies found
✓ localtunnel already installed
✓ n8n container started
✓ Tunnel created successfully!

========================================
  Setup Complete!
========================================

Public Tunnel URL: https://abc123.localtunnel.me
Local URL:        http://localhost:5678
Username:         admin
Password:         YourGeneratedPassword123

Access n8n:
  • Public: https://abc123.localtunnel.me
  • Local:  http://localhost:5678
```

## Next Steps

1. **Access n8n**: Open the Public Tunnel URL in your browser
2. **Login**: Use username `admin` and the generated password
3. **Share**: Share the tunnel URL with others or use it for webhook testing
4. **Stop**: Press `Ctrl+C` to stop the tunnel (n8n keeps running)

## Common Commands

```bash
# Start everything
./start.sh

# Stop tunnel (Ctrl+C)
# Then stop n8n
docker-compose down

# View n8n logs
docker-compose logs n8n

# View tunnel logs
tail -f /tmp/tunnel.log
```

## Need Help?

Check the [README.md](README.md) for detailed documentation and troubleshooting.

