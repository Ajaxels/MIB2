%% Options tab
% Some additional options and settings are available in this tab
% 
% <<images\DeepLearningOptions.png>>
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
% 
%
%% Custom training plot section
%
% <html>
% Settings for the custom training progress plot showing the loss function
% during training. 
% <ul>
% <li><span class="kbd">[&#10003;] <b>Custom training progress plot</b></span>, when checked the custom
% training plot is used, when unchecked a standard MATLAB training plot is
% displayed (<em>the standard MATLAB plot is only available for MATLAB version
% of MIB</em>)</li>
% <li><span class="dropdown">Refresh rate...</span>, update the plot after the specified number of
% interations. Adjust the value to improve performance. With larger
% values the plot will be updated more rare, improving performance of during training</li>
% <li><span class="dropdown">Number of points...</span>, number of points that is used to show the plot. 
% Decrease the value to improve drawing performance, increase the value to see more points</li>
% <li><span class="kbd">[&#10003;] <b>Preview image patches</b></span>, when checked the custom training plot
% will show input image and model patches for evaluation. Plotting of
% patches decreases performance, it is possible to use <span class="dropdown">Fraction of images for preview...</span>
% to specify fraction of patches that have to be shown</li>
% <li><span class="dropdown">Fraction of images for preview...</span>, specify fraction of input
% patches that are shown in the custom training plot. Use 1 to see all input patches and 
% small values to see only a fraction of those. For example, the value 0.01 
% specifies that only 1% of image patches are displayed in the progress plot window</li>
% </ul>
% </html>
% 
%% Config files section
%
% This panel brings access to loading or saving Deep MIB config files.[br]
% The config files contain all settings of DeepMIB including the network
% name and input and output directories but excluding the actual trained network. 
% Normally, these files are automatically 
% created during the training process and stored next to the network
% [class.code]*.mibDeep[/class] files also in MATLAB format using the
% [class.code]*.mibCfg[/class] extension.[br]
% Alternatively, the files can be saved manually by pressing the
% [class.kbd]Save[/class] button.
% [br16]
%
%% Tools section
%
% * [class.kbd]Import network[/class], press to import a network designed
% or trained elsewhere. At the moment, the function only supports network
% in MATLAB format. [br]
% In a typical workflow, a network can be designed using MATLAB Deep
% Network Designer and after that imported into DeepMIB for training or
% prediction. During the import process [class.code]*.mibCfg[/class] and
% [class.code]*.mibDeep[/class] files are generated.
% * [class.kbd]Export network to ONNX[/class], press to export the trained
% network outside of MATLAB using the ONNX format. 
%
% [dtls][smry] *Additional details of ONNX export* [/smry]
%
% <<images\DeepLearningOptionsONNX.png>>
% 
% During ONNX export, it is possible to choose following options:
%
% * [class.dropdown]Version of ONNX operator set &#9660;[/class], supported
% operator set versions are 6, 7, 8, 9
% * [class.dropdown]Alter the final segmentation layer as &#9660;[/class];
% use this option to modify the last segmentation layer used during
% training. For example, the CustomDice classification layer is not
% standard and thus not supported in ONNX. Instead, as this layer is not
% needed after training, it can be replaced with a standard segmentation
% layer or removed.
% 
% [dtls][smry] *List of available options* [/smry]
%
% * [class.dropdown]Keep as it is &#9660;[/class], do not modify the last segmentation layer
% * [class.dropdown]Remove the layer &#9660;[/class], remove the segmentation layer making the softmax as
% the final layer of the network
% * [class.dropdown]pixelClassificationLayer &#9660;[/class], replace the final segmentation layer with a standard 
% pixel classification layer for semantic segmentation
% * [class.dropdown]dicePixelClassificationLayer &#9660;[/class], replace the final segmentation layer with a standard 
% pixel classification layer using generalized Dice loss for semantic segmentation
%
% [/dtls]
%
% [/dtls]
%
% * [class.kbd]Count labels[/class], press to start a supporting function
% that counts the labels in the model files. Expand the section below for
% details.
%
% [dtls][smry] *Details of Count Labels* [/smry]
% 
% * Select directory with labels
% * Specify filename extension (supported formats [class.code]*.model, *.mibCat, *.png, *.tif, *.tiff[/class]) of the model file and number of classes
% 
% <<images\DeepLearningOptionsCountLabels.png>>
% 
% * Save results to a file (supported formats [class.code]*.mat, *.xls,
% *.csv[/class])
%
% [/dtls]
%
%% Augmentation section
% Supporting functions that are used to reset or disable augmentations.
% 
% <html>
% <ul>
% <li><b>2D</b>, modify augmentations for 2D networks
% <ul>
% <li>[class.kbd]Reset[/class], press to reset 2D augmentations to their default values</li>
% <li>[class.kbd]Disable[/class], press to disable all 2D augmentations</li>
% </ul>
% </li>
% <li><b>3D</b>, modify augmentations for 3D networks
% <ul>
% <li>[class.kbd]Reset[/class], press to reset 3D augmentations to their default values</li>
% <li>[class.kbd]Disable[/class], press to disable all 3D augmentations</li>
% </ul>
% </li>
% </ul>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #fff;  
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