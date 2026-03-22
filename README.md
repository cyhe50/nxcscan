# nxcscan

A wrapper script around [NetExec (nxc)](https://github.com/Pennyw0rth/NetExec) to streamline scanning across services and credentials.

## Features

1. **Credential file scanning** — provide a file with multiple username/password or username/hash pairs, the script iterates and runs nxc for each one automatically
2. **Multi-service support** — scan multiple services in a single command using comma-separated names, or use `all` as a shortcut for 6 common Windows services
3. **Broader coverage with `--with-local`** — pairs with nxc's built-in spraying to also test local accounts in the same run
4. **Clean output with `--only-success`** — automatically adds `--continue-on-success` to keep scanning after a hit, and filters output down to successful results only
5. **Full nxc compatibility** — accepts any nxc-supported service and passes extra arguments directly via `-c`, fitting naturally into the nxc workflow

## Requirements

- [NetExec](https://github.com/Pennyw0rth/NetExec) (`nxc`) installed and in `$PATH`
- (Optional) `unbuffer` for colored output — `sudo apt install expect`

## Usage

```bash
./nxcscan <service> <ip/targets> [options]
```

### Service

Any service supported by `nxc` can be passed (e.g. `smb`, `rdp`, `winrm`, `ldap`, `wmi`, `mssql`, etc.).

- Single service: `smb`
- Multiple services (comma-separated, no spaces): `smb,rdp`
- `all` — shortcut for `smb,winrm,rdp,ldap,wmi,mssql`

### Options

| Flag | Description |
|------|-------------|
| `-u <username>` | Username |
| `-p <password>` | Password |
| `-H <hash>` | NTLM hash |
| `-f <file>` | Credential file (see format below) |
| `-c <commands>` | Additional nxc arguments (supports spaces, e.g. `'--shares --users'`) |
| `--with-local` | Also run with `--local-auth` for local account testing |
| `--only-success` | Add `--continue-on-success` and filter output to successful logins only |
| `-h, --help` | Show help |

## Examples

```bash
# Scan with a credential file (iterates through all credentials in the file)
./nxcscan smb 192.168.1.10 -f creds

# Scan multiple services using a credential file
./nxcscan smb,rdp 192.168.1.10 -f creds

# Scan all 6 common services
./nxcscan all 192.168.1.10 -f creds

# Scan a list of targets
./nxcscan smb targets.txt -f creds

# Single username and password
./nxcscan smb 192.168.1.10 -u admin -p Password123

# Single username and NTLM hash
./nxcscan smb 192.168.1.10 -u admin -H aad3b435b51404eeaad3b435b51404ee

# With additional nxc commands
./nxcscan smb 192.168.1.10 -f creds -c '--shares --users'
./nxcscan smb 192.168.1.10 -f creds -c '-M lsassy'

# Only show successful results
./nxcscan smb 192.168.1.10 -f creds --only-success

# Also test local accounts
./nxcscan smb 192.168.1.10 -f creds --with-local

# Test local accounts and only show successful results
./nxcscan smb 192.168.1.10 -f creds --with-local --only-success
```

## Credential File Format

Each line follows the format `<type>:<username>:<secret>`:

```
p:administrator:Password123
P:jsmith:Summer2024!
h:administrator:31d6cfe0d16ae931b73c59d7e0c089c0
H:administrator:31d6cfe0d16ae931b73c59d7e0c089c0
```

| Prefix | Type |
|--------|------|
| `p` | Password |
| `P` | Password |
| `h` | NTLM hash |
| `H` | NTLM hash |
