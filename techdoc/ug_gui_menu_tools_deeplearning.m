%% Deep MIB - segmentation using Deep Learning
% The deep learning tool (Deep MIB) provides access to training of deep convolutional
% networks over the user data and utilization of those networks for image
% segmentation tasks.
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
% 
%
%% Overview
% 
% <html>
% For details of deep learning with DeepMIB please refer to the following tutorials:<br>
% <a href="https://youtu.be/gk1GK_hWuGE"><img
% style="vertical-align:middle;"
% src="images\youtube2.png"> DeepMIB: 2D U-net for image segmentation</a><br><br>
% <a href="https://youtu.be/U5nhbRODvqU"><img style="vertical-align:middle;" src="images\youtube2.png"> DeepMIB: 3D U-net for image segmentation</a>
% <br><br>
% <a href="https://youtu.be/iG_wsxniBKk"><img
% style="vertical-align:middle;"
% src="images\youtube2.png"> DeepMIB, features and updates in MIB 2.80</a><br><br>
% The typical workflow consists of two parts: 
% <ul>
% <li>network training</li>
% <li>image prediction</li>
% </ul>
% During network training users specify type of the
% network architecture (the <em>Network panel</em> of Deep MIB) and provide images and ground truth
% models (the <em>Directories and Preprocessing tab</em>). For training, the provided data will be split into two sets: one set to be 
% used for the actual training (normally it contains most of the ground truth data)
% and another for validation. The network trains itself over the training
% set, while checking own performance using the validation set (the
% <em>Training tab</em>). 
% <br>
% The pretrained network is saved to disk and can be distributed to predict (the <em>Predict tab</em>) unseen
% datasets.<br>
% Please refer to the documentation below for details of various
% options available in MIB.
% <img src="images\DeepLearning_scheme.jpg">
% </html>
%
%
%% Network panel
% <<images\DeepLearningNetwork.png>>
% 
% <html>
% The upper part of Deep MIB is occupied with the <em>Network panel</em>. This
% panel is used to select one of the available architectures. <br><br>
% <b><em>Always start a new project with selection of the architecture</b></em>:<br>
% <ul>
% <li><b>2D U-net</b>, is a convolutional neural network that was
% developed for biomedical image segmentation at the Computer Science
% Department of the University of Freiburg, Germany. Segmentation of a 512
% x 512 image takes less than a second on a modern GPU (<a
% href="https://en.wikipedia.org/wiki/U-Net">Wikipedia</a>)<br>
% <b>References:</b><br>
% - Ronneberger, O., P. Fischer, and T. Brox. "U-Net: Convolutional
% Networks for Biomedical Image Segmentation." Medical Image Computing and
% Computer-Assisted Intervention (MICCAI). Vol. 9351, 2015, pp.
% 234-241 (<a href="https://arxiv.org/abs/1505.04597">link</a>)<br>
% - Create U-Net layers for semantic segmentation (<a
% href="https://se.mathworks.com/help/vision/ref/unetlayers.html">link</a>)<br>
% </li>
% <li><b>2D SegNet</b>, is a convolutional network that was
% developed for segmentation of normal images University of Cambridge, UK.
% It is less applicable for the microscopy dataset than U-net.<br>
% <b>References:</b><br>
% - Badrinarayanan, V., A. Kendall, and R. Cipolla. "Segnet: A Deep Convolutional 
% Encoder-Decoder Architecture for Image Segmentation." arXiv. Preprint arXiv: 
% 1511.0051, 2015 (<a href="https://arxiv.org/abs/1511.00561">link</a>)<br>
% - Create SegNet layers for semantic segmentation
% (<a href="https://se.mathworks.com/help/vision/ref/segnetlayers.html">link</a>)
% </li>
% <li><b>3D U-net</b>, a variation of U-net, suitable for for semantic
% segmentation of volumetric images.<br>
% <b>References:</b><br>
% - Cicek, &Ouml;., A. Abdulkadir, S. S. Lienkamp, T. Brox, and O. Ronneberger. 
% "3D U-Net: Learning Dense Volumetric Segmentation from Sparse Annotation." 
% Medical Image Computing and Computer-Assisted Intervention, MICCAI 2016. 
% MICCAI 2016. Lecture Notes in Computer Science. Vol. 9901, pp. 424-432. 
% Springer, Cham (<a href="https://arxiv.org/abs/1606.06650">link</a>)<br>
% - Create 3-D U-Net layers for semantic segmentation of volumetric images 
% (<a href="https://se.mathworks.com/help/vision/ref/unet3dlayers.html">link</a>)
% </li>
% <li><b>3D U-net anisotropic</b>, a hybrid U-net that is a combination of
% 2D and 3D U-nets. The top layer of the network has 2D convolutions and 2D
% max pooling operation, while the rest of the steps are done in 3D. As
% result, it is better suited for datasets with anisotropic voxels<br>
% <img src = "images\deeplearning_3d_Unet_Ani.png">
% </ul>
% The <b>Network filename</b> button allows to choose a file for saving the
% network or for loading the pretrained network from a disk.<br>
% This button is only available when either the <em>Train</em> or <em>Predict</em>
% tab is selected.
% <p>
% <ul>
% <li>When the <em>Train</em> tab is selected, press of the  this
% button defines a file for saving the network</li>
% <li>When the <em>Predict</em> tab 
% is selected, a user can choose a file with the
% pretrained network to be used for prediction. For ease of navigation the
% button is color-coded to match the active tab</li>
% </ul>
% <b>GPU dropdown</b><br>
% define execution environment for training and prediction
% <ul>
% <li><b>Name of a GPU to use</b>, the dropdown menu starts with the list of available GPUs to use. 
% Select the one that should be used for deep learning application</li>
% <li><b>Multi-GPU</b>,  use multiple GPUs on one machine, using a local parallel pool based on your default cluster profile. 
% If there is no current parallel pool, the software starts a parallel pool
% with pool size equal to the number of available GPUs. <em>This option is
% only shown when multiple GPUs are present on the system</em></li>
% <li><b>CPU only</b>, do calculation using only a single available CPU</li>
% <li><b>Parallel</b>, use a local or remote parallel pool based on your default cluster profile. 
% If there is no current parallel pool, the software starts one using the default cluster profile. 
% If the pool has access to GPUs, then only workers with a unique GPU perform training computation. 
% If the pool does not have GPUs, then training takes place on all available CPU workers instead</li>
% </ul>
% Press the "<b>?</b>" button to see GPU info dialog<br>
% <img src = "images\DeepLearningNetwork_GPUinfo.png">
% </html>
%
%% Directories and Preprocessing tab
% This tab allows choosing directories with images for training and
% prediction as well as various preprocessing parameters. During
% preprocessing the images and model files are processed and converted to a
% mibImg format that is used for training and prediction. However, in some
% situations, preprocessing step can be omitted. In this case, DeepMIB will
% used with original image files (see below for details).
% 
% 
% <<images\DeepLearning_FileTree.jpg>>
% 
% <html>
% Image files used in DeepMIB workflows can be arranged in 3 different ways:
% <ul>
% <li><b>Preprocessing mode</b>, this mode is enabled when
% <b>Preprocess for: <em>Training and prediction</em></b> option is
% selected. This mode is recommended for the general use. The scheme below
% demonstrates organization of directories compatible with this mode. For
% the legend see a figure below.<br><br>
% <img src = "images\DeepLearningDirectories_A.png">
% </li>
% <li>
% <b>Without preprocessing, when datasets are manually split into training
% and validation sets</b>, the modes without preprocessing may be
% beneficial in situations when the input patch size of the network is
% matching the image size in files. This option is suitable, when the files
% were manually split into the training and validation sets.
% <img src = "images\DeepLearningDirectories_B.png">
% </li>
% <li>
% <b>Without preprocessing, with automatic splitting of datasets into training and validation sets</b>, 
% the modes without preprocessing may be
% beneficial in situations when the input patch size of the network is
% matching the image size in files. In this mode, the files are randomly
% split into the train and validation sets. The split is done upon press of
% the <em>Preprocess</em> button, when <b>Preprocess for: <em>Split for training and validation</em></b>
% <img src = "images\DeepLearningDirectories_C.png">
% </li>
% </ul>
% <img src = "images\DeepLearningDirectories_Legend.png">
% <br>
% <br>
% <ul>
% <li><b>Directory with images and models for training</b> [<em>used
% only for training</em>]:<br>
% use these widgets to select directory that contain images and model to be
% used for training. For the organization of directories see the schemes above.<br>
% For 2D networks the files should contain individual 2D images, while for 3D networks
% individual 3D datasets.<br>
% The <em><b>extension</b></em> dropdown menu on the right-hand side can be used to specify extension 
% of the image files. The <b><em>Bio</b></em> checkbox toggles standard or
% Bio-format readers for reading the images. If the Bio-Format file is a collection of image, the <em>Index</em> edit box can be used
% to specify an index of the file within the container<br><br>
% <ul><b>Important notes:</b><br><br>
% <li>Number of model or mask files should match the number of image files
% (with one exception for 2D networks, where it is allowed to have a single
% model file in MIB *.model format, when <b>Single MIB model file:
% ticked</b>)</li> 
% <li>For models in standard image formats it is important to
% specify number of classes including the Exterior into the <b>Number of
% classes</b> edit box</li>
% <li><b><em>Important! It is not possible to use numbers as names of
% materials, please name materials in a sensible way!</b></em></li>
% </ul>
% <br>
% <b>Tip!</b> if you have only one segmented dataset you can split it into
% several datasets using <em>Menu->File->Chopped images->Export</em>
% operation.
% <br><br>
% <br>
% <li><b>Directory with images for prediction</b><br>
% use these widgets to specify directory with images for prediction (in the schemes above <em>2_Prediction</em>). The
% image files should be placed under <em>Images</em> subfolder. Optionally,
% when the ground truth models for prediction images is available, it can
% be placed under <em>Labels</em> subfolder.
% <br> 
% When the preprocessing mode is used the images from this folder are
% converted and saved to <em>3_Results\Prediction images</em> directory. 
% <br>For 2D networks the files should contain individual 2D images, while for 3D networks
% individual 3D datasets.
% <br><br>
% When the ground truth models are present, they are also processed and copied to 
% <em>3_Results\PredictionImages\GroundTruthLabels</em>. These models can
% be used for evaluation of results (see the <em>Predict</em> tab
% below for details).<br>
% The <em><b>extension</b></em> dropdown menu on the right-hand side can be used to specify extension 
% of the image files. The <em>Bio</em> checkbox toggles standard or
% Bio-format readers for reading the images.<br><br>
% </li>
% <li><b>Single MIB model file checkbox</b>, (<em>only for 2D
% networks</em>) tick it, when using a single model file with
% segmentations</li>
% <li><b>Model extension dropdown</b>, (<em>only for 2D
% networks</em>) is used to select extension of files containing models.
% For 3D network MIB model format is used.</li>
% <li><b>Number of classes edit box</b>, (<em>TIF or PNG formats only</em>)
% is used to define number of classes (including Exterior) in models. For
% model files in MIB *.model format, this field is not used.</li>
% <li><b>Use masking checkbox</b> is used when some parts of the training 
% data should be excluded from training. The masks may be provided in various formats
% and number of mask files should match the number of image files.
% <br>
% <b>Note!</b> masking may give drop in precision of training due to
% inconsistency within the image patches.</li>
% <li><b>Mask extension</b> is used to select extension for files that
% contain masks. For 3D network only MIB *.mask format is supported</li>
% <li><b>Directory with resulting images</b><br>
% use these widgets to specify the main output directory; results and all
% preprocessed images are stored there.
% <br> All subfolders inside this
% directory are automatically created by Deep MIB:<br><br>
% <b>Details of directories (see also the Legend figure above)<br></b>
% <ul>
% <li><em>PredictionImages</em>, place for the prepocessed images for
% prediction</li>
% <li><em>PredictionImages\GroundTruthLabels</em>, place for ground truth models
% for prediction images, when available</li>
% <li><em>PredictionImages\ResultsModels</em>, the main outout directory with generated models after prediction. 
% The 2D models can be combined in MIB by selecting the files using the Shift+left mouse click during loading</li>
% <li><em>PredictionImages\ResultsScores</em>, folder for generated prediction scores (probability) for each material. 
% The score values are scaled between 0 and 255</li>
% <li><em>ScoreNetwork</em>, for accuracy and loss score plots, when the <em>Export training plots</em> option 
% of the <em>Train</em> tab is ticked and for storing checkpoints of the network after each epoch, 
% when the <em>Save progress after each epoch</em> checkbox is ticked</li>
% <li><em>TrainImages</em>, images to be used for training (<em>only for preprocessing mode</em>)</li>
% <li><em>TrainLabels</em>, models accompanying images to be used for training (<em>only for preprocessing mode</em>)</li>
% <li><em>ValidationImages</em>, images to be used for validation during training (<em>only for preprocessing mode</em>)</li>
% <li><em>ValidationLabels</em>, models accompanying images for validation (<em>only for preprocessing mode</em>)</li>
% <br>
% </ul>
% </li>
% <li><b>Compress processed images checkbox</b>, tick to compress the processed images. 
% The processed images are stored in <em>*.mibImg</em> format that can be loaded in MIB. 
% <em>*.mibImg</em> is a variation of standard MATLAB format and can also be directly loaded into MATLAB 
% using similar to this command: <em>res = load('img01.mibImg, '-mat');</em>.
% <br>
% Compression of images slows down performance!</li>
% <li><b>Compress processed models</b>, tick to compress models during preprocessing. 
% The processed models are stored in <em>*.mibCat</em> format that can be loaded in MIB (<em>Menu->Models->Load model</em>). 
% It is a variation of a standard MATLAB format, where the model is encoded using categorical class of MATLAB.
% <br> 
% Compression of models slows down performance but brings significant benefit of small file sizes</li>
% <li><b>Use parallel processing</b>, when ticked DeepMIB is using multiple
% cores to process images. Number of cores can be specified using the
% <b>Workers</b> edit box. The parallel processing during preprocessing
% operation brings significant decrease in time required for
% preprocessing.</li>
% <li><b>Fraction of images for validation</b>, define fraction of images
% that will be randomly (<b>Random generator seed</b>) assigned into
% the validation set. When set to 0, the validation option will not be used during the training</li>
% <li><b>Random generator seed</b>, number to initialize random seed
% generator, which defines how the images for training and validation are
% split. For reproducibility of tests keep value fixed</li>
% <li><b>Preprocess for</b>, select mode of operation upon press of the <b>Preprocess</b> button. 
% Results of the preprocessing operation for each mode are presented in schemes above</li>
% </ul>
% <br>
% </html>
%
%% Train tab
% This tab contains settings for generating deep convolutional network and training.
% Before processing further please finish the preprocessing part, see above.
% 
% <<images\DeepLearningTrain.png>>
%
%
% <html>
% Before starting the training process it is important to check and if needed modify
% the settings. Also, use the <em>Network filename</em> button
% in the <em>Network</em> panel to select filename for the resulting network.
% <ul>
% <li><b>Input patch size</b>, this is important field that has to be defined 
% based on available memory of GPU, dimensions of the training dataset and 
% number of color channels.<br>
% The patch size defines dimensions of a single image block that will be
% directed into the network for training. The dimensions are always
% defined with 4 numbers representing height, width, depth, colors of the
% image patch (for example, type "572 572 1 2" to specify a 2D patch of
% 572x572 pixels, 1 z-slice and 2 color channels).<br>
% The patches are taken randomly from the volume/image and number of those
% patches can be specified in the <b>Patches per image</b> field.
% </li>
% <li><b>Padding</b> defines type of the convolution padding, depending on
% the selected padding the <em>Input patch size</em> may have to be adjusted.
% <ul>
% <li><b><em>same</em></b> - zero padding is applied to the inputs to convolution 
% layers such that the output and input feature maps are the same size</li>
% <li><b><em>valid</em></b> - zero padding is not applied to the inputs to 
% convolution layers. The convolution layer returns only values of the convolution 
% that are computed without zero padding. The output feature map is smaller 
% than the input feature map.</li>
% </ul>
% </li>
% <li><b>Number of classes</b> - number of materials of the model including Exterior, specified as a positive number</li>
% <li><b>Encoder depth</b> - number of encoding and decoding layers of the
% network. U-Net is composed of an encoder subnetwork and a corresponding decoder subnetwork. 
% The depth of these networks determines the number of times the input image is 
% downsampled or upsampled during processing. The encoder network downsamples 
% the input image by a factor of 2^D, where D is the value of EncoderDepth. 
% The decoder network upsamples the encoder network output by a factor of 2^D.</li>
% <li><b>Patches per image</b> - specifies number of patches that will be taken 
% from each an image or a 3D dataset. According to our experience, the best strategy is to take
% 1 patch per image and train network for larger number of epochs. When taking a single patch per image
% it is important to set <em>Training settings (Training button)->Shuffling->every-epoch</em>). 
% However, fill free to use any sensible number</li>
% <li><b>Mini Batch Size</b> - number of patches processed at the same time by the network. 
% More patches speed up the process, but it is important to understand that the 
% resulting loss is averaged for the whole mini-batch. Number of mini batches depends on amount of GPU memory</li>
% <li><b>Filters</b> - number of output channels for the
% first encoder stage, <em>i.e.</em> number of convolitional filters used to process the input image patch during the first stage.
% In each subsequent encoder stage, the number of output channels doubles. 
% The unetLayers function sets the number of output channels in each decoder 
% stage to match the number in the corresponding encoder stage</li>
% <li><b>Filter size</b> - convolutional layer filter size; typical values are in the range [3, 7]</li>
% <li><b>Activation layer</b> - specifies type of the activation layers of
% the network. When the layer may have additional options, a settings
% button on the right-hand side becomes available.
% <ul>
% <li><em>reluLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.relulayer.html">
% Rectified Linear Unit (ReLU) layer</a>, it is a default activation layer of the networks, 
% however it can be replaced with any of other layer below</li>
% <li><em>leakyReluLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.leakyrelulayer.html">
% Leaky Rectified Linear Unit layer</a> performs a threshold operation, 
% where any input value less than zero is multiplied by a fixed scalar</li>
% <li><em>clippedReluLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.clippedrelulayer.html">
% Clipped Rectified Linear Unit (ReLU) layer</a> performs a threshold 
% operation, where any input value less than zero is set to zero and any value above the 
% clipping ceiling is set to that clipping ceiling</li>
% <li><em>eluLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.elulayer.html">
% Exponential linear unit (ELU) layer</a> performs the identity operation on positive inputs and an 
% exponential nonlinearity on negative inputs</li>
% <li><em>tanhLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.tanhlayer.html">
% Hyperbolic tangent (tanh) layer</a> applies the tanh function on the layer inputs</li>
% </ul>
% </li>
% <li><b>Segmentation layer</b> - specifies the output layer of the
% network; depending on selection a settings button on the right-hand side
% becomes available to bring access to additional parameters.
% <ul>
% <li><em>pixelClassificationLayer</em> - semantic segmentation with the 
% <a href="https://se.mathworks.com/help/vision/ref/nnet.cnn.layer.pixelclassificationlayer.html">crossentropyex loss function</a></li>
% <li><em>focalLossLayer</em> - semantic segmentation using 
% <a href="https://se.mathworks.com/help/vision/ref/nnet.cnn.layer.focallosslayer.html">focal loss</a>
% to deal with imbalance between foreground and background classes. 
% To compensate for class imbalance, the focal loss function multiplies the cross entropy 
% function with a modulating factor that increases the sensitivity of the network to misclassified observations
% </li>
% <li><em>dicePixelClassificationLayer</em> - semantic segmentation using 
% <a href="https://se.mathworks.com/help/vision/ref/nnet.cnn.layer.dicepixelclassificationlayer.html">
% generalized Dice loss</a> to alleviate the problem of class imbalance in semantic segmentation problems. 
% Generalized Dice loss controls the contribution that each class makes to the loss 
% by weighting classes by the inverse size of the expected region</li>
% <li><em>dicePixelCustomClassificationLayer</em> - a modification of the dice loss, 
% with better control for rare classes</li>
% </ul>
% </li>
% <li><b>Input layer settings button</b> - can be used to specify data
% normalization during training, see the info header of the dialog or press the Help button of the dialog for details</li>
% <li><b>Training settings button</b> - define multiple parameters used for training, for details please refer to 
% <a
% href="https://se.mathworks.com/help/deeplearning/ref/trainingoptions.html">trainingOptions</a>
% function<br><br>
% <b>Tip, <em>setting the Plots switch to "none" in the training settings may
% speed up the training time by up to 25%</em></b><br>
% </li>
% <li><b>Check network button</b> - press to preview and check the network.
% The standalone version of MIB shows only limited information about the
% network and does not check it:<br><br>
% <img src = "images\DeepLearning_OrganizationDiagram.jpg">
% </li>
% <li><b>Augmentation</b> - augment data during training. For small training sets 
% augmentation provides an easy way to extend amount of training data using
% various filters. Depending on the selected 2D or 3D network architecture
% a different sets of augmentation filters is available. These operations are configurable
% using the 2D and 3D settings buttons right under the
% <em>augmentation</em> checkbox. <br>
% There are 17 augmentation
% operations for 2D network and 5 augmentation operations for 3D networks.
% It is also possible to specify fraction of images that have to be
% augmented. <br>
% 2D augmentations specified with 2 or 3 values, where the last
% value defines probability of each particular augmentation to be
% triggered. When the augmentation is defined with 2 values, the first value specifies whether it is on (==1) or off (==0), 
% alternatively, the first two values define the variation range, a random
% number will be picked between these numbers and used as the parameter for
% the filter. Each specific augmentation may be turned off either by setting its probability (the last value) to 0 
% or by setting its variation range to be as shown in the "off=[x,x,x]" text<br>
% The 2D augmentation settings can be reset to default by
% pressing <em>Options tab->Reset 2D augmentation button</em><br>
% or disabled by pressing <em>Options tab->Disable 2D augmentation
% button</em><br>
% <img src="images\DeepLearning_2DAug_settings.jpg">
% </li>
% <li><b>Preview button</b> is used to preview input image patches that are
% generated using augmentor. It is useful for evaluation of augmenter
% operations and understanding performance. Number of patches to show and
% tweaking of various additional settings are possible by pressing the
% Settigns button on the right-hand side of the <b>Preview</b> button.<br>
% <img src="images\DeepLearning_input_patches_gallery.jpg">
% <img src="images\DeepLearning_input_patches_gallery_settings.png">
% </li>
% <li><b>Save progress after each epoch</b> when ticked Deep MIB  
% stores training checkpoints after each epoch to
% <em>3_Results\ScoreNetwork</em> directory. It will be possible to choose any of
% those networks and continue training from that checkpoint. If the checkpoint networks
% are present, a choosing dialog is displayed upon press of the Train
% button
% </li>
% <li><b>Export training plots</b> when ticked accuracy and loss scores are
% saved to <em>3_Results\ScoreNetwork</em> directory. Deep MIB uses the
% network filename as a template and generates a file in MATLAB format
% (*.score) and several files in CSV format
% </li>
% <li><b>Random seed</b> set a seed for random number generator used during initialization of training. 
% Use <b>0</b> for random initialization each time or any other number for reproducibility
% </li>
% </ul> 
% <br>
% To start training press the <b>Train</b> button highlighted under the
% panel. If a network already existing under the provided <em>Network
% filename</em> it is possible to continue training from that point 
% (a dialog with possible options appears upon restart of training).
% <br><br>
% Upon training a plot with accuracy and loss is shown; it is
% possible to stop training at any moment by pressing the <b>Stop</b> or
% <b>Emergency brake</b> buttons. When the emergency brake button
% is pressed DeepMIB will stop the training as fast as possible, which may lead to
% not finalized network in situations when the batch normalization layer is
% used.
% <br><br>
% Please note that by default DeepMIB is using a custom progress plot. If you want to use 
% the progress plot provided with MATLAB (available only in MATLAB version
% of MIB), navigate to <em>Options tab->Custom training plot->Custom
% training progress window: uncheck</em><br>
% The plot can be completely disabled to improve performance: 
% <em>Train tab->Training->Plots, plots to display during network
% training->none</em>
% <br><br>
% The right bottom corner of the window displays used input image and model
% patches. Display of those decrease training performace, but the frequency
% of the patch updates can be modified in <em>Options tab->Custom training
% plot->Preview image patches and Fraction of images for preview</em>. When
% fraction of image for preview is 1, all patches are shown. If the value
% is 0.01 only 1% of patches is displayed.<br>
% <img src="images\DeepLearning_TrainingProcess.jpg"><br>
% After the training, the network is saved to a file specified in the
% <em>Network filename</em> editbox of the <em>Network</em> panel.
% </html>
%
%% Predict tab
%
% <html>
% The trained networks can be loaded to Deep MIB and used for prediction of
% new datasets. <br>
% <img src="images\DeepLearningPredict.png"><br><br>
% <b>To start with prediction:</b>
% <ul>
% <li>select a file with the desired network in
% the <em>Network filename</em> editbox of the <em>Network</em> panel. Upon
% loading, the corresponding fields of the <em>Train</em> panel will be
% updated with the settings used for training of the loaded network</li>
% <li> specify correct directory with the images for prediction: 
% <em>Directories and Preprocessing tab -> Directory with images for
% prediction</em></li>
% <li>specify directory for the results: <em>Directories and Preprocessing tab -> 
% Directory with resulting images</em></li>
% <li>press the <em>Preprocess</em> button to perform data
% preprocessing</li>
% <li>finally switch back to the <em>Predict</em> tab and press the
% <b>Predict</b> button</li>
% </ul>
% <b>Additional options:</b><br><br>
% <ul>
% <li><b>Overlapping tiles</b>, available for the <em>same</em>
% convolutional padding, during prediction crops the edges of the predicted
% patches, which improves the segmentation, but takes more time. See comparison of results on the image below:<br>
% <img src="images\DeepLearning_OverlappingTiles.jpg">
% </li>
% <li><b>Explore activations</b><br>
% <img src="images\DeepLearningPredictActivationsExplorer.png"><br>
% Activations explorer brings the possibility for detailed evaliation of
% the network. The images processed images should be located in
% <em>3_Results\PredictionImages</em> directory.<br>
% Here is the description of the options:<br>
% <ul>
% <li><b>Image</b> has a list of all preprocessed images for prediction.
% Selection of an image in this list will load a patch, which is equal to
% the input size of the selected network<br>
% The arrows on the right side of the dropdown can be used to load previous or next image in this list
% </li>
% <li><b>Layer</b> contains a list of all layers of the selected network.
% Selection of a layer, starts prediction and acquiry of activation images</li>
% <li><b>Z1, X1, Y1</b>, this spinners make possible to shift the patch
% across the image. Shifting of the patch does not automatically update the
% activation image. To update the activation image press the <b>Update</b>
% button</li>
% <li><b>Patch Z</b>, change the z value within the loaded activation
% patch, it is used only for 3D networks</li>
% <li><b>Filter Id</b>, change of this spinner brings various activation
% layers into the view</li>
% <li><b>Update</b> press to calculate the activation images for the
% currently displayed patch</li>
% <li><b>Collage</b> press to make a collage image of the current network
% layer activations:<br>
% <img src="images\DeepLearningPredictActivationImages.png">
% </li>
% </ul>
% <li><b>Load images and models</b> press this button after the prediction 
% to open original images and result of the segmentation in the currently
% active buffer of MIB
% </li>
% <li><b>Load prediction scores</b> press to load the resulting score images (predictions)
% into the currently active buffer of MIB</li>
% <li><b>Evaluate segmentation</b> when the datasets for prediction are accompanied with 
% ground truth models (<b> requires a model file in the directory with Prediction images, 
% it is important that the model materials names match those for the training data!</b>).
% <ul>
% <li>Press the button to calculate various precision metrics<br> 
% <img src='images\DeepLearning_Evaluation.jpg'></li>
% <li>As result of the evaluation a table with the confusion matrix will be
% shown. The confusion matrix displays how well the predicted classes are
% matching classes defined in the ground truth models. The values are
% scaled from 0 (bad) to 100 (excelent):<br>
% <img src='images\DeepLearning_Evaluation2.jpg'></li>
% <li>In addition, it is possible to calculate occurrence of labels and Sørensen-Dice similarity coefficient in the
% generated and ground truth models. These options are available from a
% dropdown located in the right-bottom corner of the <em>Evaluation
% results</em> window:<br>
% <img src='images\DeepLearning_Evaluation3.jpg'></li>
% <li>The evaluation results can be exported to MATLAB or
% saved in MATLAB, Excel or CSV 
% formats to <em>3_Results\PredictionImages\ResultsModels</em> directory, see more in the 
% <em>Directories and Preprocessing</em> section above. 
% <br>For details of the
% metrics refer to MATLAB documentation for <a
% href="https://se.mathworks.com/help/vision/ref/evaluatesemanticsegmentation.html">evaluatesemanticsegmentation
% function</a></li>
% </ul>
% </li>
% </ul>
% <b>GPU Info (?)</b>, press to display information about the selected GPU
% device<br>
% </html>
%
%% Options tab
%
% <html>
% Some additional options and settings are available in this tab <br>
% <img src="images\DeepLearningOptions.png"><br><br>
% <h3>Config files panel</h3>
% <br>
% This panel brings access to loading or saving Deep MIB config files.<br>
% The config files contain all settings of Deep MIB including the network
% name and input and output directories but excluding the actual trained network. 
% Normally, these files are automatically 
% created during the training process and stored next to the network <em>*.mibDeep</em> 
% files also in MATLAB format using the <em>*.mibCfg</em> extension.<br>
% Alternatively, the files can be saved manually by pressing the
% <em>Save</em> button.
% <br><br>
% <h3>Custom training plot</h3>
% Settings for the custom training progress plot showing accuracy and loss
% during training. 
% <ul>
% <li><b>Custom training progress plot</b>, when checked the custom
% training plot is used, when unchecked a standard MATLAB training plot is
% displayed (<em>the standard MATLAB plot is only available for MATLAB version
% of MIB<em>)
% </li>
% <li><b>Refresh rate</b>, update the plot after the specified number of
% interations. Adjust the value to improve performace, when with larger
% values the plot will be updated more rare, improving performance of
% training.
% </li>
% <li><b>Number of points</b>, number of points that is used to show the plot. 
% Decrease the value to improve drawing performance, increase the value to
% see more points
% </li>
% <li><b>Preview image patches</b>, when checked the custom training plot
% will show input image and model patches for evaluation. Plotting of
% patches decrease performance, it is possible to use <b>Fraction of images
% for preview</b> to specify fraction of patches that have to be shown.
% </li>
% <li><b>Fraction of images for preview</b>, specify fraction of input
% patches that are shown in the custom training plot. Use 1 to see all input patches and 
% small values to see only a fraction of those. For example, the value 0.01 
% specifies that only 1% of image patches are displayed in the progress
% plot window
% </li>
% </ul>
% <h3>Other buttons</h3>
% <ul>
% <li><b>Reset 2D augnentation</b>, press to reset 2D augmentation settings to default values
% </li>
% <li><b>Export network to ONNX</b>, (<em>only MATLAB version of MIB, requires installation 
% of ONNX Model Format support package</em>) converts the network file to
% ONNX format. Please note that some of networks can't be converted yet.
% </li>
% </ul>
% </html>
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
