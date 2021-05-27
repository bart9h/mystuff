#!zsh
#
#  Asks confirmation before removing multiple files.
#  Unlike `/bin/rm -i`, this version:
#  -  Only asks if there's more than one file to be rm'ed.
#  -  Show the list of files to be rm'ed, and asks just once.
#  -  First if checks if all files exists, aborting otherwise.
#

function rm()
{

	# count and check files
	local file_count=0
	local ok=true
	local dashdash=false  # "--" ends options parsing
	for i in $argv; do
		if [[ $dashdash == true || ! $i =~ '^-' ]]; then
			if [[ -e "$i" ]]; then
				let file_count++
			else
				echo "eh o ($i)"
				/bin/rm $i
				ok=false
			fi
		elif [[ $i == '--' ]]; then
			dashdash=true
		fi
	done; unset i

	# if there's any missing file, abort
	if ! $ok; then
		if [[ $file_count -gt 0 ]]; then
			echo "and $file_count more item(s) not rm'ed"
		fi
		return
	fi

	# if more than one file, ask first
	if [[ $file_count -gt 1 ]]; then
		ls -d "$@"
		read "answer?remove $file_count items (y/n) [y]? "
		[[ "$answer" == "y" || "$answer" == "" ]] || return
	elif [[ $file_count -eq 0 ]]; then
		echo "no files" > /dev/stderr
		return
	fi

	# finally, call /bin/rm with original arguments
	# ie:  grep -v 'shift' rm.sh  || die
	/bin/rm -v "$@"

}
