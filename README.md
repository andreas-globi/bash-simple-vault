# Bash Simple Vault

Simple vault to store secrets securely using openssl for use in bash scripts

## Why?

Bash scripts often need secrets. Storing them is problematic.

I really like how Ansible Vault works, even though I'm not an Ansible fan.

So I created this. A simple vault for secrets written in Bash.

Main Features:
 - Mass edit all secrets in the vault
 - Multi-line secrets (like SSL certificates)
 - Multiple vaults so you can ship a vault file with your script(s) securely

## Editing the Vault

To edit the contents of the vault:

`bash vault.sh edit VAULTFILENAME [PASSWORD]`

eg

`bash vault.sh edit ~/project/.secrets`

If no password is provided, it will be prompted for.

Editing will take place in the default editor (as exported in `$EDITOR`)

Structure your values in normal BASH notation, eg:

```
SSH_PASS="i7pJasjt8x"
SSL="-----BEGIN CERTIFICATE-----
MIIETTCCAzWgAwIBAgILBAAAAAABRE7wNjEwDQYJKoZIhvcNAQELBQAwVzELMAkG
xRJzo9P6Aji+Yz2EuJnB8br3n8NA0VgYU8Fi3a8YQn80TsVD1XGwMADH45CuP1eG
l87qDBKOInDjZqdUfy4oy9RU0LMeYmcI+Sfhy+NmuCQbiWqJRGXy2UzSWByMTsCV
MTh89N1SyvNTBCVXVmaU6Avu5gMUTu79bZRknl7OedSyps9AsUSoPocZXun4IRZZ
Uw==
-----END CERTIFICATE-----
"
SSH_PORT=22
```

## Testing the Vault

To test the vault for accidental syntax errors:

`bash vault.sh test VAULTFILENAME [PASSWORD]`

eg

`bash vault.sh test ~/project/.secrets`

If no password is provided, it will be prompted for.

## Retrieving a value

To get a value from a vault:

`bash vault.sh get VAULTFILENAME KEYNAME PASSWORD`

eg

`bash vault.sh get ~/project/.secrets "SSH_PASS" "MySuperSecretPassword"`

This will return the value of the requested key (or blank).

To use in a bash script:

```
SSH_PASS=$(bash vault.sh get ~/project/.secrets "SSH_PASS" "MySuperSecretPassword")
```

BUT - you don't want to have your password for the vault in a Bash script either. So ...

Option 1:
---------

Store your password in a secure file and `cat` it in, eg:

```
VAULTPASS=$(cat ~/.vaultpass)
SSH_PASS=$(bash vault.sh get ~/project/.secrets "SSH_PASS" "$VAULTPASS")
```

Option 2:
---------

Ask for the password once at the beginning of the script, eg:

```
echo "Enter Vault Password:"
read -s VAULTPASS
SSH_PASS=$(bash vault.sh get ~/project/.secrets "SSH_PASS" "$VAULTPASS")
```

