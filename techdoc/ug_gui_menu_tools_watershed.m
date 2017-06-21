%% Microscopy Image Browser Watershed/Graphcut segmentation
% This window give access to semi-automated image segmentation and object
% separation modes. The image segmentation can be done either using a
% standard watershed algorithm (*Watershed workflow*) or using the Graphcut segmentation 
% (*Graph Cut workflow*). We recommend to use the *Graphcut workflow* due
% to its high interactive efficiency. The *Object separation workflow* allows
% to separate fused objects in both 2D and 3D. See below details of each
% mode.
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
% 
%
%% General example
%
%
% <html>
% A demonstration of the Graphcut segmentation is available in the following video:<br>
% <a href="https://youtu.be/dMeoIZPaDS4"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/dMeoIZPaDS4</a>
% </html>
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
% <td style="border: 0px">
%   <img src = "images\menuToolsWatershed_Mode.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>2D, current slice only</b>, performs segmentation on the slice that is currently shown
% in <a href="ug_panel_im_view.html">the Image View panel</a></li>
% <li><b>2D, slice-by-slice</b>, performs 2D segmentation for each slice of the
% dataset individually</li>
% <li><b>3D, volume</b>, performs 3D segmentation for complete or selected portion (<em>see Selected Area section below</em>) of the dataset</li>
% <li><b>Aspect ratio for 3D</b> indicates the aspect ratio of the dataset (only for the <b>Watershed</b> and <b>Object separation</b>
% modes). These values are calculated from the voxel size of the dataset (available from the
% <a href="ug_gui_menu_dataset.html#8">Menu->Dataset->Parameters</a>). The aspect ratio
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
% details during the <b>Watershed</b> and <b>Graph Cut</b> modes. 
% <br><b>Attention!</b> Use of binning during 
% the <b>Object separation</b> mode may give unpredictable results</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
%% Image segmentation settings (_for the Watershed and Graphcut workflows_)
% Both the *Watershed* and *Graphcut* workflows use provided labels that
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
% <td style="border: 0px">
%   <img src = "images\menuToolsWatershed_Imsegm.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>Color channel</b> defines a color channel that will be used for 
% segmentation</li>
% <li><b>Background</b> defines a material of the model that labels the
% background</li>
% <li><b>Object</b> defines a material of the model that labels the
% object to be segmented</li>
% <li><b>Type of signal</b> defines type of the data: 'black-on-white', when the
% objects are separated with dark boundaries and 'white-on-black' for the
% bright boundaries</li>
% <li><b>Update lists</b> refreshes the lists of materials</li>
% <li><b>Optional pre-processing (only for the Watershed workflow)</b>
%   <ul style="margin-left: 60px">
%   <li><b>Gradient</b> filters the image before watershed using the
%       Gradient filter to create borders around objects</li>
%   <li><b>Eigenvalue of Hessian</b>, pre-processing the data using this option may sometimes be beneficial for the following watershed transfornation. Use the <b>Sigma</b> fields to fine-tune the filter</li>
%   <li><b>Export to Matlab</b> exports pre-processed data to the main Matlab workspace</li>
%   <li><b>Preview</b> shows the result of pre-processing in the Image View panel</li>
%   <li><b>Import from Matlab</b> imports dataset that will be used for image segmentation from Matlab workspace</li>
%   <li><b>Pre-process</b> starts the data pre-processing process. When pre-processed data is present the color of the button turns to green</li>
%   <li><b>Clear</b> removes the pre-processed data from the memory</li>
%   </ul>
% </li>
% </td>
% </tr>
% <tr>
% <td style="border: 0px">
%   <img src = "images\menuToolsWatershedGraphcutSettings.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>Details panel (only for the Graphcut workflow)</b>
%   <ul style="margin-left: 60px">
%   <li><b>Type of superpixels</b> define type of the superpixels/supervoxels to calculate. 
%          The <em>SLIC</em> mode is most suitable for objects that have distinct contrast, 
%          while the <em>Watershed</em> mode is the best for objects that have distinct boundaries (in fact, the objained results are very close to those objained with the <b>Watershed workflow</b>)</li>
%   <li><b>Size of superpixels</b>, (<em>only for the SLIC superpixels</em>) defines the desired number of pixels that are clustered into a superpixel</li>
%   <li><b>Compactness</b>, (<em>only for the SLIC superpixels</em>), a number from 0 (line) to 100 (rectangle) that defines the resulting shape of superpixels</li>
%   <li><b>Reduce number of superpixels</b>, (<em>only for the Watershed superpixels</em>), a number that defines a factor that reduces number of superpixels. The larger number in this field results in the larger superpixels</li>
%   <li><b>Chop</b>, (<em>only for the SLIC superpixels</em>), calculation
%   of SLIC superpixels requires large amounts of memory. If memory is
%   insufficient for the calculation the dataset can be chopped and the
%   superpixels calculated for each of the chopped parts individually
%   <li><b>Autosave</b>, autosave results after calculation of superpixels is finished
%   <li><b>Superpixels/Graph</b> press of this button initiate generation of superpixels and their final organization into a graph</li>
%   <li><b>Recalculate Graph</b> allows to recalculate the graph using a new coefficient (|Coef|). In general, the laeger coefficients give stronger growth from the seeds</li>
%   <li><b>Preview superpixels</b> the generated superpixels may be previewed by pressing this button</li>
%   <li><b>Export</b> press to export superpixels and the generated graph to a disk or Matlab</li>
%   <li><b>Import</b> press to import superpixels and the generated graph from a disk or Matlab</li>
%   </ul>
% </li>
% </td>
% </tr>
% </table>
% </html>
% 
%% Graph cut segmentation settings
% The *Graph cut* segmentation is based on <http://vision.csd.uwo.ca/code/ Max-flow/min-cut algorithm>
% written by Yuri Boykov and Vladimir Kolmogorov and implemented for Matlab by 
% <http://www.mathworks.com/matlabcentral/fileexchange/21310-maxflow Michael Rubinstein>. 
% The max-flow/min-cut algorithm is applied not
% to individual pixels but to groups of pixels (superpixels (2D), or supervoxels(3D)) that may be generated either using
% the <http://ivrl.epfl.ch/research/superpixels *SLIC algorithm*> written by Radhakrishna Achanta, 
% Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine
% Süsstrunk or by the *Waterhed algorithm*. The objects that have intensity
% contrast are best described with the _SLIC superpixels_, while the objects
% that have distinct boundaries with the _Watershed superpixels_. Utilization of superpixels requires some time to calculate
% them but pays off during the following segmentation.
%
% 
% <<images\menuToolsWatershedGraphcut_slic_vs_watershed.jpg>>
%
%
% The picture above shows comparison between two types of superpixels. The
% upper panels show the _SLIC superpixels_ that were good to segment a dark
% lipid droplet that has a good intensity contrast. The _Watershed
% superpixels_ gave better segmentation of objects  that were surrounded
% with boundaries.
%
% 
% <<images\menuToolsWatershedGraphcut.jpg>>
% 
%
% How to use:
% 
% # Use two labels to mark areas that belong to background and the objects of interest
% # Start the Watershed/Graphcut segmentation tool: _Menu->Tools->Watershed/Graphcut segmentation_
% # Set one of the modes: _2D/3D_
% # Generate superpixels/supervoxels (_Press the *Superpixels/Graph_ button)
% # Check the size of the generated superpixels and modify the size if needed
% # Press the *Segment* button to start segmentation
%
% *Note!* some functions have to be compiled, please check the <im_browser_system_requirements.html System
% Requirements page> for details.
%
%% Object separation settings
% The *Object separation* mode uses the watershed transformation to brake
% segmented objects into smaller ones. 
% The specific settings for the *Object separation* mode are shown below.
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\menuToolsWatershed_Objsep.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>Object to watershed</b> defines a layer that contains a source object for separation. It could be one of the main layers: <em>Selection, Mask, or Model</em></li>
% <li><b>Use seeds</b> when enabled targets algorithm to the seeded watershed transformation. Some parameters should be additionally specified in the <em>Seeds panel</em></li>
% <li><b>Reduce oversegmentaion</b> (<em>available only for the unseeded watershed transformation</em>) decreases number of resulting objects</li>
% <li><b>Seeds panel</b> (<em>only for the seeded watershed transformation</em>)
%   <ul style="margin-left: 60px">
%   <li><b>Layer with seeds</b> defines a layer that contains seeds. It could be one of the main layers: <em>Selection, Mask, or Model</em></li>
%   <li><b>Watershed source</b> defines type of the information that watershed will use for labeling. 
%          When the <b>Image intensity</b> option is selected watershed is using actual image intensities rather than the distance maps. 
%          <a href="http://blogs.mathworks.com/steve/2006/06/02/cell-segmentation/">See more in the Steve Eddins's blog on Image Processing.</a></li>
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
% <li>Start the Watershed segmentation tool: <em>Menu->Tools->Watershed/Graphcut segmentation</em>.</li>
% <li>Make sure that the proper materials are selected for both Background and Object in the <em>Image segmentation settings</em></li>
% <li>Press the <b>Segment</b> button to segment mitochondria</li>
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
%% Object separation example
% The object separation with watershed can be used to separate big objects
% into smaller ones. For example, some mitochondria from the image
% segmentation example are fused together. It is possible to separate them
% using the _Object separation_ mode.
%
% * Press the *Object separation* button to enable this mode
% * Select *Mask* in the *Objects to watershed*
% * Press the *Segment* button
%
%
% 
% <<images\watershed_imsegm_05.jpg>>
% 
% Now the mitochondria are separated, but unfortunately, as usual with
% watershed, long mitochondria are broken into several small pieces as well.
% To deal with that the seeded watershed can be used.
%
% * Press the *Use seeds* checkbox
% * Choose *Model, select material* -> 'Seeds' in the *Layer with seeds*
% panel
% * Press the *Segment button*
% * If there is only one label in each mitochondria the individual
% mutochondria should be extracted (shown in green)
%
% 
% <<images\watershed_imsegm_06.jpg>>
%
%% Algorithm for image segmentation with watershed
%
% 
% <<images\menuToolsWatershedGraphcut_img_segm_alg.jpg>>
% 
%% Algorithm for object separation with watershed
%
% <<images\menuToolsWatershed_obj_sep_alg.jpg>>
%
%% References
% 
% Watershed: the Image segmentation and Object separation modes: 
%
% * <http://blogs.mathworks.com/steve/2013/11/19/watershed-transform-question-from-tech-support/ Watershed transform question from tech support by Steve Eddins>
% * <http://blogs.mathworks.com/steve/2006/06/02/cell-segmentation/ Cell segmentation by Steve Eddins>
%
% Graph Cut:
%
% * <http://vision.csd.uwo.ca/code/ Max-flow/min-cut algorithm> written by Yuri Boykov and Vladimir Kolmogorov (*_Please note that this algorithm is licensed only
% for research purposes_*). 
% * <http://www.mathworks.com/matlabcentral/fileexchange/21310-maxflow Matlab
% wrapper> for maxflow is written by Michael Rubinstein.
% * <http://ivrl.epfl.ch/research/superpixels SLIC superpixels and supervoxels> by Radhakrishna Achanta, 
% Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine Süsstrunk. 
% * <http://www.mathworks.com/matlabcentral/fileexchange/16938-region-adjacency-graph--rag- *Region Adjacency Graph (RAG)*> and its modification for watershed 
% was written by David Legland, INRA, France, 2013-2015 and was used in
% calculation of adjusent superpixels
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
