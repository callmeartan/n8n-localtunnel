#!/bin/bash

###############################################################################
# n8n Localtunnel Setup Script
# 
# This script automates the setup of n8n with localtunnel for public access.
# It handles Docker container management, tunnel creation, and configuration.
#
# Usage: ./start.sh
#
# Requirements:
#   - Docker and Docker Compose
#   - Node.js (v14+) and npm
#   - curl or wget
#
# For more information, see README.md
###############################################################################

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
N8N_PORT=5678
LOCAL_PORT=5678
COMPOSE_FILE="docker-compose.yml"
PASSWORD_FILE=".n8n_password"
TUNNEL_PASSWORD_FILE=".localtunnel_password"
TUNNEL_URL_FILE=".tunnel_url"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  n8n Automation Setup with Localtunnel${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to generate a secure random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to retrieve localtunnel password
get_tunnel_password() {
    if command_exists curl; then
        curl -s --max-time 5 https://loca.lt/mytunnelpassword 2>/dev/null | tr -d '\n\r '
    elif command_exists wget; then
        wget -q -O - --timeout=5 https://loca.lt/mytunnelpassword 2>/dev/null | tr -d '\n\r '
    else
        echo ""
    fi
}

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

if ! command_exists docker; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists docker-compose; then
    echo -e "${RED}Error: docker-compose is not installed. Please install docker-compose first.${NC}"
    exit 1
fi

if ! command_exists node; then
    echo -e "${RED}Error: Node.js is not installed. Please install Node.js first.${NC}"
    exit 1
fi

if ! command_exists npm; then
    echo -e "${RED}Error: npm is not installed. Please install npm first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All dependencies found${NC}"
echo ""

# Install localtunnel if not already installed
echo -e "${YELLOW}Checking localtunnel installation...${NC}"
if [ ! -d "node_modules/localtunnel" ]; then
    echo -e "${YELLOW}Installing localtunnel...${NC}"
    npm install
else
    echo -e "${GREEN}✓ localtunnel already installed${NC}"
fi
echo ""

# Generate or load password
if [ -f "$PASSWORD_FILE" ]; then
    echo -e "${YELLOW}Loading existing password from $PASSWORD_FILE...${NC}"
    N8N_PASSWORD=$(cat "$PASSWORD_FILE")
else
    echo -e "${YELLOW}Generating new password...${NC}"
    N8N_PASSWORD=$(generate_password)
    echo "$N8N_PASSWORD" > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
    echo -e "${GREEN}✓ Password saved to $PASSWORD_FILE${NC}"
fi
echo ""

# Stop any existing containers
echo -e "${YELLOW}Stopping any existing n8n containers...${NC}"
docker-compose -f "$COMPOSE_FILE" down 2>/dev/null || true
echo ""

# Start Docker Compose
echo -e "${YELLOW}Starting n8n with Docker Compose...${NC}"
docker-compose -f "$COMPOSE_FILE" up -d

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to start Docker Compose${NC}"
    exit 1
fi

echo -e "${GREEN}✓ n8n container started${NC}"
echo ""

# Wait for n8n to be ready
echo -e "${YELLOW}Waiting for n8n to be ready...${NC}"
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:$LOCAL_PORT > /dev/null 2>&1; then
        echo -e "${GREEN}✓ n8n is ready!${NC}"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}Error: n8n did not become ready in time${NC}"
    echo -e "${YELLOW}You can check the logs with: docker-compose logs${NC}"
    exit 1
fi

echo ""
echo ""

# Create localtunnel
echo -e "${YELLOW}Creating localtunnel...${NC}"
echo -e "${YELLOW}This may take a few seconds...${NC}"

# Use persistent file to store the tunnel URL
TEMP_URL_FILE=$(mktemp)

# Create tunnel using Node.js script in background and capture URL
# Following official localtunnel API: https://github.com/localtunnel/localtunnel
node -e "
const localtunnel = require('localtunnel');
const fs = require('fs');

let tunnel = null;
const port = $LOCAL_PORT;
const urlFile = '$TEMP_URL_FILE';
const persistentUrlFile = '$TUNNEL_URL_FILE';
let reconnectAttempts = 0;
const maxReconnectAttempts = 10;

async function createTunnel() {
  // localtunnel() returns a Promise directly - no need to wrap it
  const t = await localtunnel({ port: port });
  tunnel = t;
  const tunnelUrl = tunnel.url;
  
  // Write URL to both temp and persistent files
  fs.writeFileSync(urlFile, tunnelUrl);
  fs.writeFileSync(persistentUrlFile, tunnelUrl);
  
  console.log('Tunnel created:', tunnelUrl);
  return tunnel;
}

function setupTunnelHandlers(t) {
  // Handle tunnel close event - attempt reconnection
  t.on('close', () => {
    console.error('Tunnel closed, attempting to reconnect...');
    tunnel = null;
    
    if (reconnectAttempts < maxReconnectAttempts) {
      reconnectAttempts++;
      setTimeout(async () => {
        try {
          const newTunnel = await createTunnel();
          reconnectAttempts = 0; // Reset on successful reconnect
          setupTunnelHandlers(newTunnel);
        } catch (err) {
          console.error('Reconnection failed:', err.message);
          if (reconnectAttempts >= maxReconnectAttempts) {
            console.error('Max reconnection attempts reached');
            process.exit(1);
          }
        }
      }, 5000); // Wait 5 seconds before reconnecting
    } else {
      console.error('Max reconnection attempts reached');
      process.exit(1);
    }
  });
  
  // Handle tunnel errors
  t.on('error', (err) => {
    console.error('Tunnel error:', err.message);
    // Don't exit on error, let the close handler deal with reconnection
  });
  
  // Optional: Log requests (for debugging)
  // t.on('request', (info) => {
  //   console.log('Request:', info.method, info.path);
  // });
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    if (tunnel) tunnel.close();
    process.exit(0);
  });
  
  process.on('SIGTERM', () => {
    if (tunnel) tunnel.close();
    process.exit(0);
  });
}

(async () => {
  try {
    const t = await createTunnel();
    setupTunnelHandlers(t);
    
    // Keep process alive
    setInterval(() => {}, 1000);
  } catch (err) {
    console.error('Failed to create tunnel:', err.message);
    process.exit(1);
  }
})();
" > /tmp/tunnel.log 2>&1 &
TUNNEL_PID=$!

# Wait for tunnel URL to be written
MAX_WAIT=15
WAIT_COUNT=0
while [ ! -s "$TEMP_URL_FILE" ] && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ ! -s "$TEMP_URL_FILE" ]; then
    kill $TUNNEL_PID 2>/dev/null || true
    echo -e "${RED}Error: Failed to create localtunnel (timeout)${NC}"
    echo -e "${YELLOW}Tunnel logs:${NC}"
    tail -20 /tmp/tunnel.log 2>/dev/null || echo "No logs available"
    exit 1
fi

TUNNEL_URL=$(cat "$TEMP_URL_FILE")
rm -f "$TEMP_URL_FILE"

if [ -z "$TUNNEL_URL" ]; then
    kill $TUNNEL_PID 2>/dev/null || true
    echo -e "${RED}Error: Could not get tunnel URL${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Tunnel created successfully!${NC}"
echo ""

# Retrieve and save localtunnel password
echo -e "${YELLOW}Retrieving localtunnel password...${NC}"
TUNNEL_PASSWORD=""
MAX_PASSWORD_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_PASSWORD_RETRIES ]; do
    # Wait a bit longer on each retry
    if [ $RETRY_COUNT -gt 0 ]; then
        sleep $((RETRY_COUNT * 2))
    fi
    
    TUNNEL_PASSWORD=$(get_tunnel_password)
    
    # Check if we got a valid password (not empty, not an IP address, and has reasonable length)
    if [ -n "$TUNNEL_PASSWORD" ] && \
       [[ ! "$TUNNEL_PASSWORD" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && \
       [ ${#TUNNEL_PASSWORD} -gt 5 ]; then
        echo "$TUNNEL_PASSWORD" > "$TUNNEL_PASSWORD_FILE"
        chmod 600 "$TUNNEL_PASSWORD_FILE"
        echo -e "${GREEN}✓ Localtunnel password retrieved and saved${NC}"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_PASSWORD_RETRIES ]; then
        echo -n "."
    fi
done

if [ -z "$TUNNEL_PASSWORD" ] || \
   [[ "$TUNNEL_PASSWORD" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
   [ ${#TUNNEL_PASSWORD} -le 5 ]; then
    echo ""
    echo -e "${YELLOW}⚠ Could not retrieve localtunnel password immediately${NC}"
    echo -e "${YELLOW}  The password may take a moment to become available.${NC}"
    echo -e "${YELLOW}  Will continue trying in the background...${NC}"
    TUNNEL_PASSWORD="(retrieving...)"
    
    # Start background process to periodically try to get the password
    (
        for i in {1..10}; do
            sleep $((i * 3))
            PWD=$(get_tunnel_password)
            if [ -n "$PWD" ] && \
               [[ ! "$PWD" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && \
               [ ${#PWD} -gt 5 ]; then
                echo "$PWD" > "$TUNNEL_PASSWORD_FILE"
                chmod 600 "$TUNNEL_PASSWORD_FILE"
                echo ""
                echo -e "${GREEN}✓ Localtunnel password retrieved: $PWD${NC}"
                echo ""
                break
            fi
        done
    ) &
    PASSWORD_RETRIEVER_PID=$!
else
    PASSWORD_RETRIEVER_PID=""
fi
echo ""

# Update docker-compose.yml with the new webhook URL
echo -e "${YELLOW}Updating docker-compose.yml with tunnel URL...${NC}"

# Create a backup
cp "$COMPOSE_FILE" "${COMPOSE_FILE}.backup"

# Update WEBHOOK_URL and configure basic auth in docker-compose.yml using Python for reliability
python3 << EOF
import re
import sys

compose_file = "$COMPOSE_FILE"
tunnel_url = "$TUNNEL_URL"
password = "$N8N_PASSWORD"
host = tunnel_url.replace("https://", "").replace("http://", "").split("/")[0]

with open(compose_file, 'r') as f:
    content = f.read()

# Update WEBHOOK_URL
content = re.sub(r'WEBHOOK_URL=.*', f'WEBHOOK_URL={tunnel_url}/', content)

# Update N8N_HOST
content = re.sub(r'N8N_HOST=.*', f'N8N_HOST={host}', content)

# Update or add basic auth settings
if 'N8N_BASIC_AUTH_ACTIVE' in content:
    content = re.sub(r'N8N_BASIC_AUTH_ACTIVE=.*', 'N8N_BASIC_AUTH_ACTIVE=true', content)
else:
    # Insert after NODE_ENV line
    content = re.sub(
        r'(NODE_ENV=production)',
        r'\1\n      - N8N_BASIC_AUTH_ACTIVE=true',
        content
    )

if 'N8N_BASIC_AUTH_USER' in content:
    content = re.sub(r'N8N_BASIC_AUTH_USER=.*', 'N8N_BASIC_AUTH_USER=admin', content)
else:
    content = re.sub(
        r'(N8N_BASIC_AUTH_ACTIVE=true)',
        r'\1\n      - N8N_BASIC_AUTH_USER=admin',
        content
    )

if 'N8N_BASIC_AUTH_PASSWORD' in content:
    content = re.sub(r'N8N_BASIC_AUTH_PASSWORD=.*', f'N8N_BASIC_AUTH_PASSWORD={password}', content)
else:
    content = re.sub(
        r'(N8N_BASIC_AUTH_USER=admin)',
        f'\\1\n      - N8N_BASIC_AUTH_PASSWORD={password}',
        content
    )

with open(compose_file, 'w') as f:
    f.write(content)
EOF

echo -e "${GREEN}✓ Configuration updated${NC}"
echo ""

# Restart container to apply new environment variables
echo -e "${YELLOW}Restarting n8n to apply new configuration...${NC}"
docker-compose -f "$COMPOSE_FILE" restart n8n
echo -e "${GREEN}✓ n8n restarted${NC}"
echo ""

# Display summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Public Tunnel URL:${NC} $TUNNEL_URL"
echo -e "${GREEN}Local URL:${NC}        http://localhost:$LOCAL_PORT"
echo -e "${GREEN}n8n Username:${NC}     admin"
echo -e "${GREEN}n8n Password:${NC}     $N8N_PASSWORD"
echo -e "${GREEN}Tunnel Password:${NC}  $TUNNEL_PASSWORD"
echo ""
echo -e "${YELLOW}Important Information:${NC}"
echo -e "  • n8n password saved to: ${BLUE}$PASSWORD_FILE${NC}"
if [ -f "$TUNNEL_PASSWORD_FILE" ]; then
    echo -e "  • Tunnel password saved to: ${BLUE}$TUNNEL_PASSWORD_FILE${NC}"
fi
echo -e "  • Configuration backup: ${BLUE}${COMPOSE_FILE}.backup${NC}"
echo -e "  • Tunnel will remain active until you stop this script (Ctrl+C)"
echo ""
echo -e "${YELLOW}Access n8n:${NC}"
echo -e "  • Public: ${BLUE}$TUNNEL_URL${NC}"
echo -e "  • Local:  ${BLUE}http://localhost:$LOCAL_PORT${NC}"
echo ""
if [ "$TUNNEL_PASSWORD" = "(retrieving...)" ]; then
    echo -e "${YELLOW}Note:${NC}"
    echo -e "  • Tunnel password is being retrieved in the background"
    echo -e "  • Check ${BLUE}$TUNNEL_PASSWORD_FILE${NC} or visit ${BLUE}https://loca.lt/mytunnelpassword${NC}"
    echo ""
fi
echo -e "${YELLOW}To stop:${NC}"
echo -e "  • Press Ctrl+C to close the tunnel"
echo -e "  • Run: ${BLUE}docker-compose down${NC} to stop containers"
echo ""
echo -e "${BLUE}========================================${NC}"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down...${NC}"
    kill $TUNNEL_PID 2>/dev/null || true
    if [ -n "$PASSWORD_RETRIEVER_PID" ]; then
        kill $PASSWORD_RETRIEVER_PID 2>/dev/null || true
    fi
    # Clean up temp file
    rm -f /tmp/tunnel.log 2>/dev/null || true
    echo -e "${GREEN}✓ Tunnel closed${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Keep the tunnel alive
echo -e "${YELLOW}Tunnel is active. Press Ctrl+C to close...${NC}"
echo -e "${YELLOW}Note: Tunnel will automatically reconnect if disconnected${NC}"
echo ""

# Monitor tunnel process and show status
while kill -0 $TUNNEL_PID 2>/dev/null; do
    sleep 5
    # Check if tunnel URL file still exists and is valid
    if [ -f "$TUNNEL_URL_FILE" ] && [ -s "$TUNNEL_URL_FILE" ]; then
        CURRENT_URL=$(cat "$TUNNEL_URL_FILE" 2>/dev/null)
        if [ -n "$CURRENT_URL" ] && [ "$CURRENT_URL" != "$TUNNEL_URL" ]; then
            echo -e "${GREEN}✓ Tunnel reconnected: $CURRENT_URL${NC}"
            TUNNEL_URL="$CURRENT_URL"
        fi
    fi
done

# If we get here, the tunnel process died
echo -e "${RED}Tunnel process ended unexpectedly${NC}"
echo -e "${YELLOW}Check logs: tail -f /tmp/tunnel.log${NC}"
cleanup

