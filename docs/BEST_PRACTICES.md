# Best Practices Guide

A guide to effective patterns based on Anthropic's context engineering principles and battle-tested
workflows.

## Table of Contents

- [Core Principles](#core-principles)
- [Agent Usage Patterns](#agent-usage-patterns)
- [Planning Best Practices](#planning-best-practices)
- [Implementation Strategies](#implementation-strategies)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

---

## Core Principles

These principles are derived from Anthropic's context engineering article and proven through
real-world usage.

### 1. Context is Precious

**Principle**: Treat context window as a scarce resource. Load only what's needed, when it's needed.

**Why it matters:**

- LLMs have limited context windows
- Irrelevant information degrades performance
- Focused context produces better results

**How to apply:**

**Good - Focused Loading:**

```
# Load only the specific file needed
Read the authentication handler at src/auth/handler.js
```

**Bad - Over-Loading:**

```
# Reads entire directory tree unnecessarily
Read all files in src/
```

**Good - Just-in-Time:**

```
@awl-dev:codebase-locator find authentication files
# Then read only the relevant ones
```

**Bad - Preemptive Loading:**

```
Read all these files in case we need them later:
[long list of files]
```

### 2. Just-in-Time Loading

**Principle**: Load context dynamically as needed, not upfront.

**Why it matters:**

- You don't know what you need until you explore
- Upfront loading often misses the right files
- Dynamic loading follows actual code paths

**Pattern:**

1. Start with broad search (codebase-locator)
2. Identify relevant files
3. Read specific files
4. Follow references to related code
5. Load additional context as needed

**Example:**

```
# Step 1: Locate
@awl-dev:codebase-locator find rate limiting code

# Step 2: Analyze what was found
@awl-dev:codebase-analyzer explain how rate limiting works in src/middleware/rate-limit.js

# Step 3: Load related code as discovered
# Agent identifies dependency on Redis
Read src/cache/redis-client.js

# Step 4: Continue following the path
```

### 3. Sub-Agent Architecture

**Principle**: Use parallel, focused agents instead of monolithic analysis.

**Why it matters:**

- Focused agents are more accurate
- Parallel execution is faster
- Specialized tools restrict scope (preventing over-exploration)
- Each agent has clear, limited responsibility

**Good - Parallel Specialists:**

```
# Spawn multiple focused agents
@awl-dev:codebase-locator find payment files
@awl-dev:codebase-pattern-finder show payment patterns
```

**Bad - Monolithic:**

```
# Single agent with too much responsibility
@awl-dev:research everything about payments including files, history, patterns, and implementation
```

**Benefits of Sub-Agents:**

- **Tool Restrictions**: Each agent has specific tools (read-only, no edits)
- **Clear Scope**: Bounded responsibility prevents scope creep
- **Parallel Execution**: Faster than sequential
- **Composable**: Mix and match agents as needed

### 4. Structured Persistence

**Principle**: Save context outside the conversation window for reuse.

**Why it matters:**

- Conversations are ephemeral
- Context is expensive to rebuild
- Persistent context enables compaction

**Implementation:**

- **Linear Documents**: Persistent, searchable, attached to tickets
- **Plans**: Detailed specifications that survive conversation resets
- **Research Documents**: Reusable findings
- **Ticket Analysis**: Deep context that persists

**Pattern:**

```
# Research phase (expensive)
@awl-dev:codebase-analyzer deeply analyze authentication system

# Save findings (persistence)
/awl-dev:research-codebase PROJ-123
# Saves research as Linear document attached to ticket

# Later conversation (cheap)
/awl-dev:resume-handoff PROJ-123
# Instant context recovery without re-research
```

### 5. Progressive Context Discovery

**Principle**: Start broad, narrow down progressively.

**Why it matters:**

- You don't know what you don't know
- Premature specificity misses important context
- Progressive refinement follows natural investigation

**Pattern:**

```
# Level 1: Broad search
@awl-dev:codebase-locator find all webhook code

# Level 2: Categorical understanding
# Based on results, focus on specific areas
@awl-dev:codebase-analyzer explain webhook validation in src/webhooks/validator.js

# Level 3: Deep dive
# Follow specific code path discovered
Read src/utils/crypto.js  # Discovered during analysis
```

---

## Agent Usage Patterns

### When to Use Which Agent

**codebase-locator** - "Where is X?"

- Finding files by topic
- Discovering test locations
- Mapping directory structure
- Initial exploration

**codebase-analyzer** - "How does X work?"

- Understanding implementation
- Tracing data flow
- Identifying integration points
- Learning code patterns

**codebase-pattern-finder** - "Show me examples of X"

- Finding similar implementations
- Discovering coding conventions
- Locating test patterns
- Understanding common approaches

### Parallel vs Sequential Agent Usage

**Use Parallel When:**

- Researching independent aspects
- Gathering comprehensive context
- Exploring multiple options
- Initial discovery phase

**Example:**

```
# All independent, spawn together
@awl-dev:codebase-locator find database migration files
@awl-dev:codebase-pattern-finder show migration patterns
```

**Use Sequential When:**

- Second agent depends on first's results
- Following a specific code path
- Drilling into findings
- Refining from broad to specific

**Example:**

```
# Step 1
@awl-dev:codebase-locator find rate limiting code

# Wait for results, then step 2
@awl-dev:codebase-analyzer analyze the rate limiting middleware at [path from step 1]

# Wait for results, then step 3
Read the Redis client used by the middleware
```

### Writing Effective Agent Requests

**Be Specific:**

Good:

```
@awl-dev:codebase-analyzer trace how a webhook request flows from receipt to database storage
```

Bad:

```
@awl-dev:codebase-analyzer look at webhooks
```

**Include Context:**

Good:

```
@awl-dev:codebase-locator find all files related to user authentication in the API service, focusing on JWT token handling
```

Bad:

```
@awl-dev:codebase-locator find auth stuff
```

**Specify What You Need:**

Good:

```
@awl-dev:codebase-pattern-finder show me examples of pagination with cursor-based approaches, including test patterns
```

Bad:

```
@awl-dev:codebase-pattern-finder pagination
```

---

## Planning Best Practices

### Plan Structure

**Always Include:**

1. **Overview** - What and why
2. **Current State Analysis** - What exists now
3. **Desired End State** - Clear success definition
4. **What We're NOT Doing** - Explicit scope control
5. **Phases** - Logical, incremental steps
6. **Success Criteria** - Separated: automated vs manual
7. **References** - Links to tickets, research, similar code

**Phase Guidelines:**

**Good Phase:**

```markdown
## Phase 1: Database Schema

### Overview

Add rate_limits table to track user quotas

### Changes Required

- Migration adds table with user_id, limit, window_seconds
- Add index on (user_id, created_at)
- Add foreign key to users table

### Success Criteria

#### Automated Verification

- [ ] Migration runs: `make migrate`
- [ ] Schema matches spec: `make db-verify-schema`
- [ ] Tests pass: `make test-db`

#### Manual Verification

- [ ] Can insert rate limit records
- [ ] Foreign key constraint works
- [ ] Index improves query performance
```

**Bad Phase:**

```markdown
## Phase 1: Setup

Do database stuff and API stuff

### Success Criteria

- [ ] It works
```

### Separating Automated vs Manual Verification

**Automated Verification:**

- Can be run by execution agents
- Deterministic pass/fail
- No human judgment required
- Examples: tests, linting, compilation, specific curl commands

**Manual Verification:**

- Requires human testing
- Subjective assessment (UX, performance)
- Visual or behavioral checks
- Edge cases hard to automate

**Good Separation:**

```markdown
### Success Criteria

#### Automated Verification

- [ ] Unit tests pass: `make test-unit`
- [ ] Integration tests pass: `make test-integration`
- [ ] Type checking passes: `npm run typecheck`
- [ ] API returns 429 on exceeded limit:
      `curl -X POST http://localhost:8080/api/test -H "X-Test: rate-limit-exceeded"`

#### Manual Verification

- [ ] Error message is user-friendly when rate limit hit
- [ ] UI shows helpful retry-after timer
- [ ] Performance is acceptable with 10,000 requests
- [ ] Mobile app handles 429 gracefully
```

**Bad Mixing:**

```markdown
### Success Criteria

- [ ] Tests pass
- [ ] Looks good
- [ ] No bugs
- [ ] Works in production
```

### Scope Control

**Always Explicitly State What's NOT Being Done:**

```markdown
## What We're NOT Doing

- Not implementing per-endpoint rate limits (global only)
- Not adding rate limit dashboard/UI (tracking only)
- Not handling distributed rate limiting across regions
- Not implementing IP-based rate limiting (user-based only)
- Not adding rate limit configuration UI (code config only)
```

**Why this matters:**

- Prevents scope creep
- Clarifies boundaries
- Enables faster delivery
- Makes follow-up tickets clear

### No Open Questions in Final Plans

**Bad Plan (with open questions):**

```markdown
## Phase 2: API Implementation

### Changes Required

- Add rate limiting middleware
- Use Redis or maybe in-memory? Need to decide.
- Return 429 status code
- Not sure if we should include retry-after header?
```

**Good Plan (all decisions made):**

```markdown
## Phase 2: API Implementation

### Changes Required

- Add rate limiting middleware using Redis
  - Rationale: Need to work across multiple instances
  - Alternative in-memory rejected due to multi-instance deployment
- Return 429 status code with retry-after header
  - Standard practice, helps clients implement backoff
```

**Process:** If you have open questions during planning:

1. STOP writing the plan
2. Research the question (spawn agents, ask user)
3. Make the decision
4. Document decision and rationale
5. Continue planning

---

## Implementation Strategies

### Follow the Plan's Intent, Not Letter

Plans are guides, not rigid scripts. Reality may differ:

**When to Adapt:**

- File has been moved since plan was written
- Better pattern discovered in codebase
- Configuration has changed
- Dependencies updated

**When to Stop and Ask:**

- Core approach no longer makes sense
- Significant architectural mismatch
- Security or correctness concern
- Scope impact

**How to Handle:**

```
Issue in Phase 2:
Expected: Configuration in config/auth.json
Found: Configuration now uses environment variables (ENV_AUTH_SECRET)
Why this matters: Plan assumes JSON editing, but env vars are standard here

Adaptation: Will use env vars following codebase convention
Updating plan approach while maintaining same outcome.
```

### Incremental Verification

**Don't wait until the end to verify:**

**Good - Incremental:**

```
Phase 1: Database schema
[implement]
[run: make migrate && make test-db]
[fix any issues]
[mark phase complete]

Phase 2: API endpoints
[implement]
[run: make test-api]
[fix any issues]
[mark phase complete]
```

**Bad - Deferred:**

```
Phase 1: Database schema
[implement]

Phase 2: API endpoints
[implement]

Phase 3: Tests
[implement]

[run all tests]
[discover phase 1 was broken]
[waste time debugging]
```

### Update Progress as You Go

**Use Checkboxes:**

```markdown
## Phase 1: Database Schema

### Changes Required

- [x] Add migration file
- [x] Add table definition
- [ ] Add indexes
- [ ] Add foreign keys

### Success Criteria

- [x] Migration runs: `make migrate`
- [ ] Schema verified: `make db-verify-schema`
```

**Benefits:**

- Clear progress tracking
- Easy to resume if interrupted
- Documents what's complete
- Helps validation later

---

## Anti-Patterns to Avoid

### 1. Context Over-Loading

**Anti-Pattern:**

```
# Reading entire codebase upfront
Read all files in src/
Read all files in tests/
Read all files in config/
```

**Why it's bad:**

- Wastes context window
- Includes irrelevant information
- Degrades AI performance

**Better Approach:**

```
# Progressive, targeted loading
@awl-dev:codebase-locator find authentication files
[analyze results]
Read src/auth/handler.js
[follow specific code paths]
```

### 2. Monolithic Research

**Anti-Pattern:**

```
@awl-dev:research everything about payments including all files, all history, all patterns, and create a complete analysis
```

**Why it's bad:**

- Unclear scope
- Mixed responsibilities
- No parallelization
- Hard to verify completeness

**Better Approach:**

```
# Parallel, focused research
@awl-dev:codebase-locator find payment files
@awl-dev:codebase-pattern-finder show payment patterns
```

### 3. Vague Plans

**Anti-Pattern:**

```markdown
## Phase 1: Setup

Do database stuff

### Success Criteria

- [ ] It works
```

**Why it's bad:**

- No clear completion criteria
- Can't verify success
- Unclear scope
- No actionable steps

**Better Approach:**

```markdown
## Phase 1: Database Schema

### Overview

Add rate_limits table with user quotas and time windows

### Changes Required

- Add migration: 012_add_rate_limits_table.sql
  - Columns: id, user_id, endpoint, limit_per_minute, created_at
  - Index on (user_id, endpoint)
  - Foreign key to users(id)

### Success Criteria

#### Automated Verification

- [ ] Migration runs: `make migrate`
- [ ] Schema validation passes: `make db-verify-schema`
- [ ] Can insert test records: `make test-db-rate-limits`

#### Manual Verification

- [ ] Table visible in database client
- [ ] Foreign key constraint prevents invalid user_ids
```

### 4. Implementation Without Planning

**Anti-Pattern:**

```
# Jumping straight to implementation
Let's add rate limiting. I'll start coding...
[implements without research or planning]
```

**Why it's bad:**

- Misses existing patterns
- Duplicates code
- Ignores constraints
- No thought-out approach

**Better Approach:**

```
# Research, plan, then implement
/awl-dev:research_codebase ENG-1234
[collaborative planning with research]
/awl-dev:create_plan
/awl-dev:implement_plan
```

### 5. No Context Persistence

**Anti-Pattern:**

```
# All work in conversation window
[extensive research]
[detailed planning]
[conversation ends]
# All context lost
```

**Why it's bad:**

- Research must be redone
- No reusable knowledge
- Team can't benefit
- Wastes time

**Better Approach:**

```
# Persist everything important
[research]
/awl-dev:research-codebase ENG-1234  # Saves to Linear

[planning]
/awl-dev:create-plan  # Saves to Linear

[handoff if pausing]
/awl-dev:create-handoff  # Saves to Linear
```

### 6. Mixed Automated and Manual Criteria

**Anti-Pattern:**

```markdown
### Success Criteria

- [ ] Tests pass and UI looks good
- [ ] No errors and performance is acceptable
- [ ] Everything works correctly
```

**Why it's bad:**

- Can't distinguish what's automatable
- Unclear what needs human testing
- Validation agents can't help
- Ambiguous completion

**Better Approach:**

```markdown
### Success Criteria

#### Automated Verification

- [ ] Unit tests pass: `make test-unit`
- [ ] Integration tests pass: `make test-integration`
- [ ] No TypeScript errors: `npm run typecheck`

#### Manual Verification

- [ ] UI displays rate limit errors clearly
- [ ] Performance acceptable with 1000+ requests
- [ ] Error messages are user-friendly
```

### 7. Ignoring Existing Patterns

**Anti-Pattern:**

```
# Implementing without checking existing code
I'll create a new pagination approach...
[implements custom solution]
# Codebase already has 3 pagination patterns
```

**Why it's bad:**

- Creates inconsistency
- Duplicates code
- Misses proven patterns
- Harder maintenance

**Better Approach:**

```
# Check existing patterns first
@awl-dev:codebase-pattern-finder show pagination implementations
[review existing patterns]
# Use the same pattern as similar endpoints
```

### 8. Scope Creep

**Anti-Pattern:**

```markdown
# Plan for "Add rate limiting"

## Phase 1: Basic rate limiting

## Phase 2: Dashboard for viewing limits

## Phase 3: Admin UI for configuring limits

## Phase 4: Per-endpoint limits

## Phase 5: Geographic rate limiting

## Phase 6: Machine learning for dynamic limits
```

**Why it's bad:**

- Original goal lost
- Never finishes
- Delays value delivery
- Increases complexity

**Better Approach:**

```markdown
# Plan for "Add rate limiting"

## What We're NOT Doing

- Not building admin UI (configuration via code only)
- Not implementing per-endpoint limits (global only)
- Not adding geographic rules (user-based only)
- Not implementing ML/dynamic limits

## Phase 1: Basic Global Rate Limiting

[Focused on original goal]
```

---

## Key Takeaways

1. **Context is precious** - Load only what's needed, when needed
2. **Just-in-time loading** - Discover dynamically, don't preload
3. **Use specialized agents** - Parallel, focused research beats monolithic
4. **Persist important context** - Use Linear documents for reusable knowledge
5. **Separate automated vs manual** - Clear success criteria enable better validation
6. **Follow existing patterns** - Check codebase before creating new approaches
7. **Control scope** - Explicitly state what's NOT being done
8. **Progressive discovery** - Start broad, narrow progressively
9. **Verify incrementally** - Don't wait until end to test

---

## Next Steps

- See [USAGE.md](USAGE.md) for detailed usage instructions
- See [PATTERNS.md](PATTERNS.md) for creating custom agents
- See [CONTEXT_ENGINEERING.md](CONTEXT_ENGINEERING.md) for deeper principles
