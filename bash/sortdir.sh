
function sortdir() {
	#FIXME: doesn't work for hidden files/dirs within
	#TODO: check read-only permission before starting
	#TODO: recursive
	local arg
	if test "$1" == ""; then
		echo "usage: sortdir [-v] <directory> [<directory> ...]"
	else
		while test "$1"; do
			if test "$1" == "-v"; then
				arg="-v"
			elif test -d "$1"; then
				local tmpdir="_sortdir_tmp"
				mv $arg "$1" "$tmpdir" && \
				mkdir $arg "$1" && \
				mv $arg "$tmpdir"/* "$1" && \
				rmdir $arg "$tmpdir" \
				|| return
			fi
			shift
		done
	fi
}

