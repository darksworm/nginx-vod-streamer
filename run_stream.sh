#!/bin/bash
set -e

uplink=rtmp:127.0.0.1/show/stream?pwd=change_this_password
videos=(prestream.mp4 movie.mp4)
skip_seconds=0

for item in ${videos[*]}
do
    [ ! -f "export/$item" ] && echo "File export/$item does not exist!" && exit 1
done

if [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null; then
    echo "skipping first $1 seconds of playback"
    skip_seconds=$1
fi

seconds_left_to_skip=$skip_seconds
video_skips=()
for item in ${videos[*]}
do
    video_len=`ffprobe -v error \
	    -show_entries format=duration \
	    -of default=noprint_wrappers=1:nokey=1 \
	    export/$item | cut -d. -f1`

    if [ "$video_len" -lt "$seconds_left_to_skip" ]; then
        skip_for_this_video=$video_len
	seconds_left_to_skip=`expr $seconds_left_to_skip - $video_len`
    else
	skip_for_this_video=$seconds_left_to_skip
	seconds_left_to_skip=0
    fi

    video_skips+=($skip_for_this_video)
done

start_time=`date "+%s"`

function finish {
    finish_time=`date "+%s"`
    echo `expr $finish_time - $start_time + $skip_seconds` > .last_stream_duration
}
trap finish EXIT

for index in "${!videos[@]}"
do
    ffmpeg \
        -re \
	-ss ${video_skips[index]} \
        -i export/${videos[index]} \
        -c:v copy \
        -c:a copy \
	-f flv \
        $uplink;
done
