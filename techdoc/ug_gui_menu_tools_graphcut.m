%% Microscopy Image Browser Graphcut segmentation
% This window give access to semi-automated image segmentation using the
% maxflow/mincut graphcut method. 
%
%
% The *Graph cut* segmentation is based on <http://vision.csd.uwo.ca/code/ Max-flow/min-cut algorithm>
% written by Yuri Boykov and Vladimir Kolmogorov and implemented for Matlab by 
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
%
%% Mode panel
% The |Mode panel| offers possibility to select a desired working mode for
% the segmentation. 
%%
% 
% <html>
% <table style="width: 800px; border: 0px; line-height:150%">
% <tr>
% <td style="border: 0px">
%   <img src = "images\menuToolsGraphcut_Mode.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>2D, current slice only</b>, performs segmentation on the slice that is currently shown
% in <a href="ug_panel_im_view.html">the Image View panel</a></li>
% <li><b>2D, slice-by-slice</b>, performs 2D segmentation for each slice of the
% dataset individually</li>
% <li><b>3D, volume</b>, performs 3D segmentation for complete or selected portion (<em>see Selected Area section below</em>) of the dataset</li>
% <li><b>3D, volume, grid</b>, a special mode of 3D graphcut, where the dataset is chopped into several subvolumes (defined by Chop edit boxes, see below) and the dataset which is centered 
% at the Image View panel is gets segmented (for convenience, turn on the marker of the center point, <code>toolbar->center marker button</code>). Chopping of large volume into several small subvolumes (<em>e.g.</em>400x400x400 pixels allows effective interactive segmentation of this large volume
% To segment all subvolumes press the <b>Segment All</b> button</li>
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
% <table style="width: 800px; border: 0px; line-height:150%">
% <tr>
% <td style="border: 0px">
%   <img src = "images\menuToolsWatershed_Subarea.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>X:</b> defines the width of the dataset to process. Please use two numbers separated by a colon sign (:)</li>
% <li><b>Y:</b> defines the height of the dataset to process</li>
% <li><b>Z:</b> defines the z-slices of the dataset to process</li>
% <li><b>from Selection</b> button populates the <b>X:</b>, <b>Y:</b>, <b>Z:</b> fields
% using coordinates of a bounding box that describes the <em>Selection</em> layer</li>
% <li><b>Current View</b> button limits the *X:* and *Y:* parameters to the image
% that is currently displayed in the <a href="ug_panel_im_view.html"> Image View panel</a></li>
% <li><b>Reset</b> resets the Subarea fields to the dimensions of the dataset</li>
% <li><b>Bin x times</b> defines a binning factor for the data before segmentation. 
% It allows to perform faster but with less
% details. <br><b>Attention!</b> The auto update mode is not available for the binned datasets!</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
%% Calculation of superpixels/supervoxels
% Before the segmentation, the pixels of the opened dataset should be
% clustered using the SLIC or Watershed algorithms.
% The picture below shows comparison between two types of superpixels. The
% upper panels show the _SLIC superpixels_ that were good to segment a dark
% lipid droplet that has a good intensity contrast. The _Watershed
% superpixels_ gave better segmentation of objects  that were surrounded
% with boundaries.
%
% 
% <<images\menuToolsWatershedGraphcut_slic_vs_watershed.jpg>>
%
% 
% <<images\menuToolsGraphcut_Superpixels.jpg>>
%
% * *Size of superpixels*, defines approximate size of superpixels (_SLIC only_)
% * *Compactness*, a number between 1 and 99 that defines how square the
% superpixels should be; for example, 99 - results in quite square
% superpixels (_SLIC only_)
% * *Reduce number of superpixels*, a factor that is allowing to increase
% size of superpixels, the larger numbers results in larger superpixels (_Watershed only_)
% * *Color channel*, index of the color channel to be used for calculation
% of superpixels
% * *Type of signal*, use black-on-white for electron microscopy and
% light-on black for light microscopy
% * *Chop edit boxes*, allow to chop the dataset into smaller subvolumes for the *3D volume grid* mode
% or for calculation of the SLIC supervoxels
% * *autosave* checkbox - when enabled, the resulting graphcut structure
% with the generated supervoxels is automatically saved to disk for future
% use
% * *parfor* checkbox - when enabled, the Watershed clustering for the *3D volume grid* mode is
% calculated using the parallel processing, which improves calculation
% performance in several times
% * *use PixelIdsList* - when enabled, the generation of final models is
% based on detected indices of supervoxels. This mode may improve
% performance in some situations, but requires more memory
% % *Recalculate Graph* - allows to recalculate the graph using a new
% coefficient (|Coef|). In general, the larger coefficients give stronger
% growth from the seeds. Sometimes, however, the large coefficients results
% in segmentation of areas that are distant from the seeds, which is
% considered as an artefact of the method.
% * *Superpixels/Graph* press this button to initiate generation of superpixels and their final organization into a graph
% * *Import* press to import superpixels and the generated graph from a disk or Matlab
% * *Export* press to export superpixels and the generated graph to a file,
% Matlab, a new model or as Lines3D graph object (not recommended for many superpixels, see also here
% <https://youtu.be/xrsTVqD7kOQ https://youtu.be/xrsTVqD7kOQ>)
% * *Preview superpixels* the generated superpixels may be previewed by pressing this button
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
% <td style="border: 0px">
%   <img src = "images\menuToolsGraphcut_ImageSegmSettings.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>Background</b> defines a material of the model that labels the
% background areas</li>
% <li><b>Object</b> defines a material of the model that labels the
% object to be segmented</li>
% <li><b>Update lists</b> refreshes the lists of materials</li>
% <li><b>Auto update</b> - enables auto update of the segmentation results each time when material is modified. It is mostly useful for relatively small datasets (~400x400x400 pixels). 
%       <b><em>Important:</b></em> please do not use the <kbd>Shift+A</kbd> key shortcut, but only <kbd>A</kbd> shortcut. Also, when this mode is used it is recommended to 
%       recalculate the final segmentation by pressing the Segment button. Also the auto update mode is not available if the <b>Bin</b> mode is used.</li>
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
%   <img src = "images\watershed_imsegm_01.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li>Load a sample dataset: <em>Menu->File->Import image from->URL</em>, enter the address: http://mib.helsinki.fi/tutorials/WatershedDemo/watershed_demo1.tif</li>
% <li>Press the <b>+</b> button in the <a href="ug_panel_segm.html">Segmentation panel</a> to add material to the model and name is as 'Background' (use the right mouse button to call a popup menu)</li>
% <li>Use the brush tool to label an area that belongs to cytoplasm</li>
% </ul>
% </td>
% </tr>
% <tr><td colspan=2 style="border: 0px">
% <img src = "images\watershed_imsegm_02.jpg"> 
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <ul>
% <li>Press the <b>A</b> button to add selected area to the first material (Background) of the model</li>
% <li>Press the <b>+</b> button again to add another material and name it as 'Seeds'</li>
% <li>Draw labels inside mitochondria.</li>
% </ul>
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <img src = "images\watershed_imsegm_03.jpg"> 
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <ul>
% <li>Press the <b>A</b> button to add selected area to the second material (Seeds) of the model</li>
% <li>Start the Graphcut segmentation tool: <em>Menu->Tools->Semi-automatic segmentation->Graphcut</em>.</li>
% <li>Select the Watershed type of superpixels</li>
% <li>Make sure that the proper materials are selected for both Background and Object in the <em>Image segmentation settings</em></li>
% <li>Press the <b>Segment</b> button to segment mitochondria</li>
% <li>Add more seeds to the background and object materials to improve segmentaion</li>
% <li>Press the <b>Segment</b> button again of use the <b>Auto update</b> mode for instant update of the segmentation results</li>
% <li>The segmented mitochondria are placed to the <em>Mask</em> layer</li>
% <li>Optionally smooth mitochondria: <em>Menu->Mask->Smooth Mask</li>
% </ul>
% </td></tr>
% <tr><td colspan=2 style="border: 0px">
% <img src = "images\watershed_imsegm_04.jpg"> 
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
% * <http://www.mathworks.com/matlabcentral/fileexchange/21310-maxflow *Matlab
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
