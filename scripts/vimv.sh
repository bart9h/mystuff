#!/bin/bash
#
# VImv, a manual mass-renaming tool using the VIM editor.
# Rodolfo Borges <barrett@9hells.org>
#

# Configuration variables:
script="`mktemp /tmp/vimv.XXXXXX`"
include_instructions=false


# Usage instructions:
function usage() {
	echo "usage: vimv [-v|-f|-i] <files-to-rename>"
	echo "the -v or -f options (use only one) are passed to mv(1)"
	echo "the -i option includes brief instructions in the script"
	exit
}


# Arguments:
verbose=""
force=""
prompt=" -i"

while true; do
	not_arg=0
	case "$1" in
		"" | --help)
			usage
		;;
		-v)
			verbose=" -v"
		;;
		-f)
			force=" -f"
			prompt=""
		;;
		-i)
			include_instructions=true
		;;
		*)
			not_arg=1
		;;
	esac
	test $not_arg == 1 && break
	shift
done


function quote() {
	echo "$@" | sed 's/\$/\\$/g'
}

# Calculate the max lenght of names, to format the columns properly:
maxlen=0
for z in "$@"; do
	len=$( quote "$z" | wc -c)
	test $len -gt $maxlen && maxlen=$len
done


# Create the script with the 'mv' commands for the user to edit:
{
	echo "exit  # This script _will_ be executed after Vim."
	$include_instructions && cat << EOF

# INSTRUCTIONS:
# Edit the names in the right column, then remove the above line.
# Save and exit the editor, to execute this script.
# To cancel, just quit this editor (leaving the 'exit' at the first line).
# [ Vim tip: Use <Ctrl-V> to enter block-selection mode. ]

EOF
	for z in "$@"; do
		q="$( quote "$z" )"
		len=$( echo "$q" | wc -c)
		echo -n "mv${prompt}${verbose}${force} \"$q\""
		let count=maxlen-len
		while test $count -gt 0; do
			echo -n " "
			let count=count-1
		done
		echo " \"$q\""
	done
} > $script


# Call the editor, then execute the resulting script:
vim "+set nowrap" "+set filetype=sh" "$script"

