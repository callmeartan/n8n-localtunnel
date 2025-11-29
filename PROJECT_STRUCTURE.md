# Project Structure

This document explains the structure and purpose of each file in the project.

## Core Files

### `start.sh`
**Purpose**: Main setup script that automates the entire process
- Checks dependencies
- Installs localtunnel
- Generates passwords
- Starts Docker containers
- Creates tunnel
- Updates configuration

**Usage**: `./start.sh`

### `docker-compose.yml`
**Purpose**: Docker Compose configuration for n8n
- Defines n8n service
- Configures ports, volumes, and environment variables
- Sets up data persistence

### `package.json`
**Purpose**: Node.js project configuration
- Defines project metadata
- Lists dependencies (localtunnel)
- Contains npm scripts

## Documentation Files

### `README.md`
**Purpose**: Main documentation file
- Comprehensive guide
- Installation instructions
- Usage examples
- Troubleshooting guide
- Feature list

### `QUICKSTART.md`
**Purpose**: Quick start guide for new users
- 3-step setup process
- Basic usage examples
- Common commands

### `EXAMPLES.md`
**Purpose**: Usage examples and advanced scenarios
- Webhook testing examples
- Multiple instance setup
- Custom configurations
- Integration examples

### `CONTRIBUTING.md`
**Purpose**: Guidelines for contributors
- How to contribute
- Code style guidelines
- Testing requirements

### `CHANGELOG.md`
**Purpose**: Version history and changes
- Tracks all versions
- Documents changes per version
- Follows Keep a Changelog format

### `PUBLISHING.md`
**Purpose**: Guide for publishing the project
- GitHub publishing steps
- Release creation
- Marketing tips

### `PROJECT_STRUCTURE.md`
**Purpose**: This file - explains project structure

## Configuration Files

### `.gitignore`
**Purpose**: Git ignore rules
- Excludes sensitive files (passwords)
- Excludes dependencies (node_modules)
- Excludes OS files

### `.editorconfig`
**Purpose**: Editor configuration
- Ensures consistent code style
- Defines indentation rules
- Sets charset and line endings

### `LICENSE`
**Purpose**: MIT License
- Defines usage rights
- Legal terms

## Generated Files (Not in Git)

### `.n8n_password`
**Purpose**: Stores generated n8n password
- Auto-generated on first run
- Used for n8n authentication
- Excluded from git

### `.localtunnel_password`
**Purpose**: Stores tunnel password
- Retrieved from localtunnel service
- Used for tunnel management
- Excluded from git

### `.tunnel_url`
**Purpose**: Stores current tunnel URL
- Updated when tunnel is created/reconnected
- Used for reference
- Excluded from git

### `docker-compose.yml.backup`
**Purpose**: Backup of docker-compose.yml
- Created before modifications
- Allows restoration if needed

## GitHub Files

### `.github/workflows/test.yml`
**Purpose**: GitHub Actions workflow
- Runs syntax checks
- Validates script on push/PR
- Ensures code quality

## Dependencies

### `node_modules/`
**Purpose**: Node.js dependencies
- Contains localtunnel package
- Installed via `npm install`
- Excluded from git

### `package-lock.json`
**Purpose**: Lock file for npm dependencies
- Ensures consistent installs
- Tracks exact versions
- Can be included in git (optional)

## File Permissions

- `start.sh`: Executable (`chmod +x`)
- Other files: Standard read permissions

## Directory Structure

```
.
├── .github/
│   └── workflows/
│       └── test.yml
├── node_modules/          # Generated (excluded from git)
├── .n8n_password          # Generated (excluded from git)
├── .localtunnel_password  # Generated (excluded from git)
├── .tunnel_url            # Generated (excluded from git)
├── docker-compose.yml.backup
├── start.sh               # Main script (executable)
├── docker-compose.yml
├── package.json
├── package-lock.json
├── .gitignore
├── .editorconfig
├── LICENSE
├── README.md
├── QUICKSTART.md
├── EXAMPLES.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── PUBLISHING.md
└── PROJECT_STRUCTURE.md   # This file
```

## File Sizes (Approximate)

- `start.sh`: ~14 KB (main script)
- `README.md`: ~8 KB (comprehensive docs)
- `docker-compose.yml`: ~0.5 KB (Docker config)
- `package.json`: ~0.5 KB (npm config)

## Maintenance

### Files to Update Regularly
- `CHANGELOG.md` - When releasing new versions
- `README.md` - When adding features or fixing bugs
- `package.json` - When updating dependencies

### Files Rarely Changed
- `LICENSE` - Only if changing license
- `.gitignore` - Only if adding new file types
- `.editorconfig` - Only if changing style preferences

## Notes

- All documentation files use Markdown format
- Scripts use bash shell scripting
- Configuration files use YAML/JSON
- Sensitive files are excluded from git via `.gitignore`

