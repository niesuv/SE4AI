BUCKET="agriculture-bucket-ai"
while true; do
  aws s3 sync /mnt/stream_data/hls s3://$BUCKET/live/ --delete
  sleep 3
done