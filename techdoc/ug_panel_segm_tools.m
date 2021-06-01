%% Segmentation Tools
% This panel hosts different tools that are used for the image
% segmentation. 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| 
% <ug_gui_panels.html *Panels*> |*-->*| <ug_panel_segm.html *Segmentation Panel*>
%
% 
%% The 3D ball
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationTools3DBall.png">
% </td>
% <td style="border: 0px">
% Makes selection as a spherical object in the 3D space with a radius taken from the
% <b>Radius, px</b> edit box. The <b>Eraser, x</b> edit box modifies
% increse of the 3D ball eraser, when holding the Clrl key.<br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=1s"><img
% style="vertical-align:middle;" src="images\youtube2.png">
% https://youtu.be/ZcJQb59YzUA?t=1s</a><br><br>
% <br><br>
% <b>Note!</b> The 3D shape of the ball is defined by the
% pixel dimensions, see <em>Dataset Parameters</em> in <a href="ug_gui_menu_dataset.html">Menu->Dataset->Parameters</a>.
% <br><br>
% <b>Selection modifiers</b>
% <ul>
% <li><b>None / Shift+left mouse click</b>, will add selection with the existing one</li>
% <li><b>Ctrl + left mouse click</b>, will remove selection from the current</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
%% The 3D lines
%
% <html>
% A demonstration is available on youtube:<br>
% <a href=""><img style="vertical-align:middle;" src="images\youtube2.png">
% https://youtu.be/DNRUePJiCbE</a><br>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationTools3DLines.png">
% </td>
% <td style="border: 0px">
% The 3D lines tool can be used to draw lines in 3D and arrange them as
% graphs or skeletons. The 3D lines composed of Nodes (Vertices) 
% connected with Edges (a line that connect two nodes). Separated from each
% other sets of 3D lines organized into separate trees. 
% <br><br>
% Modification of nodes is possible using mouse clicks. To increase
% flexibility, the clicks can be extended with key-modifiers, such as
% <em>Shift, Control, Alt</em>. Each action can be configured depending on
% needs. Please refer to a table below for various options:
% <br><br>
% <b>Available actions</b>
% <ul>
% <li><b>Add node</b>, add a new node to the active tree; the new point will be connected to the active point (shown in red) of the tree</li>
% <li><b>Assign active node</b>, assign the closest node to position of the mouse click, as a new active node</li>
% <li><b>Connect to node</b>, connect active node to another existing node</li>
% <li><b>Delete node</b>, delete the closest node to position of the mouse click; the edges will be rearranged to prevent splitting of the tree</li>
% <li><b>Insert node after active</b>, insert a new node after the active node</li>
% <li><b>Modify active node</b>, change position of the active node</li>
% <li><b>New tree</b>, add a new node and assign it to a new tree, which is not connected to other trees</li>
% <li><b>Split tree</b>, delete the closest node to position of the mouse click and split the tree at this point</li>
% </ul>
% Use the <b>Show lines</b> checkbox to toggle visibility of the lines in
% the Image View panel.
% <br>
% Press the <b>Table view</b> button to start a window which tables that
% describe the 3D lines (see below).
% <br><br>
% </td>
% </tr>
% </table>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationTools3DLinesDlg.png">
% <br><br>
% <b>Tools panel</b><br>
% <ul>
% <li><b>Load</b>, load 3D lines from a file in matlab-compatible lines3d format</li>
% <li><b>Save</b>, export to Matlab or save 3D lines to a file:
%   <ul>
%   <li><b>Matlab format, *.lines3d</b>, it is recommended to save the 3D lines in the matlab format!</li>
%   <li><b>Amira Spatial graph, *.am</b>, Amira-compatible format in binary or ascii form</li>
%   <li><b>Excel format, *.xls</b>, export Nodes and Edges tables to an Excel file</li>
%   </ul>
% </li>
% <li><b>Refresh</b>, refresh the tables shown in this window</li>
% <li><b>Delete all</b>, delete all 3D lines</li>
% <li><b>Visualize in 3D</b>, plot all trees in the 3D space</li>
% <li><b>Settings</b>, modify color and thickness of 3D lines</li>
% </ul>
% </td>
% <td style="border: 0px">
% <b>Table with the list of trees</b><br>
% The upper table shows the list of trees and number of nodes that compose
% each tree. <b><em>Each tree should have an unique name!</b></em><br><br>
% Right mouse click starts a popup menu with various options:
% <ul>
% <li><b>Rename selected tree...</b>, rename selected in the table tree; tree name should be unique!</li>
% <li><b>Find tree by node...</b>, find a tree which has a node with provided index</li>
% <li><b>Visualize in 3D selected tree(s)</b>, plot the selected trees in 3D</li>
% <li><b>Save/export selected tree(s)</b>, export to Matlab or save to a file the selected trees, see the Tools panel below for the list of available file formats</li>
% <li><b>Delete selected tree(s)</b>, delete selected tree from the table</li>
% </ul>
% <br><br>
% <b>Space between the tables</b><br>
% <ul>
% <li><b>Active tree</b>, an index of the active tree</li>
% <li><b>Active node</b>, an index of the active node</li>
% <li><b>Table</b>, a combo box to select what should be shown in the lower table: Nodes or Edges</li>
% <li><b>Field</b>, a combo box to define an additional field that should be shown the lower table. By default, only the Radius and Weights fields are available</li>
% <li><b>Auto jump</b>, when selected, auto jump to the selected node</li>
% <li><b>Auto refresh</b>, automatically refresh the tables, may be quite slow with many nodes</li>
% </ul>
% <br>
% <b>Nodes table</b><br>
% The table shows list of nodes and offers multiple actions via a popup
% menu:
% <ul>
% <li><b>Jump to the node</b>, jumps to the selected node and put it in the center of the Image View panel</li>
% <li><b>Set as active node</b>, makes the selected node active</li>
% <li><b>Rename selected nodes...</b>, assign a new name for the selected nodes</li>
% <li><b>Show coordinates in pixels...</b>, by default, the coordinates of the nodes are shown in the physical units of the dataset, <em>i.e.</em> with respect to <a href="ug_gui_menu_dataset.html#8">the bounding box</a>; this action shows coordinate of the node in pixels</li>
% <li><b>New annotations from nodes</b>, generate a new annotations from the position of nodes</li>
% <li><b>Add nodes to annotations</b>, add selected nodes to the existing annotations</li>
% <li><b>Delete nodes from annotations</b>, delete selected nodes from the existing annotations</li>
% <li><b>Delete nodes...</b>, delete selected nodes</li>
% </ul>
% <br>
% <b>Edges table</b><br>
% The table shows list of edges; certain actions available via a popup menu:
% <ul>
% <li><b>Jump to the node</b>, jumps to the selected node and put it in the center of the Image View panel</li>
% <li><b>Set as active node</b>, makes the selected node active</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
%% Annotations
%
% <html>
% A brief demonstration is available in the following videos:<br>
% <a href="https://youtu.be/3lARjx9dPi0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/3lARjx9dPi0</a>
% <br>
% <a href="https://youtu.be/3lARjx9dPi0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/6otBey1eJ0U</a>
% <br>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsAnnotations.png">
% </td>
% <td style="border: 0px">
% A set of tools to add/remove annotations. Each annotation allows to mark specific location in the dataset, assign a label and a value to it<br><br>
% When the Annotation tool is selected the mouse click above the image adds annotation to the model.
% The annotations can be removed by using <em>Ctrl + left mouse click</em> combination.
% <br>
% <ul>
% <li>The <b>Annotation list</b> button starts a window with the list of existing
% annotations. It is possible to load and save annotations to the main Matlab
% workspace or to a file (matlab and excel formats). See more below.</li>
% <li>The <b>Delete All</b> button removes all annotations
% <li><b>Precision</b> edit box - specify number of digits after decimal
% point</li>
% <li>The <b>Display as</b> combobox - enables way how the annotations are
% displayed in the <a href="ug_panel_im_view.html">Image View panel</a>. 
    % <ul>The following modes are available:<br><br>
    % <li><b>Marker</b>, show only location of the annotation using a cross-marker</li>
    % <li><b>Label</b>, show marker and label for each annotation</li>
    % <li><b>Value</b>, show marker and value for each annotation</li>
    % <li><b>Label + Value</b>, show marker, label and value for each annotation</li>
    % </ul>
% </li>
% <li><b>Focus on Value</b> checkbox, when enabled, the first parameter during visualization of annotations is
% value and the second parameter is label.
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% <html>
% <b>List of annotations window</b>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsAnnotationsTable.png">
% </td>
% <td style="border: 0px">
% <ul>
% <li>The <b>List of annotations</b> table shows a list of annotations. 
%   <ul>The <em>right mouse button</em></b> click calls an additional popup menu that allows to 
%       <li><em><b>Jump to annotation</em></b>, moves the image so that the selected annotation is in the middle of the Image View panel</li>
%       <li><em><b>Add annotation</em></b>, manually add annotation to the list, position of the first and second fields are defined by the <em>Value eccentric</em> checkbox of the Annotation panel, see above</li>
%       <li><em><b>Rename selected annotations</em></b>, rename names of the selected annotations</li>
%       <li><em><b>Batch modify selected annotations</em></b>, modify annotation values or coordinates using a provided expression</li>
%       <li><em><b>Count selected annotations</em></b>, calculate occurance of each annotation in the list of selected annotations. 
%           The results are displayed in the Matlab command window and
%           copied to the system clipboard 
%           <a href="https://youtu.be/rqZbH3Jpru8"><img style="vertical-align:middle;" src="images\youtube.png"></a>
%           </li>
%       <li><em><b>Copy selected annotations to clipboard</em></b>, the selected annotations are copied to the system clipboard as a text string ready to be pasted to Excel</li>
%       <li><em><b>Export selected annotations</em></b>, export selected annotations in the Matlab format, landmarks for Amira (<em><b>Note!</em> only the coordinates are exported to Amira!</b>), PSI format for Amira and Excel</li>
%       <li><em><b>Export selected annotations to Imaris</em></b>, export selected annotations to Imaris (<em><b>Note!</em> please first export the dataset!</b>)</li>
%       <li><em><b>Order</b></em>, subitems of the Order entry can be used to move annotations towards the top or the bottom of the list</li>
%       <li><em><b>Delete annotation</em></b>, delete selected annotations from the list</li>
%   </ul>
% <li>The <b>Load</b> button, press to import annotations from the main Matlab workspace or load them from a file</li>
% <li>The <b>Save</b> button, press to export annotations to the main Matlab workspace or to save them as a file in Matlab, Comma-separated CSV format, Excel formats or as landmarks for Amira (
%           <a href="https://youtu.be/wHr6nHpmVMo"><img style="vertical-align:middle;" src="images\youtube.png"></a> <em><b>Note!</em> only the coordinates are exported!</b>), or PSI format for Amira</li>
% <li>The <b>Precision</b> editbox, modify precision of the value field in the table and for the visualization in the Image View panel
% <li>The <b>Auto jump</b> checkbox - when enabled, the image in the <a href="ug_panel_im_view.html">Image View panel</a> is automatically shifted, thereby placing the selected annotation at the center of the image</li>
% <li>The <b>Sort table</b> allows to sort annotations based on their Name, Value, X, Y, Z, T</li>
% <li>The <b>Settings</b> provides configuration of additional settings: extra slices to display annotation, when this value 0 annotations only belonging to the current slice are displayed, when a positive number from -value to +value depth</li>
% <li>The <b>Refresh table</b> button updates the list of annotations</li>
% <li>The <b>Delete all</b> button removes all annotations</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
%% The Brush tool 
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsBrush.png">
% </td>
% <td style="border: 0px">
% Use brush to make selection. The brush size is regulated with
% the <b>Radius, px</b> edit box
% <br>
% A brief demonstration is available in the following videos:<br>
% <a href="https://youtu.be/VlTCxVAUxFc"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/VlTCxVAUxFc</a>
% <a href="https://youtu.be/ZcJQb59YzUA?t=37s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=37s</a>
% <br>
% <br><br>Objects from different image slices may be connected
% using the <em>Interpolation</em> function (shortcut <b>i</b> or via <em>Menu->Selection->Interpolate</em>),
% see more in the <a href="ug_gui_menu_selection.html">Selection menu</a> section.
% <br><br>
% Size of the Brush can be regulated using <em>Ctrl + Mouse wheel</em>.
% <br><br>
% <b>Selection modifiers</b>
% <ul>
% <li><b>None / Shift + left mouse click</b>, will add selection with the existing one </li>
% <li><b>Ctrl + left mouse click</b>, will remove selection from the
% current, <em>i.e.</em> eraser mode</li>The radius of the brush in the
% eraser mode could be amplifier using the <b>Eraser, x</b> edit box.
% </ul>
% <br>
% <b>Interpolation settings</b>, press to start a dialog that allows to
% modify the interpolation settings. The settings can also be modified from
% the <a href="ug_gui_menu_file_preferences.html">Preference dialog</a> and the type can be switched
% using a dedicated button in the <a href="ug_gui_toolbar.html">toolbar</a>.<br>
% <img src="images\PanelsSegmentationToolsBrushInterpolation.png">
% </td>
% </tr>
% </table>
% <br>
% <h3>Superpixels with the Brush tool</h3>
% </html>
%
% *The Superpixels mode* can be initiated by selecting the <https://youtu.be/vVh1j3HBh-c *Watershed*> or <https://youtu.be/6bZb_Mr_nS0?list=PLGkFvW985wz8cj8CWmXOFkXpvoX_HwXzj *SLIC*> checkbox. In the 
% Superpixels mode the brush tool selects not individual pixels but rather
% groups of pixels (superpixels). While drawing the selection of the last superpixel can
% be undone by pressiong the *|Ctrl+Z|* shortcut.
% 
% The superpixels are calculated using the 
%
% 
% * *SLIC* (Simple Linear Iterative Clustering, good for objects with distinct intensities) algorithm written by
% <http://ivrl.epfl.ch/supplementary_material/RK_SLICSuperpixels/index.html
% Radhakrishna Achanta et al., 2015> , Ecole Polytechnique Federale de
% Lausanne (EPFL), Switzerland. 
% * *Watershed* (good for objects with distinct boundaries).
% 
% The two additional edit boxed (|N|, |Compact/Invert|) offer possibility
% to modify the size of generated superpixels (_see below_). The values in
% the |N| edit box can be changed using the *_Ctrl+Alt + mouse wheel_* or
% *_Ctrl+Alt+Shift + mouse wheel_* shortcuts.
%
% References:
%%
% 
% * Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine S?sstrunk, SLIC Superpixels Compared to State-of-the-art Superpixel Methods, IEEE Transactions on Pattern Analysis and Machine Intelligence, vol. 34, num. 11, p. 2274 - 2282, May 2012.
% * Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine S?sstrunk, SLIC Superpixels, EPFL Technical Report no. 149300, June 2010.
% 
%%
% 
% <<images\PanelsSegmentationToolsBrushSupervoxels.jpg>>
% 
% The set of superpixels is individual for each magnification (especially in the _SLIC_ mode). It is
% possible to define size of superpixels (the |N| edit box, default
% value 220 for SLIC, for Watershed use lower numbers) and compactness (the |Compact| edit box; higher compactness
% gives more rectangularly shaped superpixels). In the _Watershed_ mode the
% |Compact| edit box is called |Invert|; when objects have dark boundaries
% over bright backround number in the |Invert| edit box should be 1 (or
% higher), if the objects have bright boundaries over dark background this
% number should be 0.
%
% During drawing the boundaries of the superpixels for the SLIC mode are shown using the _drawregionboundaries.m_ function written by <http://www.peterkovesi.com/projects/segmentation/ Peter Kovesi>
% Centre for Exploration Targeting, School of Earth and Environment, The
% University of Western Australia.
%
% *Note 1!* The Superpixels mode is sensitive to the |Adapt.| checkbox in
% the |Selection panel|. When the |Adapt.| checkbox is selected the
% superpixels are selected based on the _mean value_ of the initial
% selection _plus/minus_ standard deviation within the same area multiplied
% by the factor specified in the |Adapt.| editbox of the |Selection| panel.
%
% *Note 2!* While drawing the value in the |Adapt.| editbox may be changed
% using the mouse wheel.
%
% *Note 3!* The function relies on _slicmex.c_ that should be compiled for
% your operating system. Please refer to the
% <im_browser_system_requirements.html
% Microscopy Image Browser System Requirements> section for details.
%
%% The Black and White Thresholding tool 
%
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsBWThres.png">
% </td>
% <td style="border: 0px">
% Makes black and white thresholding of the current image slice or the
% whole dataset (depending on status of the <b>3D</b> and <b>4D</b> checkboxes). 
% <br><br>
% Use the <b>Low Lim</b> and <b>High Lim</b> sliders and edit boxes to provide
% the threshold values. 
% <br><br>
% If the <b>Masked area</b> check box is selected the thresholding is 
% performed only for the masked areas of the image, which is very convenient for local black and white thresholding.
% <br><br>
% The right mouse click above the threshold sliders opens a popup menu that
% allows to set the step for slider movement.
% <br><br>
% The <b>Adaptive</b> checkbox starts adaptive threshoding with the
% 'Sensitivity' and 'Width' parameters modified by the scroll bars.
% </td>
% </tr>
% </table>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=4m37s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=4m37s</a>
% </html>
%
%
%% Drag & Drop materials
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsDragDrop.png">
% </td>
% <td style="border: 0px">
% Shift MIB layers (selection, mask, model) to left/right/up/down
% direction. The tool allows to move individual 2D/3D objects as well as
% complete contents of the layers in 2D and 3D.
% <br><br>
% A combobox offers possibility to choose the layer to be moved. Mouse click or use of the buttons
% in the panel move the selected layer left/right/up/down by the specified number of pixels.
% <br><br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/NGudNrxBbi0"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/NGudNrxBbi0</a>
% <br><br>
% </td>
% </tr>
% </table>
% <br><br>
% <table style="width: 800px; text-align: center;" cellspacing=2px cellpadding=2px >
% <tr style="font-weight: bold; background: #ffb74d;">
%   <td>Start by</td>
%   <td>Modifier</td>
%   <td>3D checkbox</td>
%   <td>Action</td>
% </tr>
% <tr><td>Mouse click over an object</td><td>Control</td><td>Unchecked</td><td>Move the selected object in 2D</td></tr>
% <tr><td>Mouse click over an object</td><td>Control</td><td>Checked</td><td>Move the selected 3D object. <b>Note! Only for Matlab version 2017b and newer</b></td></tr>
% <tr><td>Mouse click</td><td>Shift</td><td>Unchecked</td><td>Move all objects on the shown slice, i.e. 2D movement</td></tr>
% <tr><td>Mouse click</td><td>Shift</td><td>Checked</td><td>Move all objects on all slices, i.e. 3D movement</td></tr>
% <tr><td>Left/Right/Up/Down buttons</td><td>-</td><td>Unchecked</td><td>Move all objects on the shown slice by the specified number of pixels, i.e. 2D movement</td></tr>
% <tr><td>Left/Right/Up/Down buttons</td><td>-</td><td>Checked</td><td>Move all objects on all slices by the specified number of pixels, i.e. 3D movement</td></tr>
% </table>
% </html>
% 
%
%% The Lasso tool
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsLasso.png">
% </td>
% <td style="border: 0px">
% Selection with a <em>lasso, rectangle, ellipse or polyline</em> tools.
% <br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/OHFdGj9uBro"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/OHFdGj9uBro</a>
% <br><br>
% <b>How to use:</b>
% <ul>
% <li>Press and release the selection mouse key (default: left mouse button) above the
% image to initialize the lasso tool</li>
% <li>Press the <em>left mouse button</em> and drag the mouse to start selection of areas</li>
% <li>Release the <em>left mouse button</em> to finish selection</li>
% <li>Modify selected area, if needed</li>
% <li>Accept selection using a double click of the <em>left mouse button</em></li>
% </ul>
% When the <em>Add mode</em> is switched to the <em>Subtract mode</em> the
% selected area is removed from the Selection layer.
% </td>
% </tr>
% </table>
% </html>
% 
% The Lasso tool works also in 3D.
%
%% The Magic Wand+Region Growing tool
% Selection of pixels with the _mouse button_ based on their
% intensities. The intensity variation is calculated from the intensity of the 
% selected pixel and two threshold values from the |Variation| edit boxes.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=1m50s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=1m50s</a>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsMagicWand.png">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>Connect 8</b> specifies the 8 (26 for 3D) connected neighbourhood connectivity</li>
% <li><b>Connect 4</b> specifies the 4 (6 for 3D) connected neighbourhood connectivity</li>
% <li><b>Radius</b> allows defining an effective range for the magic wand</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% The Magic Wand works also in the 3D mode (the 3D switch in the
% <ug_panel_selection.html |Selection panel|>).
%
% *Selection modifiers for the Magic wand tool:*
%
% * *None + left mouse click*, will replace the existing selection with the new one.
% * *Shift + left mouse click*, will add new selection to the existing one.
% * *Ctrl + left mouse click*, will remove new selection from the current.
%
%% The Membrane Click Tracker tool
% This tool tracks membrane-type objects by using 2 mouse clicks that define start and end point of the membrane domain. 
%
% <html>
% A brief demonstration for 2D is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=3m14s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=3m14s</a>
% <br>
% A brief demonstration for 3D is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=2m22s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=2m22s</a>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsMembraneClick.png">
% </td>
% <td style="border: 0px">
% <b>How to use:</b>
% <ul>
% <li><b>Ctrl + left mouse click</b> to define the starting point of a membrane fragment (before MIB version 2.651 the Shift + left mouse click combination was used)</li>
% <li><b>mouse click</b> to trace the membrane from the starting point to the clicked point</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
% The membrane is traced with help of Accurate Fast Marching function 
% <http://www.mathworks.se/matlabcentral/fileexchange/24531-accurate-fast-marching>
% by Dirk-Jan Kroon, 2011, University of Twente.
%
% *_Note!_* It is highly recommended to compile the corresponding function 
% (see details in the Membrane Click Tracker section of <im_browser_system_requirements.html the System Requirements page> ), otherwise the function is very slow! 
%
% *Extra parameters:* 
%
% * The *Scale* edit box - during the tracing the image gets enhanced by taking
% into account intensities of the starting and ending points |img(img>min([val1 val2])-diff([val1
% val2])*options.scaleFactor) = maxIntensity;| 
% * The *Width* edit box - defines a width of the resulting trace 
% * The *BlackSignal* checkbox defines whether the signal is Black on White, or White on Black 
% * The *Straight line* checkbox - when checked, the points are connected with a straight line
% 
% *_Note!_* When the 3D switch in the <ug_panel_selection.html |Selection| panel> is enabled the *Membrane Click Tracker*
% tool connects points (_linearly_) in the 3D space (this may be very
% usefull for tracing microtubules).
%
%
%% Object Picker
%
% This mode allows fast selection of objects from the |Mask| or |Model|
% layers. When the |Mask| and |Model| radio buttons define the target layer
% for selection.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/mzILHpbg89E"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/mzILHpbg89E</a>
% <br>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsObjectPicker.png">
% </td>
% <td style="border: 0px">
% Works also in <em>3D</em> (select the <b>3D</b> check box in the <a href="ug_panel_selection.html">Selection panel</a>).
% <br><br>
% <b>Note!</b> The 3D mode requires calculating statistics for the objects. Please select the material in the 
% <a href="ug_panel_segm.html">Select from</a> list box and press the <b>Recalc. Stats</b> button (the button becomes available when the 
% <a href="ug_panel_selection.html>3D check box</a> is checked).
% <br><br>
% <b>Note!</b> Some advanced mask or model filtering may be done via 
% <a href="ug_gui_menu_mask_statistics.html"Menu->Mask->Mask statistics...</a> or <a href="ug_gui_menu_mask_statistics.html">Menu->Models->Model statistics...</a>. 
% </td>
% </tr>
% </table>
% </html>
% 
%
% *Possible Object Picker selection modes are:*
%
% <html>
% <ul style="position:relative; left:35px;">
% <li> 
% 1. <b>Mouse click</b>: selects object from the <i>Mask/Model</i> layers with <i>mouse
% click</i>. 
% <b>Note 1!</b> Separation of objects is sensitive to the connected neighbourhood connectivity parameter from the <i>Magic Wand</i> tool; 
% <b>Note 2!</b> In the 3D mode the function uses object statistics that is
% generated by pressing the |Recalc. Stats| button. If the <i>Mask/Model</i> layers have been changed press the |Recalc. Stats| button again.
% </li>
% <li>
% 2. <b>Lasso</b>: selects object with <em>lasso</em> tool (Press first 
% <i>[None/Shift/Ctrl] + Right mouse button</i>, then hold the left mouse button
% while moving mouse around). Can also make selection for the whole dataset if the |3D| checkbox in 
% the <a href="ug_panel_selection.html">Selection panel</a> is checked. 
% </li>
% <li>
% 3. <b>Rectangle</b> or <b>Ellipse</b>: these tools work in similar to the <i>lasso</i> tool
% manner but give rectangle or ellipsoid selection. Works also in 3D.
% </li>
% <li>
% 4. With the <b>Polyline</b> option the selection is done by drawing a polygon 
% shape point by point. Start drawing with <i>right mouse button</i> and finish with
% a <i>double click</i> or <i>right mouse click</i>. Works also in 3D.
% </li>
% <li>
% 5. Use <b>Brush</b> to select some of the masked/model areas. Size of the Brush is defined in the Brush edit box.
% </li>
% <li>
% 6. <b>Mask within selection</b> with <em>mouse click</em> on the image
% makes a new selection that is an intersection of the existing selection
% and the mask/model layer. With <em>Ctrl+mouse click</em> the new selection is
% Selection <em>-minus-</em> Mask. This action is sensitive to the 3D checkbox state in the Selection panel. 
% </li>
% </ul>
% </html>
%
% *Selection modifiers*:
%
% * *None / Shift + left mouse click*, will add selection with the existing one.
% * *Ctrl + left mouse click*, will remove selection from the current.
%
%
%% The Spot tool 
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsSpot.png">
% </td>
% <td style="border: 0px">
% Adds a spot - a circular object with a <em>mouse click</em><br><br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/AlCzjKuyJww"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/AlCzjKuyJww</a>
% <br>
% Use the <b>Radius, px</b> edit box to specify the radius of the spot. 
% <br><br>
% Works also in 3D.
% <br><br>
% <b>Selection modifiers</b>
% <ul>
% <li><b>None / Shift + left mouse click</b>, will add new spot to the existing ones</li>
% <li><b>Ctrl + left mouse click</b>, will remove selection from the current</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| 
% <ug_gui_panels.html *Panels*> |*-->*| <ug_panel_segm.html *Segmentation Panel*>
%
