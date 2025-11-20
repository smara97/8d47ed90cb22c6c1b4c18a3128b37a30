# Command Execution Rules

## Auto-Execute Safe Commands

Automatically execute commands that are safe and non-destructive:

### Allowed Commands

- `ls`, `cat`, `head`, `tail`, `grep`, `find`, `which`, `pwd`
- `docker ps`, `docker logs`, `docker inspect`
- `make help`, `make status`, `make health`
- `git status`, `git log`, `git diff`, `git branch`
- `curl` (GET requests only), `wget` (read-only)
- `python --version`, `node --version`, `go version`
- `ps`, `top`, `df`, `free`, `uptime`

### Require Confirmation

Commands that modify system state require user confirmation:

### Forbidden Auto-Execute

Never auto-execute destructive commands:

- `rm`, `rmdir`, `del`, `delete`
- `mv` (when moving to different directories)
- `dd`, `format`, `fdisk`
- `kill`, `killall`, `pkill`
- `shutdown`, `reboot`, `halt`
- `chmod 777`, `chown root`
- `sudo` commands (except read-only)
- `docker rm`, `docker rmi`, `docker system prune`
- `git reset --hard`, `git clean -fd`

## Execution Guidelines

- Always explain what command will do before execution
- Show command output and explain results
- Ask for confirmation on any system modifications
- Provide alternative safer commands when possible
