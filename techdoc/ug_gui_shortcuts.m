%% Key & mouse shortcuts
% List of key and mouse shortcuts; 
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/qrLyrP9f018"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/qrLyrP9f018</a>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
%
%% General notes
% *Please note,* the following list refers 
% to the default settings, _i.e._ when the left mouse button is used for drawing and selection, while the right mouse button for
% panning the image left/right and up/down.
% The buttons may be swapped using the <ug_gui_menu_file_preferences.html Preference dialog> or by pressing 
% the |Swap left and right mouse buttons| on the <ug_gui_toolbar.html toolbar>.
%
% The default behaviour of the mouse wheel is to change the slices and the |Q|, |W| keyboard keys to zoom in/zoom out; this may be swapped using the 
% |mouse| key in the <ug_gui_toolbar.html toolbar> or using the <ug_gui_menu_file_preferences.html Preferences dialog>.
%
% The key shortcuts can be customized in the <ug_gui_menu_file_preferences.html *File->Preferences->Shortcuts dialog*>.
%
%%
%
%%% Combination of mouse and keys
%%
%
%
% <html>
% <head>
% <link rel="stylesheet" type="text/css" href="style.css">
% </head>
% <body>
% <table>
% <tr>
%   <td style="width: 120pt"><kbd>move cursor</kbd></td>
%   <td>to dispay intensity information and cursor coordinates;<br>shown in the <a href="ug_panel_path.html">Path Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>mouse wheel</kbd></td>
%   <td>change slices or zoom in/zoom out, depening on settings in the <a href="ug_gui_menu_file_preferences.html">Preferences dialog</a></td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>mouse wheel</kbd></td>
%   <td>jump to 10 slices up/down,<br>number of slices can be defined from a popup menu that appears during the <kbd>right click</kbd> above the slices slider in the 
% <a href="ug_panel_im_view.html">Image View Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>Alt</kbd>+<kbd>mouse wheel</kbd></td>
%   <td>change time point for the 5D datasets</td>
% </tr>
% <tr>
%   <td><kbd>Alt</kbd>+<kbd>&#8679; Shift</kbd>+<kbd>mouse wheel</kbd></td>
%   <td>jump to 10 time points,<br>number of time points can be defined from a popup menu that appears during the <kbd>right click</kbd> above the slices slider in the 
%       <a href="ug_panel_im_view.html">Image View Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>left-click</kbd></td>
%   <td>select pixels in the image based on specified method specified in the <a href="ug_panel_segm.html">Segmentation Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>right-click</kbd>+<kbd>drag</kbd></td>
%   <td>turns on the pan mode to move the image left/right and up/down</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>left-click</kbd></td>
%   <td>add selection to the existing selection</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>left-click</kbd></td>
%   <td>remove selection to the existing selection, eraser</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>mouse wheel</kbd></td>
%   <td>change size of the brush and other selection tools</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>&#8679; Shift</kbd>+<kbd>mouse wheel</kbd></td>
%   <td>change size of the brush and other selection tools in bigger increments</td>
% </tr>
% </table>
% </body>
% </html>
%
%%% Interaction with ROIs
%%
%
%
% <html>
% <head>
% <link rel="stylesheet" type="text/css" href="../style.css">
% </head>
% <body>
% To interact with ROIs (for example to change its size or position) please use <kbd>right click</kbd> over the ROI name in the ROI List of <a href="ug_panel_roi.html"> the ROI Panel</a> to start a popup menu. Choose <b>Edit</b> to modify the selected ROI.
% <br><br>
% When the Edit mode is enabled the following actions are available:
% <ul>
% <li><kbd>left click</kbd>+<kbd>drag</kbd> to change position of the selected ROI</li>
% <li><kbd>right click</kbd> on a vertex of the selected ROI to delete it</li>
% <li>hold <kbd>A</kbd>+<kbd>left click</kbd> on an edge of the selected ROI to add a new vertex</li>
% <li><kbd>double click</kbd> to accept changes</li>
% </ul>
% </body>
% </html>
% 
%%% Keyboard shortcuts
%
%
%%
% 
% <<images\keyboard_shortcuts.jpg>>
%
%
% <html>
% <head>
% <link rel="stylesheet" type="text/css" href="../style.css">
% </head>
% <body>
% <table>
% <tr>
%   <td style="width: 100pt"><kbd>&#8592;</kbd>, <kbd>&#8594;</kbd><br><br>
%     <kbd>Alt</kbd>+<kbd>Q</kbd> / <kbd>Alt</kbd>+<kbd>W</kbd>      </td>
%   <td>change time points to the next or previous one<br>
%       enabled when the Mouse wheel in the zoom mode (check the <a href="ug_gui_menu_file_preferences.html">Preferences</a>)</td>
% </tr>
% <tr>
%   <td><kbd>&#8593;</kbd>, <kbd>&#8595;</kbd></td>
%   <td>change slice (in Z) to the next or previous one</td>
% </tr>
% <tr>
%   <td><kbd>Q</kbd></td>
%   <td>zoom out or change to the previous slice (depending on choosen settings in the <a href="ug_gui_menu_file_preferences.html">Preferences</a>)</td>
% </tr>
% <tr>
%   <td><kbd>W</kbd></td>
%   <td>zoom in or change to the next slice (depending on choosen settings in the <a href="ug_gui_menu_file_preferences.html">Preferences</a>)</td>
% </tr>
% <tr>
%   <td><kbd>space</kbd></td>
%   <td>toggle the visibility of the <b>Model</b> layer</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>space</kbd></td>
%   <td>toggle the visibility of the <b>Mask</b> layer</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>space</kbd></td>
%   <td>toggle the state of the <b>Fix selection to material</b> checkbox in the <a href="ug_panel_segm.html">Segmentation Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>A</kbd></td>
%   <td>add <em>Selection</em> (<em>for the shown slice only</em>) to the selected material of the model or to the <b>Mask</b> layer<br>
%           (depending on selected entry in the <b>Add to</b> list of the <a href="ug_panel_segm.html">Segmentation Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>A</kbd></td>
%   <td>add <em>Selection</em> (<em>for all slices of the dataset</em>) to the selected material of the model or to the <b>Mask</b> layer<br>
%           (depending on selected entry in the <b>Add to</b> list of the <a href="ug_panel_segm.html">Segmentation Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>Alt</kbd>+<kbd>A</kbd></td>
%   <td>add <em>Selection</em> (<em>for all slices and all time points of the dataset</em>) to the selected material of the model or to the <b>Mask</b> layer<br>
%           (depending on selected entry in the <b>Add to</b> list of the <a href="ug_panel_segm.html">Segmentation Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>A</kbd></td>
%   <td>if <b>Mask</b> is shown, select the Mask layer for the current slice;<br>if Mask is not shown select the
% selected (in the <b>Select from</b> list, <a href="ug_panel_segm.html">Segmentation Panel</a>) material of the model</td>
% </tr>
% <tr>
%   <td><kbd>Alt</kbd>+<kbd>A</kbd></td>
%   <td>if <b>Mask</b> is shown, select the Mask layer for all slices;<br>if Mask is not shown select the
% selected (in the <b>Select from</b> list, <a href="ug_panel_segm.html">Segmentation Panel</a>) material of the model</td>
% </tr>
% <tr>
%   <td><kbd>S</kbd></td>
%   <td>subtract <em>Selection</em> (<em>for the shown slice only</em>) from the selected material of the model or from the <b>Mask</b> layer<br>
%           (depending on selected entry in the <b>Add to</b> list of the <a href="ug_panel_segm.html">Segmentation Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>S</kbd></td>
%   <td>subtract <em>Selection</em> (<em>for all slices of the dataset</em>) from the selected material of the model or from the <b>Mask</b> layer<br>
%           (depending on selected entry in the <b>Add to</b> list of the <a href="ug_panel_segm.html">Segmentation Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd></td>
%   <td>subtract <em>Selection</em> (<em>for all slices and all time points of the dataset</em>) from the selected material of the model or from the <b>Mask</b> layer<br>
%           (depending on selected entry in the <b>Add to</b> list of the <a href="ug_panel_segm.html">Segmentation Panel</a></td>
% </tr>
% <tr>
%   <td><kbd>R</kbd></td>
%   <td>replace (<em>for the shown slice only</em>) the selected material
%   of the model or the <b>Mask</b> layer with the <em>Selection</em></td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>R</kbd></td>
%   <td>replace (<em>for all slices</em>) the selected material
%   of the model or the <b>Mask</b> layer with the <em>Selection</em></td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>Alt</kbd>+<kbd>R</kbd></td>
%   <td>replace (<em>for all slices and all time points</em>) the selected material
%   of the model or the <b>Mask</b> layer with the <em>Selection</em></td>
% </tr>
% <tr>
%   <td><kbd>C</kbd></td>
%   <td>clear (<em>for the shown slice only</em>) the <em>Selection</em> layer</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>C</kbd></td>
%   <td>clear (<em>for all slices</em>) the <em>Selection</em> layer</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>Alt</kbd>+<kbd>C</kbd></td>
%   <td>clear (<em>for all slices and all time points</em>) the <em>Selection</em> layer</td>
% </tr>
% <tr>
%   <td><kbd>F</kbd></td>
%   <td>fill holes (<em>for the shown slice only</em>) in the <em>Selection</em> layer</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>F</kbd></td>
%   <td>fill holes (<em>for all slices</em>) in the <em>Selection</em> layer</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>Alt</kbd>+<kbd>F</kbd></td>
%   <td>fill holes (<em>for all slices and all time points</em>) in the <em>Selection</em> layer</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>F</kbd></td>
%   <td>find index of material under the cursor and select it in the Segmentation table</td>
% </tr>
% <tr>
%   <td><kbd>Z</kbd></td>
%   <td>erode (shrink) (<em>for the shown slice only</em>) the <em>Selection</em> layer<br>
%       when the <b>3D</b> check box of the <a href="ug_panel_selection.html">Selection panel</a> is enabled erode in 3D space</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>Z</kbd></td>
%   <td>erode (shrink) (<em>for all slices</em>) the <em>Selection</em> layer in 2D</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>Alt</kbd>+<kbd>Z</kbd></td>
%   <td>erode (shrink) (<em>for all slices and all time points</em>) the <em>Selection</em> layer in 2D</td>
% </tr>
% <tr>
%   <td><kbd>X</kbd></td>
%   <td>dilate (expand) (<em>for the shown slice only</em>) the <em>Selection</em> layer<br>
%       when the <b>3D</b> check box of the <a href="ug_panel_selection.html">Selection panel</a> is enabled dilate in 3D space</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>X</kbd></td>
%   <td>dilate (expand) (<em>for all slices</em>) the <em>Selection</em> layer in 2D</td>
% </tr>
% <tr>
%   <td><kbd>&#8679; Shift</kbd>+<kbd>Alt</kbd>+<kbd>X</kbd></td>
%   <td>dilate (expand) (<em>for all slices and all time points</em>) the <em>Selection</em> layer in 2D</td>
% </tr>
% <tr>
%   <td><kbd>D</kbd></td>
%   <td>swap between the preferable fast-access selection tools, see
%           more in the <a href="ug_panel_segm.html">6. The "D" checkbox, to select fast access tools</a></td>
% </tr>
% <tr>
%   <td><kbd>E</kbd></td>
%   <td>toggle between two recently selected materials</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>E</kbd></td>
%   <td>toggle between current and previously selected image buffer</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>Z</kbd></td>
%   <td>undo the last action<br>To get further in the undo history use
%   the <b>Undo</b> button in the <a href="ug_gui_toolbar.html">toolbar</a>
%   <br>Undo is not implemented for actiond with 4D datasets</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>C</kbd></td>
%   <td>copy the current |Selection| layer to buffer</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>V</kbd></td>
%   <td>paste the stored |Selection| buffer to the shown slice</td>
% </tr>
% <tr>
%   <td><kbd>^ Ctrl</kbd>+<kbd>&#8679; Shift</kbd>+<kbd>V</kbd></td>
%   <td>paste the stored |Selection| buffer to all slices</td>
% </tr>
% <tr>
%   <td><kbd>Alt</kbd>+<kbd>1</kbd></td>
%   <td>switch the view to the XY plane using the image coordinates under the mouse cursor</td>
% </tr>
% <tr>
%   <td><kbd>Alt</kbd>+<kbd>2</kbd></td>
%   <td>switch the view to the YZ plane using the image coordinates under the mouse cursor</td>
% </tr>
% <tr>
%   <td><kbd>Alt</kbd>+<kbd>3</kbd></td>
%   <td>switch the view to the XZ plane using the image coordinates under the mouse cursor</td>
% </tr>
% </table>
% </body>
% </html>
%
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
