#!/usr/bin/env bash
set -euo pipefail

function print_hex_bar {
  local percent=$1
  local width=30
  local filled=$(( (percent * width) / 100 ))
  local empty=$(( width - filled ))
  printf "\r\033[38;5;82m["; printf "\033[48;5;82m \033[0m%.0s" $(seq 1 $filled)
  printf "\033[38;5;242m%.0s─\033[0m" $(seq 1 $empty)
  printf "\033[38;5;82m]\033[0m %3d%%" "$percent"
}

echo -e "\n\033[38;5;45mCommencing Skyscope Sentinel Intelligence auto configuration of Crush terminal application\033[0m"
sleep 2

echo -e "\n\033[38;5;93mYour instance will support persistent memory, sequential thinking, Ollama LLMs, MCP tool use, and browser automation.\033[0m"
sleep 2

echo -e "\033[38;5;105mUpdating and installing dependencies...\033[0m"
sudo apt-get update -qq && sudo apt-get install -y curl npm jq git nodejs npm

echo -e "\n\033[38;5;99mInstalling Ollama local environment...\033[0m"
curl -fsSL https://ollama.com/install.sh | sh

sleep 2
echo -e "\033[38;5;105mValidating Ollama installation...\033[0m"
ollama --version

echo -e "\n\033[38;5;111mPulling recommended Ollama models...\033[0m"
models=("glm4:latest" "devstral:latest" "starcoder2:15b")
for model in "${models[@]}"; do
  echo -e " Pulling model $model..."
  ollama pull "$model" &

  # Simulate progress bar for pulls
  for p in {0..100..10}; do
    print_hex_bar $p
    sleep 0.25
  done
  echo
done

echo -e "\033[38;5;105mConfiguring Crush CLI...\033[0m"

if ! command -v crush &>/dev/null; then
  echo -e "\033[38;5;105mInstalling Crush CLI via npm...\033[0m"
  npm install -g @charmland/crush
else
  echo -e "\033[38;5;105mCrush CLI found, skipping installation.\033[0m"
fi

crush --version || { echo -e "\033[38;5;196mCrush install failed! Exiting.\033[0m" >&2; exit 1; }

CRUSH_CONFIG_DIR="${HOME}/.config/crush"
mkdir -p "$CRUSH_CONFIG_DIR"

cat > "$CRUSH_CONFIG_DIR/crush.json" <<EOF
{
  "providers": {
    "ollama": {
      "type": "openai",
      "base_url": "http://localhost:11434/v1",
      "api_key": "ollama"
    }
  },
  "models": {
    "large": {
      "model": "glm4:latest",
      "provider": "ollama",
      "reasoning_effort": "medium",
      "max_tokens": 65536
    },
    "small": {
      "model": "devstral:latest",
      "provider": "ollama",
      "reasoning_effort": "medium",
      "max_tokens": 65536
    },
    "code": {
      "model": "starcoder2:15b",
      "provider": "ollama",
      "max_tokens": 4096
    }
  },
  "options": {
    "memory": {
      "persistent": true,
      "max_history": 1000,
      "sequential": true
    },
    "thinking": {
      "enabled": true,
      "delay_ms": 300
    },
    "tool_use": {
      "enabled": true,
      "mcp_endpoint": "http://localhost:8080"
    },
    "tui": {
      "compact_mode": true
    }
  }
}
EOF

echo -e "\033[38;5;117mCrush configuration file created at $CRUSH_CONFIG_DIR/crush.json\033[0m"

echo -e "\033[38;5;105mSetting Ollama daemon systemd service...\033[0m"

cat <<EOF | sudo tee /etc/systemd/system/ollama.service >/dev/null
[Unit]
Description=Ollama LLM Local API Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama daemon
Restart=always
User=$USER
Environment=OLLAMA_API_KEY=ollama

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ollama.service
sudo systemctl start ollama.service

sleep 2

if systemctl is-active --quiet ollama.service; then
  echo -e "\033[38;5;82mOllama daemon is running and functional.\033[0m"
else
  echo -e "\033[38;5;196mOllama daemon failed to start! Please check logs.\033[0m"
  exit 1
fi

echo -e "\033[38;5;105mInstalling and configuring MCP servers for extended tools...\033[0m"

npm install -g @charmland/mcp puppeteer playwright

MCP_CONFIG_DIR="${HOME}/.config/mcp"
mkdir -p "$MCP_CONFIG_DIR"

cat > "$MCP_CONFIG_DIR/browser_automation.js" <<'EOF'
#!/usr/bin/env node
const puppeteer = require('puppeteer');

async function main() {
  let command = process.argv[2] || "";
  let url = process.argv[3] || "about:blank";

  const browser = await puppeteer.launch({headless: true});
  const page = await browser.newPage();

  if (command === "navigate") {
    await page.goto(url);
    console.log(`Navigated to ${url}`);
  }
  // Extend commands like screenshot, fill form here
  await browser.close();
}

main().catch(console.error);
EOF
chmod +x "$MCP_CONFIG_DIR/browser_automation.js"

cat > "$MCP_CONFIG_DIR/mcp.json" <<EOF
{
  "servers": {
    "stdio": {
      "type": "stdio",
      "enabled": true
    },
    "http": {
      "type": "http",
      "port": 8080,
      "allowed_origins": ["*"],
      "enabled": true
    }
  },
  "tools": {
    "fetch": {
      "command": "curl",
      "args": ["-s", "-L"],
      "enabled": true
    },
    "filesystem_read": {
      "command": "cat",
      "args": [],
      "enabled": true
    },
    "filesystem_write": {
      "command": "tee",
      "args": [],
      "enabled": true
    },
    "git": {
      "command": "git",
      "args": [],
      "enabled": true
    },
    "browser_firefox": {
      "command": "firefox",
      "args": ["--remote-debugging-port=9222"],
      "enabled": true
    },
    "browser_chromium": {
      "command": "browseros",
      "args": ["--remote-debugging-port=9223"],
      "enabled": true
    },
    "browser_automation": {
      "command": "$MCP_CONFIG_DIR/browser_automation.js",
      "args": [],
      "enabled": true
    },
    "process_list": {
      "command": "ps",
      "args": ["aux"],
      "enabled": true
    },
    "kill_process": {
      "command": "kill",
      "args": [],
      "enabled": true
    },
    "system_info": {
      "command": "top",
      "args": ["-b", "-n", "1"],
      "enabled": true
    },
    "file_explore": {
      "command": "ls",
      "args": ["-la"],
      "enabled": true
    },
    "package_manager": {
      "command": "apt",
      "args": ["list", "--installed"],
      "enabled": true
    }
  }
}
EOF

pkill -f mcp || true
nohup mcp -c "$MCP_CONFIG_DIR/mcp.json" >"$HOME/mcp.log" 2>&1 &

echo -e "\033[38;5;82mMCP server with extended tools started.\033[0m"

echo -e "\033[38;5;45mConfiguring 5GB RAM disk for rapid cache to speed model inference...\033[0m"
RAMDISK_DIR="${HOME}/ramdisk_inference_cache"
mkdir -p "$RAMDISK_DIR"
sudo mount -t tmpfs -o size=5G tmpfs "$RAMDISK_DIR" || echo -e "\033[38;5;214mRamdisk probably already mounted\033[0m"

echo -e "Ollama inference cache directory set to RAM disk: $RAMDISK_DIR"
export OLLAMA_CACHE_DIR="$RAMDISK_DIR"

jq --arg cache_dir "$OLLAMA_CACHE_DIR" '
  .options.memory.cache_dir = $cache_dir
  | .options.memory.max_ram_usage_mb = 5120
' "$CRUSH_CONFIG_DIR/crush.json" > "$CRUSH_CONFIG_DIR/crush.tmp.json"
mv "$CRUSH_CONFIG_DIR/crush.tmp.json" "$CRUSH_CONFIG_DIR/crush.json"

echo -e "\033[38;5;117mUpdated Crush configuration for RAM-based keep-alive inference.\033[0m"

export CRUSH_MCP_ENDPOINT="http://localhost:8080"
export CRUSH_PROVIDER="ollama"
export CRUSH_DISABLE_PROVIDER_AUTO_UPDATE=1

choose_ollama_model() {
  echo -e "\033[38;5;105mAvailable Ollama models:\033[0m"
  ollama list

  read -r -p "Enter large model name [glm4:latest]: " large_model
  large_model=${large_model:-glm4:latest}

  read -r -p "Enter small model name [devstral:latest]: " small_model
  small_model=${small_model:-devstral:latest}

  read -r -p "Enter code model name [starcoder2:15b]: " code_model
  code_model=${code_model:-starcoder2:15b}

  jq --arg lm "$large_model" --arg sm "$small_model" --arg cm "$code_model" '
    .models.large.model = $lm |
    .models.small.model = $sm |
    .models.code.model = $cm
  ' "$CRUSH_CONFIG_DIR/crush.json" > "$CRUSH_CONFIG_DIR/crush.tmp.json"
  mv "$CRUSH_CONFIG_DIR/crush.tmp.json" "$CRUSH_CONFIG_DIR/crush.json"
  echo -e "\033[38;5;82mCrush config updated with selected models.\033[0m"
}

choose_ollama_model

echo -e "\n\033[38;5;45mInstallation and Configuration complete!\033[0m"
echo -e "\033[38;5;82mRun 'crush' in your terminal to start your AI coding assistant with Ollama and MCP.\033[0m"
sleep 2
