%% ROI Panel
% ROI panel provides a way to add one or more ROI (Region of Interest)
% above the image. The ROIs may be used to analyse or do filtering in only the ROI defined parts of the dataset.
%
% The implementation of the ROI mode was updated in MIB version 0.998 using
% the code of the <http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility *Image Measurement Utility*> written by Jan Neggers, 
% Eindhoven Univeristy of Technology.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
% 
%%
%
% <<images\PanelsROI.png>>
%
%% The [class.dropdown]ROI type &#9660;[/class] dropdown 
%
% Define the type of ROI to add. Several ROI types are available. By default, an interactive mode 
% for placing the ROIs is enabled. However, it is possible to add ROIs manually 
% using the *Define parameters manually* panel under the ROI type combo box.
%
% * *Rectangle*, rectangular ROI. To add, press the [class.kbd]Add[/class] button
% and define two corners of the ROI using the left mouse button. Modify the ROI
% if needed and double click above the ROI to accept it
% * *Ellipse*, ellipsoid ROI. To add, press the [class.kbd]Add[/class] button
% and define the center and a side of the ellipse using the left mouse button. Modify the ROI
% if needed and double click above the ROI to accept it
% * *Polyline*, adds a polyline object with the desired number of vertices. The
% number of vertices can be selected in the |Define parameters manually|
% panel. To add, press the [class.kbd]Add[/class] button
% and click as many times as the number of defined vertices. Modify the ROI
% if needed (it is possible to add extra vertices: press and hold the [class.kbd]A[/class]
% key followed by pressing the left mouse button to add a new vertex). To remove a vertex, press the 
% right mouse button above the vertex and select [class.kbd]Delete[/class]. Finally, double click above the ROI to accept it
% * *Lasso*, a freehand drawing of a ROI. To add, press the [class.kbd]Add[/class] button,
% hold the left mouse key while drawing the ROI.  After the ROI has been drawn, it is converted 
% into the ROI polyline object with a suggestion for reducing the number of vertices 
% (a large number of vertices reduces the rendering of images significantly,
% so it is recommended to reduce the number of vertices during this conversion to the ROI polyline).
%
%% Define parameters manually
% This panel offers a posibility to place ROI to specific position. 
% To do that, please check the [class.kbd][&#10003;] *manually*[/class] checkbox and provide required
% coordinates. When done press the [class.kbd]Add[/class] button to add a ROI.
%
%% [class.kbd][&#10003;] *Fix aspect ratio*[/class]
% This checkbox can be used to fix aspect ratio of ROIs during initial
% placing or later during their modification.
%
%% The [class.kbd]Add[/class] button
% Press the [class.kbd]Add[/class] button to add a ROI to the image.
%
%% The [class.kbd]Remove[/class] button
% Press the [class.kbd]Remove[/class] button to delete a ROI highlighed in the |ROI list|.
%
%% The [class.kbd]ROI to Selection [/class] button
% Add area under the shown ROI to the Selection layer.
%
%% ROI List
% The |ROI List| may be used to select single or all ROIs for filtering or
% analysis. Additional actions are available for the ROIs:
%
% 
% <<images\PanelsROIContext.png>>
% 
% 
% 
% * *Rename*, change the name of ROI
% * *Edit*, modify position of the ROI. Use double click to finish the
% editing. The [class.kbd]A[/class] key shortcut allows to add a vertix to the polyline type
% of ROIs
% * *Remove*, delete the ROI from the list
% 
%
%% Options
% Define visualization options for ROIs. It is possible to tweak type, size, and color of
% the markers, width and color of the lines, color and size of the label
%
%% The [class.kbd]Load[/class] button
%
% Load ROIs from a disk. 
%
%% The [class.kbd]Save[/class] button
%
% Save the ROIs information to disk in MATLAB format (a structure with _label,
% type, X, Y, orientation_ fields).
%
%% [class.kbd][&#10003;] *Show label*[/class]
%
% When enabled, a text field with the ROI's label is displayed in
% the <ug_panel_im_view.html Image View panel>.
%
%% [class.kbd][&#10003;] *Show ROI*[/class]
%
% When checked the ROIs are shown in the <ug_panel_im_view.html Image View panel>. Alternatively the viewing state of 
% the ROI objects may be switched using the [class.kbd]|R|[/class] button in the <ug_gui_toolbar.html Toolbar>.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
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
