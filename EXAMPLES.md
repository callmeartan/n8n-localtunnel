# Usage Examples

## Basic Usage

### Start n8n with Public Tunnel

```bash
./start.sh
```

This will:
- Start n8n in Docker
- Create a public tunnel URL
- Display all connection information

### Access Your n8n Instance

1. **Public Access**: Use the tunnel URL shown in the output
   ```
   https://abc123.localtunnel.me
   ```

2. **Local Access**: Use localhost
   ```
   http://localhost:5678
   ```

## Webhook Testing Examples

### Twilio Webhook

Use your tunnel URL for Twilio webhook callbacks:

```
https://abc123.localtunnel.me/webhook/twilio
```

### Stripe Webhook

Configure Stripe webhooks to point to:

```
https://abc123.localtunnel.me/webhook/stripe
```

### Generic Webhook

Any webhook endpoint can be accessed via:

```
https://abc123.localtunnel.me/webhook/[your-endpoint-name]
```

## Multiple Instances

### Running Multiple n8n Instances

1. **Create separate docker-compose files**:
   ```bash
   cp docker-compose.yml docker-compose-dev.yml
   ```

2. **Modify ports** in the new file:
   ```yaml
   ports:
     - "5679:5678"  # Different host port
   ```

3. **Update start.sh** to use different ports:
   ```bash
   N8N_PORT=5679
   LOCAL_PORT=5679
   COMPOSE_FILE="docker-compose-dev.yml"
   ```

## Custom Subdomain

### Request a Specific Subdomain

Edit `start.sh` and modify the tunnel creation:

```javascript
const tunnel = await localtunnel({ 
  port: port,
  subdomain: 'my-n8n-instance'  // Your desired subdomain
});
```

**Note**: Subdomains may not always be available.

## Environment-Specific Setup

### Development Environment

```bash
# Use different port
export N8N_PORT=5679
./start.sh
```

### Production-like Testing

```bash
# Use production-like settings
export NODE_ENV=production
./start.sh
```

## Troubleshooting Examples

### Check if Tunnel is Active

```bash
# View tunnel URL
cat .tunnel_url

# Test tunnel
curl $(cat .tunnel_url)
```

### View Logs

```bash
# n8n logs
docker-compose logs -f n8n

# Tunnel logs
tail -f /tmp/tunnel.log
```

### Restart Everything

```bash
# Stop all
docker-compose down
pkill -f localtunnel

# Start fresh
./start.sh
```

## Integration Examples

### CI/CD Pipeline

```yaml
# Example GitHub Actions workflow
- name: Start n8n with tunnel
  run: |
    npm install
    ./start.sh &
    sleep 30
    # Your tests here
```

### Automated Testing

```bash
#!/bin/bash
# test-webhook.sh

./start.sh &
TUNNEL_URL=$(cat .tunnel_url)
sleep 10

# Test webhook
curl -X POST "$TUNNEL_URL/webhook/test" \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

## Security Best Practices

### Use Strong Passwords

The script auto-generates passwords, but you can set your own:

```bash
# Generate custom password
openssl rand -base64 32 > .n8n_password
./start.sh
```

### Limit Tunnel Access

- Don't share tunnel URLs publicly
- Use basic authentication (enabled by default)
- Close tunnels when not in use

## Advanced Configuration

### Custom Docker Image

Edit `docker-compose.yml`:

```yaml
services:
  n8n:
    image: n8nio/n8n:latest  # Change to specific version
    # or
    # image: n8nio/n8n:1.0.0
```

### Custom Timezone

Edit `docker-compose.yml`:

```yaml
environment:
  - TZ=Europe/London  # Your timezone
  - GENERIC_TIMEZONE=Europe/London
```

### Additional Environment Variables

Add to `docker-compose.yml`:

```yaml
environment:
  - N8N_ENCRYPTION_KEY=your-encryption-key
  - N8N_USER_MANAGEMENT_DISABLED=false
  # ... other variables
```

