# Example 2: Generating Code with AIWB

This example demonstrates how to use AIWB's powerful mode-based workflow to generate code.

## Scenario

You need to create a REST API endpoint for user authentication.

## Method 1: Using /make Mode (Recommended ⭐)

### Step 1: Start AIWB and Enter Make Mode

```bash
aiwb
> /make
```

### Step 2: Set Your Instructions

Provide your requirements as a prompt:

```bash
make> prompt Create a secure user authentication REST API with Express.js and TypeScript. Include POST /api/v1/auth/login (email/password, returns JWT), POST /api/v1/auth/register (email/password/name with validation), and POST /api/v1/auth/refresh. Use PostgreSQL with Prisma, bcrypt for passwords, JWT for auth, Joi for validation, and rate limiting. Provide production-ready code with proper error handling.
```

### Step 3: Choose Your AI Model

```bash
make> model
```

Select from available providers (Gemini, Claude, OpenAI, etc.)

### Step 4: Configure Verification (Optional but Recommended)

```bash
make> check Focus on security vulnerabilities, input validation, and error handling
```

This sets up a second AI to review the output.

### Step 5: Check Status

```bash
make> status
```

Review your configuration before running.

### Step 6: Execute

```bash
make> run
```

AIWB will:
1. Show cost estimate
2. Ask for confirmation
3. Generate the code
4. (If check configured) Verify with second AI
5. Display the output
6. Save to `~/.aiwb/workspace/outputs/`

## Method 2: Using Quick Command

For simpler, one-shot generation:

```bash
aiwb quick "Create a user authentication API with Express.js, JWT, and bcrypt. Include login, register, and refresh endpoints."
```

This automatically:
- Generates code
- Verifies with a second AI
- Shows results immediately

## Method 3: Using Wizard (Beginner-Friendly)

```bash
aiwb wizard
```

The wizard guides you through:
1. Selecting what to create
2. Choosing provider/model
3. Entering requirements
4. Adding context files
5. Configuring verification
6. Executing with confirmation

## Method 4: Traditional Task-Based Approach

The original approach still works for compatibility:

```bash
# Create task file
mkdir -p ~/.aiwb/workspace/tasks
vi ~/.aiwb/workspace/tasks/user-auth.prompt.md
```

Add your requirements to the file, then:

```bash
# Generate
aiwb generate user-auth

# Verify (optional)
aiwb verify user-auth

# Or refine iteratively
aiwb refine user-auth
```

## What You Learned

- **Mode-Based Workflows**: Using `/make` mode for structured generation
- **Quick Commands**: Using `aiwb quick` for simple tasks
- **Wizard Mode**: Guided workflow for beginners
- **Generator-Verifier Loop**: Automatic code review with second AI
- **Cost Estimation**: Understanding costs before execution
- **Multiple Methods**: Different approaches for different needs

## Key Takeaways

1. **Use modes for complex tasks** - They provide structure and verification
2. **Use quick command for simple tasks** - Fast and automatic
3. **Always configure verification** - Second AI improves quality
4. **Check costs first** - Avoid surprises with built-in estimation
5. **Try the wizard** - Great for learning the workflow

## Next Steps

- Explore [WORKFLOW-GUIDE.md](../docs/WORKFLOW-GUIDE.md) for advanced patterns
- Read [USAGE.md](../docs/USAGE.md) for complete command reference
- Try the `/tweak` and `/debug` modes
- Experiment with different AI models to compare results
