#!/bin/bash

images=`aws s3 ls s3://image-demo-lab | grep jp | cut -c32-`
for i in $images
do
  echo -n Comparing $i
  aws rekognition compare-faces --source-image "{\"S3Object\":{\"Bucket\":\"image-demo-lab\",\"Name\":\"ric_harvey.jpeg\"}}" --target-image "{\"S3Object\":{\"Bucket\":\"image-demo-lab\",\"Name\":\"$i\"}}" --output json > o.txt
  cat o.txt | jq '.FaceMatches | length'
done
