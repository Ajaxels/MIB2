%% Microscopy Image Browser Watershed/Graphcut segmentation
% Tools for separation of objects that can be as materials of the current model, the mask or selection layers.
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
% 
%
%% General example
%
%
%
% <<images\menuToolsObjSep_Overview.jpg>>
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
% <li><b>Aspect ratio for 3D</b> indicates the aspect ratio of the dataset. These values are calculated from the voxel size of the dataset (available from the
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
% It allows to perform faster but with less details.
% <br><b>Attention!</b> Use of binning during 
% the <b>Object separation</b> mode may give unpredictable results</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
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
%% Object separation example
% The object separation with watershed can be used to separate big objects
% into smaller ones. For example, some mitochondria from the image
% segmentation example are fused together. It is possible to separate them
% using the _Object separation_ mode.
%
% * |Menu->Tools->Object separation|
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
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
