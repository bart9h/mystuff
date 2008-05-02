# With no args, list;
# if args are files or dirs, add (or radd) them;
# else pass args to xmms2.

function x()
{
	if ! pidof xmms2d >/dev/null; then
		( exec xmms2d >| $HOME/var/log/xmms2d.log 2>&1 )&
	fi

	if test "$1" == ""; then
		xmms2 list
	else
		while test "$1"; do
			if test -d "$1"; then
				xmms2 radd "$1"
				shift
			elif test -e "$1"; then
				xmms2 add "$1"
			else
				xmms2 "$@"
				break
			fi
			shift
		done
	fi
}

