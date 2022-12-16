%% DeepMIB - Network panel
% The upper part of Deep MIB is occupied with the _Network panel_. This
% panel is used to select workflow and convolutional network architecture to be used during training
%
% <<images\DeepLearningNetwork.png>>
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools
% Menu*> |*-->*| <ug_gui_menu_tools_deeplearning.html *Deep learning segmentation*>
% 
%
%% Workflows
%
% <html>
% <b><em>Start a new project with selection of the workflow</b></em>:<br>
% <ul>
% <li><b>2D Semantic</b> segmentation, where 2D image pixels that belong
% to the same material are clustered together. 
% <li><b>3D Semantic</b> segmentation, where 3D image voxels that belong
% to the same material are clustered together. 
% <li><b>2D Patch-wise</b> segmentation, where 2D image is predicted in
% blocks (patches) resulting a heavy downsampled image indicating positions
% of objects of interest
% </ul>
% </html>
%
%% 2D Semantic workflow
%
% [dtls][smry] *Application of DeepMIB for 2D semantic segmentation of mitochondria on TEM images* [/smry]
%
% <<images\DeepLearning_2D_semantic.jpg>>
% 
%
% [/dtls]
%
% [dtls][smry] *List of available network architectures for 2D semantic segmentation* [/smry]
%
% <html>
% The following architectures are available for 2D semantic segmentation
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
% <li><b>2D DeepLabV3 Resnet18/Resnet50/Xception/Inception-ResNet-v2</b>, (<b><em>recommended</b></em>) an efficient DeepLab v3+ convolutional neural network for 
% semantic image segmentation initialized with selectable base network. Suitable for large variety
% of segmentation tasks. The input images can be grayscale or RGB colors. 
% <ul>Base networks:
% <li><b>Resnet18</b> initialize DeepLabV3 using ResNet-18, a convolutional neural network that is 18 layers deep with original image input size of 224 x 224 pixels.
% This is the lightest available version that is quickest and has lowest
% GPU requirements. The network is intialized using a pretrained for EM or pathology
% template that is automatically downloaded the first time the network is used.
% <br>
% <b>ResNet-18 reference:</b> <br>He, Kaiming, Xiangyu Zhang, Shaoqing Ren, and Jian Sun. "Deep residual learning for image recognition." <a href="https://ieeexplore.ieee.org/document/7780459">In Proceedings of the IEEE conference on computer vision and pattern recognition</a>, pp. 770-778. 2016
% <li><b>Resnet50</b> initialize DeepLabV3 using ResNet-50, a convolutional neural network that is 50 layers deep with original image input size of 224 x 224 pixels. 
% The most balanced option for moderate GPU with good performance/requirements ratio. The network is intialized using a pretrained for EM or pathology
% template that is automatically downloaded the first time the network is used.
% <br> 
% <b>ResNet-50 reference:</b> <br>He, Kaiming, Xiangyu Zhang, Shaoqing Ren, and Jian Sun. "Deep residual learning for image recognition." In <a href="https://ieeexplore.ieee.org/document/7780459">Proceedings of the IEEE conference on computer vision and pattern recognition</a>, pp. 770-778. 2016
% </li>
% <li><b>Xception</b> [<em><b>MATLAB version of MIB only</b></em>]
% initialize DeepLabV3 using Xception, a convolutional neural network that
% is 71 layers deep with original image input size of 299 x 299 pixels.
% <br> 
% <b>Xception reference:</b> <br>Chollet, Francois, 2017. "Xception: Deep Learning with Depthwise Separable Convolutions." <a href="https://arxiv.org/abs/1610.02357">arXiv preprint, pp.1610-02357</a>.
% </li>
% <li><b>Inception-ResNet-v2</b> [<em><b>MATLAB version of MIB only</b></em>] initialize DeepLabV3 using Inception-ResNet-v2, a convolutional neural network that 
% is 164 layers deep with original image input size of 299 x 299 pixels.
% This network has high GPU requirements, but expected to provide the best results. <br> 
% <b>Inception-ResNet-v2 reference:</b> <br>Szegedy Christian, Sergey Ioffe, Vincent Vanhoucke, and Alexander A. Alemi. "Inception-v4, Inception-ResNet and the Impact of Residual Connections on Learning." In <a href="https://dl.acm.org/doi/10.5555/3298023.3298188">AAAI</a>, vol. 4, p. 12. 2017.
% </li>
% </ul>
% <br>
% <b>Reference:</b><br>
% -  Chen, L., Y. Zhu, G. Papandreou, F. Schroff, and H. Adam. "Encoder-Decoder 
% with Atrous Separable Convolution for Semantic Image Segmentation." 
% Computer Vision - ECCV 2018, 833-851. Munic, Germany: ECCV, 2018. (<a href="https://arxiv.org/abs/1802.02611">link</a>)<br>
% </li>
% </ul>
% </html>
%
% [/dtls]
% [br8]
%
%% 3D Semantic workflow
%
% 3D Semantic workflow is suitable for anisotropic and slightly anisotropic
% 3D datasets, where information from multiple sections is utilized to
% train a network for better prediction of 3D structures.
%
% [dtls][smry] *List of available network architectures for 3D semantic segmentation* [/smry]
%
% <html>
% The following architectures are available for 3D semantic segmentation:
% <ul>
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
% result, it is better suited for datasets with anisotropic voxels
% </ul>
% </html>
%
% [dtls][smry] *Architecture of 3D U-net anisotropic* [/smry]
% 
% <<images\deeplearning_3d_Unet_Ani.png>>
%
% [/dtls]
%
% [/dtls]
%
% [br8]
%
%% 2D Patch-wise workflow
% 
% In the patch-wise workflow the training is done on patches of images,
% where each image contains an example of a specific class. [br]
% During prediction, the images are processed in blocks (with or without an
% overlap) and each block is assigned to one or another class.[br16]
% This workflow may be useful to quickly find areas where the object of
% interest is located or to target semantic segmentation to some specific
% aras.
%
% [dtls][smry] *Detection of nuclei using the 2D patch-wise workflow* [/smry]
%
% Examples of patches for detection of nuclei using the 2D patch-wise
% workflow:
%
% <<images\DeepLearning_2D_patchwise_patches2.png>> 
%
% Snapshot showing result of 2D patch-wise segmentation of nuclei.[br]
%
% * Green color patches indicate predicted locations of nuclei
% * Red color patches indicate predicted locations of background
% * Uncolored areas indicate patches that were skipped due to dynamic masking
% 
% <<images\DeepLearningPredictDynMaskingResults.png>>
%
% [/dtls]
%
% [dtls][smry] *Detection of spots using the 2D patch-wise workflow* [/smry]
%
% The images below show examples of patches of two classes: "spots" and
% "background" using for training.
%
% <<images\DeepLearning_2D_patchwise_patches.png>>
%
% Synthetic example showing detection of spots using the patch-wise
% workflow.
%
% <<images\DeepLearning_2D_patchwise.png>> 
%
% [/dtls]
%
%
% [dtls][smry] *List of available networks for the 2D patch-wise workflow* [/smry]
%
% [dtls][smry] *Comparison of different network architectures* [/smry]
% Indicative plot of the relative speeds of the different networks (credit:
% Mathworks Inc.):
% 
% <<https://se.mathworks.com/help/deeplearning/ug/pretrained_20b.png>>
% 
% [/dtls]
%
% [class.h3]Resnet18[/class]
% a convolutional neural network that is 18 layers deep. It is fairly light
% network, which is however capable to give very nice results. The default image size is 224x224 pixels but it can be adjusted to any value.[br]
% This network in MIB for MATLAB can be initialized using a pretrained
% version of the network trained on more than a million images from the ImageNet database.
%
% *References* 
%
% * ImageNet. http://www.image-net.org
% * He, Kaiming, Xiangyu Zhang, Shaoqing Ren, and Jian Sun. "Deep residual learning for image recognition." In Proceedings of the IEEE conference on computer vision and pattern recognition, pp. 770-778. 2016.
%
%
% [class.h3]Resnet50[/class]
% a convolutional neural network that is 50 layers deep. The default image size is 224x224 pixels but it can be adjusted to any value.[br]
% This network in MIB for MATLAB can be initialized using a pretrained
% version of the network trained on more than a million images from the ImageNet database.
%
% *References* 
%
% * ImageNet. http://www.image-net.org
% * He, Kaiming, Xiangyu Zhang, Shaoqing Ren, and Jian Sun. "Deep residual learning for image recognition." In Proceedings of the IEEE conference on computer vision and pattern recognition, pp. 770-778. 2016.
% * https://keras.io/api/applications/resnet/#resnet50-function
%
%
% [class.h3]Resnet101[/class]
% a convolutional neural network that is 101 layers deep. The default image size is 224x224 pixels but it can be adjusted to any value.[br]
% This network in MIB for MATLAB can be initialized using a pretrained
% version of the network trained on more than a million images from the ImageNet database.
%
% *References* 
%
% * ImageNet. http://www.image-net.org
% * He, Kaiming, Xiangyu Zhang, Shaoqing Ren, and Jian Sun. "Deep residual learning for image recognition." In Proceedings of the IEEE conference on computer vision and pattern recognition, pp. 770-778. 2016.
% * https://github.com/KaimingHe/deep-residual-networks
%
%
% [class.h3]XCeption[/class]
% is a convolutional neural network that is 71 layers deep. It is the most computationally intense network available now in DeepMIB for the patch-wise workflow.
% The default image size is 299x299 pixels but it can be adjusted to any value.[br]
% This network in MIB for MATLAB can be initialized using a pretrained
% version of the network trained on more than a million images from the ImageNet database.
%
% *References* 
%
% * ImageNet. http://www.image-net.org
% * Chollet, F., 2017. "Xception: Deep Learning with Depthwise Separable Convolutions." arXiv preprint, pp.1610-02357.
%
%
% [/dtls]
%
%
%
%% Network filename
%
% <html>
% The <b>Network filename</b> button allows to choose a file for saving the
% network or for loading the pretrained network from a disk.<br>
% <br>
% <ul>
% <li>When the <em>Directories and preprocessing</em> or <em>Train</em> tab is selected, press of the  this
% button defines a file for saving the network</li>
% <li>When the <em>Predict</em> tab is selected, a user can choose a file with the
% pretrained network to be used for prediction</li>
% </ul>
% For ease of navigation the button is color-coded to match the active tab
% </html>
%
% [br8]
%
%% The [class.dropdown]GPU  &#9660;[/class] dropdown
% define execution environment for training and prediction
%
% <html>
% <ul>
% <li><b>Name of a GPU to use</b>, the dropdown menu starts with the list
% of available GPUs to use; select one that should be used for deep learning application</li>
% <li><b>Multi-GPU</b> (<b>under development</b>),  use multiple GPUs on one machine, using a local parallel pool based on your default cluster profile. 
% If there is no current parallel pool, the software starts a parallel pool
% with pool size equal to the number of available GPUs. <em>This option is
% only shown when multiple GPUs are present on the system</em></li>
% <li><b>CPU only</b>, do calculation using only a single available CPU</li>
% <li><b>Parallel</b> (<b>under development</b>), use a local or remote parallel pool based on your default cluster profile. 
% If there is no current parallel pool, the software starts one using the default cluster profile. 
% If the pool has access to GPUs, then only workers with a unique GPU perform training computation. 
% If the pool does not have GPUs, then training takes place on all available CPU workers instead</li>
% </ul>
% Press the "<b>?</b>" button to see GPU info dialog<br>
% </html>
%
% [dtls][smry] *GPU information dialog* [/smry]
%
% <<images\DeepLearningNetwork_GPUinfo.png>>
%
% [/dtls]
%
%
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools
% Menu*> |*-->*| <ug_gui_menu_tools_deeplearning.html *Deep learning segmentation*>
%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #fff; 
% 	padding: 0.1em 0.4em; 
% 	font-size: 1em;
% }
% .kbd { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	-moz-border-radius: 0.2em; 
% 	-webkit-border-radius: 0.2em; 
% 	border-radius: 0.2em; 
% 	-moz-box-shadow: 0.1em 0.2em 0.2em #ddd; 
% 	-webkit-box-shadow: 0.1em 0.2em 0.2em #ddd; 
% 	box-shadow: 0.1em 0.2em 0.2em #ddd; 
% 	background-color: #f9f9f9; 
% 	background-image: -moz-linear-gradient(top, #eee, #f9f9f9, #eee); 
% 	background-image: -o-linear-gradient(top, #eee, #f9f9f9, #eee); 
% 	background-image: -webkit-linear-gradient(top, #eee, #f9f9f9, #eee); 
% 	background-image: linear-gradient(&#91;&#91;:Template:Linear-gradient/legacy]], #eee, #f9f9f9, #eee); 
% 	padding: 0.1em 0.4em; 
% 	font-family: inherit; 
% 	font-size: 1em;
% }
% .h3 {
% color: #E65100;
% font-size: 12px;
% font-weight: bold;
% }
% .code {
% font-family: monospace;
% font-size: 10pt;
% background: #eee;
% padding: 1pt 3pt;
% }
% [/cssClasses]
%%
% <html>
% <script>
%   var allDetails = document.getElementsByTagName('details');
%   toggle_details(0);
% </script>
% </html>