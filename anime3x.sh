#!/bin/bash

# SET UP WORKING FOLDERS
mkdir -p out
mkdir -p done
# LOOP THROUGH VARIOUS FILE TYPES
for i in *.{mp4,mkv,avi}
do
# START TIMER FOR LOGGING PURPOSES
  start=$(date +%s)
# DETERMINES RESOLUTION HEIGHT (NOT CURRENTLY USED)
  resolution=$(ffmpeg -i "$i" 2>&1 | grep Video: | grep -Po '\d{3,5}x\d{3,5}' | cut -d'x' -f2)
# DETERMINES FPS OF ORIGINAL VIDEO
  fps=$(ffmpeg -i "$i" 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")
# DETERMINES THE HEIGHT AND WIDTH FOR DISPLAY ASPECT RATIO PURPOSES
  hh=$(ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=noprint_wrappers=1:nokey=1 "$i"  | cut -d':' -f2)
  ww=$(ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=noprint_wrappers=1:nokey=1 "$i"  | cut -d':' -f1)
# DETERMINES THE PROPER SCALING WIDTH TO MAINTAIN ASPECT RATIO AT 1080P RESOLUTION
  ws=$(echo $((1080/$hh*ww)))
# CREATES TEMP FOLDERS FOR STORING VIDEO FRAMES
  mkdir -p tmp/in
  mkdir -p tmp/out
# EXTRACTS FRAMES
  ffmpeg -i "$i" -qscale:v 1 -qmin 1 -qmax 1 -vsync 0 "tmp/in/frame%08d.png"
# UPSCALES FRAMES TO 3X ORIGINAL RESOLUTION
  realesrgan-ncnn-vulkan -i "tmp/in" -o "tmp/out" -m models -n realesr-animevideov3-x3 -s 3 -f jpg
# TRANSCODES UPSCALED FRAMES TO 1080P HEVC VIDEO
  ffmpeg -r $fps -i "tmp/out/frame%08d.jpg" -i "$i" -vf "scale=-$ws:1080,setdar=$ww/$hh" -map 0:v:0 -map 1:a:0 -sn -c:v libx265 -crf $1 -preset slow -c:a aac -r 29.97 -pix_fmt yuv420p "out/${i%.*}.mkv"
# MOVES ORIGINAL VIDEO TO "DONE" FOLDER
  mv "$i" "done/$i"
# DELETES TEMP FOLDERS FOR STORING VIDEO FRAMES
  rm -R tmp/in
  rm -R tmp/out
  end=$(date +%s)
# END TIMER AND OUTPUT TO LOG
  echo "$i -- $(( ($end-$start)/60 )) minutes" >> upscale.log
done
