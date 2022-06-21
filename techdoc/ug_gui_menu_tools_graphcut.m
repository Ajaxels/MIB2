%% Microscopy Image Browser Graphcut segmentation
% This window give access to semi-automated image segmentation using the
% maxflow/mincut graphcut method. 
%
%
% The *Graph cut* segmentation is based on <http://vision.csd.uwo.ca/code/ Max-flow/min-cut algorithm>
% written by Yuri Boykov and Vladimir Kolmogorov and implemented for MATLAB by 
% <http://www.mathworks.com/matlabcentral/fileexchange/21310-maxflow Michael Rubinstein>. 
% The max-flow/min-cut algorithm is applied not
% to individual pixels but to groups of pixels (superpixels (2D), or supervoxels(3D)) that may be generated either using
% the <http://ivrl.epfl.ch/research/superpixels *SLIC algorithm*> written by Radhakrishna Achanta, 
% Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine
% S?sstrunk or by the *Waterhed algorithm*. The objects that have intensity
% contrast are best described with the _SLIC superpixels_, while the objects
% that have distinct boundaries with the _Watershed superpixels_. Utilization of superpixels requires some time to calculate
% them but pays off during the following segmentation.
% 
%
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
% 
%%
%
% <<images\menuToolsGraphcut_Overview.jpg>>
%
%% General example
%
%
% <html>
% A demonstration of the Graphcut segmentation is available in the following video:<br>
% <a href="https://youtu.be/dMeoIZPaDS4"><img style="vertical-align:middle;" src="images\youtube2.png"><br>https://youtu.be/dMeoIZPaDS4</a>
% </html>
%
% [dtls][smry] *How to use* [/smry]
% 
% <<images\menuToolsWatershedGraphcut.jpg>>
% 
%
% How to use:
% 
% # Use two labels to mark areas that belong to background and the objects of interest
% # Start the Graphcut segmentation tool: _Menu->Tools->Semi-automatic segmentation Graphcut_
% # Set one of the modes: _2D/3D_
% # Define type of superpixels/supervoxels: _SLIC_, or _Watershed_
% # Generate superpixels/supervoxels (_Press the *Superpixels/Graph* button_)
% # Check the size of the generated superpixels and modify the size if needed
% # Press the *Segment* button to start segmentation
%
% *Note!* some functions have to be compiled, please check the <im_browser_system_requirements.html System
% Requirements page> for details.
%
% [/dtls]
% [br8]
%
%% Mode panel
% The |Mode panel| offers possibility to select a desired working mode for
% the segmentation. 
% 
% <html>
% <table style="width: 800px; border: 0px; line-height:150%">
% <tr>
% <td style="border: 0px; width: 180px">
%   <img src="images\menuToolsGraphcut_Mode.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><span class="kbd">&#9673; <b>2D, current slice only</b></span>, performs segmentation on the slice that is currently shown
% in <a href="ug_panel_im_view.html">the Image View panel</a></li>
% <li><span class="kbd">&#9673; <b>2D, slice-by-slice</b></span>, performs 2D segmentation for each slice of the
% dataset individually</li>
% <li><span class="kbd">&#9673; <b>3D, volume</b></span>, performs 3D segmentation for complete or selected portion (<em>see Selected Area section below</em>) of the dataset</li>
% <li><span class="kbd">&#9673; <b>3D, volume, grid</b></span>, a special mode of 3D graphcut, where the dataset is chopped into several subvolumes (defined by Chop edit boxes, see below) and the dataset which is centered 
% at the Image View panel is gets segmented (for convenience, turn on the marker of the center point, <span class="code">toolbar->center marker button</span> 
% <img src="images\toolbar_center_marker.jpg">). Chopping of large volume into several small subvolumes (<em>e.g.</em>400x400x400 pixels allows effective interactive segmentation of this large volume
% To segment all subvolumes press the <span class="kbd">Segment All</span> button</li>
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
% <html>
% <table style="width: 800px; border: 0px; line-height:150%">
% <tr>
% <td style="border: 0px; width: 180px">
%   <img src="images\menuToolsWatershed_Subarea.jpg">
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
% details. <br><b>Attention!</b> The auto update mode (<span class="kbd">[&#10003;] <b>auto update</b></span>) is not available for the binned datasets!</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% [br8]
% 
%% Calculation of superpixels/supervoxels
%
% Before the segmentation, the pixels of the opened dataset should be
% clustered using the SLIC or Watershed algorithms.
% The picture below shows comparison between two types of superpixels. The
% upper panels show the _SLIC superpixels_ that were good to segment a dark
% lipid droplet that has a good intensity contrast. The _Watershed
% superpixels_ gave better segmentation of objects  that were surrounded
% with boundaries.
%
% [dtls][smry] *Image example of clusters* [/smry]
% 
% <<images\menuToolsWatershedGraphcut_slic_vs_watershed.jpg>>
%
% [/dtls]
% 
% <<images\menuToolsGraphcut_Superpixels.jpg>>
%
% * [class.dropdown]Superpixels &#9660;[/class], define type of superpixels to use
% * [class.dropdown]Size of superpixels...[/class], defines approximate size of superpixels (_SLIC only_)
% * [class.dropdown]Compactness...[/class], a number between 1 and 99 that defines how square the
% superpixels should be; for example, 99 - results in quite square superpixels (_SLIC only_)
% * [class.dropdown]Reduce number of superpixels...[/class], a factor that is allowing to increase
% size of superpixels, the larger numbers results in larger superpixels (_Watershed only_)
% * [class.dropdown]Color channel &#9660;[/class], index of the color channel to be used for calculation of superpixels
% * [class.dropdown]Type of signal &#9660;[/class], use black-on-white for electron microscopy and
% light-on black for light microscopy
% * The [class.dropdown]Chop...[/class]editboxes, allow to chop the dataset into smaller subvolumes for the [class.kbd]&#9673; *3D volume grid*[/class] mode
% or for calculation of the SLIC supervoxels
% * The [class.kbd][&#10003;] *autosave*[/class] checkbox - when enabled, the resulting graphcut structure
% with the generated supervoxels is automatically saved to disk for future use
% * The [class.kbd][&#10003;] *parfor*[/class] checkbox - when enabled, the Watershed clustering for the *3D volume grid* mode is
% calculated using the parallel processing, which improves calculation
% performance in several times
% * [class.kbd][&#10003;] *use PixelIdsList*[/class] - when enabled, the generation of final models is
% based on detected indices of supervoxels. This mode may improve
% performance in some situations, but requires more memory
% % [class.kbd]Recalculate Graph[/class] - allows to recalculate the graph using a new
% coefficient (|Coef|). In general, the larger coefficients give stronger
% growth from the seeds. Sometimes, however, the large coefficients results
% in segmentation of areas that are distant from the seeds, which is
% considered as an artefact of the method.
% * [class.kbd]Superpixels/Graph[/class] press this button to initiate generation of superpixels and their final organization into a graph
% * [class.kbd]Import[/class] press to import superpixels and the generated graph from a disk or MATLAB
% * [class.kbd]Export[/class] press to export superpixels and the generated graph to a file,
% MATLAB, a new model or as Lines3D graph object (not recommended for many superpixels, see also here
% https://youtu.be/xrsTVqD7kOQ)
% * [class.kbd]Preview superpixels[/class] the generated superpixels may be previewed by pressing this button
%
%
%% Image segmentation settings
% Both the <ug_gui_menu_tools_watershed.html *Watershed*> and *Graphcut* workflows use provided labels that
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
% <table style="width: 800px; border: 0px; line-height:150%">
% <tr>
% <td style="border: 0px; width:400px">
%   <img src="images\menuToolsGraphcut_ImageSegmSettings.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><span class="dropdown">Background &#9660;</span> defines a material of the model that labels the
% background areas</li>
% <li><span class="dropdown">Object &#9660;</span> defines a material of the model that labels the
% object to be segmented</li>
% <li><span class="kbd">Update lists</span> refreshes the lists of materials</li>
% <li><span class="kbd">[&#10003;] <b>Auto update</b></span> - enables auto update of the segmentation results each time when material is modified. 
% It is mostly useful for relatively small datasets (~400x400x400 pixels). 
%       <br><b><em>Important:</b></em> please do not use the <span class="kbd">&#8679; Shift+A</span> key shortcut, but only <span class="kbd">A</span> shortcut. 
%       Also, when this mode is used it is recommended to 
%       recalculate the final segmentation by pressing the <span class="kbd">Segment</span> button. Also the auto update mode is not available if the <b>Bin</b> mode is used.</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
%% Image segmentation example
%
% <html>
% <table style="width: 800px; border: 0px; line-height:150%">
% <tr>
% <td style="border: 0px">
%   <img src="images\watershed_imsegm_01.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li>Load a sample dataset: <span class="code">Menu->File->Import image
% from->URL</span>, enter the address:<br>
% http://mib.helsinki.fi/tutorials/WatershedDemo/watershed_demo1.tif</li>
% <li>Press the <span class="kbd"><b>+</b></span> button in the <a href="ug_panel_segm.html">Segmentation panel</a> to add material to the model and name is as 'Background' (use the right mouse button to call a popup menu)</li>
% <li>Use the brush tool to label an area that belongs to cytoplasm</li>
% </ul>
% </td>
% </tr>
% <tr><td colspan=2 style="border: 0px">
% <img src="images\watershed_imsegm_02.jpg"> 
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <ul>
% <li>Press the <span class="kbd"><b>A</b></span> button to add selected area to the first material (Background) of the model</li>
% <li>Press the <span class="kbd"><b>+</b></span> button again to add another material and name it as 'Seeds'</li>
% <li>Draw labels inside mitochondria.</li>
% </ul>
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <img src="images\watershed_imsegm_03.jpg"> 
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <ul>
% <li>Press the <span class="kbd"><b>A</b></span> button to add selected area to the second material (Seeds) of the model</li>
% <li>Start the Graphcut segmentation tool: <span class="code">Menu->Tools->Semi-automatic segmentation->Graphcut</span>.</li>
% <li>Select the <span class="dropdown">Watershed &#9660;</span> type of superpixels</li>
% <li>Make sure that the proper materials are selected for both Background and Object in the <em>Image segmentation settings</em></li>
% <li>Press the <span class="kbd">Segment</span> button to segment mitochondria</li>
% <li>Add more seeds to the background and object materials to improve segmentaion</li>
% <li>Press the <span class="kbd">Segment</span> button again of use the <span class="kbd">[&#10003;] <b>Auto update</b></span> mode 
% for instant update of the segmentation results</li>
% <li>The segmented mitochondria are placed to the <em>Mask</em> layer</li>
% <li>Optionally smooth mitochondria: <span class="code">Menu->Mask->Smooth Mask</span></li>
% </ul>
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <img src="images\watershed_imsegm_04.jpg"> 
% </td></tr>
% </table>
% </html>
%
%% References
% 
% Graph Cut:
%
% * <http://vision.csd.uwo.ca/code/ *Max-flow/min-cut algorithm*> written by Yuri Boykov and Vladimir Kolmogorov (*_Please note that this algorithm is licensed only
% for research purposes_*). 
% * <http://www.mathworks.com/matlabcentral/fileexchange/21310-maxflow *MATLAB
% wrapper*> for maxflow is written by Michael Rubinstein.
% * <http://ivrl.epfl.ch/research/superpixels *SLIC superpixels and supervoxels*> by Radhakrishna Achanta, 
% Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine S?sstrunk. 
% * <http://www.mathworks.com/matlabcentral/fileexchange/16938-region-adjacency-graph--rag- *Region Adjacency Graph (RAG)*> and its modification for watershed 
% was written by David Legland, INRA, France, 2013-2015 and was used in
% calculation of adjusent superpixels
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
%
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