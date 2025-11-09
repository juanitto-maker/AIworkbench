# AIWB Installation Guide for Termux

Complete step-by-step installation guide for running AIWB v2.0 on Termux (Android).

---

## 📱 Step 1: Install and Setup Termux

### Download Termux
- **F-Droid** (Recommended): https://f-droid.org/en/packages/com.termux/
- NOT from Google Play (outdated version)

### First-Time Termux Setup

```bash
# Update package manager
pkg update && pkg upgrade -y

# Allow storage access (IMPORTANT - enables Android-visible workspace)
termux-setup-storage

# Press "Allow" when prompted
```

---

## ⚙️ Step 2: Install Dependencies

```bash
# Install required packages
pkg install -y bash curl jq git

# Install optional but HIGHLY recommended
pkg install -y gum fzf

# Verify installation
which bash jq curl git
```

---

## 📥 Step 3: Clone AIWB

```bash
# Go to home directory
cd ~

# Clone the repository
git clone https://github.com/juanitto-maker/AIworkbench.git

# Enter directory
cd AIworkbench

# Checkout the v2.0 branch with all enhancements
git checkout claude/analyze-app-enhancements-011CUwGmkEuSHmiJKRhE5bGG

# Make aiwb executable
chmod +x aiwb
```

---

## 🔑 Step 4: Get Your API Keys

AIWB now supports **4 providers**. Get at least ONE key:

### Option 1: Groq (RECOMMENDED - FREE!)
1. Go to: https://console.groq.com/
2. Sign up (free account)
3. Go to "API Keys"
4. Click "Create API Key"
5. Copy the key (starts with `gsk_...`)

**Why Groq?**
- ✅ FREE tier available
- ✅ Ultra-fast inference (fastest in the industry!)
- ✅ Llama 3.1 70B model
- ✅ Perfect for Termux users

### Option 2: Gemini (Google)
1. Go to: https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key

**Free tier**: 15 requests/minute, 1,500 requests/day

### Option 3: Claude (Anthropic)
1. Go to: https://console.anthropic.com/
2. Sign up and add payment method
3. Generate API key (starts with `sk-ant-...`)

**Paid only**: $3-15 per 1M tokens

### Option 4: OpenAI
1. Go to: https://platform.openai.com/api-keys
2. Create API key (starts with `sk-...`)

**Paid only**: $0.15-10 per 1M tokens

---

## 🚀 Step 5: First Run!

```bash
# Run AIWB from the repo directory
./aiwb
```

You'll see this beautiful interface:

```
╔══════════════════════════════════════════════════════════╗
║ AIWB Interactive Chat                                     ║
╚══════════════════════════════════════════════════════════╝

AIWB Status

Platform:   termux
Workspace:  ~/storage/shared/aiwb  (Android-visible!)
Provider:   gemini
Model:      flash-1.5
```

---

## 🔐 Step 6: Configure API Keys

AIWB will detect you have no keys and prompt you:

```
Which API key would you like to configure?
  > Gemini ○ Not set
    Claude ○ Not set
    OpenAI ○ Not set
    Groq ○ Not set  ⭐ (NEW!)
    Done
```

### To Add Groq Key:

1. Select "Groq"
2. Paste your API key (starts with `gsk_...`)
3. Press Enter
4. Done!

### Alternative: Manual Setup

```bash
# Create env file
cat > ~/.aiwb/.aiwb.env <<'EOF'
export GROQ_API_KEY="gsk_your_key_here"
EOF

# Secure it
chmod 600 ~/.aiwb/.aiwb.env
```

---

## ✅ Step 7: Test It!

### Quick Test:

```bash
./aiwb status
```

You should see your configuration.

### Chat Test:

```bash
./aiwb chat
```

Then type:

```
> Write a Python function to reverse a string
```

If you see a response, **IT WORKS!** 🎉

---

## 💡 Step 8: Choose Your Provider

Want to use Groq's ultra-fast models?

```bash
./aiwb settings
```

Then:
1. Select "Provider: gemini"
2. Choose "groq"
3. Select "Model: llama-3.1-70b-versatile"

Now Groq is your default!

---

## 📱 Step 9: Understand the Workspace

AIWB creates a special Android-visible workspace:

```
~/storage/shared/aiwb/
├── tasks/              # Your task prompts
│   └── inbox.prompt.md
├── outputs/            # Generated content
├── logs/               # Chat history & costs
├── templates/          # Reusable templates
└── history/            # Session backups
```

**You can access these files from any Android file manager!**

---

## 🎯 Step 10: Try a Real Task

Let's create a REST API:

```bash
# Create a new task
./aiwb task new my-api

# Edit the task (uses $EDITOR or vi)
nano ~/storage/shared/aiwb/tasks/my-api.prompt.md
```

Add this content:

```markdown
# Create a simple REST API

Create a Node.js Express API with:
- GET /users - list all users
- POST /users - create user
- Include input validation
- Add error handling
```

Save and exit, then:

```bash
# Estimate cost first
./aiwb estimate my-api

# Generate the code
./aiwb generate my-api
```

Output saved to: `~/storage/shared/aiwb/outputs/my-api_[timestamp].md`

---

## 🔄 Step 11: Try Multi-Model Refinement

The killer feature - automated improvement:

```bash
# Let multiple AIs refine your code
./aiwb refine my-api --iterations=3
```

This will:
1. Generate with Groq (fast & cheap)
2. Verify with Claude (if you have key)
3. Refine based on feedback
4. Repeat 3 times!

---

## 🌟 Pro Tips for Termux

### 1. Add to PATH (optional)

```bash
# Create a link in ~/.local/bin
mkdir -p ~/.local/bin
ln -s ~/AIworkbench/aiwb ~/.local/bin/aiwb

# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Now you can run from anywhere:
aiwb
```

### 2. Enable Shell Completion

```bash
# For bash
echo 'source ~/AIworkbench/completions/aiwb.bash' >> ~/.bashrc
source ~/.bashrc

# Now you have tab completion!
aiwb <TAB><TAB>
```

### 3. View Logs on Android

Open any file manager app, navigate to:
```
Internal Storage/aiwb/logs/
```

You can read chat history directly on your phone!

### 4. Use Templates

```bash
./aiwb template list
./aiwb template use rest-api
```

### 5. Track Costs

```bash
./aiwb costs
```

See exactly how much you've spent!

---

## ⚙️ Groq Model Comparison

Available Groq models:

| Model | Speed | Quality | Cost (per 1M tokens) | Best For |
|-------|-------|---------|----------------------|----------|
| **llama-3.1-70b-versatile** | ⚡⚡⚡ Fast | 🏆 High | $0.059 in / $0.079 out | General use, code |
| **llama-3.1-8b-instant** | ⚡⚡⚡⚡ Ultra-fast | ⭐ Good | $0.005 in / $0.008 out | Quick tasks, chat |
| **mixtral-8x7b-32768** | ⚡⚡ Very fast | ⭐⭐ Very good | $0.024 / $0.024 | Long context |
| **gemma2-9b-it** | ⚡⚡⚡ Fast | ⭐ Good | $0.02 / $0.02 | Lightweight tasks |

**Switch models:**
```bash
./aiwb settings
# → Provider → groq
# → Model → [choose from list]
```

---

## 🔧 Troubleshooting

### "Command not found: aiwb"

```bash
# Run from the repo directory
cd ~/AIworkbench
./aiwb
```

Or add to PATH (see Pro Tips above).

### "Missing library" error

```bash
# Ensure you're in the repo directory
cd ~/AIworkbench
pwd  # Should show: /data/data/com.termux/files/home/AIworkbench

# Check libraries exist
ls -la lib/
```

### "No API key found"

```bash
./aiwb keys
# → Select provider
# → Enter your key
```

### "Permission denied"

```bash
chmod +x ~/AIworkbench/aiwb
```

### Check system health:

```bash
./aiwb doctor
```

---

## 🎊 You're All Set!

AIWB is now running on your Android device via Termux!

**Next Steps:**
- Read the [Quick Start](QUICKSTART.md)
- Try [Examples](examples/)
- Explore [Templates](templates/)
- Check [Changelog](CHANGELOG.md) for features

**Join the Community:**
- GitHub: https://github.com/juanitto-maker/AIworkbench
- Issues: https://github.com/juanitto-maker/AIworkbench/issues

---

## 🚀 Quick Reference

```bash
# Essential commands
./aiwb                          # Start chat
./aiwb keys                     # Manage API keys
./aiwb settings                 # Configure provider/model
./aiwb status                   # Show current config
./aiwb doctor                   # System health check

# Task workflow
./aiwb task new my-task         # Create task
./aiwb estimate my-task         # Check cost
./aiwb generate my-task         # Generate content
./aiwb verify my-task           # AI review
./aiwb refine my-task           # Auto-improve

# Utilities
./aiwb costs                    # Cost breakdown
./aiwb history                  # Session history
./aiwb security-audit           # Security check
./aiwb --help                   # Full help
```

---

**Happy AI Coding on Android!** 🎉📱🤖
