%% Deep MIB - Predict tab
% 
% This tab contains parameters used for efficient prediction (inference) of
% images and generation of semantic segmentation models.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
% 
%
%% How to start the prediction (inference) process
%
% <html>
% <img src="images\DeepLearningPredict.png"><br><br>
% <br>
% Prediction (inference) requires a pretrained network, if you do not have the
% pretrained network, you neet to <a
% href="ug_gui_menu_tools_deeplearning_train.html">train it</a>. <br>
% The pretrained networks can be loaded to DeepMIB and used for prediction of
% new datasets<br><br>
% <span class="h3">To start with prediction:</span>
% <ul>
% <li>select a file with the pretrained network in
% the <span class="dropdown">Network filename...</span> editbox of the <em><b>Network</b></em> panel. Upon
% loading, the corresponding fields of the <em>Train</em> panel will be
% updated with the settings used for training of the loaded network<br>
% Alternatively, a config file can be loaded using <b><em>Options
% tab->Config files->Load</em></b>
% </li>
% <li>make sure that directory with the images for prediction is correct<br>
% <span class="code">Directories and Preprocessing tab->Directory with images for
% prediction</span></li>
% <li>make sure that the output directory for results is correct:<br>
% <span class="code">Directories and Preprocessing tab->Directory with resulting images</span></li>
% <li>if needed, do file preprocessing (typically it is not needed):<br>
% <ul>
% <li>select <span class="dropdown">Preprocess for: Prediction
% &#9660;</span> in the <b>Directories and Preprocessing</b> tab</li>
% <li>press the <span class="kbd">Preprocess</span> button to perform data preprocessing</li>
% </ul>
% <li>finally switch back to the <b>Predict</b> tab and press the <span class="kbd">Predict</span> button</li>
% </ul>
% </html>
% 
%% Settings sections
% The Settings section is used to specify the main parameters using for the
% prediction (inference) process
% 
% <<images\DeepLearningPredictSettings.png>>
% 
% * [class.dropdown]Prediction engine &#9660;[/class], use this dropdown to
% select a tiling engine that will be used during the prediction process.
% The legacy engine was in use until MIB version 2.83, for all later
% releases the Blocked-image engine is recommended. Some of operations (for example, *Dynamic masking* or *2D Patch-wise*) are
% not available in the Legacy engine.
% * [class.kbd][&#10003;] *Overlapping tiles*[/class], available for [class.dropdown]Padding: same &#9660;[/class] convolutional padding.
% During prediction the edges of the predicted patch are cropped improving the segmentation, but taking more time. The percentage of the
% overlap between tiles can be specified using the
% [class.dropdown]%%...[/class] editbox.
%
% [dtls][smry] *Overlapping vs non-overlapping mode* [/smry]
% 
% <<images\DeepLearning_OverlappingTiles.jpg>>
% 
% *Same* padding in the non-overlapping mode may have vertical and
% horizontal artefacts, that are eliminated when the overlapping
% mode is used.
%
% [/dtls]
%
% * [class.kbd][&#10003;] *Dynamic masking*[/class], apply on-fly masking
% to skip prediction on some of the tiles. Settings for dynamic masking can
% be specified using the *Settings* button on the right-hand side of the
% checkbox. See the block below for details.
%
% [dtls][smry] *Dynamic masking settings and preview* [/smry]
%
% <html>
% <ul>
% <li><img src="images\DeepLearningTrainSettingsBtn.png">, press the
% button to specify parameters for dynamic masking.<br>
% <img src="images\DeepLearningPredictDynMasking.png"></li>
% <ul>
% <li><span class="dropdown">Masking method &#9660;</span>, specify whether
% to keep blocks with average intensity below or above the specified in the
% <span class="dropdown">Intensity threshold value...</span> editbox</li>
% <li><span class="dropdown">Intensity threshold value...</span> is used to
% specify the treshold value; patches with average intensity above or below
% this value will be predicted</li>
% <li><span class="dropdown">Inclusion threshold (0-1)...</span> is used to
% specify a fraction of pixels that should be above or below the tresholding
% value to keep the tile for prediction</li>
% </ul>
% <li>The <span class="kbd">Eye</span> button, hit to see the effect of the
% specified dynamic masking settings on a portion of the image that is
% currently shown in the <b>Image View</b> panel of MIB</li>
% </ul>
% <img src="images\DeepLearningPredictSettingsDynMaskPreview.png">
% </html>
%
% [dtls][smry] *Example of patch-wise segmentation with dynamic masking* [/smry]
% Snapshot showing result of 2D patch-wise segmentation of nuclei.[br]
%
% * Green color patches indicate predicted locations of nuclei
% * Red color patches indicate predicted locations of background
% * Uncolored areas indicate patches that were skipped due to dynamic masking
% 
% <<images\DeepLearningPredictDynMaskingResults.png>>
% 
%
% [/dtls]
%
% [/dtls]
%
% * [class.dropdown]Batch size for prediction...[/class], this editbox
% allows to specify number of input image patches that are processed by GPU
% at the same time. The larger the value, the quicker prediction takes, but
% the max value is limited by the total memory available on GPU.
% * [class.dropdown]Model files &#9660;[/class], specify output format for
% the generated model files. For the patch-wise workflow CSV files are
% created.
%
% [dtls][smry] *List of available image formats for the model files* [/smry]
% 
% * [class.dropdown]MIB Model format &#9660;[/class], standard formal for models in MIB. The model files
% have [class.code]*.model[/class] extension and can be read directly to
% MATLAB using [class.code]model = load('filename.model', '-mat');[/class]
% command
% * [class.dropdown]TIF compressed format &#9660;[/class], a standard TIF
% LZW compressed file, where each pixel encodes the predicted class as 1, 2, 3, etc... 
% * [class.dropdown]TIF uncompressed format &#9660;[/class], a standard TIF
% uncompressed file, where each pixel encodes the predicted class as 1, 2, 3, etc... 
%
% [/dtls]
%
% * [class.dropdown]Score files &#9660;[/class], specify output format for
% the generated score files with prediction maps.
%
% [dtls][smry] *List of available image formats for the score files* [/smry]
% 
% * [class.dropdown]Do not generate &#9660;[/class], skip generation of
% score files improving performance and minimizing disk usage
% * [class.dropdown]Use AM format &#9660;[/class], AmiraMesh format, compatible with MIB, Fiji or Amira
% * [class.dropdown]Use Matlab non-compressed format &#9660;[/class],
% resulting score files are generated in MATLAB uncompressed format with
% [class.code]*.mibImg[/class] extension. The score files can be loaded to
% MIB or to MATLAB using [class.code]model = load('filename.mibImg',
% '-mat');[/class] command
% * [class.dropdown]Use Matlab compressed format &#9660;[/class],
% resulting score files are generated in MATLAB compressed format with
% [class.code]*.mibImg[/class] extension. The score files can be loaded to
% MIB or to MATLAB using [class.code]model = load('filename.mibImg',
% '-mat');[/class] command
%
% [/dtls]
%
% * [class.kbd][&#10003;] *upsample predictions*[/class] (*only for the
% 2D patch-wise workflow*). By default, the 2D patch-wise workflow generates
% a heavily downsampled image (and CSV file), where each pixel encodes
% detected class at each predicted block. To overlap such prediction over
% the original image, the predicted image should be upsampled to match the
% original image size.
%
%% Explore activations
%
% <html>
% Activations explorer brings the possibility for detailed evaliation of
% the network. <br>
% <img src="images\DeepLearningPredictActivationsExplorer.png"><br>
% <br>
% Here is the description of the options:<br>
% <ul>
% <li><span class="dropdown">Image &#9660;</span> has a list of all preprocessed images for prediction.
% Selection of an image in this list will load a patch, which is equal to
% the input size of the selected network<br>
% The arrows on the right side of the dropdown can be used to load previous or next image in this list
% </li>
% <li><span class="dropdown">Layer &#9660;</span> contains a list of all layers of the selected network.
% Selection of a layer, starts prediction and acquiry of activation images</li>
% <li><span class="dropdown">Z1...</span>, <span class="dropdown">X1...</span>, <span class="dropdown">Y1...</span>, 
% these spinners make it possible to shift the patch across the image. Shifting of the patch does not automatically update the
% activation image. To update the activation image press the <span class="kbd">Update</span> button</li>
% <li><span class="dropdown">Patch Z...</span>, change the z value within the loaded activation
% patch, it is used only for 3D networks</li>
% <li><span class="dropdown">Filter Id...</span>, change of this spinner brings various activation
% layers into the view</li>
% <li><span class="kbd">Update</span> press to calculate the activation images for the
% currently displayed patch</li>
% <li><span class="kbd">Collage</span> press to make a collage image of the current network
% layer activations</li>
% </ul>
% </html>
%
% [dtls][smry] *Snapshot with the generated collage image* [/smry]
% 
% <<images\DeepLearningPredictActivationImages.png>>
% 
% [/dtls]
%
%% Preview results section
%
% <<images\DeepLearningPredictPreviewResults.png>>
% 
%
% <html>
% <ul>
% <li><span class="kbd">Load images and models</span> press this button after finishing prediction 
% to open original images and the resulting segmentations in the currently
% active buffer of MIB</li>
% <li><span class="kbd">Load models</span> press this button after finishing prediction 
% to load the resulting segmentations over already loaded image in MIB</li>
% <li><span class="kbd">Load prediction scores</span> press to load the resulting score images (probabilities)
% into the currently active buffer of MIB</li>
% <li><span class="kbd">Evaluate segmentation</span>. When the datasets for prediction are accompanied with 
% ground truth models (<b> requires a model file in the Labels directory
% under Prediction images directory; it is important that the model materials names match those for the training data!</b>).
% </li>
% </ul>
% </html>
%
% [dtls][smry] *Details of the Evaluate segmentation operation* [/smry]
%
% <html>
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
% formats to <span class="code">3_Results\PredictionImages\ResultsModels</span> directory, see more in the 
% <a href="ug_gui_menu_tools_deeplearning_dirs.html">Directories and Preprocessing</a> section. 
% <br>For details of the metrics refer to MATLAB documentation for <a
% href="https://se.mathworks.com/help/vision/ref/evaluatesemanticsegmentation.html">evaluatesemanticsegmentation
% function</a></li>
% </ul>
% </li>
% </ul>
% </html>
%
% [/dtls]
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #e8f5e8;  
% 	padding: 0.1em 0.4em; 
% 	font-family: inherit; 
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