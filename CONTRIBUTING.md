# Contributing to PILOT

Thank you for your interest in contributing to PILOT!

## Ways to Contribute

1. **Report Bugs** — Help identify issues
2. **Suggest Features** — Share your ideas
3. **Improve Documentation** — Fix typos, add examples
4. **Create Packs** — Share your custom packs
5. **Code Contributions** — Fix bugs, add features

## Development Setup

### Prerequisites

- Bash 4.0+
- jq (JSON processor)
- Kiro CLI

### Clone Repository

```bash
git clone https://github.com/pilot-project/pilot.git
cd pilot
```

### Install Locally

```bash
cd src
./install.sh
./verify.sh
```

## Code Standards

### Bash Scripts

```bash
#!/usr/bin/env bash
set -euo pipefail

# Use local for function variables
my_function() {
    local param="$1"
}

# Quote variables
echo "$variable"

# Check command existence
command -v jq &>/dev/null || exit 1
```

### Commit Messages

```
type(scope): description

Types: feat, fix, docs, refactor, test, chore

Examples:
- feat(hooks): add algorithm phase tracking
- fix(memory): correct warm memory path
- docs(readme): update installation steps
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test: `./src/verify.sh`
5. Submit a pull request

## Pack Contributions

See `src/packs/pilot-pack-template/` for the pack template.

### Pack Checklist

- [ ] `pack.json` with metadata
- [ ] `README.md` with documentation
- [ ] `INSTALL.md` with installation steps
- [ ] `VERIFY.md` with verification procedures
- [ ] All hooks exit 0 (fail-safe)
- [ ] Bash-only (no TypeScript)

## Directory Structure

```
~/.kiro/
├── pilot/              # PILOT home
│   ├── identity/       # User context
│   ├── resources/      # Algorithm & Principles
│   └── memory/         # Hot/Warm/Cold
├── agents/pilot.json   # Agent config
├── hooks/pilot/        # Hook scripts
└── steering/pilot/     # Steering files
```

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
