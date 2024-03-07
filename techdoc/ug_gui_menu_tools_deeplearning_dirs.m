%% DeepMIB - Directories and Preprocessing tab
% This tab allows choosing directories with images for training and
% prediction as well as various parameters used during image loading and
% preprocessing
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools
% Menu*> |*-->*| <ug_gui_menu_tools_deeplearning.html *Deep learning segmentation*>
% 
% 
%% Widgets and settings
%
% <<images\DeepLearning_FileTree.jpg>>
%
% [class.h3]Directory with images and labels for training[/class][br]
% [ _used only for training_ ][br]
% 
% <<images\DeepLearningDirs_panel1.png>>
% 
% <html>
% use these widgets to select directory that contain images and model to be
% used for training. For the organization of directories see the
% organization schemes below.<br>
% For 2D networks the files should contain individual 2D images, while for 3D networks
% individual 3D datasets.<br>
% The <span class="dropdown">extension &#9660;</span> dropdown menu on the right-hand side can be used to specify extension 
% of the image files. <br>
% The <span class="kbd">[&#10003;] <b>Bio</b></span> checkbox toggles standard or Bio-format readers for loading images. 
% If the Bio-Format file is a collection of image, the <span class="dropdown">Index...</span> edit box can be used
% to specify an index of the file within the container.<br>
% For better performance, it is recommended to convert Bio-Formats compatible images to standard formats or to use the Preprocessing option (see below). 
% <br>
% </html>
%
% [dtls][smry] *Important notes considering training files* [/smry]
%
% <html>
% <ul>
% <li>Number of model or mask files should match the number of image files
% (one exception is 2D networks, where it is allowed to have a single
% model file in MIB <span class="code">*.model</span> format, when <b>Single MIB model file:
% ticked</b>). This option requires [jumpto2]data preprocessing[/jumpto]</li> 
% <li>For labels in standard image formats it is important to
% specify number of classes <b>including the Exterior</b> into the <b>Number of
% classes</b> edit box</li>
% <li><b><em>Important! It is not possible to use numbers as names of
% materials, please name materials in a sensible way when using the <span class="code">*.model</span> format!</b></em></li>
% </ul>
% </html>
%
% [/dtls]
% [br8]
% 
% [class.h3]Directory with images for prediction[/class][br]
% [ _used only for prediction_ ][br]
% use these widgets to specify directory with images for prediction (named [class.code]2_Prediction[/class] in [jumpto1]the file organization schemes below[/jumpto]).
% 
% <<images\DeepLearningDirs_panel2.png>>
% 
% <html>
% The image files should be placed under <span class="code">Images</span> subfolder 
% (it is also possible to place images directly into a folder specified in this panel). 
% Optionally, when the ground truth labels for prediction images are available, they can be placed under <span class="code">Labels</span> subfolder.
% <br><br>
% When the preprocessing mode is used the images from this folder are
% converted and saved to <span class="code">3_Results\Prediction images</span> directory. 
% When the ground truth labels are present, they are also processed and copied to 
% <span class="code">3_Results\PredictionImages\GroundTruthLabels</span>. These labels can
% be used for evaluation of results (see <ug_gui_menu_tools_deeplearning_predict.html the *Predict* tab> for details).
% <br><br>
% For 2D networks the files should contain individual 2D images or 3D stacks, while for 3D networks
% individual 3D datasets.
% <br><br>
% The <span class="dropdown">extension &#9660;</span> dropdown menu on the right-hand side can be used to specify extension 
% of the image files. The <span class="kbd">[&#10003;] <b>Bio</b></span> checkbox toggles standard or Bio-format readers for loading the images. 
% If the Bio-Format file is a collection of image, the <b>Index</b> edit box can be used
% to specify an index of the file within the container.<br>
% </html>
%
% [br8]
% [class.h3]Directory with resulting images[/class][br]
% use these widgets to specify the main output directory; results and all
% preprocessed images are stored there.
% 
% <<images\DeepLearningDirs_panel3.png>>
%
% All subfolders inside this
% directory are automatically created by Deep MIB:[br8]
%
% [dtls][smry] *Description of directories created by DeepMIB* [/smry]
%
% <html>
% <ul>
% <li><span class="code">PredictionImages</span>, place for the prepocessed images for
% prediction</li>
% <li><span class="code">PredictionImages\GroundTruthLabels</span>, place
% for ground truth labels for prediction images, when available</li>
% <li><span class="code">PredictionImages\ResultsModels</span>, the main outout directory with generated labels after prediction. 
% The 2D models can be combined in MIB by selecting the files using the <span class="kbd">&#8679; Shift</span>+<span class="kbd">left mouse click</span> during loading</li>
% <li><span class="code">PredictionImages\ResultsScores</span>, folder for generated prediction scores (probability) for each material. 
% The score values are scaled between 0 and 255</li>
% <li><span class="code">ScoreNetwork</span>, for accuracy and loss score plots, when the <em>Export training plots</em> option 
% of the <em>Train</em> tab is ticked and for storing checkpoints of the network after each epoch (or specified frequency), 
% when the <span class="kbd">[&#10003;] <b>Save progress after each epoch</b></span> checkbox is ticked. The score files are started with a date-time tag and overwritten when a new training is started</li>
% <li><span class="code">TrainImages</span>, images to be used for training (<em>only for preprocessing mode</em>)</li>
% <li><span class="code">TrainLabels</span>, labels accompanying images to be used for training (<em>only for preprocessing mode</em>)</li>
% <li><span class="code">ValidationImages</span>, images to be used for validation during training (<em>only for preprocessing mode</em>)</li>
% <li><span class="code">ValidationLabels</span>, labels accompanying images for validation (<em>only for preprocessing mode</em>)</li>
% </ul>
% </html>
%
% [/dtls]
%
% [class.h3]Label file details[/class]
% 
% <<images\DeepLearningDirs_panel4.png>>
%
% <html>
% <ul>
% <li>The <span class="kbd">[&#10003;] <b>Single MIB model file </b></span> checkbox, (<em>only for 2D networks</em>) when checked, a single model file with labels will be used</li>
% <li>The <span class="dropdown">Labels extension &#9660;</span> dropdown, (<em>only for 2D networks</em>) is used to select extension of files containing models.
% For 3D network MIB model format is used</li>
% <li>The <b>Number of classes edit box</b>, (<em>TIF or PNG formats only</em>) is used to define number of classes (including <span class="code">Exterior</span>) 
% in labels. For label files in MIB <span class="code">*.model</span> format, this field will be updated automatically</li>
% <li><span class="kbd">[&#10003;] <b>Use masking</b></span> checkbox is used when some parts of the training 
% data should be excluded from training. The masks may be provided in various formats
% and number of mask files should match the number of image files. When
% mask files are provided the preprocessing operation has to be done. When <span class="dropdown">USE 0-s IN LABELS &#9660;</span>
% is selected the mask is assumed to be areas of label files with 0-values.
% This option is recommended for work with masks without the preprocessing operation<br>
% <div class="info">
% <ul>
% <li> When <span class="dropdown">USE 0-s IN LABELS &#9660;</span> is used, the
% first material in the prediction results will be assigned to the
% Exterior material, i.e. will acquire index 0.<br>
% It is recommended to have the first material in the ground truth assigned to background!</li>
% <li> When mask with the preprocessing operation is used, the Exterior material will be used to indicate the background areas</li>
% <li> Masking may give drop in precision of training due to
% inconsistency within the image patches, it is recommended to minimize use
% of masking</li>
% </ul>
% </div>
% </li>
% <li><span class="dropdown">Mask extension &#9660;</span> is used to select extension for files that
% contain masks. Without preprocessing (<span class="dropdown">USE 0-s IN LABELS &#9660;</span> any files are allowed); 
% with preprocessing only <span class="code">*.mask</span> format is
% allowed for the 3D network</li>
% </html>
%
% [target5]
%
% [class.h3]Additional settings[/class]
% 
% <<images\DeepLearningDirs_panel5.png>>
% 
% <html>
% <ul>
% <li><span class="kbd">[&#10003;] <b>Compress processed images</b></span>, tick to compress the processed images. 
% The processed images are stored in <em>*.mibImg</em> format that can be loaded in MIB. 
% <em>*.mibImg</em> is a variation of standard MATLAB format and can also be directly loaded into MATLAB 
% using similar to this command:<br><span class="code">res = load('img01.mibImg, '-mat');</span>.
% <br>
% Compression of images slows down performance!</li>
% <li><span class="kbd">[&#10003;] <b>Compress processed labels</b></span>, tick to compress labels during preprocessing. 
% The processed labels are stored in <em>*.mibCat</em> format that can be loaded in MIB (<em>Menu->Models->Load model</em>). 
% It is a variation of a standard MATLAB format, where the model is encoded using categorical class of MATLAB.
% <br> 
% Compression of labels slows down performance but brings significant benefit of small file sizes</li>
% <li><span class="kbd">[&#10003;] <b>Use parallel processing</b></span>, when ticked DeepMIB is using multiple
% cores to process images. Number of cores can be specified using the
% <span class="dropdown">Workers</span> edit box. The parallel processing during preprocessing
% operation brings significant decrease in time required for
% preprocessing.</li>
% <li><span class="dropdown"><b>Fraction of images for validation</b></span>, define fraction of images
% that will be randomly (depending on <span class="dropdown">Random generator seed</span>) assigned into
% the validation set. When set to 0, the validation option will not be used during the training</li>
% <li><span class="dropdown">Random generator seed</span>, a number to initialize random seed
% generator, which defines how the images for training and validation are
% split. For reproducibility of tests keep value fixed. 
% When random seed is initialized with 0, the random seed generator is shuffled based on the current system time</li>
% <li><span class="dropdown">Preprocess for &#9660;</span>, select mode of operation upon press of the <span class="kbd">Preprocess</span> button. 
% Results of the preprocessing operation for each mode are presented in schemes below</li>
% </ul>
% </html>
%
% [br32]
%
%% Preprocessing of files
% 
% [target1]
%
% <html>
% Originally, the preprocessing of files in DeepMIB was required for most of workflows. 
% Currently, however, DeepMIB is capable to work with unprocessed images most of 
% times: use the <span class="dropdown">Preprocessing is not required &#9660;</span> or 
% <span class="dropdown">Split for training/validation &#9660;</span> options.
% </html>
%
% [dtls][smry] *When the preprocessing step is required or recommended* [/smry]
%
% The preprocessing is recommended/required in the following situations:
%
% * when labels are stored in a single [class.code]*.MODEL[/class] file
% * when training set is coming in proprietary formats that can only be read using BioFormats reader
%
% During preprocessing the images and model files are converted to 
% *mibImg* and *mibCat* formats (a variation of MATLAB standard data format) that are adapted for training and prediction.
%
% [/dtls]
% [br32]
%
%% Organization of directories without preprocessing for semantic segmentation
%
% [br12]
%
% [class.h3]Without preprocessing, when datasets are manually split into training
% and validation sets[/class]
%
% In this mode, the training image files are not preprocessed and loaded on-demand during network training. 
% The image files should be split into subfolders [class.code]TrainImages, TrainLabels[/class] 
% and optional subfolders [class.code]ValidationImages,
% ValidationLabels[/class] (for details see Snapshot with the legend below). The images may also be automatically split, see
% [jumpto4]the following section[/jumpto] for details.
% [br]When Bio-Format library is used, it is
% recommended to [jumpto2]preprocess images[/jumpto] for the training process to speed up the
% file reading performance.
%
% [dtls][smry] *Snapshot with the directory tree* [/smry]
% 
% <<images\DeepLearningDirectories_B.png>>
% 
% [/dtls]
%
% [dtls][smry] *Snapshot with the legend* [/smry]
%
% <<images\DeepLearningDirectories_Legend.png>>
%
% [/dtls]
% [br8]
%
% [class.h3]Without preprocessing, with automatic splitting of datasets
% into training and validation sets[/class]
%
% In this mode, the image and label files are randomly
% split into the train and validation sets. The split is done upon press of
% the [class.kbd]Preprocess[/class] button, when [class.code]Preprocess
% for: Split for training and validation[/class][br]
% Splitting of the files depends on a seed value provided in the
% [class.code]Random generator seed[/class] field; when seed is *0* a new
% random seed value is used each time the spliting is done.
%
% [dtls][smry] *Snapshot with the directory tree* [/smry]
%
% <<images\DeepLearningDirectories_C.png>>
%
% [/dtls]
% [br8]
% 
% [dtls][smry] *Snapshot with the legend* [/smry]
%
% <<images\DeepLearningDirectories_Legend.png>>
%
% [/dtls]
% [br32]
%
%% Organization of directories with preprocessing for semantic segmentation
%
% [target2]
% This mode is enabled when the [class.code]Preprocess for[/class] has one of the following selections:
%
% * *Training and prediction*, to preprocess images for both training and
% prediction
% * *Training*, to preprocess images only for training
% * *Prediction*, to preprocess images only for prediction
%
% The preprocessing starts by pressing of the [class.kbd]Preprocess[/class]
% button.
%
% The scheme below demonstrates organization of directories, when the preprocessing mode is used. 
%
% [dtls][smry] *Snapshot with the directory tree* [/smry]
%
% <<images\DeepLearningDirectories_A.png>>
%
% [/dtls]
%
% [dtls][smry] *Snapshot with the legend* [/smry]
% 
% <<images\DeepLearningDirectories_Legend.png>>
% 
% [/dtls]
%
%
%% Organization of directories for 2D patch-wise workflow
%
% The 2D patch-wise workflow requires slightly different organization of
% images in folders. In brief, instead having [class.code]Images[/class]
% and [class.code]Labels[/class] training directories, all images are organized in
% [class.code]Images\[ClassnameN][/class] subfolders. Where
% [class.code]ClassnameN[/class] encodes a directory name with images patches that belong to
% *ClassnameN* class. Number of these subfolders should match number of
% classes to be used for training.
% [br16]
%
% In contrast to semantic segmentation, the preprocessing is not used
% during the patch-wise mode.
%
% [class.h3]Without preprocessing, when datasets are manually split into training
% and validation sets[/class]
%
% The images for training should be organized in own subfolders named by
% corresponding class names and placed under:
% 
% * [class.code]1_Training\TrainImages[/class], images to be used for training
% * [class.code]1_Training\ValidationImages[/class], images to be used for
% validation (optionally)
% 
% The images may also be [jumpto4]automatically split[/jumpto] into subfolder for training
% and validation.
%
% [dtls][smry] *Snapshot with the directory tree* [/smry]
% 
% <<images\DeepLearningDirectories_PW1.png>>
% 
% [class.code]bg[/class] and [class.code]spots[/class] are examples of two class names
%
% When the ground-truth data for prediction is present, it can be arranged
% in a similar way to the semantic segmentation under [br]
% [class.code]2_Prediction\Images[/class] and [br]
% [class.code]2_Prediction\Labels[/class] directories[br]
% or in subfolders named by class names as
% [class.code]2_Prediction\bg[/class] and
% [class.code]2_Prediction\spots[/class], where [class.code]bg[/class] and
% [class.code]spots[/class] subfolders contain patches that belong to these
% classes.
%
% [/dtls]
%
% [dtls][smry] *Snapshot with the legend* [/smry]
%
% <<images\DeepLearningDirectories_Legend.png>>
%
% [/dtls]
% [br8]
%
% [target4]
% [class.h3]Without preprocessing, with automatic splitting of datasets
% into training and validation sets[/class]
%
% In this mode, the files are randomly split (depending on [jumpto5]*Random generator seed*[/jumpto]) into the train and validation sets.
% The split is done upon press of the [class.kbd]Preprocess[/class] button,
% when [class.code]Preprocess for: Split for training and validation[/class][br8]
% Initially, all images for training should be organized in own subfolders named by
% corresponding class names and placed under: [class.code]1_Training\Images[/class]
%
% [dtls][smry] *Snapshot with the directory tree* [/smry]
%
% <<images\DeepLearningDirectories_PW2.png>>
% 
% [class.code]bg[/class] and [class.code]spots[/class] are examples of two class names
%
% When the ground-truth data for prediction is present, it can be arranged
% in a similar way to the semantic segmentation under [br]
% [class.code]2_Prediction\Images[/class] and [br]
% [class.code]2_Prediction\Labels[/class] directories[br]
% or in subfolders named by class names as
% [class.code]2_Prediction\bg[/class] and
% [class.code]2_Prediction\spots[/class], where [class.code]bg[/class] and
% [class.code]spots[/class] subfolders contain patches that belong to these
% classes.
%
%
% [/dtls]
% [br8]
% 
% [dtls][smry] *Snapshot with the legend* [/smry]
%
% <<images\DeepLearningDirectories_Legend.png>>
%
% [/dtls]
% [br32]
%
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools
% Menu*> |*-->*| <ug_gui_menu_tools_deeplearning.html *Deep learning segmentation*>
%
%%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #fffce8; 
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
% .info {
%  position: relative;
%  left: 40px;
%  width: 600px;
%  padding: 1em 1em 1em 4em;
%  margin: 2em 0;
%  color: #555;
%  background: #e7f2fa;
%  border-left: 4px solid #93cfeb;
% }
% .info:before {
%  content: url(images\\info.png);
%  position: absolute;
%  top: 10px;
%  left: 10px;
% }
% [/cssClasses]
%
%
% <html>
% <script>
%   var allDetails = document.getElementsByTagName('details');
%   toggle_details(0);
% </script>
% </html>