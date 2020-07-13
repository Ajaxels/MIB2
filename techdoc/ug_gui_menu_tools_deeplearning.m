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
% panel is used to select one of the available architectures. <br>
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
% tab is selected. When the <em>Train</em> tab is selected, press of the  this
% button defines a file for saving the network. When the <em>Predict</em> tab 
% is selected, a user can choose a file with the
% pretrained network to be used for prediction. For ease of navigation the button is color-coded to match the active tab.
% </html>
%
%% Directories and Preprocessing tab
% This tab allows choosing directories with images and specifying certain preprocessing parameters.
% 
% 
% <<images\DeepLearning_FileTree.jpg>>
% 
% <html>
% <ul>
% <li><b>Directory with images and models for training</b> [<em>required
% only for training</em>]:<br>
% use these widgets to select directory that contain images and model to be
% used for training. In the scheme of a typical project above, this
% directory is <em>1_Training</em>. Collection of images in this folder will 
% be processed and split into the training (placed into <em>3_Results\TrainImages</em>
% and <em>3_Results\TrainLabels</em> directories) and validation datasets 
% (placed into <em>3_Results\ValidationImages</em>
% and <em>3_Results\ValidationLabels</em> directories) as shown on a figure above.<br>
% The <em>file extension</em> dialog on the right-hand side can be used to specify extension 
% of the image files. The <em>Bio</em> checkbox toggles standard or
% Bio-format readers for reading the images<br><br>
% <ul><b>These are requirements for files:</b><br><br>
% <li><b>For 2D networks</b>, each file should contain a single 2D image. The
% ground truth models should also be provided in the same directory, but in
% a <em>single *.model</em> file:<br>
% <img src = "images\DeepLearning_TrainingFiles2D.png"></li>
% <li><b>For 3D networks</b>, each file should contain a stack of images,
% the image files should be accompanied with the <em>*.model</em>
% files.<br>
% <em>Number of model files should match the number of image
% files:</em><br>
% <img src = "images\DeepLearning_TrainingFiles3D.png"><br>
% <b>Tip!</b> if you have only one segmented dataset you can split it into
% several datasets using <em>Menu->File->Chopped images->Export</em>
% operation.
% </li>
% </li>
% </ul>
% <br>
% <b><em>Important! It is not possible to use numbers as names of
% materials, please name materials in a sensible way!</b></em><br><br>
% <li><b>Directory with images for prediction</b><br>
% use these widgets to specify directory with images for prediction (in the scheme above <em>2_Prediction</em>). The
% images placed here will be preprocessed and saved to
% <em>3_Results\Prediction images</em> directory. <br>For 2D networks the
% files should contain individual 2D images, while for 3D networks
% individual 3D datasets. <br><br>
% If the ground truth data for the prediction datasets is known, it can
% also be placed as <em>*.model</em> file(s) into the same directory
% (<em>2_Prediction</em>) using the same rules as for the training models.
% If the models are present, they are also processed and copied to 
% <em>3_Results\PredictionImages\GroundTruthLabels</em>. These models can
% be used for evaluation of results (see the <em>Predict</em> tab
% below for details).<br>
% The <em>file extension</em> dialog on the right-hand side can be used to specify extension 
% of the image files. The <em>Bio</em> checkbox toggles standard or
% Bio-format readers for reading the images.<br><br>
% </li>
% <li><b>Directory with resulting images</b><br>
% use these widgets to specify the main work directory; results and all
% preprocessed images are stored there.
% <br> All subfolders inside this
% directory are automatically created by Deep MIB:<br><br>
% <b>Details of directories<br></b>
% <ul>
% <li><em>PredictionImages</em>, place for the prepocessed images for
% prediction</li>
% <li><em>PredictionImages\GroundTruthLabels</em>, place for ground truth models
% for prediction images, when available</li>
% <li><em>PredictionImages\ResultsModels</em>, place for generated models after prediction. 
% The 2D models can be combined in MIB by selecting the files using the Shift+left mouse click during loading</li>
% <li><em>PredictionImages\ResultsScores</em>, place for generated prediction scores (probability) for each material. The score is scaled between 0 and 255</li>
% <li><em>ScoreNetwork</em>, for accuracy and loss score plots, when the <em>Export training plots</em> option of the <em>Train</em> tab is ticked</li>
% <li><em>TrainImages</em>, images to be used for training</li>
% <li><em>TrainLabels</em>, models accompanying images to be used for training</li>
% <li><em>ValidationImages</em>, images to be used for validation during training</li>
% <li><em>ValidationLabels</em>, models accompanying images for validation</li>
% <br>
% </ul>
% </li>
% <li><b>Compress processed images</b>, tick to compress the processed images. 
% The processed images are stored as standard Matlab matrices in <em>*.mat</em> format. 
% Compression of images slows down performance!</li>
% <li><b>Compress processed models</b>, tick to compress the processed models. 
% The processed models are stored as standard Matlab matrices in <em>*.mat</em> format. 
% Compression of models slows down performance but brings significant benefits of small file sizes</li>
% <li><b>Fraction of images for validation</b>, define fraction of images
% that will randomly (<em>Random generator seed</em>) assigned into
% the validation set. When set to 0, the validation option will not be used during the training</li>
% <li><b>Random generator seed</b>, number to initialize random seed
% generator, which defines how the images for training and validation are
% split</li>
% <li><b>Preprocess for</b>, select type of data for preprocessing</li>
% </ul>
% When all directories are defined press the <b>Preprocess</b> button to
% start.
% </html>
%
%% Train tab
% This tab contains settings for assembling the network and training.
% Before processing further please finish the preprocessing part, see above.
% 
% <<images\DeepLearningTrain.png>>
%
%
% <html>
% Before starting the training process it is important to check and if needed modify
% the settings. Also, use the <em>Network filename</em> button
% in the <em>Network</em> panel to select filename for the network.
% <ul>
% <li><b>Input patch size</b>, this is important field that has to be defined 
% based on available memory of GPU, dimensions of the training dataset and 
% number of color channels. <br>
% The patch size defines dimensions of a single image block that will be
% targeted into the network for training. The dimensions are always
% defined with 4 numbers representing height, width, depth, colors of the
% image patch (for example, type "572 572 1 2" to specify a 2D patch of
% 572x572 pixels with 2 color channels).<br>
% The patches are taken randomly from the volume and number of those
% patches can be specified in the <em>Patches per image</em> field.
% </li>
% <li><b>Padding</b> defines type of the convolution padding, depending on
% the selected padding the <em>Input patch size</em> may have to be adjusted.
% <ul>
% <li><em>same</em> - zero padding is applied to the inputs to convolution 
% layers such that the output and input feature maps are the same size</li>
% <li><em>valid</em> - zero padding is not applied to the inputs to 
% convolution layers. The convolution layer returns only values of the convolution 
% that are computed without zero padding. The output feature map is smaller 
% than the input feature map.</li></ul>
% </li>
% <li><b>Number of classes</b> - number of materials of the model including Exterior, specified as a positive number</li>
% <li><b>Encoder depth</b> - number of encoding and decoding layers in the
% network. U-Net is composed of an encoder subnetwork and a corresponding decoder subnetwork. 
% The depth of these networks determines the number of times the input image is 
% downsampled or upsampled during processing. The encoder network downsamples 
% the input image by a factor of 2^D, where D is the value of EncoderDepth. 
% The decoder network upsamples the encoder network output by a factor of 2^D.</li>
% <li><b>Patches per image</b> - specifies number of patches that will be taken 
% from each image or 3D dataset. Number of patches per image can be estimated 
% from a ratio between dimensions of each image and the input patch multiplied by number of augmentation filters uses</li>
% <li><b>Mini Batch Size</b> - number of patches processed at the same time by the network. 
% More patches speed up the process, but it is important to understand that the 
% resulting loss is averaged for the whole mini-batch. Number of mini batches depends on amount of GPU memory</li>
% <li><b>NumFirstEncoderFilters</b> - number of output channels for the
% first encoder stage. In each subsequent encoder stage, the number of output channels doubles. 
% The unetLayers function sets the number of output channels in each decoder 
% stage to match the number in the corresponding encoder stage</li>
% <li><b>Filter size</b> - convolutional layer filter size; typical values are in the range [3, 7]</li>
% <li><b>Segmentation layer</b> - specifies the output layer of the network:
% <ul>
% <li><em>pixelClassificationLayer</em> - semantic segmentation with the crossentropyex loss function</li>
% <li><em>dicePixelClassificationLayer</em> - semantic segmentation using generalized 
% Dice loss to alleviate the problem of class imbalance in semantic segmentation problems. 
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
% various methods. Depending on the selected 2D or 3D network various
% augmentation operations available. These operations are configurable
% using the 2D and 3D settings buttons right under the
% <em>augmentation</em>
% checkbox
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
% network filename as a template and generates a file in Matlab format
% (*.score) and several files in CSV format
% </li>
% </ul> 
% To start training press the <b>Train</b> button highlighted under the
% panel. If a network already existing under the provided <em>Network
% filename</em> it is possible to continue training from that point.
% Upon training a plot with accuracy and loss is shown; it is
% possible to stop training at any moment by pressing the stop button at
% the right upper side of the window (the training windows are different 
% in the compiled and Matlab versions of MIB)<br>
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
% ground truth models, press of this button allows to calculate various
% precision metrics. The evaluation results can be exported to Matlab or saved in Matlab or Excel
% formats to <em>3_Results\PredictionImages\GroundTruthLabels</em> directory, see more in the 
% <em>Directories and Preprocessing</em> section above. 
% <br>For details of the
% metrics refer to Matlab documentation for <a
% href="https://se.mathworks.com/help/vision/ref/evaluatesemanticsegmentation.html">evaluatesemanticsegmentation
% function</a><br>
% <img src='images\DeepLearning_Evaluation.jpg'>
% </li>
% </ul>
% </html>
%
%% Options tab
%
% <html>
% Some additional options and settings are available in this tab <br>
% <img src="images\DeepLearningOptions.png"><br><br>
% <h3>Config files panel</h3><br>
% This panel brings access to loading or saving Deep MIB config files.<br>
% The config files contain all settings of Deep MIB including the network
% name and input and output directories but excluding the actual trained network. 
% Normally, these files are automatically 
% created during the training process and stored next to the network <em>*.mibDeep</em> 
% files also in Matlab format using the <em>*.mibCfg</em> extension.<br>
% Alternatively, the files can be saved manually by pressing the
% <em>Save</em> button.
% </html>
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
