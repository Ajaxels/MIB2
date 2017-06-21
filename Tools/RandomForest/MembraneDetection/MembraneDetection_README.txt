This is a test folder for the training of a random forest classifier for membrane detection.

There is an outline on how to use the framework below, if you encounter any other problems, please write me an email at vkaynig@seas.harvard.edu.

If you find this code useful, please reference the following paper:
Kaynig, V., Fuchs, T., Buhmann, J. M., Neuron Geometry Extraction by Perceptual Grouping in ssTEM Images, CVPR, 2010

This is how it works:
- go to the folder externalPackages and download the required matlab packages, compile them and make sure they work and are in the matlab path
- open matlab
- add the membraneDetection directory to your matlab path
- change into the folder with the test images
- each test image needs to be name Ixxxxx_image.tif and be a gray value image
- for training images use the naming scheme Ixxxxx_train.TIF
- annotations in the training image need to be done in green and red, take care that you use only one color channel in the red and green colors
- when you run the skript_trainClassifier_for_membraneDetection it creates a feature matrix for each test image, if the file Ixxxxx_fm.mat does not exist yet. Then it extracts all training labels from the annotated color images and applies the trained classifier to all test images in the folder. The results are opened in different matlab figures. 
- Iterate between executing the skript, and adding annotations in the training images, until you are satisfied
- save the trained classifier in matlab:
save forest.mat forest

- you can then apply the classifier to other images using the skripts skript_extractMembraneFeatures_for_allImages.m and skript_applyClassifier_to_all_images.m
- the result segmentation is saved as tif files with the name Ixxxxx_seg.tif