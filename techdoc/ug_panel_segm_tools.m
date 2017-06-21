%% Segmentation Tools
% This panel hosts different tools that are used for the image
% segmentation. 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| 
% <ug_gui_panels.html *Panels*> |*-->*| <ug_panel_segm.html *Segmentation Panel*>
%
% 
%% 1. The 3D ball
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
% increse of the 3D ball eraser, when holding the Clrl key.
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
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=1s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=1s</a>
% </html>
%
%% 2. Annotations
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/3lARjx9dPi0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/3lARjx9dPi0</a>
% <br>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsAnnotations.png">
% </td>
% <td style="border: 0px">
% A set of tools to add/remove annotations.<br><br>
% When the Annotation tool is selected the mouse click above the image adds annotation to the model.
% The annotations can be removed by using <em>Ctrl + left mouse click</em> combination.
% <ul>
% <li>The <b>Annotation list</b> button starts a window with the list of existing
% annotations. It is possible to load and save annotations to the main Matlab
% workspace or to a file (matlab and excel formats). See more below.</li>
% <li>The <b>Show only marker</b> checkbox - when selected the annotation text is not
% displayed and the marker cross is only seen.</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\PanelsSegmentationToolsAnnotationsTable.png">
% </td>
% <td style="border: 0px">
% <ul>
% <li>The <b>List of labels</b> table shows a list of annotations. The <em>right
% mouse button</em> click calls an additional popup menu that allows to <em>add,
% delete or jump</em> to the highlighted annotation</li>
% <li>The <b>Auto jump</b> checkbox - when enabled, the image in the <a href="ug_panel_im_view.html">Image View panel</a> is automatically shifted, thereby placing the selected annotation at the center of the image</li>
% <li>The <b>Load</b> button imports annotations from the main Matlab workspace or load them from a file</li>
% <li>The <b>Save</b> button exports annotations to the main Matlab workspace or to save them as a file in Matlab or Excel formats </li>
% <li>The <b>Refresh table</b> button updates the list of annotations</li>
% <li>The <b>Delete all</b> button removes all annotations</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
%% 3. The Brush tool 
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
% A brief demonstration is available in the following video:<br>
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
% * Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine Süsstrunk, SLIC Superpixels Compared to State-of-the-art Superpixel Methods, IEEE Transactions on Pattern Analysis and Machine Intelligence, vol. 34, num. 11, p. 2274 - 2282, May 2012.
% * Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine Süsstrunk, SLIC Superpixels, EPFL Technical Report no. 149300, June 2010.
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
%% 4. The Black and White Thresholding tool 
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
%% 5. The Lasso tool
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
% <li>Press the <em>left mouse button</em> to start selection of areas</li>
% <li>Release the <em>left mouse button</em> to accept selection</li>
% <li>When working in the <em>Polyline mode</em> selection is finished using a double
% click of the <em>left mouse button</em></li>
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
%% 6. The Magic Wand+Region Growing tool
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
%% 7. The Membrane Click Tracker tool
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
% <li><b>Shift + left mouse click</b> to define the starting point of a membrane fragment</li>
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
%% 8. Object Picker
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
%% 9. The Spot tool 
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
