function start_screen()
{
	if test "$1" == "-S"; then
		name="$2"
		shift 2
	else
		name="`basename "$1"`"
	fi

	test "$1" || { echo 'what?'; exit; }
	test -x "$1" || test -x "`which $1`" || { echo "no $1"; exit; }

	tmp=`mktemp "/tmp/start_screen.$name.XXXXXX"`

	cat <<EOF >| "$tmp"
#!/bin/bash
echo -- "> $@"
if $@ ; then
	echo "> true"
else
	echo -- "> \"$name\" terminated with exitcode $?"
	echo -n "> press enter to close"
	read
fi
rm "\$0"
EOF

	chmod +x "$tmp"
	screen -D -m -S "$name" "$tmp" &
}

