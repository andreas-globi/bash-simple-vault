#!/usr/bin/env bash
#/
#/ Simple secret vault manager in bash using OPENSSL
#/
#/   Edit Vault:        vault.sh edit filename [password]
#/   Test Vault:        vault.sh test filename [password]
#/   Get a secret:      vault.sh get filename key password
#/   Dump database:     vault.sh dump filename [password]
#/

# config
OPENSSLPARAMS="-aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt"

# exit on errors
set -o errexit

# now you can use exit 77 to bubble up an exit all the way from a subshell
set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR

# print usage from comments on top starting with #/
function usage {
	grep "^#/" <"$0" | cut -c4-
}

# die with error
function faildie {
	echo -e "ERROR: $1" >&2
	exit 77
}

# ensure argument is set: require_arg "Name of argument" "$value"
function require_arg {
	NAME="$1"
	RET="$2"
	if [[ "$RET" == "" ]]; then
		faildie "Missing Argument $1"
	fi
	echo "$RET"
}

# get content of vault as text: load_vault "file_name" "password"
function load_vault {
	FILE=$(require_arg "File" "$1")
	PASS=$(require_arg "Password" "$2")
	CONTENT=""
	if [ -f "$FILE" ]; then
		CONTENT=$(openssl enc -d $OPENSSLPARAMS -pass pass:$PASS < $FILE)
		if [ $? -ne 0 ]; then
			faildie "ERROR: Failed opening file"
		fi
	fi
	echo -e "$CONTENT"
}

# save content to vault: save_vault "file_name" "content" "password"
function save_vault {
	FILE=$(require_arg "File" "$1")
	CONTENT=$(require_arg "Vault Content" "$2")
	PASS=$(require_arg "Password" "$3")
	TMPFILE=$(mktemp)
	echo "$CONTENT" > $TMPFILE
	ENC=$(openssl enc $OPENSSLPARAMS -pass pass:$PASS < $TMPFILE > $FILE)	
	rm $TMPFILE
}

# edit vault content with default editor: edit_vault "file_name" "password"
function edit_vault {
	FILE=$(require_arg "File" "$1")
	PASS=$2
	if [[ "$PASS" == "" ]]; then
		echo "Enter pass phrase:"
		read -s PASS
	fi
	
	TXT=$(load_vault "$FILE" "$PASS")
	TMPFILE=$(mktemp)
	echo "$TXT" > $TMPFILE
	$EDITOR $TMPFILE
	ENC=$(openssl enc $OPENSSLPARAMS -pass pass:$PASS < $TMPFILE > $FILE)	
	rm $TMPFILE
}

# get a key from vault text: load_vault_key "vault_content" "key_name"
function load_vault_key {
	CONTENT=$(require_arg "Vault Content" "$1")
	VAR=$(require_arg "Key Name" "$2")

	TMPFILE=$(mktemp)
	echo "$CONTENT" > $TMPFILE
	VALUE=$(source $TMPFILE && echo "${!VAR}")
	rm $TMPFILE
	echo "$VALUE"
}

# test vault content for syntax errors: test_vault_contents "vault_content"
function test_vault_content {
	CONTENT=$(require_arg "Vault Content" "$1")
	VAR="gsm_vault_foo"
	WANT="bar1701"
	CONTENT="$CONTENT
$VAR=\"$WANT\"
"
	TEST=$(load_vault_key "$CONTENT" "$VAR")
	if [[ "$TEST" != "$WANT" ]]; then
		faildie "Errors in Vault"
	fi
}

# test vault for syntax errors: test_vault "file_name" "password"
function test_vault {
	FILE=$(require_arg "File" "$1")
	PASS=$(require_arg "Password" "$2")
	TXT=$(load_vault "$FILE" "$PASS")
	TEST=$(test_vault_content "$TXT" 2>&1)
	if [[ "$TEST" != "" ]]; then
		faildie "$TEST"
	fi
}

# get key from vault: get_key "file_name" "key_name" "password"
function get_key {
	FILE=$(require_arg "File" "$1")
	VAR=$(require_arg "Key Name" "$2")
	PASS=$3
	if [[ "$PASS" == "" ]]; then
		echo "Enter pass phrase:"
		read -s PASS
	fi
	CONTENT=$(load_vault "$FILE" "$PASS")
	VAL=$(load_vault_key "$CONTENT" "$VAR")
	echo "$VAL"
}

case $1 in
	help|--help|'')
		usage
		exit 0
		;;
	get)
		VAL=$(get_key "$2" "$3" "$4")
		echo "$VAL"
		;;
	edit)
		edit_vault "$2" "$3"
		;;
	test)
		test_vault "$2" "$3"
		echo -e "Vault OK"
		;;
	dump)
		DUMP=$(load_vault "$2" "$3")
		echo -e "$DUMP"
		;;
	*)
		echo "ERROR: operation must be 'get', 'edit', 'test' or 'dump'" >&2
		usage
		exit 1
		;;
esac
