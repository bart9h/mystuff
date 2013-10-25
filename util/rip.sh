#!/bin/bash

function rip_cd()
{
	if test -e '01.flac'; then
		echo 'dir not empty'
		exit
	fi

	source "$ETC/bash/show.sh"
	source "$ETC/bash/job.sh"

	tries=10
	while true; do
		track_count=$(
		cdparanoia -Q 2>&1 |
		grep '^\ *[0-9]\+\.\ ' |
		tail -1 |
		cut -d . -f 1
		)
		track_count=$(( $track_count ))
		test $track_count -gt 0 && break
		let tries=tries-1
		if test $tries -le 0; then
			echo 'No CD found.'
			exit
		fi
		echo "Waiting for CD,  ${tries}.."
		sleep 1
	done

	cd "/tmp" || exit
	#FIXME: use unique temp dir

	cdparanoia -z -X -B 1-$track_count || exit

	for i in $(seq $track_count | sed s/^[0-9]$/0\&/)
	do
		echo "$i/$track_count"
		job nice -19 ionice -c2 -n7 \
			flac \
			--best \
			--delete-input-file \
			--output-name="$OLDPWD/$i.flac" \
			track$i*.wav
	done
	job wait

	sudo eject &
}

function rip_dvd()
{
	# from
	# http://en.gentoo-wiki.com/wiki/Ripping_DVD_to_Matroska_and_H.264

	# rip video (VOB)
	mplayer -dvd-device /path/to/vobfiles dvd://${TRACK} -dumpstream -dumpfile ${RIPPATH}movie.vob

	# chapter info
	dvdxchap -t ${TRACK} /dev/dvd > ${RIPPATH}chapters.txt

	# subtitle info
	cp /media/cdrom/VIDEO_TS/VTS_01_0.IFO ${RIPPATH}
	mplayer -v

	# subtitles
	foreach SID
	tccat -i ${RIPPATH}movie.vob | tcextract -x ps1 -t vob -a ${HEXSID} > ${RIPPATH}subs-${SID}
	subtitle2vobsub -o ${RIPPATH}vobsubs -i ${RIPPATH}vts_01_0.ifo -a ${SID} < ${RIPPATH}subs-${SID}
	mkdir ${RIPPATH}${SID}
	subtitle2pgm -o ${RIPPATH}${SID}/${SID} -c 255,0,0,255 < ${RIPPATH}subs-${SID}

	# audio
	foreach AID
	mplayer ${RIPPATH}movie.vob -aid ${AID} -dumpaudio -dumpfile ${RIPPATH}audio${AID}.ac3

	# crop
	mplayer ${RIPPATH}movie.vob -vf cropdetect -sb 50000000

	# encode
	mencoder ${RIPPATH}movie.vob \
-vf pullup,softskip,crop=${CROP},harddup -oac copy \
-ovc x264 -x264encopts bitrate=${BITRATE}:\
subq=5:bframes=3:\
b_pyramid=normal:weight_b:turbo=1:threads=auto:pass=1 \
-o /dev/null
	mencoder ${RIPPATH}movie.vob \
-vf pullup,softskip,crop=${CROP},harddup -oac copy \
-ovc x264 -x264encopts bitrate=${BITRATE}:\
subq=5:8x8dct:frameref=2:bframes=3:\
b_pyramid=normal:weight_b:threads=auto:pass=2 \
-o ${RIPPATH}movie.264

	# mkv
	mkvmerge --title "${MOVIE_TITLE}" -o ${RIPPATH}movie.mkv --chapters ${RIPPATH}chapters.txt --default-duration 0:${VIDEO_FPS}fps -A ${RIPPATH}movie.264 ${RIPPATH}audio${AID}.ac3
}

rip_cd "$@"
#rip_dvd "$@"

