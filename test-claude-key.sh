#!/usr/bin/env bash
# Test Claude API key validity

API_KEY="${1:-$ANTHROPIC_API_KEY}"

if [ -z "$API_KEY" ]; then
    echo "❌ No API key provided"
    echo "Usage: $0 <api-key>"
    echo "   OR: export ANTHROPIC_API_KEY='sk-ant-...' && $0"
    exit 1
fi

echo "Testing Claude API key..."
echo "Key: ${API_KEY:0:20}...${API_KEY: -4}"
echo ""

# Test with minimal request
RESPONSE=$(curl -sS https://api.anthropic.com/v1/messages \
  -H "x-api-key: $API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 10,
    "messages": [{"role": "user", "content": "Hi"}]
  }' 2>&1)

# Check for errors
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    ERROR_TYPE=$(echo "$RESPONSE" | jq -r '.error.type')
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message')

    echo "❌ API Key Test FAILED"
    echo ""
    echo "Error Type: $ERROR_TYPE"
    echo "Error Message: $ERROR_MSG"
    echo ""

    case "$ERROR_TYPE" in
        authentication_error)
            echo "🔑 Your API key is INVALID or EXPIRED"
            echo "   → Get a new key from: https://console.anthropic.com/"
            ;;
        permission_error)
            echo "🚫 Your API key lacks permissions"
            echo "   → Check your API key settings"
            ;;
        rate_limit_error)
            echo "⏱️  Rate limit exceeded (but key is valid!)"
            ;;
        *)
            echo "Full response:"
            echo "$RESPONSE" | jq '.'
            ;;
    esac
    exit 1
elif echo "$RESPONSE" | jq -e '.content[0].text' >/dev/null 2>&1; then
    TEXT=$(echo "$RESPONSE" | jq -r '.content[0].text')
    echo "✅ API Key is VALID and working!"
    echo ""
    echo "Response from Claude: $TEXT"
    echo ""
    echo "Model: claude-3-5-sonnet-20241022"
    echo "Status: Ready to use"
else
    echo "⚠️  Unexpected response:"
    echo "$RESPONSE"
fi
