# Example 2: Generating Code with AIWB

This example demonstrates how to use AIWB to generate code for a specific task.

## Scenario

You need to create a REST API endpoint for user authentication.

## Step 1: Create a Task

```bash
aiwb task new user-auth
```

This creates: `~/.aiwb/workspace/tasks/user-auth.prompt.md`

## Step 2: Edit the Task Prompt

Edit the task file with your preferred editor:

```bash
# Or the task will open in your $EDITOR
vi ~/.aiwb/workspace/tasks/user-auth.prompt.md
```

Add this content:

```markdown
# User Authentication API

Create a secure user authentication REST API endpoint with the following requirements:

## Requirements

1. POST /api/v1/auth/login
   - Accept email and password
   - Return JWT token on success
   - Return 401 on invalid credentials

2. POST /api/v1/auth/register
   - Accept email, password, and name
   - Validate email format
   - Hash password securely
   - Return user object and JWT

3. POST /api/v1/auth/refresh
   - Accept refresh token
   - Return new access token

## Technology

- Framework: Express.js (Node.js)
- Database: PostgreSQL with Prisma ORM
- Authentication: JWT
- Password hashing: bcrypt

## Code Standards

- TypeScript
- Async/await
- Proper error handling
- Input validation with Joi
- Rate limiting

## Deliverables

Provide complete, production-ready code with:
- Route handlers
- Validation schemas
- Error middleware
- Database models
- JWT utilities
```

## Step 3: Estimate Cost

Before generating, check the cost:

```bash
aiwb estimate user-auth
```

Output:
```
╔══════════════════════════════════════════════════════════╗
║ Cost Estimate for: user-auth                             ║
╚══════════════════════════════════════════════════════════╝

Provider: gemini
Model:    flash-1.5

Input tokens:  450

Tier        Output Tokens   Cost (USD)
───────────────────────────────────────
Basic       585             $0.0023
Medium      900             $0.0035
Best        1440            $0.0055
```

## Step 4: Generate

If the cost looks good, generate:

```bash
aiwb generate user-auth
```

AIWB will:
1. Show cost estimate (if auto-estimate is enabled)
2. Ask for confirmation
3. Call the AI API
4. Save output to `~/.aiwb/workspace/outputs/user-auth_[timestamp].md`

## Step 5: Review the Output

The generated code will be saved with full implementation. Example output structure:

```
~/.aiwb/workspace/outputs/user-auth_20251108_153045.md
```

## Step 6: Verify with AI (Optional)

Use a second AI model to review the generated code:

```bash
aiwb verify user-auth
```

This will:
- Use a different provider (e.g., Claude to verify Gemini output)
- Provide constructive feedback
- Save feedback to `user-auth_[timestamp].feedback.md`

## Step 7: Refine (Automated Loop)

If you want the AI to improve based on feedback automatically:

```bash
aiwb refine user-auth --iterations=3
```

This runs the Generator-Verifier loop:
1. Generate → Verify → Incorporate feedback → Generate again
2. Repeats for specified iterations
3. Each iteration improves based on previous feedback

## What You Learned

- Creating focused task prompts
- Cost estimation before generation
- Generating production code
- Automated verification
- Iterative refinement

## Next Steps

- Try [Generator-Verifier Loop in depth](05-refine-loop.md)
- Learn [Template usage](06-templates.md)
- Explore [Cost tracking](07-cost-management.md)
