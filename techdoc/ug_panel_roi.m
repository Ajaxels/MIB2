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
%% 1. ROI type combo box
% Define type of a ROI to add. Several ROI types are available. By default,
% an inteactive mode for placing of the ROIs is enabled, however it is
% possible to add ROIs manually using the |Define parameters manually| panel (*2.*) under the |ROI type| combo box. 
%
% * *Rectangle*, rectangular ROI. To add: press the |Add| button (*4.*)
% and define two corners of the ROI using the left mouse button. Modify ROI
% if needed and double click above the ROI to accept it
% * *Ellipse*, ellipsoid ROI. To add: press the |Add| button (*4.*)
% and define a center and a side of the ellipse using the left mouse button. Modify ROI
% if needed and double click above the ROI to accept it
% * *Polyline*, adds a polyline object with desired number of vertices. The
% number of vertices can be selected in the |Define parameters manually|
% panel. To add: press the |Add| button (*4.*)
% and click as many times as number of defined vertices. Modify ROI
% if needed (it is possible to add extra vertices: press and hold the |A|
% key followed by pressing of the left mouse button to add a new vertice). To remove the
% vertex press right mouse button above the vertex and select |Delete|.
% Finally double click above the ROI to accept it
% * *Lasso*, a freehand drawing of a ROI. To add: press the |Add| button (*4.*),
% hold the left mouse key while drawing the ROI. After the RIO has been drawn
% it is converted into the ROI polyline object with the suggestion for the reduction of
% number of vertices (large number of vertices reduces rendering of images significantly, so it is recommended to 
% reduce number of vertices during this convertion to the ROI polyline)
%% 2. Define parameters manually
% This panel offers a posibility to place ROI to specific position. 
% To do that, please check the |manually| checkbox and provide required
% coordinates. When done press the |Add| button (*4.*) to add a ROI.
%% 3. Fix aspect ratio
% This checkbox can be used to fix aspect ratio of ROIs during initial
% placing or later during their modification.
%% 4. Add button
% Press the |Add| button to add a ROI to the image.
%
%% 5. Remove button
% Press the |Remove| button to delete a ROI highlighed in the |ROI list|.
%
%% 6. ROI to Selection button
% Add area under the shown ROI to the Selection layer.
%
%% 7. ROI List
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
%% 8. Options
% Define visualization options for ROIs
%
%% 9. Load button
% Load ROI from a disk. 
%
%% 10. Save button
% Save ROI information to disk in Matlab format (a structure with _label,
% type, X, Y, orientation_ fields).
%% 11. Show label
% When enabled, a text with the label of the selected ROI is displayed in
% the |Image View| panel.
%% 12. Show ROI
% When checked the ROIs are shown in the |Image View| panel. Alternatively the viewing state of the ROI objects may be
% switched using the *|R|* button in the <ug_gui_toolbar.html Toolbar>.
%
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>

