#!/bin/bash

# LOOP THROUGH VARIOUS FILE TYPES
for i in *.{mp4,mkv,avi,webm}
do
# START TIMER FOR LOGGING PURPOSES
  start=$(date +%s)
# DETERMINES FPS OF ORIGINAL VIDEO
  fps=$(ffmpeg -i "$i" 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")
# DETERMINES THE HEIGHT AND WIDTH FOR DISPLAY ASPECT RATIO PURPOSES
  hh=$(ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=noprint_wrappers=1:nokey=1 "$i"  | cut -d':' -f2)
  ww=$(ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=noprint_wrappers=1:nokey=1 "$i"  | cut -d':' -f1)
# CREATES TEMP FOLDERS FOR STORING VIDEO FRAMES
  mkdir -p tmp/in
  mkdir -p tmp/out
# EXTRACTS FRAMES
  ffmpeg -i "$i" -qscale:v 1 -qmin 1 -qmax 1 -vsync 0 "tmp/in/frame%08d.png"
# UPSCALES FRAMES TO 3X ORIGINAL RESOLUTION
  realesrgan-ncnn-vulkan -i "tmp/in" -o "tmp/out" -m models -n realesr-animevideov3-x3 -s 3 -f jpg
# TRANSCODES UPSCALED FRAMES TO 1080P HEVC VIDEO
  ffmpeg -r $fps -i "tmp/out/frame%08d.jpg" -i "$i" -vf "scale=-2:1080,setdar=$ww/$hh" -map 0:v:0 -map 1:a:0 -sn -c:v libx265 -crf $1 -preset slow -c:a aac -r $fps -pix_fmt yuv420p "out/${i%.*}.mkv"
# MOVES ORIGINAL VIDEO TO "DONE" FOLDER
  # LENGTH OF ORIGINAL FILE (INT AND FLOAT)
  a=$(ffprobe "$i" -show_entries format=duration -v quiet -of csv="p=0")
  b=$( printf "%.0f" $a )
  # LENGTH OF NEW FILE (INT AND FLOAT)
  c=$(ffprobe "out/${i%.*}.mkv" -show_entries format=duration -v quiet -of csv="p=0")
  d=$( printf "%.0f" $c )
  # LENGTH OF NEW FILE + 10
  e=$((d + 10))
  # CHECK IF OUTPUT LENGTH MATCHES INPUT LENGTH
  if [[  $b -le $e  ]]
  # IF IT DOES THEN MOVE ORIGINAL FILE TO "DONE" AND DELETE TEMP FOLDERS
  then
    mv "$i" "done/$i"
  # IF IT DOESN'T THEN REMOVE OUTPUT FILE ARCHIVE FRAMES, AND DELETE TEMP FOLDERS
  else
    rm "out/${i%.*}.mkv"
  fi
  rm -R tmp/in
  rm -R tmp/out
  end=$(date +%s)
# END TIMER AND OUTPUT TO LOG
  echo "$(date) -- $i -- $(( ($end-$start)/60 )) minutes" >> upscale.log
done
