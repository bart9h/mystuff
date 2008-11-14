function eset()
{
	tmp="/tmp/eset.$USER.sh"
	if test -s "$tmp"; then
		rm "$tmp" || return
	fi

	local i
	for i in "$@"; do
		echo "export $i=${!i}" >> "$tmp"
	done
	$EDITOR "$tmp" && source "$tmp"
}

