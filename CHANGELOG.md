# Changelog

## 0.1.4

### Quality Plugin (0.0.1)

- Added AI-driven code review plugin with 9 parallel agents
- Added multi-language support (Go/Java/Python/Kotlin/Swift/TypeScript)
- Added four-dimensional review: bug detection, code quality, security analysis, performance analysis
- Added confidence scoring mechanism with redundancy confirmation (threshold: 80)
- Added intelligent project standards checking (CLAUDE.md/CONTRIBUTING.md auto-detection)
- Added `/review` command for automated code review workflow

### Sync Plugin (0.1.4)

- Improved `sync-from-zeus.sh` to auto-discover all plugins instead of hardcoding plugin names
- Removed warnings for non-existent plugins by using dynamic plugin directory scanning

### Marketplace

- Bumped version from 0.1.3 to 0.1.4
- Added quality plugin to marketplace registry

## 0.1.3

### Git Plugin (0.1.1)

- Added `/git:commit-push` command for commit and push workflow without creating MR
- Added `command-procedures.md` as shared logic layer for all commands and skills to reference
- Added intelligent branch prefix detection for `/git:commit-push-pr` (analyzes git diff to determine feat-, fix-, docs-, etc.)
- Added three-tier task ID extraction strategy (branch name → user input → ask user)
- Improved commit message format with bilingual support (English + Chinese sections)
- Improved README.md with architecture diagrams, command comparison table, and detailed workflow documentation
- Improved all command documentation to reference shared logic layer instead of duplicating procedures
- Changed commit signature format to use `Generated-By` and `Co-Authored-By` with proper spacing

### Sync Plugin (0.1.3)

- Added `cursor-templates/` directory with pre-formatted Cursor-compatible templates
- Added direct template copying approach (no runtime conversion needed)
- Improved `/sync:basic` to directly overwrite files without checking existence or conflicts
- Improved `/sync:cursor` to use three-tier template lookup and direct overwrite strategy
- Improved sync workflow to use single source of truth for Cursor format
- Changed conflict handling from interactive prompts to direct overwrite for team consistency
- Removed backup file creation (simplified sync process)

### Documentation

- Improved installation and usage instructions in root README.md
- Added detailed architecture documentation for Git plugin workflow
- Added best practices for template maintenance and customization

## 0.1.2

- Added Sync plugin with MCP and Cursor IDE synchronization features
- Improved Git plugin documentation

## 0.1.1

- Improved sync script with enhanced reliability
- Updated documentation

## 0.1.0

- Initial release with Git and Sync plugins
- Added Git workflow automation (commit, push, merge request creation)
- Added project configuration synchronization
