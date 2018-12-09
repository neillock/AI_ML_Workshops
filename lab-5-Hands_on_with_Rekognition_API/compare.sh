#!/bin/bash

images=`aws s3 ls s3://image-demo-lab | grep jp | cut -c32-`
c=0

for i in $images
do
  echo -n Comparing $i : matches found =" "
  aws rekognition compare-faces --source-image "{\"S3Object\":{\"Bucket\":\"image-demo-lab\",\"Name\":\"ric_harvey.jpeg\"}}" --target-image "{\"S3Object\":{\"Bucket\":\"image-demo-lab\",\"Name\":\"$i\"}}" --output json > o.txt
  matches=$(cat o.txt | jq '.FaceMatches | length')
  echo $matches
  c=$(($c + $matches))
done
echo Total images matched:" "$c
