# Smart Setup System - Complete Summary

Intelligent token discovery and validation for Awl setup.

---

## What Was Built

### 1. Token Discovery & Validation (`scripts/awl-integration-helpers.sh`)

**Functions for Linear:**
- `discover_linear_token()` - Checks env var and `~/.linear_api_token`
- `validate_linear_token()` - Calls Linear API to validate and fetch org/teams
- `format_linear_teams()` - Formats teams for display

### 2. Smart Configuration Prompts

**`scripts/smart-linear-config.sh`:**
- Auto-discovers existing token
- Validates via GraphQL API
- Fetches all teams and organizations
- Lets user select from discovered options
- Falls back to manual entry if needed

### 3. Documentation

- **`docs/SMART_SETUP.md`** - User-facing guide
- **`scripts/INTEGRATION_GUIDE.md`** - Developer integration guide

---

## Token Discovery Locations

### Linear

Checked in order:
1. `$LINEAR_API_TOKEN` environment variable
2. `~/.linear_api_token` file

**Compatible with standard Linear token locations!**

### PostHog

Checked in order:
1. `$POSTHOG_AUTH_HEADER` environment variable (format: `Bearer phx_...`)

---

## User Experience Comparison

### Before (Manual Entry)

```
Configure Linear? [Y/n] y

Linear API token: lin_api_xxxxxxxxxxxxx
Linear team key: ENG
Linear team name: Engineering
```

User must:
- Copy token from Linear settings
- Find team key (identifier field)
- Type team name exactly

### After (Smart Discovery)

```
Configure Linear? [Y/n] y

🔍 Checking for existing Linear API token...
✓ Found existing Linear API token in: file

🔍 Validating token and fetching organization info...
✓ Token is valid!
  Organization: Acme Corp (acme)
  Found 3 team(s):
    - ENG: Engineering
    - PROD: Product
    - DESIGN: Design

Use this token? [Y/n] y

Select a team:
  1. ENG: Engineering
  2. PROD: Product
  3. DESIGN: Design

Enter team number [1-3]: 1

✓ Using team: ENG (Engineering)
```

User must:
- Confirm using existing token
- Select team from list

**Benefits:**
- No copying tokens
- No typing team keys
- No typos
- Validates token works before saving

---

## API Validation Details

### Linear GraphQL Query

```graphql
{
  viewer {
    id
    name
    email
    organization {
      id
      name
      urlKey
    }
  }
  teams {
    nodes {
      id
      name
      key
    }
  }
}
```

**Returns:**
- User information
- Organization name and URL key
- All teams with their keys and names

**Auto-populated fields:**
- Team key (e.g., "ENG")
- Team name (e.g., "Engineering")
- Organization context

---

## How to Enable

### Option 1: Set Environment Variables (Session-Based)

```bash
# Linear
export LINEAR_API_TOKEN="lin_api_..."

# PostHog
export POSTHOG_AUTH_HEADER="Bearer phx_..."
```

Good for: Testing, temporary setups

### Option 2: Save to Files (Persistent)

#### Linear
```bash
echo "lin_api_..." > ~/.linear_api_token
chmod 600 ~/.linear_api_token
```

Good for: Permanent setups, shared with other CLIs

---

## Manual Testing

### Test Discovery
```bash
# Linear
./scripts/awl-integration-helpers.sh discover-linear
# Output: "file" or "env" (source) + token
```

### Test Validation
```bash
# Linear (replace with real token)
./scripts/awl-integration-helpers.sh validate-linear "lin_api_..."
# Output: JSON with viewer, org, teams
```

### Test Full Flow
```bash
# Set up test tokens
echo "lin_api_your_token" > ~/.linear_api_token

# Run setup
./setup-awl.sh

# Should auto-discover and validate Linear token
```

---

## Integration Status

### ✅ Completed

- [x] Linear token discovery (env + file)
- [x] Linear API validation (GraphQL)
- [x] Linear team/org extraction
- [x] Smart config prompt functions
- [x] Documentation

### 🚧 Integration Needed

- [ ] Source smart functions in `setup-awl.sh`
- [ ] Replace `prompt_linear_config` with `prompt_linear_config_smart`
- [ ] Test full setup flow
- [ ] Update README with smart setup mention

See `scripts/INTEGRATION_GUIDE.md` for step-by-step integration instructions.

---

## Fallback Behavior

**If token not found:**
- Shows standard manual entry prompts
- Provides helpful setup instructions
- Offers to save token for next time

**If validation fails:**
- Warns user but continues
- Allows manual entry as fallback
- Doesn't block setup

**If API unavailable:**
- Graceful degradation
- Falls back to manual entry
- Logs warning

**Completely backward compatible** - existing setups continue to work!

---

## Security

### Token Storage
- Files created with `chmod 600` (owner only)
- No tokens displayed after validation
- No tokens in logs or git

### API Calls
- HTTPS only
- Read-only operations
- Minimal required scopes
- No data sent to third parties

### Error Handling
- Generic error messages (no token leaks)
- Validation happens client-side
- Failed attempts don't retry automatically

---

## Future Enhancements

### Phase 2: Additional Services
- [ ] Exa API key validation
- [ ] GitHub token from `gh` CLI

### Phase 3: Smart Defaults
- [ ] Extract ticket prefix from Linear issues
- [ ] Suggest project names from git remotes
- [ ] Auto-detect team from recent activity

### Phase 4: Multi-Config
- [ ] Discover multiple config sets
- [ ] Let user choose which to use
- [ ] Support org-wide defaults

---

## Files Created

```
scripts/
├── awl-integration-helpers.sh    # Discovery & validation functions
├── smart-linear-config.sh             # Smart Linear prompt
└── INTEGRATION_GUIDE.md               # Integration instructions

docs/
├── SMART_SETUP.md                     # User-facing documentation
└── SMART_SETUP_SUMMARY.md             # This file
```

---

## Quick Start for Users

### 1. Set up your tokens once

```bash
# Linear
echo "YOUR_LINEAR_TOKEN" > ~/.linear_api_token

# PostHog
export POSTHOG_AUTH_HEADER="Bearer phx_YOUR_TOKEN"
```

### 2. Run setup

```bash
./setup-awl.sh
```

### 3. Enjoy auto-discovery!

Setup will:
- Find your tokens automatically
- Validate them via API
- Show you available teams/orgs
- Let you select from a list
- Save your selections

**Zero copying and pasting!**

---

## Benefits Summary

### For Users
- ✅ Faster setup (fewer prompts)
- ✅ No typos (select from list)
- ✅ Validated tokens (catches errors early)
- ✅ Reuses CLI configs (no duplication)

### For Developers
- ✅ Modular helper functions
- ✅ Easy to extend (add new services)
- ✅ Well-documented APIs
- ✅ Backward compatible

### For Teams
- ✅ Consistent setup across members
- ✅ Standard token locations
- ✅ Shared CLI configurations
- ✅ Reduced onboarding friction

---

## Next Steps

1. **Review** the integration guide: `scripts/INTEGRATION_GUIDE.md`
2. **Integrate** smart functions into `setup-awl.sh`
3. **Test** with real Linear tokens
4. **Document** in README and QUICKSTART
5. **Ship** to users!
