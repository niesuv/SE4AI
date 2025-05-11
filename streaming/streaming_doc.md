**Simple RTMP Server**

Setup
1. Run EC2 install with docker installed and assumed role to have access to s3, GET, PUT, DELETE OBJECT
2. RUN docker image built.
3. RUN SCRIPT to sync hlf folder and s3 directory.

Streaming flow
1. Streaming device like OBS(Desktop), or rtmp-lib in Android,... will generate stream file and send through port 1035 to server
2. Server will process file and save in /mnt/hls folder (or any you wish), better save in RAM, so EC2 should have enough RAM
3. SYNC the file in that folder to S3, using S3 sync or S3 FUSE, that time we use S3 sync
4. Cloudfront distributes the file to end user
5. User using HLS player (hls.js in web, VLC on Desktop, HLS-lib android) and watch the stream


NOTE: 
1. The delay of the streaming is the delay of encoding video to rtmp format, from rtmp to hls, send to s3, and from S3 to enduser, in best scenerio, the delay time can be less than 5 seconds.
2. EC2 RAM should be considered.
3. Cost to sync file between ec2 and s3 should be considered.