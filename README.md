# Scripts for AI Upscaling

## Anime3x Script for Cartoons and Anime
A batch script that uses the realesrgan animev3-x3 model to upscale all MP4, AVI, and MKV videos in a directory to 3x the original resolution (https://github.com/xinntao/Real-ESRGAN). The content is then transcoded and scaled to a 1080p HEVC MKV file.
### Usage
- realesrgan-ncnn-vulkan must be installed (or the executable present).
- The script must be run from a directory that contains the Real-ESRGAN model folder.
```bash
sh anime3x.sh 27
# In this example "27" is the CRF value being used during the HEVC trascode.
```
