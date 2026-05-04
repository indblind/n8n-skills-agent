#!/bin/bash
# Registers Atlas bot webhook with Telegram after cloudflared tunnel is ready.
# Run once after `docker compose up -d` to activate Telegram.

set -e

ROSSELL_AI_TOKEN="8104577186:AAHEwlQcQ65UUqiXrN_OnbAho81fToGD4Bo"
# NOTE: Atlas bot (8296459115) is reserved for openclaw polling — do NOT register a webhook on it
WEBHOOK_ID="tg-rossell-ai-bot-001"

echo "Waiting for cloudflared tunnel URL..."

TUNNEL_URL=""
for i in $(seq 1 30); do
  TUNNEL_URL=$(docker logs n8n-cloudflared 2>&1 | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' | tail -1)
  if [ -n "$TUNNEL_URL" ]; then
    break
  fi
  echo "  attempt $i/30..."
  sleep 3
done

if [ -z "$TUNNEL_URL" ]; then
  echo "ERROR: could not get tunnel URL from cloudflared logs"
  docker logs n8n-cloudflared 2>&1 | tail -20
  exit 1
fi

echo "Tunnel URL: $TUNNEL_URL"

# Update n8n WEBHOOK_URL so it generates correct URLs
WEBHOOK_PATH="$TUNNEL_URL/webhook/$WEBHOOK_ID"
echo "Telegram webhook: $WEBHOOK_PATH"

# Register with Telegram
RESULT=$(curl -s "https://api.telegram.org/bot${ROSSELL_AI_TOKEN}/setWebhook" \
  --data-urlencode "url=$WEBHOOK_PATH")

echo "Telegram response: $RESULT"

OK=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ok'))" 2>/dev/null)
if [ "$OK" = "True" ]; then
  echo ""
  echo "SUCCESS — @atlas_rossell_bot is live at $TUNNEL_URL"
  echo "Send a message to @atlas_rossell_bot to test"
else
  echo "FAILED — check response above"
fi
