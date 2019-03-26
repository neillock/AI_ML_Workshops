![Workshops](../banners/aws.png)  ![Workshops](images/rekognition.png)
**Last Updated:** March 2019

# Hands on with the Amazon Rekognition API

### Requirements

- AWS Account with local access credentials
- AWS CLI tools installed
- python + boto3 + some python skills

## Why Amazon Rekognition?

A different AI/ML in this series looked at image recognition using Apache MXNet and we analysed an image of a rock guitarist - see [here](<https://github.com/drandrewkane/AI_ML_Workshops/blob/master/lab-3-Hands_on_with_Apache_MXNet>). In order to do that we had to prepare the data, this takes time when dealing with thousands or millions of images. Rekognition does this for you automatically. The screen shot below shows the same image processed by rekognition.

![demo0.png](demo0.png)

As you can see AWS has already done the heavy lifting of data preparation for you. Also it extends much further with object detection. It can detect faces, guess the age of the person, compare faces and even process video streams in the same way.

## Using Amazon Rekognition

To start with let's look at the AWS CLI for Rekognition, we'll want a few sample images, ones you can use easily are from this repository, but feel free to subsitute with your own.

Create an S3 bucket and upload the sample images - we are using photos of one our Evangelists, Ric Harvey, but you could use any photo sets that you like.

First of all lets scan a picture to find a face - note, use your bucket name, not literally *YOURBUCKETNAME*:

```bash
aws rekognition detect-faces --image "S3Object={Bucket="YOURBUCKETNAME", Name="ric_harvey.jpeg"}"
```
The output of this shows there is indeed a face detected, and you can see details on the Landmarks it used to detect the face and its confidence.

```json
{
    "FaceDetails": [
        {
            "BoundingBox": {
                "Width": 0.3238965570926666,
                "Top": 0.1666368991136551,
                "Left": 0.33553096652030945,
                "Height": 0.3074423372745514
            },
            "Landmarks": [
                {
                    "Y": 0.2876920998096466,
                    "X": 0.4322119653224945,
                    "Type": "eyeLeft"
                },
                {
                    "Y": 0.2862488329410553,
                    "X": 0.5742876529693604,
                    "Type": "eyeRight"
                },
                {
                    "Y": 0.3933376669883728,
                    "X": 0.45016252994537354,
                    "Type": "mouthLeft"
                },
                {
                    "Y": 0.3922717273235321,
                    "X": 0.5671025514602661,
                    "Type": "mouthRight"
                },
                {
                    "Y": 0.3384993076324463,
                    "X": 0.508313000202179,
                    "Type": "nose"
                }
            ],
            "Pose": {
                "Yaw": 1.473808765411377,
                "Roll": -2.1248180866241455,
                "Pitch": -3.9496753215789795
            },
            "Quality": {
                "Sharpness": 89.85481262207031,
                "Brightness": 84.628662109375
            },
            "Confidence": 100.0
        }
    ]
}
```
However in most cases you don't want to just find a face you want some information about that face, gender and defining features, maybe the sentiment. We can do this by calling __detect-labels__.

```bash
aws rekognition detect-labels --image "S3Object={Bucket="YOURBUCKETNAME", Name="ric_harvey.jpeg"}"
```

The resulting output determines that Ric is, indeed, human - we've removed some of the output JSON for the sake of clarity:

```json
{
    "LabelModelVersion": "2.0",
    "Labels": [
        {
            "Confidence": 97.83240509033203,
            "Instances": [],
            "Name": "Human",
            "Parents": []
        },
        {
            "Confidence": 97.83240509033203,
            "Instances": [
                {
                    "BoundingBox": { <removed> },
                    "Confidence": 97.83240509033203
                }
            ],
            "Name": "Person",
            "Parents": []
        },
        {
            "Confidence": 96.00078582763672,
            "Instances": [],
            "Name": "Clothing",
            "Parents": []
        },
        {
            "Confidence": 96.00078582763672,
            "Instances": [],
            "Name": "Apparel",
            "Parents": []
        },
         {
            "Confidence": 96.00078582763672,
            "Instances": [
                {
                    "BoundingBox": { <removed> },
                    "Confidence": 96.00078582763672
                }
            ],
            "Name": "Sweater",
            "Parents": [
                {
                    "Name": "Clothing"
                }
            ]
        },
       {
            "Confidence": 95.15144348144531,
            "Instances": [],
            "Name": "Man",
            "Parents": [
                {
                    "Name": "Person"
                }
            ]
        },
        {
            "Confidence": 67.18626403808594,
            "Instances": [],
            "Name": "Sleeve",
            "Parents": [
                {
                    "Name": "Clothing"
                }
            ]
        }
    ]
}
```

In a recent upgrade to the Rekognition model AWS introduced the idea of *parent* objects - in this example for Ric, the label *Man* links back to the object for *Person*, and *Sleeve* links back to *Clothing*.

So if we can find faces in images and identify key objects about that face we should be able to compare faces and find the same person in multiple photos. Heres an example using __compare-faces__.

```bash
aws rekognition compare-faces --source-image '{"S3Object":{"Bucket":"YOURBUCKETNAME","Name":"ric_harvey.jpeg"}}' --target-image '{"S3Object":{"Bucket":"YOURBUCKETNAME","Name":"ric.jpg"}}'
```

In the first example we have a match - we are 100% confident that we have found a face in both images, and then 99.27% confident that they match.  We're pretty confident that this is Ric.

```json
{
    "UnmatchedFaces": [],
    "FaceMatches": [
        {
            "Face": {
                "BoundingBox": {
                    "Width": 0.41572150588035583,
                    "Top": 0.12303049862384796,
                    "Left": 0.316993772983551,
                    "Height": 0.6135206818580627
                },
                "Confidence": 100.0,
                "Pose": {
                    "Yaw": 0.6714985966682434,
                    "Roll": -0.0029848809354007244,
                    "Pitch": 0.6671947240829468
                },
                "Quality": {
                    "Sharpness": 78.64350128173828,
                    "Brightness": 50.17827606201172
                },
                "Landmarks": [
                    {
                        "Y": 0.33426931500434875,
                        "X": 0.42318251729011536,
                        "Type": "eyeLeft"
                    },
                    {
                        "Y": 0.33917325735092163,
                        "X": 0.6163105368614197,
                        "Type": "eyeRight"
                    },
                    {
                        "Y": 0.5411261916160583,
                        "X": 0.4390724301338196,
                        "Type": "mouthLeft"
                    },
                    {
                        "Y": 0.5456682443618774,
                        "X": 0.5989208221435547,
                        "Type": "mouthRight"
                    },
                    {
                        "Y": 0.44001856446266174,
                        "X": 0.5190205574035645,
                        "Type": "nose"
                    }
                ]
            },
            "Similarity": 99.27263641357422
        }
    ],
    "SourceImageFace": {
        "BoundingBox": {
            "Width": 0.3238965570926666,
            "Top": 0.1666368991136551,
            "Left": 0.33553096652030945,
            "Height": 0.3074423372745514
        },
        "Confidence": 100.0
    }
}
```

However lets look at a picture with more than one person in it.

```bash
aws rekognition compare-faces --source-image '{"S3Object":{"Bucket":"YOURBUCKETNAME","Name":"ric_harvey.jpeg"}}' --target-image '{"S3Object":{"Bucket":"YOURBUCKETNAME","Name":"ric_crowd1.jpg"}}'
```

The output from this shows 1 matched face in the *FaceMatches* section, and several unmatched faces in the *UnmatchedFaces* section - however, you do get useful metadata about every face that have been picked out.  Rekognition gives 98.74% similarity rating for the matched face, and that's despite the image being slightly blurry and with poor lighting.

```json
{
    "UnmatchedFaces": [
        {
            "BoundingBox": {
                "Width": 0.23272210359573364,
                "Top": 0.510046124458313,
                "Left": 0.7415141463279724,
                "Height": 0.4028888940811157
            },
            "Confidence": 99.99987030029297,
            "Pose": {
                "Yaw": -23.619752883911133,
                "Roll": -5.818271636962891,
                "Pitch": 9.376426696777344
            },
            "Quality": {
                "Sharpness": 53.330047607421875,
                "Brightness": 29.453981399536133
            },
            "Landmarks": [
                {
                    "Y": 0.6929454803466797,
                    "X": 0.8373074531555176,
                    "Type": "eyeLeft"
                },
                {
                    "Y": 0.6977059245109558,
                    "X": 0.945943295955658,
                    "Type": "eyeRight"
                },
                {
                    "Y": 0.8433666229248047,
                    "X": 0.8459407687187195,
                    "Type": "mouthLeft"
                },
                {
                    "Y": 0.8482340574264526,
                    "X": 0.93607497215271,
                    "Type": "mouthRight"
                },
                {
                    "Y": 0.7731311917304993,
                    "X": 0.8804974555969238,
                    "Type": "nose"
                }
            ]
        },
        {
            "BoundingBox": {
                "Width": 0.12664306163787842,
                "Top": 0.4119572043418884,
                "Left": 0.48019713163375854,
                "Height": 0.24227945506572723
            },
            "Confidence": 99.99998474121094,
            "Pose": {
                "Yaw": 4.041987419128418,
                "Roll": 3.3684937953948975,
                "Pitch": -20.516826629638672
            },
            "Quality": {
                "Sharpness": 38.89601135253906,
                "Brightness": 26.469314575195312
            },
            "Landmarks": [
                {
                    "Y": 0.5068619847297668,
                    "X": 0.5267886519432068,
                    "Type": "eyeLeft"
                },
                {
                    "Y": 0.5116945505142212,
                    "X": 0.5861381888389587,
                    "Type": "eyeRight"
                },
                {
                    "Y": 0.5888504385948181,
                    "X": 0.5275153517723083,
                    "Type": "mouthLeft"
                },
                {
                    "Y": 0.5928797125816345,
                    "X": 0.5768627524375916,
                    "Type": "mouthRight"
                },
                {
                    "Y": 0.5561686754226685,
                    "X": 0.5575464963912964,
                    "Type": "nose"
                }
            ]
        },
        {
            "BoundingBox": {
                "Width": 0.31463298201560974,
                "Top": 0.36742377281188965,
                "Left": -0.010811327025294304,
                "Height": 0.5718353986740112
            },
            "Confidence": 100.0,
            "Pose": {
                "Yaw": 25.575437545776367,
                "Roll": 7.750082969665527,
                "Pitch": -0.5794483423233032
            },
            "Quality": {
                "Sharpness": 73.32209777832031,
                "Brightness": 26.861705780029297
            },
            "Landmarks": [
                {
                    "Y": 0.6168197393417358,
                    "X": 0.09621831029653549,
                    "Type": "eyeLeft"
                },
                {
                    "Y": 0.636400043964386,
                    "X": 0.24112087488174438,
                    "Type": "eyeRight"
                },
                {
                    "Y": 0.8429403305053711,
                    "X": 0.09124591201543808,
                    "Type": "mouthLeft"
                },
                {
                    "Y": 0.8571742177009583,
                    "X": 0.21000227332115173,
                    "Type": "mouthRight"
                },
                {
                    "Y": 0.7462476491928101,
                    "X": 0.19551265239715576,
                    "Type": "nose"
                }
            ]
        },
        {
            "BoundingBox": {
                "Width": 0.1486806869506836,
                "Top": 0.31899121403694153,
                "Left": 0.6218242049217224,
                "Height": 0.2892136871814728
            },
            "Confidence": 99.99995422363281,
            "Pose": {
                "Yaw": -9.001951217651367,
                "Roll": -15.084820747375488,
                "Pitch": -0.08522148430347443
            },
            "Quality": {
                "Sharpness": 46.02980041503906,
                "Brightness": 36.90113067626953
            },
            "Landmarks": [
                {
                    "Y": 0.45112869143486023,
                    "X": 0.657817542552948,
                    "Type": "eyeLeft"
                },
                {
                    "Y": 0.4396614730358124,
                    "X": 0.7241609692573547,
                    "Type": "eyeRight"
                },
                {
                    "Y": 0.5389857888221741,
                    "X": 0.675711452960968,
                    "Type": "mouthLeft"
                },
                {
                    "Y": 0.5303119421005249,
                    "X": 0.7309232950210571,
                    "Type": "mouthRight"
                },
                {
                    "Y": 0.49695348739624023,
                    "X": 0.6839836239814758,
                    "Type": "nose"
                }
            ]
        }
    ],
    "FaceMatches": [
        {
            "Face": {
                "BoundingBox": {
                    "Width": 0.1646803468465805,
                    "Top": 0.38141894340515137,
                    "Left": 0.2834920287132263,
                    "Height": 0.31770819425582886
                },
                "Confidence": 99.99987030029297,
                "Pose": {
                    "Yaw": 30.25555992126465,
                    "Roll": 25.35053253173828,
                    "Pitch": 1.6962026357650757
                },
                "Quality": {
                    "Sharpness": 60.49041748046875,
                    "Brightness": 25.469776153564453
                },
                "Landmarks": [
                    {
                        "Y": 0.4987576901912689,
                        "X": 0.3558201193809509,
                        "Type": "eyeLeft"
                    },
                    {
                        "Y": 0.5361648201942444,
                        "X": 0.4192109704017639,
                        "Type": "eyeRight"
                    },
                    {
                        "Y": 0.6199691295623779,
                        "X": 0.3274959921836853,
                        "Type": "mouthLeft"
                    },
                    {
                        "Y": 0.6497430801391602,
                        "X": 0.3787180185317993,
                        "Type": "mouthRight"
                    },
                    {
                        "Y": 0.5817705392837524,
                        "X": 0.38942280411720276,
                        "Type": "nose"
                    }
                ]
            },
            "Similarity": 98.74687957763672
        }
    ],
    "SourceImageFace": {
        "BoundingBox": {
            "Width": 0.3238965570926666,
            "Top": 0.1666368991136551,
            "Left": 0.33553096652030945,
            "Height": 0.3074423372745514
        },
        "Confidence": 100.0
    }
}
```

Repeating this with __ric_crowd0.jpg__ will show no results - the *FaceMatches* section is completely empty.

## Doing this from python

Using the CLI is fine but if you want to embed this into you system you'll need to make these calls from code. We'll use Python to do this and we'll need boto3 installed for accessing the AWS API:

```bash
pip install boto3
```

__Note:__ OSX may need to run ```sudo -H pip install boto3```

### Sample code

Lets look at some same code that allows you to detect faces and the labels for each face. Try running this on a few of the sample images.

```python
#!/usr/bin/env python

import sys
import boto3

defaultRegion = 'eu-west-1'
defaultUrl = 'https://rekognition.eu-west-1.amazonaws.com'

def connectToRekognitionService(regionName=defaultRegion, endpointUrl=defaultUrl):
    return boto3.client('rekognition', region_name=regionName, endpoint_url=endpointUrl)

def detectFaces(rekognition, imageBucket, imageFilename, attributes='ALL'):
    resp = rekognition.detect_faces(
            Image = {"S3Object" : {'Bucket' : imageBucket, 'Name' : imageFilename}},
            Attributes=[attributes])
    return resp['FaceDetails']

def detectLabels(rekognition, imageBucket, imageFilename, maxLabels=100, minConfidence=0):
    resp = rekognition.detect_labels(
        Image = {"S3Object" : {'Bucket' : imageBucket, 'Name' : imageFilename}},
        MaxLabels = maxLabels, MinConfidence = minConfidence)
    return resp['Labels']

def printFaceInformation(face, faceCounter):
    print('*** Face ' + str(faceCounter) + ' detected, confidence: ')+str(face['Confidence'])
    print('Gender: ')+face['Gender']['Value']
    # You need boto3>=1.4.4 for AgeRange
    print('Age: ')+str(face['AgeRange']['Low'])+"-"+str(face['AgeRange']['High'])
    if (face['Beard']['Value']):
        print ('Beard')
    if (face['Mustache']['Value']):
        print ('Mustache')
    if (face['Eyeglasses']['Value']):
        print ('Eyeglasses')
    if (face['Sunglasses']['Value']):
        print ('Sunglasses')
    for e in face['Emotions']:
        print e['Type']+' '+str(e['Confidence'])

def printLabelsInformation(labels):
    for l in labels:
        print('Label ' + l['Name'] + ', confidence: ' + str(l['Confidence']))

def usage():
    print('\nrekognitionDetect <S3BucketName> <image>\n')
    print('S3BucketName  : the S3 bucket where Rekognition will find the image')
    print('image         : the image to process')
    print('Output        :  labels & face information (stdout)\n')

if (len(sys.argv) != 3):
    usage()
    sys.exit()

imageBucket = str(sys.argv[1])
image       = str(sys.argv[2])

reko = connectToRekognitionService()

labels = detectLabels(reko, imageBucket, image, maxLabels=10, minConfidence=70.0)
printLabelsInformation(labels)

faceList = detectFaces(reko, imageBucket, image)
faceCounter = 0
for face in faceList:
    printFaceInformation(face, faceCounter)
    faceCounter=faceCounter+1

labelText = ''
for l in labels:
    if (l['Confidence'] > 80.0):
        labelText = labelText + l['Name'] + ", "
```

Copy and paste into a python file, such as **rekLab.py**.  You can now run this against any image that you have uploaded into your bucket, as follows:

```bash
$ python rekLab.py YOURBUCKETNAME ric_harvey.jpeg
```

This code will call **detect-labels** and **detect-faces** and try and provide some intelligible output.  For instance,  if you run this against **ric_harvey.jpeg** then you should the following output:

```
Label Human, confidence: 97.8324050903
Label Person, confidence: 97.8324050903
Label Sweater, confidence: 96.0007858276
Label Clothing, confidence: 96.0007858276
Label Apparel, confidence: 96.0007858276
Label Man, confidence: 95.151473999
*** Face 0 detected, confidence: 100.0
Gender: Male
Age: 35-52
Beard
CALM 93.4333953857
SURPRISED 0.905286967754
SAD 2.43520069122
CONFUSED 1.0990087986
HAPPY 0.299568772316
DISGUSTED 0.428233355284
ANGRY 1.39930927753
```

## Challenge - Where's Ric?

Durring registration at a recent AWS event we took some photos and uploaded them to a public S3 bucket **s3://image-demo-lab** there is also an array of asorted images in the bucket. Your challenge is to:

- find how many pictures in the bucket contain a photo of Ric

You'll need to create a compare-faces function and also get a list of all the objects in the S3 bucket (warning they may not all be images!) Extra points for the fastest way of doing this.

## Resources

[http://boto3.readthedocs.io/en/latest/reference/services/rekognition.html](http://boto3.readthedocs.io/en/latest/reference/services/rekognition.html)

Let an instructor know when you've completed this.

