#!/bin/sh
#
# The receiver side processing is illustrated below
# The SCReAM receiver application receives multiplexed RTP media on port $2
#  and transits RTCP feedback over the same port
# The received RTP media is demultiplexed and forwarded on local 
#  ports 30112, 30114, 31016 and 30118
# The video decoding assumes an NVIDIA Jetson Nano or Xavier NX platform, change to applicable 
#  HW decoding, depending on platform
#
#                     +----------------------+               +--------------------+
#                     |                      |  Lo:30112     |                    |
#                     |                      +-------------->+  Front camera      |
#                     |                      |               |  decode/render     |
# +------------------>+                      |               +--------------------+
#    $1:$2            |  SCReAM receiver     |
# <-------------------+                      |               +--------------------+
#                     |                      |  Lo:30114     |                    |
#                     |                      +-------------->+  Rear  camera      |
#                     |                      |               |  decode/render     |
#                     +----------------------+               +--------------------+


# Start SCReAM receiver side
#./scream/bin/scream_receiver $1 $2 $3 | tee ./scream_$4.txt &


## /dev/video0
#gst-launch-1.0 udpsrc port=30112 ! application/x-rtp,media=video,clock-rate=90000,encoding-name=H264 ! rtpjitterbuffer latency=100 ! rtph264depay ! h264parse ! omxh264dec disable-dpb=true ! nvvidconv !  nveglglessink window-x=640 window-y=360 max-lateness=2000000 sync=true & 



gst-launch-1.0 rtpbin name=rtpbin udpsrc port=30112 ! application/x-rtp,media=video,clock-rate=90000,encoding-name=H264 ! rtpbin.recv_rtp_sink_0 rtpbin. ! rtph264depay ! avdec_h264 ! videoconvert ! xvimagesink sync=false async=false udpsrc port=30001 ! rtpbin.recv_rtcp_sink_0  rtpbin.send_rtcp_src_0 ! udpsink port=30001 host=$SENDER_IP sync=false async=false &

#gst-launch-1.0 rtpbin name=rtpbin udpsrc port=30114 ! application/x-rtp,media=video,clock-rate=90000,encoding-name=H264 ! rtpbin.recv_rtp_sink_0 rtpbin. ! rtph264depay ! avdec_h264 ! videoconvert ! xvimagesink sync=false async=false udpsrc port=5001 ! rtpbin.recv_rtcp_sink_0  rtpbin.send_rtcp_src_0 ! udpsink port=5001 host=$SENDER_IP sync=false async=false &


## /dev/video1
#gst-launch-1.0 udpsrc port=30114 ! application/x-rtp,media=video,clock-rate=90000,encoding-name=H264 ! rtpjitterbuffer latency=100 ! rtph264depay ! h264parse ! omxh264dec disable-dpb=true ! nvvidconv ! nveglglessink window-x=960 window-y=0 sync=true &

