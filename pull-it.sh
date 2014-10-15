#!/bin/bash

export http_proxy="http://127.0.0.1:8087"
export https_proxy="https://127.0.0.1:8087"

video_key="$1"
test -n "$video_key" || {
    echo "Usage: $0 <video_key>"
    exit 1
}

video_url="https://www.youtube.com/watch?v=$video_key"
echo "video url: $video_url"

youtube-dl -F "$video_url" | tee /tmp/fmt$$.list
fmt=$(grep "(best)" /tmp/fmt$$.list | cut -d' ' -f1)
echo "best video format: $fmt"
echo $fmt | grep -q "^[0-9]\+$" || {
    echo "Error video format: $fmt"
    exit 1
}

test -f *${video_key}.mp4.part \
    && old_size=$(ls -l *${video_key}.mp4.part | awk '{print $5}') \
    || old_size=0
echo "old size: $old_size"

pkill youtube-dl; youtube-dl -f $fmt "$video_url" &

while true; do
    sleep 16
    test -f *${video_key}.mp4.part || { echo "Streaming Done"; break; }
    new_size=$(ls -l *${video_key}.mp4.part | awk '{print $5}')
    if [ $new_size -eq $old_size ]; then
        echo " - Streaming blocked, restart ..."
        echo ""
        pkill youtube-dl; youtube-dl -f $fmt "$video_url" &
    else
        echo " - Streaming OK"
    fi
    old_size=$new_size
done
