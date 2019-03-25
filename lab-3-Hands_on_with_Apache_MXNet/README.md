![Workshops](../banners/aws.png)  ![Workshops](images/mxnet.png)
**Last Updated:** December 2018
# Hands on with Apache MXNet

### Requirements

- AWS Account
- Basic understanding of ML and NDArrays
- SSH Client and key
- Linux Skills

### Credits

This workshop is adapted from Julien Simons blog posts: [https://medium.com/@julsimon/getting-started-with-deep-learning-and-apache-mxnet-34a978a854b4](https://medium.com/@julsimon/getting-started-with-deep-learning-and-apache-mxnet-34a978a854b4)

## Workshop Overview

In this workshop we are going to take a look at running Apache MXNet on the Amazon Linux Deep Learning AMI. We'll take a pre-trained image reckognition model and use this to predict the contents of images we feed into the model.

## Running MXNet on AWS

AWS provides you with the Deep Learning AMI, available both for Amazon Linux and Ubuntu - simply search for __Deep Learning AMI__ for the operating system AMI of your choice when launching an EC2 instance - remember to select the **Amazon Linux**. This AMI comes pre-installed with many Deep Learning frameworks (MXNet included), as well as all the Nvidia tools and more. No plumbing needed.

You can run this AMI either on a standard instance or on a GPU instance. If you want to train a model and don’t have a NVidia GPU on your machine your most inexpensive option with this AMI will be to use a *p2.xlarge* instance at $0.90 per hour.

However in these labs we are using pre-trained models for speed so a standard *m5.2xlarge* instance of Amazon Linux will be fine . This will allow us to get going with the lab without installing any special tools as the Deep Learning AMI comes with those pre-baked.

When you launch the instance use configuration like the following:

- Use a VPC with an Internet Gateway
- Enable Auto-Assign Public IP
- 75Gb of SSD storage
- Security Group allowed SSH from the Internet
- Create a new EC2 key-pair, or re-use an existing EC2 key-pair that you have locally

Once the instance has launched, connect to it using SSH with a tool of your preference, using the public IP address of the instance and the user **ec2-user**.  For instance, on a Mac the standard CLI command for doing would be similar to:

`ssh -i myEC2keypairfile.pem ec2-user@10.11.12.13`

Remember to replade the IP address with that of your instance!  You should see the following screen banner, followed by a series of instructions to enable the various available frameworks; the list is long, so the screen below is just the start of the output.

```bash
=============================================================================
       __|  __|_  )
       _|  (     /   Deep Learning AMI (Amazon Linux) Version 22.0
      ___|\___|___|
=============================================================================

Please use one of the following commands to start the required environment with the framework of your choice:
for MXNet(+Keras2) with Python3 (CUDA 9.0 and Intel MKL-DNN) _____________________________________ source activate mxnet_p36
for MXNet(+Keras2) with Python2 (CUDA 9.0 and Intel MKL-DNN) _____________________________________ source activate mxnet_p27

<<screen cut for brevity>>

[ec2-user@ip-172-31-42-173 ~] _
```

If you have launched a GPU-enabled intance then you can quickly see what's available with this command:

```bash
[ec2-user@ip-172-31-29-159 ~]$ nvidia-smi -L
GPU 0: Tesla K80 (UUID: GPU-cf550255-cb68-db1d-e9ad-ff9e6681c0d8)
```

Before we start we need to activate our framework, and in our case we want to use MXNet and python 2, so enter the following command:

```bash
[ec2-user@ip-172-31-29-159 ~]$ source activate mxnet_p27
WARNING: First activation might take some time (1+ min).
Installing MXNet optimized for your Amazon EC2 instance......
Env where framework will be re-installed: mxnet_p27
<<followed by a large list of dependency checks>>
Installation complete.
```

## Using a pre-trained model

### The MXNet model zoo

In this first part of the lab we are going to recognising images with Inception v3, published in December 2015, Inception v3 is an evolution of the GoogleNet model (which won the 2014 ImageNet challenge). We won’t go into the details of the research paper, but paraphrasing its conclusion, Inception v3 is 15–25% more accurate than the best models available at the time, while being six times cheaper computationally and using at least five times less parameters (i.e. less RAM is required to use the model).

The model zoo is a collection of pre-trained models ready for use. You’ll find the model definition, the model parameters (i.e. the neuron weights) and instructions.

Let’s download the definition and the parameters. Feel free to open the first file you’ll see the definition of all the layers. The second one is a binary file, so don’t try and open that.

```bash
$ wget http://data.mxnet.io/models/imagenet/inception-bn/Inception-BN-symbol.json

$ wget -O Inception-BN-0000.params http://data.mxnet.io/models/imagenet/inception-bn/Inception-BN-0126.params
```

__Note:__ if your compute resource is defaulting an IPv6 download, and the connection is simply taking too long (or not starting), then you can always force __wget__ to use IPv4 by appending the __-4__ parameter.

Since this model has been trained on the ImageNet data set, we also need to download the corresponding list of image categories which contains the 1000 categories, that way we can see the human readable prediction output. You can take a look at this file also.

```bash
$ wget https://s3-eu-west-1.amazonaws.com/ak-public-docs/synset.txt

$ wc -l synset.txt
    1000 synset.txt

$ head -5 synset.txt
n01440764 tench, Tinca tinca
n01443537 goldfish, Carassius auratus
n01484850 great white shark, white shark, man-eater, man-eating shark, Carcharodon carcharias
n01491361 tiger shark, Galeocerdo cuvieri
n01494475 hammerhead, hammerhead shark
```

Now we are also going to need some sample images to test the model against. I'm going to suggest two images and if you are feeling adventurous, feel free to add some of your own images and have a look at the outputs

```bash
wget -O image0.jpeg https://cdn-images-1.medium.com/max/1600/1*sPdrfGtDd_6RQfYvD5qcyg.jpeg

wget -O image1.jpeg http://kidszoo.org/wp-content/uploads/2015/02/clownfish3-1500x630.jpg
```

### Loading the model for use

Open your python shell,

```bash
python
>>>
```

Load the model from its saved state - note that this first call may take a number of seconds to complete. MXNet calls this a checkpoint. In return, we get the input Symbol and the model parameters.

```python
import mxnet as mx

sym, arg_params, aux_params = mx.model.load_checkpoint('Inception-BN', 0)
```

Create a new Module and assign it the input Symbol. We could also use a context parameter indicating where we want to run the model. By default the module uses the value cpu(0), but we could also use gpu(0) to run this on a GPU.

```python
mod = mx.mod.Module(symbol=sym)
```

Bind the input Symbol to input data. We’ll call it ‘data’ because that’s its name in the input layer of the network (look at the first few lines of the JSON file).

Define the shape of ‘data’ as 1 x 3 x 224 x 224.

```python
mod.bind(for_training=False, data_shapes=[('data', (1,3,224,224))])
```

‘224 x 224’ is the image resolution, that’s how the model was trained. ‘3’ is the number of channels : red, green and blue (in this order). ‘1’ is the batch size: we’ll predict one image at a time.  You may get an error around label-names - you can ignore this.

Set the model parameters.

```python
mod.set_params(arg_params, aux_params)
```

That’s all it takes. Four lines of code! Now it’s time to push some data in there and see what happens. 

### Data preparation

Before we get some predictions out of our model we'll need to prep the data (the images you downloaded)

Remember that the model expects a 4-dimension NDArray holding the red, green and blue channels of a single 224 x 224 image. We’re going to use the popular OpenCV library to build this NDArray from our input image. This is already installed on the Amazon Deep Learning AMI.

First lets load some libaries we'll need.

```python
import numpy as np
import cv2
```

Now we read the image, this will return a numpy array shaped as (image height, image width, 3), with the three channels in BGR order (blue, green and red).

```python
img = cv2.imread('<YOUR_IMAGE_FILE_NAME>')
```

Let’s convert the image to RGB, so we have the correct order (RGB) for the pre-trained model we are using.

```python
img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
```

Now resize the image to 224 x 224.

```python
img = cv2.resize(img, (224, 224,))
```

reshape the array from (image height, image width, 3) to (3, image height, image width).

```python
img = np.swapaxes(img, 0, 2)
img = np.swapaxes(img, 1, 2)
```

Add a fourth dimension and build the NDArray

```python
img = img[np.newaxis, :]
array = mx.nd.array(img)

>>> print array.shape
(1L, 3L, 224L, 224L)
```

Here’s our input pictures.

_Guitarist: images/sample-image0.jpeg_
![Input picture 448x336 (Source: metaltraveller.com)](images/sample-image0.jpeg)

_Clownfish: images/sample-image1.jpeg_
![Input picture 1500x630 (Source: kidszoo.org](images/sample-image1.jpeg)

There imput sizes are 448x336 / 1500x630 and they are in full colour. Remember our model needs images of 224x224 and in RGB.

Once processed, these pictures have been resized and split into RGB channels stored in array[0] 

_Guitarist_
![array[0][0] : 224x224 red channel](images/image0-red.jpeg)  ![array[0][1] : 224x224 green channel](images/image0-green.jpeg)  ![array[0][2] : 224x224 blue channel](images/image0-blue.jpeg)

_Clown Fish_
![array[0][0] : 224x224 red channel](images/image1-red.jpeg)  ![array[0][1] : 224x224 red channel](images/image1-green.jpeg)  ![array[0][2] : 224x224 blue channel](images/image1-blue.jpeg)

If you choose to increase the batch size to higher than 1 and run both images through the model together, then we would have a second image in array[1], a third in array[2] and so on.

Now your data is prepared let’s predict!

### Predicting

Normally we'd use a module object and we must feed data to a model in batches, the common way to do this is to use a data iterator (specifically, we used an NDArrayIter object).

Here, we’d like to predict a single image, so although we could use data iterator, it’d probably be overkill. Instead, we’re going to create a named tuple, called Batch, which will act as a fake iterator by returning our input NDArray when its data attribute is referenced.

```python
from collections import namedtuple
Batch = namedtuple('Batch', ['data'])
```

Now we can pass this “batch” to the model and let it predict.

```python
mod.forward(Batch([array]))
```

This may give a *malloc* message - ignore it.  The model will output an NDArray holding the 1000 probabilities, corresponding to the 1000 categories. It has only one line since batch size is equal to 1.

```python
prob = mod.get_outputs()[0].asnumpy()

>>> prob.shape
(1, 1000)
```

Let’s turn this into an array with squeeze(). Then, using argsort(), we’re creating a second array holding the index of these probabilities sorted in descending order.

```python
prob = np.squeeze(prob)

>>> prob.shape
(1000,)
>> prob
[  4.14978594e-08   1.31608676e-05   2.51907986e-05   2.24045834e-05
   2.30327873e-06   3.40798979e-05   7.41563645e-06   3.04062659e-08 etc.

sortedprob = np.argsort(prob)[::-1]

>> sortedprob.shape
(1000,)
```

According to the model, the most likely category for this picture is #546 (if you are using image0.jpeg), with a probability of over 65%.

```python
>> sortedprob
[546 819 862 818 542 402 650 420 983 632 733 644 513 875 776 917 795
etc.
>> prob[546]
0.6544399
```

Let’s find the name of this category. Using the synset.txt file, we can build a list of categories and find the one at index 546.

```python
synsetfile = open('synset.txt', 'r')
categorylist = []
for line in synsetfile:
  categorylist.append(line.rstrip())

>>> categorylist[546]
'n03272010 electric guitar'
```

The model has correctly identified there is an electric guitar in the image, pretty impressive.

What about the second highest category?

```python
>>> prob[819]
0.27168664
>>> categorylist[819]
'n04296562 stage'
```

Now you know how to use a pre-trained, state of the art model for image classification. All it took was a few lines of code and the rest was just data preparation. You can now try this with the other images (image1.jpeg and your own images) by starting at the data preparation stage again.

## Exercise

Now you know how to load a model and run a test against it, lets try with two other popular models. The following models are all trained against the ImageNet data set so in terms of code it's simply about replacing the model.

Make a note of the categories that it returns and compare the results

### VGG16

Published in 2014, VGG16 is a model built from 16 layers (research paper). It won the 2014 ImageNet challenge by achieving a 7.4% error rate on object classification. As a bonus you can also download and test VGG19.

### ResNet-152

Published in 2015, ResNet-152 is a model built from 152 layers (research paper). It won the 2015 ImageNet challenge by achieving a record 3.57% error rate on object detection. That’s much better than the typical human error rate which is usually measured at 5%.

### Downloading the models

Time to visit the model zoo once again. Just like for Inception v3, we need to download model definitions and parameters. All three models have been trained on the same categories, so we can reuse our synset.txt file.

```bash
$ wget http://data.mxnet.io/models/imagenet/vgg/vgg16-symbol.json
```

__NOTE:__ You'll need to edit this file and swap ```prob_label``` and ```prob``` to ```softmax_label``` and ```softmax``` respectively

```bash
$ wget http://data.mxnet.io/models/imagenet/vgg/vgg16-0000.params

$ wget http://data.mxnet.io/models/imagenet/resnet/152-layers/resnet-152-symbol.json

$ wget http://data.mxnet.io/models/imagenet/resnet/152-layers/resnet-152-0000.params
```