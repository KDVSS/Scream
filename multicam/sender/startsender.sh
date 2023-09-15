#!/bin/bash
#
# The semder side processing is illustrated below
# Each gstreamer pipeline encodes media and sends it on local
#  ports 30000 and 30002 to the SCReAM sender
# The SCReAM sender implements the congestion control
#  and prioritization between media
#  and sends the multiplexed RTP media over port UDP_PORT_VIDEO to the destination,
#  RTCP feedback from the destinaton is also received on port UDP_PORT_VIDEO
#
# +-----------------+ Lo:30001  +---------------------+
# |                 +<----------+                     |
# |  /dev/video0    |           |                     |
# |  capture/encode +---------->+                     |
# +-----------------+ Lo:30000  |                     +------------------->
#                               |  SCReAM sender      |   DST_IP:51000
# +-----------------+ Lo:30003  |                     +<-------------------
# |                 +<----------+                     |
# |  /dev/video1    |           |                     |
# |  capture/encode +---------->+                     |
# +-----------------+ Lo:30002  +---------------------+


# Set path to codecctrl plugin
export GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0/

# Settings for video encoding and streaming
RECEIVER_IP=192.168.1.103 #Change to applicable receiver address
UDP_PORT_VIDEO=51000
NETWORK_QUEUE_DELAY_TARGET=0.2
MAX_TOTAL_RATE=60000

# Select type of camera here
#SOURCE="e-CAM50_CUNX"
#SOURCE="Raspberry-Pi-HQ_Camera_12MP"
SOURCE="Movie" 


if [ "$SOURCE" == "e-CAM50_CUNX" ]; then
  echo "Starting e-CAM50_CUNX camera(s)"

  # Settings for exposure compensation and sharpness
  # for low light condition this can be set to 8000 and 0 to
  # maintain full framerate
  EXPOSURE_COMPENSATION=140000 #default 140000
  SHARPNESS=16 #default 16

   --set-ctrl=low_latency_mode=1 --set-ctrl=exposure_compensation=$EXPOSURE_COMPENSATION --set-ctrl=sharpness=$SHARPNESS
  v4l2-ctl -d /dev/video1 --set-ctrl=low_latency_mode=1 --set-ctrl=exposure_compensation=$EXPOSURE_COMPENSATION --set-ctrl=sharpness=$SHARPNESS

  echo "Start gstreamer pipelines"

  ## /dev/video0
  # encode at 1920*1080, run application ecam_tk1_guvcview for other alternatives
  gst-launch-1.0 rtpbin name=rtpbin nvv4l2camerasrc device=/dev/video0 ! \
  "video/x-raw(memory:NVMM), format=(string)UYVY, width=(int)1920, height=(int)1080" ! nvvidconv ! "video/x-raw(memory:NVMM),format=(string)I420" ! \
  nvv4l2h264enc name=video iframeinterval=500 control-rate=1 bitrate=1000000 insert-sps-pps=true preset-level=1 profile=2 maxperf-enable=true EnableTwopassCBR=true vbv-size=500000 poc-type=2 ! \
  queue max-size-buffers=2 !  rtph264pay mtu=1300 !  codecctrl media-src=4 port=30001 ! udpsink host=127.0.0.1 port=30000 &

  sleep 1
  ## /dev/video1
  gst-launch-1.0 rtpbin name=rtpbin nvv4l2camerasrc device=/dev/video1 ! "video/x-raw(memory:NVMM), format=(string)UYVY, width=(int)1920, height=(int)1080" ! \
  nvvidconv ! nvv4l2h264enc name=video iframeinterval=500 control-rate=1 bitrate=1000000 insert-sps-pps=true preset-level=1 profile=2 maxperf-enable=true EnableTwopassCBR=true vbv-size=500000 poc-type=2 !\
  queue max-size-buffers=2 !  rtph264pay  mtu=1300 !  codecctrl media-src=4 port=30003 ! udpsink host=127.0.0.1 port=30002 &
fi

if [ "$SOURCE" == "Raspberry-Pi-HQ_Camera_12MP" ]; then
  echo "Raspberry Pi HQ Camera 12MP camera(s)"

  #gst-launch-1.0  rtpbin name=rtpbin nvarguscamerasrc sensor-id=0  saturation=0.5 tnr_mode=2 ee-mode=0 tnr_strength=0.1 wbmode=4 exposurecompensation=0.6  ! \
  #"video/x-raw(memory:NVMM),width=1920,height=1080,framerate=60/1" ! nvvidconv ! "video/x-raw(memory:NVMM),format=(string)I420" ! \
  #nvv4l2h264enc name=video iframeinterval=500 control-rate=1 bitrate=1000000 insert-sps-pps=true preset-level=1 profile=2 maxperf-enable=true EnableTwopassCBR=true vbv-size=500000 poc-type=2 ! \
  #queue max-size-buffers=2 ! rtph264pay  mtu=1300 !  codecctrl media-src=4 port=30001 ! udpsink host=127.0.0.1 port=30000 &

  #gst-launch-1.0  rtpbin name=rtpbin nvarguscamerasrc sensor-id=1  saturation=0.6 tnr_mode=2 ee-mode=0 tnr_strength=0.1 ! \
  #"video/x-raw(memory:NVMM),width=1920,height=1080,framerate=60/1" ! nvvidconv ! "video/x-raw(memory:NVMM),format=(string)I420" ! \
  #nvv4l2h264enc name=video iframeinterval=500 control-rate=1 bitrate=1000000 insert-sps-pps=true preset-level=1 profile=2 maxperf-enable=true EnableTwopassCBR=true vbv-size=500000 poc-type=2 ! \
  #queue max-size-buffers=2 ! rtph264pay  mtu=1300 !  codecctrl media-src=4 port=30003 ! udpsink host=127.0.0.1 port=30002 &

  ###########################
  #gst-launch-1.0 -vvvv  rtpbin name=rtpbin v4l2src device=/dev/video0 ! "video/x-raw, format=(string)UYVY, width=(int)640, height=(int)480" ! videoconvert ! "video/x-raw,format=(string)I420" ! v4l2h264enc name=video extra-controls="s,video_bitrate=600000,h264_i_frame_period=15,h264_profile=1;" ! queue max-size-buffers=2 ! rtph264pay  mtu=1300 !  codecctrl media-src=6 port=30001 ! udpsink host=127.0.0.1 port=30000 &
  

  #gst-launch-1.0 -vvv videotestsrc  num-buffers=300 ! video/x-raw,framerate=30/1,width=1280,height=720,format=I420 ! capssetter caps="video/x-h264, colorimetry=bt709" ! v4l2h264enc name=video extra-controls="controls,video_bitrate=1000000,video_bitrate_mode=1;" !  'video/x-h264,level=(string)4' ! queue max-size-buffers=2 ! rtph264pay  mtu=1300 !  codecctrl media-src=6 port=30001 ! udpsink host=127.0.0.1 port=30000 &


  gst-launch-1.0 rtpbin name=rtpbin ! v4l2src device=/dev/video0 ! videoconvert ! video/x-raw,width=1920,height=1080,framerate=30/1 ! x264enc name=video tune=zerolatency ! rtph264pay ! codecctrl media-src=4 port=30001 ! udpsink host=127.0.0.1 port=30000 &



fi

if [ "$SOURCE" == "Movie" ]; then
  # Download the big buck bunny 1080p60fps movie 
  #  from http://ftp.vim.org/ftp/ftp/pub/graphics/blender/demo/movies/BBB/
  MEDIA=/home/dhana-pi/Downloads/bbb_sunflower_1080p_30fps_normal.mp4
  
  #gst-launch-1.0 rtpbin name=rtpbin multifilesrc location=$MEDIA location=$MEDIA loop=true stop-index=-1 ! qtdemux name=demux ! queue ! h264parse ! omxh264dec ! queue ! nvv4l2h264enc name=video iframeinterval=500 control-rate=1 bitrate=1000000 insert-sps-pps=true preset-level=1 profile=2 maxperf-enable=true EnableTwopassCBR=true vbv-size=500000 poc-type=2 ! queue max-size-buffers=2 ! rtph264pay  mtu=1300 ! codecctrl media-src=4 port=30001 ! udpsink host=127.0.0.1 port=30000 &

  
  gst-launch-1.0 rtpbin name=rtpbin multifilesrc location=$MEDIA location=$MEDIA loop=true stop-index=-1 ! qtdemux name=demux ! queue ! h264parse ! v4l2h264dec ! queue ! v4l2h264enc name=video extra-controls="controls,video_bitrate=6000000,video_bitrate_mode=1;" ! 'video/x-h264,level=(string)4' ! queue max-size-buffers=2 ! rtph264pay  mtu=1300 ! codecctrl media-src=6 port=30001 ! udpsink host=127.0.0.1 port=30000 &
  

fi

sleep 1
##Start SCReAM sender side.
# The rate control is configured so that /dev/video0 gets a higher prority (1.0)
# while /dev/video1 gets a lower priority (0.5), see -priority parameter
# Min, max and init rate for /dev/video{0,1} can also be configured
# ratescale compensates for offset that may occur between target and actual bitrates for the video coder
# For L4S capability, change to
#  ./screamTx/bin/scream_sender -ect 1
# For new CC algorithm add
#  -newcc and optionally -fincrease X where X is a value in range ]0.0 10]

echo "Video streaming started"
./scream/bin/scream_sender -ect 1 -delaytarget $NETWORK_QUEUE_DELAY_TARGET -priority 1.0:0.5 -ratemax 25000:25000 -ratemin 2000:2000 -rateinit 5000:5000 -ratescale 1.0:1.0 -cwvmem 60 -maxtotalrate  $MAX_TOTAL_RATE -pacingheadroom 1.2 2 $RECEIVER_IP $UDP_PORT_VIDEO &


