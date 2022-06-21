%% Microscopy Image Browser Watershed/Graphcut segmentation
% This window give access to semi-automated image segmentation using the
% Watershed method. 
% 
% _It is recommended to use the <ug_gui_menu_tools_graphcut.html *Graphcut segmentation*> due to its high interactivity._ 
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
% 
%
%% General example
%
%
% <<images\menuToolsWatershed_Overview.jpg>>
% 
%
%% Mode panel
% The |Mode panel| offers possibility to select a desired working mode for
% the segmentation. 
%%
% 
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px; width: 180px">
%   <img src = "images\menuToolsWatershed_Mode.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><span class="kbd">&#9673; <b>2D, current slice only</b></span>, performs segmentation on the slice that is currently shown
% in <a href="ug_panel_im_view.html">the Image View panel</a></li>
% <li><span class="kbd">&#9673; <b>2D, slice-by-slice</b></span>, performs 2D segmentation for each slice of the
% dataset individually</li>
% <li><span class="kbd">&#9673; <b>3D, volume</b></span>, performs 3D segmentation for complete or selected portion (<em>see Selected Area section below</em>) of the dataset</li>
% <li><span class="dropdown">Aspect ratio for 3D...</span> indicates the aspect ratio of the dataset. 
% These values are calculated from the voxel size of the dataset (available from the
% <a href="ug_gui_menu_dataset.html">Menu->Dataset->Parameters</a>). The aspect ratio
% values are used when watershed is running using the distance map (see below)</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
%
%% Subarea panel
% The |Subarea panel| allows selection of the sub-area of the dataset for
% processing. If dataset is too big it can be processed in parts or binned
% using this panel.
%
%%
% 
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\menuToolsWatershed_Subarea.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><span class="dropdown">X:...</span> defines the width of the dataset to process. Please use two numbers separated by a colon sign (:)</li>
% <li><span class="dropdown">Y:...</span> defines the height of the dataset to process</li>
% <li><span class="dropdown">Z:...</span> defines the z-slices of the dataset to process</li>
% <li><span class="kbd">from Selection</span> button populates the <b>X:</b>, <b>Y:</b>, <b>Z:</b> fields
% using coordinates of a bounding box that describes the <em>Selection</em> layer</li>
% <li><span class="kbd">Current View</span> button limits the <b>X:</b> and <b>Y:</b> parameters to the image
% that is currently displayed in the <a href="ug_panel_im_view.html"> Image View panel</a></li>
% <li><span class="kbd">Reset</span> resets the Subarea fields to the dimensions of the dataset</li>
% <li><span class="dropdown">Bin x times...</span> defines a binning factor for the data before segmentation. 
% It allows to perform faster but with less
% details.</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
%% Image segmentation settings
% Both the *Watershed* and <ug_gui_menu_tools_graphcut.html *Graphcut segmentation*> workflows use provided labels that
% mark areas belonging to the Object and Background to perform the fine
% segmentation. Comparing to the *Graphcut* workflow, the *Watershed* workflow is a bit less interactive; it
% requires more time for the each execution and separates only objects that have distinct boundaries, 
% for example membrane enclosed organelles. 
%
% On the other hand, the *Graphcut* workflow spends more time on the image preprocessing (calculation of the superpixels and generation of a graph) but each following
% interaction is fast. Using this workflow it is possible to separate objects that have both boundaries and intensity contrast. In general the *Graphcut workflow* is recommended
% for most of the cases. 
%
% Below, description of the *Image segmentation settings*:
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px; width: 300px">
%   <img src = "images\menuToolsWatershed_Imsegm.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><span class="dropdown">Color channel &#9660;</span> defines a color channel that will be used for 
% segmentation</li>
% <li><span class="dropdown">Background &#9660;</span> defines a material of the model that labels the
% background</li>
% <li><span class="dropdown">Object &#9660;</span> defines a material of the model that labels the
% object to be segmented</li>
% <li><span class="dropdown">Type of signal &#9660;</span> defines type of the data: 'black-on-white', when the
% objects are separated with dark boundaries and 'white-on-black' for the
% bright boundaries</li>
% <li><span class="kbd">Update lists</span> refreshes the lists of materials</li>
% <li><b>Optional pre-processing (only for the Watershed workflow)</b>
%   <ul style="margin-left: 60px">
%   <li><span class="kbd">[&#10003;] <b>Gradient</b></span> filters the image before watershed using the
%       Gradient filter to create borders around objects</li>
%   <li><span class="kbd">[&#10003;] <b>Eigenvalue of Hessian</b></span>, pre-processing the data using this option may sometimes be beneficial for the following watershed transfornation. Use the <b>Sigma</b> fields to fine-tune the filter</li>
%   <li><span class="kbd">[&#10003;] <b>Export to MATLAB</b></span> exports pre-processed data to the main MATLAB workspace</li>
%   <li><span class="kbd">[&#10003;] <b>Preview</b></span> shows the result of pre-processing in the Image View panel</li>
%   <li><span class="kbd">Pre-process</span> starts the data pre-processing process. When pre-processed data is present the color of the button turns to green</li>
%   <li><span class="kbd">Import from MATLAB</span> imports dataset that will be used for image segmentation from MATLAB workspace</li>
%   <li><span class="kbd">Clear</span> removes the pre-processed data from the memory<br></li>
%   </ul>
% </li>
% </td>
% </tr>
% </table>
% </html>
% 
%% Image segmentation example
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\watershed_imsegm_01.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li>Load a sample dataset: <span class="code">Menu->File->Import image from->URL</span>, enter the address:<br>http://mib.helsinki.fi/tutorials/WatershedDemo/watershed_demo1.tif</li>
% <li>Press the <span class="kbd"><b>+</b></span> button in the <a href="ug_panel_segm.html">Segmentation panel</a> to add material to the model and name is as 'Background' (use the right mouse button to call a popup menu)</li>
% <li>Use the brush tool to label an area that belongs to cytoplasm</li>
% </ul>
% </td>
% </tr>
% <tr><td colspan=2 style="border: 0px">
% <img src = "images\watershed_imsegm_02.jpg"> 
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <ul>
% <li>Press the <span class="kbd"><b>A</b></span> button to add selected area to the first material (Background) of the model</li>
% <li>Press the <span class="kbd"><b>+</b></span> button again to add another material and name it as 'Seeds'</li>
% <li>Draw labels inside mitochondria.</li>
% </ul>
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <img src = "images\watershed_imsegm_03.jpg"> 
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <ul>
% <li>Press the <span class="kbd"><b>A</b></span> button to add selected area to the second material (Seeds) of the model</li>
% <li>Start the Watershed segmentation tool: <span class="code">Menu->Tools->Semi-automatic segmentation->Watershed</span>.</li>
% <li>Make sure that the proper materials are selected for both Background and Object in the <em>Image segmentation settings</em></li>
% <li>Press the <span class="kbd">Segment</span> button to segment mitochondria</li>
% <li>Add more seeds to the background and object materials to improve segmentaion</li>
% <li>Press the <span class="kbd">Segment</span> button again</li>
% <li>The segmented mitochondria are placed to the <em>Mask</em> layer</li>
% <li>Optionally smooth mitochondria: <span class="code">Menu->Mask->Smooth Mask</span></li>
% </ul>
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <img src = "images\watershed_imsegm_04.jpg"> 
% </td></tr>
% </table>
% </html>
%
%% Algorithm for image segmentation with watershed
%
% 
% <<images\menuToolsWatershedGraphcut_img_segm_alg.jpg>>
% 
%% References
% 
% Watershed: the Image segmentation and Object separation modes: 
%
% * <http://blogs.mathworks.com/steve/2013/11/19/watershed-transform-question-from-tech-support/ Watershed transform question from tech support by Steve Eddins>
% * <http://blogs.mathworks.com/steve/2006/06/02/cell-segmentation/ Cell segmentation by Steve Eddins>
%
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
% 	background-color: #e0f5ff; 
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