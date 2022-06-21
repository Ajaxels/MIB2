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
%% ROI type combo box
% Define type of a ROI to add. Several ROI types are available. By default,
% an inteactive mode for placing of the ROIs is enabled, however it is
% possible to add ROIs manually using the |Define parameters manually| panel under the |ROI type| combo box. 
%
% * *Rectangle*, rectangular ROI. To add: press the [class.kbd]Add[/class] button
% and define two corners of the ROI using the left mouse button. Modify ROI
% if needed and double click above the ROI to accept it
% * *Ellipse*, ellipsoid ROI. To add: press the [class.kbd]Add[/class] button
% and define a center and a side of the ellipse using the left mouse button. Modify ROI
% if needed and double click above the ROI to accept it
% * *Polyline*, adds a polyline object with desired number of vertices. The
% number of vertices can be selected in the |Define parameters manually|
% panel. To add: press the [class.kbd]Add[/class] button
% and click as many times as number of defined vertices. Modify ROI
% if needed (it is possible to add extra vertices: press and hold the [class.kbd]A[/class]
% key followed by pressing of the left mouse button to add a new vertice). To remove the
% vertex press right mouse button above the vertex and select [class.kbd]Delete[/class].
% Finally double click above the ROI to accept it
% * *Lasso*, a freehand drawing of a ROI. To add: press the [class.kbd]Add[/class] button,
% hold the left mouse key while drawing the ROI. After the RIO has been drawn
% it is converted into the ROI polyline object with the suggestion for the reduction of
% number of vertices (large number of vertices reduces rendering of images significantly, so it is recommended to 
% reduce number of vertices during this convertion to the ROI polyline)
%
%% Define parameters manually
% This panel offers a posibility to place ROI to specific position. 
% To do that, please check the [class.kbd][&#10003;] *manually*[/class] checkbox and provide required
% coordinates. When done press the [class.kbd]Add[/class] button to add a ROI.
%
%% Fix aspect ratio
% This checkbox can be used to fix aspect ratio of ROIs during initial
% placing or later during their modification.
%
%% Add button
% Press the [class.kbd]Add[/class] button to add a ROI to the image.
%
%% Remove button
% Press the [class.kbd]Remove[/class] button to delete a ROI highlighed in the |ROI list|.
%
%% ROI to Selection button
% Add area under the shown ROI to the Selection layer.
%
%% ROI List
% The |ROI List| may be used to select single or all ROIs for filtering or
% analysis. Additional actions are available for the ROIS:
%
% 
% <<images\PanelsROIContext.png>>
% 
% 
% 
% * *Rename*, change the name of ROI
% * *Edit*, modify position of the ROI. Use double click to finish the
% editing. The '*a*' key shortcut allows to add a vertix to the polyline type
% of ROIs
% * *Remove*, delete ROI from the list
% 
%
%% Options
% Define visualization options for ROIs
%
%% Load button
% Load ROI from a disk. 
%
%% Save button
% Save ROI information to disk in MATLAB format (a structure with _label,
% type, X, Y, orientation_ fields).
%
%% Show label
% When enabled, a text with the label of the selected ROI is displayed in
% the |Image View| panel.
%
%% Show ROI
% When checked the ROIs are shown in the |Image View| panel. Alternatively the viewing state of the ROI objects may be
% switched using the *|R|* button in the <ug_gui_toolbar.html Toolbar>.
%
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
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
% 	padding: 0.2em 0.4em; 
% 	font-family: inherit; 
% 	font-size: 1em;
% }
% [/cssClasses]
