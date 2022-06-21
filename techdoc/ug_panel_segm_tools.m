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
% increse of the 3D ball eraser, when holding the <span class="kbd">Clrl</span> key.<br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=1s"><img
% style="vertical-align:middle;" src="images\youtube2.png">
% https://youtu.be/ZcJQb59YzUA?t=1s</a><br><br>
% <b>Note!</b> The depth of 3D ball is defined by the pixel dimensions,<br>see <em>Dataset Parameters</em> in <a href="ug_gui_menu_dataset.html">Menu->Dataset->Parameters</a>
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Selection modifiers* [/smry]
%
% * [class.kbd]None[/class] / [class.kbd]&#8679; Shift[/class]+[class.kbd]left mouse click[/class], add 3D ball selection with the existing one
% * [class.kbd]Ctrl[/class] + [class.kbd]left mouse click[/class], remove 3D ball selection from the current selection layer
%
% [/dtls]
% [br8]
%
%% The 3D lines
%
% [target1]
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationTools3DLines.png">
% </td>
% <td style="border: 0px">
% The 3D lines tool can be used to draw lines in 3D and arrange them as
% graphs or skeletons. The 3D lines composed of Nodes (Vertices) 
% connected with Edges (a line that connect two nodes). Separated from each
% other sets of 3D lines organized into separate trees. <br>
% A demonstration is available on: 
% <a href=""><img style="vertical-align:middle;" src="images\youtube2.png">
% https://youtu.be/DNRUePJiCbE</a><br>
% <br>
% Modification of nodes is possible using mouse clicks. To increase
% flexibility, the clicks can be extended with key-modifiers, such as
% <span class="kbd">&#8679; Shift</span>, <span class="kbd">Ctrl</span>, <span class="kbd">Alt</span>. 
% Each action can be configured depending on needs. Please refer to a
% table below for various options.
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Available actions* [/smry]
% 
% <html>
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
% Use the <span class="kbd">[&#10003;] <b>Show lines</b></span> checkbox to toggle visibility of the lines in
% the Image View panel.
% <br>
% Press the <span class="kbd">Table view</span> button to start a window which tables that
% describe the 3D lines (see below).
% </html>
%
% [/dtls]
%
% [class.h3]Lines 3D View[/class]
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationTools3DLinesDlg.png">
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
% <li><b>Save/export selected tree(s)</b>, export to MATLAB or save to a file the selected trees, see the Tools panel below for the list of available file formats</li>
% <li><b>Delete selected tree(s)</b>, delete selected tree from the table</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Space between the tables* [/smry]
% 
% * *Active tree*, an index of the active tree
% * *Active node*, an index of the active node
% * *Table*, a combo box to select what should be shown in the lower table: Nodes or Edges
% * *Field*, a combo box to define an additional field that should be shown the lower table. 
% By default, only the Radius and Weights fields are available
% * *Auto jump*, when selected, auto jump to the selected node
% * *Auto refresh*, automatically refresh the tables, may be quite slow with many nodes
%
% [/dtls]
%
% [dtls][smry] *Nodes table* [/smry]
% 
% The table shows list of nodes and offers multiple actions via a popup
% menu:
%
% * *Jump to the node*, jumps to the selected node and put it in the center of the Image View panel
% * *Set as active node*, makes the selected node active
% * *Rename selected nodes...*, assign a new name for the selected nodes
% * *Show coordinates in pixels...*, by default, the coordinates of the nodes are shown in the physical units of the dataset, 
% _i.e._ with respect to <ug_gui_menu_dataset.html#8 the bounding box> ; this action shows coordinate of the node in pixels
% * *New annotations from nodes*, generate a new annotations from the position of nodes
% * *Add nodes to annotations*, add selected nodes to the existing annotations
% * *Delete nodes from annotations*, delete selected nodes from the existing annotations
% * *Delete nodes...*, delete selected nodes
%
% [/dtls]
%
% [dtls][smry] *Edges table* [/smry]
% The table shows list of edges; certain actions available via a popup menu:
%
% * *Jump to the node*, jumps to the selected node and put it in the center of the Image View panel
% * *Set as active node*, makes the selected node active
%
% [/dtls]
%
% [dtls][smry] *Tools panel*[/smry]
%
% * *[class.kbd]Load[/class]*, load 3D lines from a file in matlab-compatible lines3d format
% * *[class.kbd]Save[/class]*, export to MATLAB or save 3D lines to a file:
%
% <html>   
% <ul>
% <li><b>MATLAB format, *.lines3d</b>, it is recommended to save the 3D lines in the matlab format!</li>
% <li><b>Amira Spatial graph, *.am</b>, Amira-compatible format in binary or ascii form</li>
% <li><b>Excel format, *.xls</b>, export Nodes and Edges tables to an Excel file</li>
% </ul>
% </html>
%
% * *[class.kbd]Refresh[/class]*, refresh the tables shown in this window
% * *[class.kbd]Delete all[/class]*, delete all 3D lines
% * *[class.kbd]Visualize in 3D[/class]*, plot all trees in the 3D space
% * *[class.kbd]Settings[/class]*, modify color and thickness of 3D lines
%
% [/dtls]
% [br8]
%
%% Annotations
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsAnnotations.png">
% </td>
% <td style="border: 0px">
% A set of tools to add/remove annotations. Each annotation allows to mark
% specific location in the dataset, assign a label and a value to it<br><br>
% Brief demonstration is available in the following videos:<br>
% <a href="https://youtu.be/3lARjx9dPi0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/3lARjx9dPi0</a>
% <br>
% <a href="https://youtu.be/3lARjx9dPi0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/6otBey1eJ0U</a>
% <br><br>
% <b> Addition and removal of annotations</b><br>
% <ul>
% <li><span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> left mouse click</span>, add annotation to the
% position under the mouse cursor</li>
% <li><span class="kbd">Ctrl</span> + <span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> left mouse click</span>, remove annotation that is the closest to the
% position under the mouse cursor</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Annotation panel widgets* [/smry]
%
% <html>
% <ul>
% <li>The <span class="kbd">Annotation list</span> button starts a window with the list of existing
% annotations. It is possible to load and save annotations to the main MATLAB
% workspace or to a file (matlab and excel formats). See more below.</li>
% <li>The <span class="kbd">Delete All</span> button removes all annotations
% <li><b>Precision</b> edit box - specify number of digits after decimal
% point</li>
% <li><span class="kbd">[&#10003;] <b>Show prompt</b></span> checkbox, when ticked a dialog asking for label and value appear after addition of each annotation, 
% otherwise the dialog is not shown and the label and field values are taken from the previously added annotation</li>
% <li><span class="kbd">[&#10003;] <b>Focus on Value</b></span> checkbox, when ticked, the first parameter during visualization of annotations is
% value and the second parameter is label.</li>
% <li>The <b>Display as</b> combobox - enables way how the annotations are
% displayed in the <a href="ug_panel_im_view.html">Image View panel</a>. 
    % <ul><b><em>The following modes are available:</b></em><br>
    % <li><b>Marker</b>, show only location of the annotation using a cross-marker</li>
    % <li><b>Label</b>, show marker and label for each annotation</li>
    % <li><b>Value</b>, show marker and value for each annotation</li>
    % <li><b>Label + Value</b>, show marker, label and value for each annotation</li>
    % </ul>
% </li>
% </ul>
% </html>
%
% [/dtls]
%
% [class.h3]List of annotations window[/class]
%
% <html>
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
%       <li><em><b>Add annotation</em></b>, manually add annotation to the list, position of the first and second fields are defined by the <span class="kbd">[&#10003;] <b>Value eccentric</b></span> checkbox of the Annotation panel, see above</li>
%       <li><em><b>Rename selected annotations</em></b>, rename names of the selected annotations</li>
%       <li><em><b>Batch modify selected annotations</em></b>, modify annotation values or coordinates using a provided expression</li>
%       <li><em><b>Count selected annotations</em></b>, calculate occurance of each annotation in the list of selected annotations. 
%           The results are displayed in the MATLAB command window and copied to the system clipboard 
%           <a href="https://youtu.be/rqZbH3Jpru8"><img style="vertical-align:middle;" src="images\youtube.png"></a>
%           </li>
%       <li><em><b>Copy selected annotations to clipboard</em></b>, the selected annotations are copied to the system clipboard as a text string ready to be pasted to Excel</li>
%       <li><em><b>Convert selected annotations to Mask...</em></b>, generate 2D/3D Mask spots centered at each annotation marker. The
%           size of the spot can either be fixed or scaled from the value field of the selected annotations<br>
%           <img src="images\PanelsSegmentationToolsAnnotationsTableToMask.png"></li>
%       <li><em><b>Crop out patches around selected annotations</em></b>, 2D/3D patch of the predefined size is generated when this operation is used
%           <a href="https://youtu.be/QrKHgP76_R0"><img style="vertical-align:middle;" src="images\youtube.png"></a></li>
%       <li><em><b>Export selected annotations</em></b>, export selected annotations in the MATLAB format, landmarks for Amira (<em><b>Note!</em> only the coordinates are exported to Amira!</b>), PSI format for Amira and Excel</li>
%       <li><em><b>Export selected annotations to Imaris</em></b>, export selected annotations to Imaris (<em><b>Note!</em> please first export the dataset!</b>)</li>
%       <li><em><b>Order</b></em>, subitems of the Order entry can be used to move annotations towards the top or the bottom of the list</li>
%       <li><em><b>Delete annotation</em></b>, delete selected annotations from the list</li>
%   </ul>
% <li>The <span class="kbd">Load</span> button, press to import annotations from the main MATLAB workspace or load them from a file</li>
% <li>The <span class="kbd">Save</span> button, press to export annotations to the main MATLAB workspace or to save them as a file in MATLAB, Comma-separated CSV format, Excel formats or as landmarks for Amira (
%           <a href="https://youtu.be/wHr6nHpmVMo"><img style="vertical-align:middle;" src="images\youtube.png"></a> <em><b>Note!</em> only the coordinates are exported!</b>), or PSI format for Amira</li>
% <li>The <b>Precision</b> editbox, modify precision of the value field in the table and for the visualization in the Image View panel
% <li>The <span class="kbd">[&#10003;] <b>Auto jump</b></span> checkbox - when enabled, the image in the <a href="ug_panel_im_view.html">Image View panel</a> is automatically shifted, thereby placing the selected annotation at the center of the image</li>
% <li>The <b>Sort table</b> allows to sort annotations based on their Name, Value, X, Y, Z, T</li>
% <li>The <span class="kbd">Settings</span> provides configuration of additional settings: extra slices to display annotation, when this value 0 annotations only belonging to the current slice are displayed, when a positive number from -value to +value depth</li>
% <li>The <span class="kbd">Refresh table</span> button updates the list of annotations</li>
% <li>The <span class="kbd">Delete all</span> button removes all annotations</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% [br8]
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
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Brush mouse controls* [/smry]
%
% * [class.kbd]Ctrl[/class] + [class.kbd]Mouse wheel[/class],  change brush size
% * [class.kbd]None[/class] / [class.kbd]&#8679; Shift[/class] + [class.kbd]left mouse click[/class], paint with brush
% * [class.kbd]Ctrl[/class] + [class.kbd]left mouse click[/class], start eraser. The brush radius in the
% eraser mode could be amplifier using the *Eraser, x* edit box.
%
% [/dtls]
% 
% [dtls][smry] *Widgets of the brush panel* [/smry]
% 
% <html>
% <b>Radius</b>, define radius of the brush tool in pixels<br>
% <b>Eraser, x</b>, define radius size multiplier when brush is in the eraser mode<br>
% <b>Interpolation settings</b>, press to start a dialog that allows to
% modify the interpolation settings. The settings can also be modified from
% the <a href="ug_gui_menu_file_preferences.html">Preference dialog</a> and the type can be switched
% using a dedicated button in the <a href="ug_gui_toolbar.html">toolbar</a>.<br>
% <img src="images\PanelsSegmentationToolsBrushInterpolation.png">
% The <span class="kbd">[&#10003;] <b>Watershed</b></span> checkbox, when ticked, pixels of the image are clustered using the watershed algorithm and can be selected as clusters (see the following section)<br>
% The <span class="kbd">[&#10003;] <b>SLIC</b></span> checkbox, , when ticked, pixels of the image are clustered using the SLIC algorithm and can be selected as clusters (see the following section)<br>
% </html>
%
% [/dtls]
%
% [dtls][smry] *Superpixels with the Brush tool* [/smry]
%
% *The Superpixels mode* can be initiated by selecting the <https://youtu.be/vVh1j3HBh-c *Watershed*> or <https://youtu.be/6bZb_Mr_nS0?list=PLGkFvW985wz8cj8CWmXOFkXpvoX_HwXzj *SLIC*> 
% checkbox. In the Superpixels mode the brush tool selects not individual pixels but rather
% groups of pixels (superpixels). While drawing the selection of the last superpixel can
% be undone by pressiong the [class.kbd]Ctrl+Z[/class] shortcut.
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
% the |N| edit box can be changed using the [class.kbd]Ctrl+Alt + mouse wheel[/class] or
% [class.kbd]Ctrl[/class]+[class.kbd]Alt[/class]+[class.kbd]&#8679; Shift[/class] + [class.kbd]mouse wheel[/class] shortcuts.
%
% *References:*
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
% *Note 1!* The Superpixels mode is sensitive to the [class.kbd][&#10003;] *Adapt.*[/class] checkbox in
% the |Selection panel|. When the [class.kbd][&#10003;] *Adapt.*[/class] checkbox is selected the
% superpixels are selected based on the _mean value_ of the initial
% selection _plus/minus_ standard deviation within the same area multiplied
% by the factor specified in the |Adapt.| editbox of the |Selection| panel.
%
% *Note 2!* While drawing the value in the |Adapt.| editbox may be changed
% using the mouse wheel.
%
% *Note 3!* The function relies on [class.code]slicmex.c[/class] that should be compiled for
% your operating system. Please refer to the
% <im_browser_system_requirements.html
% Microscopy Image Browser System Requirements> section for details.
%
% [/dtls]
% [br8]
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
% whole dataset (depending on status of the <span class="kbd">[&#10003;] <b>3D</b></span> and <span class="kbd">[&#10003;] <b>4D</b></span> checkboxes). 
% <br><br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=4m37s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=4m37s</a>
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Parameters and controls* [/smry]
%
% Use the *Low* and *High* sliders and edit boxes to provide
% threshold values tha will be used to select pixels with intensities
% between these values.
% [br8]
% If the *Masked area* check box is selected the thresholding is 
% performed only for the masked areas of the image, which is very convenient for local black and white thresholding.
% [br8]
% [class.kbd]Right mouse click[/class] above the threshold sliders opens a popup menu that
% allows to set precision for the slider movement.
% [br8]
% The [class.kbd][&#10003;] *Adaptive*[/class] checkbox starts adaptive threshoding with the
% |Sensitivity| and |Width| parameters modified by the scroll bars.
%
% *Usage notes*[br]
% When doing thesholding for large 3D/4D datasets it is recommended to:
%
% * start in 2D mode by unchecking [class.kbd][&#10003;] *3D*[/class] and [class.kbd][&#10003;] *4D*[/class] checkboxes
% * adjust parameters using the currently shown slice
% * when parameters are chosen, tick [class.kbd][&#10003;] *3D*[/class] or [class.kbd][&#10003;] *4D*[/class] checkbox 
% * select |Low| or |High| editbboxe and hit [class.kbd]Enter[/class] to apply thresholding values for the whole dataset
%
% [/dtls]
% [br8]
%
%% Drag & Drop material
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
% </html>
%
% [dtls][smry] *Mouse and key controls* [/smry]
%
% <html>
% <table style="width: 800px; text-align: center;" cellspacing=2px cellpadding=2px >
% <tr style="font-weight: bold; background: #ffb74d;">
%   <td>Start by</td>
%   <td>Modifier</td>
%   <td><span class="kbd">[&#10003;] <b>3D</b></span> checkbox</td>
%   <td>Action</td>
% </tr>
% <tr><td><span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> Left mouse click</span> over an object</td><td><span class="kbd">Ctrl</span></td><td>Unchecked</td><td>Move the selected object in 2D</td></tr>
% <tr><td><span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> Left mouse click</span> over an object</td><td><span class="kbd">Ctrl</span></td><td>Checked</td><td>Move the selected 3D object. <b>Note! Only for MATLAB version 2017b and newer</b></td></tr>
% <tr><td><span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> Left mouse click</span></td><td><span class="kbd">&#8679; Shift</span></td><td>Unchecked</td><td>Move all objects on the shown slice, i.e. 2D movement</td></tr>
% <tr><td><span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> Left mouse click</span></td><td><span class="kbd">&#8679; Shift</span></td><td>Checked</td><td>Move all objects on all slices, i.e. 3D movement</td></tr>
% <tr><td><span class="kbd">Left</span>/<span class="kbd">Right</span>/<span class="kbd">Up</span>/<span class="kbd">Down buttons</span></td><td>-</td><td>Unchecked</td><td>Move all objects on the shown slice by the specified number of pixels, i.e. 2D movement</td></tr>
% <tr><td><span class="kbd">Left</span>/<span class="kbd">Right</span>/<span class="kbd">Up</span>/<span class="kbd">Down buttons</span></td><td>-</td><td>Checked</td><td>Move all objects on all slices by the specified number of pixels, i.e. 3D movement</td></tr>
% </table>
% </html>
%
% [/dtls]
% [br8]
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
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *How to use:* [/smry]
%
% * Press and release [class.kbd]left mouse button[/class] above the image to initialize the lasso tool
% * Press and hold [class.kbd]left mouse button[/class] and drag the mouse to select an area
% * Release the [class.kbd]left mouse button[/class] to finish the selection process
% * Modify selected area, if needed
% * Accept selection using [class.kbd]double left mouse button click[/class]
%
% *Modes:*
%
% * *Add*, a new selection is added to the existing one
% * *Subtract*, a new selection is subtracted from the existing one
% 
% The Lasso tool works also in 3D.
%
% [/dtls]
% [br8]
%
%% The Magic Wand + Region Growing tool
% 
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsMagicWand.png">
% </td>
% <td style="border: 0px">
% Selection of pixels with the _mouse button_ based on their
% intensities. The intensity variation is calculated from the intensity of the 
% selected pixel and two threshold values from the |Variation| edit boxes.
% <br><br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=1m50s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=1m50s</a>
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Widgets and parameters* [/smry]
%
% * *Variation* editboxes, specify variation of image intensities relative to the clicked value
% * *Connect 8* specifies the 8 (26 for 3D) connected neighbourhood connectivity
% * *Connect 4* specifies the 4 (6 for 3D) connected neighbourhood connectivity
% * *Radius* allows defining an effective range for the magic wand
%
% The Magic Wand works also in the 3D mode (the 3D switch in the
% <ug_panel_selection.html |Selection panel|>).
%
% [/dtls]
%
% [dtls][smry] *Selection modifiers for the Magic wand tool* [/smry]
%
% * [class.kbd]left mouse click[/class], will replace the existing selection with the new one.
% * [class.kbd]&#8679; Shift[/class] + [class.kbd]left mouse click[/class], will add new selection to the existing one.
% * [class.kbd]Ctrl[/class] + [class.kbd]left mouse click[/class], will remove new selection from the current.
%
% [/dtls]
% [br8]
%
%% The Membrane Click Tracker tool
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsMembraneClick.png">
% </td>
% <td style="border: 0px">
% This tool tracks membrane-type objects by using 2 mouse clicks that define start and end point of the membrane domain. 
% <br><br>
% A brief demonstration for 2D is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=3m14s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=3m14s</a>
% <br>
% A brief demonstration for 3D is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=2m22s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=2m22s</a>
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *How to use* [/smry]
%
% * [class.kbd]Ctrl[/class] + [class.kbd]left mouse click[/class] to define the starting point of a membrane fragment 
% (before MIB version 2.651 the [class.kbd]&#8679; Shift[/class] + [class.kbd]left mouse click[/class] combination was used)</li>
% * [class.kbd]Left mouse click[/class] to trace the membrane from the starting point to the clicked point</li>
%
% [/dtls]
%
% [dtls][smry] *Additional parameters* [/smry]
% 
% * The *Scale* edit box - during the tracing the image gets enhanced by taking
% into account intensities of the starting and ending points |img(img>min([val1 val2])-diff([val1
% val2])*options.scaleFactor) = maxIntensity;| 
% * The *Width* edit box - defines a width of the resulting trace 
% * The [class.kbd][&#10003;] *BlackSignal*[/class] checkbox defines whether the signal is Black on White, or White on Black 
% * The [class.kbd][&#10003;] *Straight line*[/class] checkbox - when checked, the points are connected with a straight line
% 
% *_Note!_* When the 3D switch in the <ug_panel_selection.html |Selection| panel> is enabled the *Membrane Click Tracker*
% tool connects points (_linearly_) in the 3D space (this may be very
% usefull for tracing microtubules). Alternatively for microtunules, consider [jumpto1]3D lines tool[/jumpto]
%
% [/dtls]
% 
% [dtls][smry] *Reference and compilation* [/smry]
% The membrane is traced with help of Accurate Fast Marching function 
% <http://www.mathworks.se/matlabcentral/fileexchange/24531-accurate-fast-marching>
% by Dirk-Jan Kroon, 2011, University of Twente.
%
% *_Note!_* It is highly recommended to compile the corresponding function 
% (see details in the Membrane Click Tracker section of <im_browser_system_requirements.html the System Requirements page> ), otherwise the function is very slow! 
%
% [/dtls]
% [br8]
%
%% Object Picker
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsObjectPicker.png">
% </td>
% <td style="border: 0px">
% This mode allows fast selection of objects from the |Mask| or |Model|
% layers. When the |Mask| and |Model| radio buttons define the target layer
% for selection.<br><br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/mzILHpbg89E"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/mzILHpbg89E</a>
% <br>
% Works also in <em>3D</em> (select the <b>3D</b> check box in the <a href="ug_panel_selection.html">Selection panel</a>).
% <br><br>
% <b>Note!</b> The 3D mode requires calculating statistics for the objects. Please select the material in the 
% <a href="ug_panel_segm.html">Select from</a> list box and press the <span class="kbd">Recalc. Stats</span> button (the button becomes available when the 
% <a href="ug_panel_selection.html>3D check box</a> is checked).
% <br><br>
% <b>Note!</b> Some advanced mask or model filtering may be done via 
% <a href="ug_gui_menu_mask_statistics.html"Menu->Mask->Mask statistics...</a> or <a href="ug_gui_menu_mask_statistics.html">Menu->Models->Model statistics...</a>. 
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Possible Object Picker selection modes* [/smry]
%
% <html>
% <ul style="position:relative; left:35px;">
% <li> 
% 1. <span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> Left mouse click</span>, selects object from the <em>Mask/Model</em> layers with a single mouse click.<br> 
% <b>Note 1!</b> Separation of objects is sensitive to the connected neighbourhood connectivity parameter from the <em>Magic Wand</em> tool; 
% <b>Note 2!</b> In the 3D mode the function uses object statistics that is
% generated by pressing the  <span class="kbd">Recalc. Stats</span> button. If the <em>Mask/Model</em> layers have been changed press the 
% <span class="kbd">Recalc. Stats</span> button again.
% </li>
% <li>
% 2. <b>Lasso</b>: selects object with <em>lasso</em> tool (Press first 
%  <span class="kbd">None</span>/<span class="kbd">&#8679; Shift</span>/<span class="kbd">Ctrl</span> +  <span class="kbd">Right mouse button</span>, 
%  then hold the  <span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> left mouse button</span> while moving mouse around). Can also make selection for the whole dataset if the <span class="kbd">[&#10003;] <b>3D</b></span> checkbox in 
% the <a href="ug_panel_selection.html">Selection panel</a> is checked. 
% </li>
% <li>
% 3. <b>Rectangle</b> or <b>Ellipse</b>: these tools work in similar to the <em>lasso</em> tool
% manner but give rectangle or ellipsoid selection. Works also in 3D.
% </li>
% <li>
% 4. With the <b>Polyline</b> option the selection is done by drawing a polygon 
% shape point by point. Start drawing with the <span class="kbd">right mouse button</span> and finish with
% a <span class="kbd">double click</span> or the <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right mouse click</span>. Works also in 3D.
% </li>
% <li>
% 5. Use <b>Brush</b> to select some of the masked/model areas. Size of the Brush tool is defined in the <em>Brush</em> editbox.
% </li>
% <li>
% 6. <b>Mask within selection</b> with the <span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> left mouse click</span> on the image
% make a new selection that is an intersection of the existing selection
% and the mask/model layer. With  <span class="kbd">Ctrl</span>+ <span class="kbd">mouse click</span> the new selection is
% Selection <em>-minus-</em> Mask. This action is sensitive to the <span class="kbd">[&#10003;] <b>3D</b></span> checkbox state in the Selection panel. 
% </li>
% </ul>
% </html>
%
% [/dtls]
%
% [dtls][smry] *Selection modifiers* [/smry]
%
% * [class.kbd]None[/class]/[class.kbd]&#8679; Shift[/class] + [class.kbd]left mouse click[/class], will add selection with the existing one
% * [class.kbd]Ctrl[/class] + [class.kbd]left mouse click[/class], will remove selection from the current
%
% [/dtls]
% [br8]
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
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Widgets and parameters* [/smry]
%
% <html>
% Use the <b>Radius, px</b> edit box to specify the radius of the spot.
% <br>
% *Eraser, x*, specifies magnifier for the spot eraser tool
% <br><br>
% Works also in 3D.
% <br><br>
% <b>Selection modifiers</b>
% <ul>
% <li><span class="kbd">None</span>/<span class="kbd">&#8679; Shift</span> + <span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> left mouse click</span>, will add new spot to the existing ones</li>
% <li><span class="kbd">Ctrl</span> + <span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> left mouse click</span>, will remove selection from the current</li>
% </ul>
% </html>
%
% [/dtls] 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| 
% <ug_gui_panels.html *Panels*> |*-->*| <ug_panel_segm.html *Segmentation Panel*>
%
% [cssClasses]
% .kbd { 
%     font-family: monospace;
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