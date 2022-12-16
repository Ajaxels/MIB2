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
% <a href="https://youtu.be/gk1GK_hWuGE"><img style="vertical-align:middle;" src="images\youtube.png"> DeepMIB: 2D U-net for image segmentation</a><br>
% <a href="https://youtu.be/U5nhbRODvqU"><img style="vertical-align:middle;" src="images\youtube.png"> DeepMIB: 3D U-net for image segmentation</a><br>
% <a href="https://youtu.be/iG_wsxniBKk"><img style="vertical-align:middle;" src="images\youtube.png"> DeepMIB, features and updates in MIB 2.80</a><br>
% <a href="https://youtu.be/451nwPxyD-Q"><img style="vertical-align:middle;" src="images\youtube.png"> DeepMIB, 2D Patch-wise mode</a><br>
% <br><br>
% The typical semantic segmentation workflow consists of two parts: 
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
% options available in MIB.<br>
% <img src="images\DeepLearning_scheme.jpg">
% </html>
%
% For the list of available workflows and networks jump to description of <ug_gui_menu_tools_deeplearning_network.html the Network panel> 
% [br32]
%
%% Network panel
% 
% This panel is used to select workflow and convolutional network architecture to be used during training
%
% <ug_gui_menu_tools_deeplearning_network.html Details of the Network panel> 
%
%% Directories and Preprocessing tab
%
% This tab allows choosing directories with images for training and
% prediction as well as various parameters used during image loading and
% preprocessing. 
%
% <ug_gui_menu_tools_deeplearning_dirs.html Details of the Directories and Preprocessing tab> 
%
%% Train tab
% This tab contains settings for generating deep convolutional network and training.
%
% <ug_gui_menu_tools_deeplearning_train.html Details of the Train tab> 
%
%
%% Predict tab
%
% The trained networks can be loaded to Deep MIB and used for prediction of
% new datasets
%
% <ug_gui_menu_tools_deeplearning_predict.html Details of the Predict tab> 
%
%
%% Options tab
%
% Some additional options and settings are available in this tab
%
% <ug_gui_menu_tools_deeplearning_options.html Details of the Predict tab> 
%
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
%
%%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	box-shadow: 0.1em 0.2em 0.2em #ddd; 
% 	background-color: #FFF; 
% 	padding: 0.1em 0.4em; 
% 	font-family: inherit; 
% 	font-size: 1em;
% }
% .label {
% font-family: monospace;
% font-size: 10pt;
% font-weight: bold;
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
% padding: 2pt 3pt;
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