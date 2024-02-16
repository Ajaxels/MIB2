%% Mask Menu
% Actions that can be applied to the |Mask| layer. The |Mask layer| is one
% of three main segmentation layers (|Model, Selection, Mask|) which can be
% used in combibation with other layer. See more about segmentation layers
% in <ug_gui_data_layers.html the Data layers of Microscopy Image Browser section>.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
%%
%
% <<images\menuMask.png>>
%
%% ..->Selection
% Allows modification of the |Selection| layer by the |Mask| layer. It
% is possible to replace the selection with the mask, add mask to the
% selection, or remove mask from the selection. These actions can be applied
% for the currently shown slice or for the whole volume.
%
%% Clear mask
% Clears the mask, i.e. deletes the |Mask| layer from computer memory.
%
%% Load mask
% Load mask from disk. The mask is saved in the MATLAB format with the |*.mask|
% extension.
%
%% Import Mask from
% Imports mask from the main MATLAB workspace or from another dataset opened in MIB. 
% The mask should be a matrix with dimensions similar to those of the loaded dataset [class.code][1:height, 1:width, 1:no-slices][/class] of the [class.code]uint8[/class] class.
%
%% Export Mask to
% Exports mask to the main MATLAB workspace or to another dataset opened in MIB, the exported mask may be imported back 
% to |MIB| using _Import Mask from Matlab_ command.
%
%% Save mask as...
% Saves mask to disk. By default, the mask is saved in the MATLAB format with |*.mask|
% extension and |Mask_| prefix.
%
% [dtls][smry] *List of available formats to save masks* [/smry]
%
% * *Matlab format (.mask)*, default MATLAB format for saving masks
% * *Amira mesh binary (.am)*, Amira mesh binary format
% * *Amira mesh binary RLE compression SLOW (.am), compressed Amira Mesh
% format. *Note*, use of this format is not recommended as it is very slow.
% When working with Amira, the best to save mask in *Amira mesh binary* and
% resave it from Amira using RLE compression
% * *Hierarchial Data Format (.h5)*, chunked format suitable for saving masks to Ilastik
% * *PNG format (.png)* - save mask as 2D slices using Portable Network Graphic format 
% * *TIF format (.tif)* - save mask as 2D slices or 3D volumes using Tag Image File format
% * *Hierarchial Data Format with XML header (.xml)*, generate HDF5 file and XML file with image parameters
%
% [/dtls]
%
%% Invert mask
% Inverts mask so that the masked areas become background and the background
% becomes a mask.
%
%% Replace masked area in the image.
% Replaces image intensity in the masked areas with new values. A new dialog
% would ask to provide new intensities, slices, and the color channels.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/fNz1vGq7Hb0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/fNz1vGq7Hb0</a>
% </html>
%%
% 
% <<images\menuMaskReplaceColor.png>>
% 
%% Smooth mask
% Smoothes the |Mask| layer in 2D or 3D space.
%
%% Mask Statistics
% Get statistics for the mask layer. See more <ug_gui_menu_mask_statistics.html here>
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
% [cssClasses]
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