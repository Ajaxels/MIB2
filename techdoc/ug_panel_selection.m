%% Selection Panel
% Selection panel contatins tools for manipulation with the |Selection|
% layer. The |Selection| is one of three main segmentation layers (|Model, Selection, Mask|) which can be
% used in combibation with other layer. See more about segmentation layers
% in <ug_gui_data_layers.html the Data layers of Microscopy Image Browser section>.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
%%
% 
% <<images\PanelsSelection.png>>
%
%% *'A'* button
% Press to add |Selection| layer to the selected |Model| or |Mask| layer, the destination layer is selected using |Add to|
% list box in the <ug_panel_segm.html Segmentation panel>.
% 
% Shortcuts:
%
% * 'A', do addition for the currently shown slice only
% * Shift+'A', do addition for all slices of dataset
% * Shift+Alt+'A', do addition for all slices of dataset including the time
% dimension
% 
%%  *'S'* button
% Press to subtract |Selection| layer from the selected |Model| or |Mask| layer, the layer for subtraction is selected using |Add to|
% list box in the <ug_panel_segm.html Segmentation panel>.
% 
%
% <html>
% <table style="width: 550px; text-align: left;" cellspacing=2px cellpadding=2px >
% <tr style="font-weight: bold;">
% <td>Select from</td><td>Add to</td><td>Fix Selection to Material</td><td>Masked area</td><td>Result of subtraction</td>
% </tr>
% <tr style="background: #F0F8FF;"><td>Any</td><td>Mask</td><td>OFF</td><td>OFF</td><td>Mask - Selection</td></tr>
% <tr style="background: #F0F8FF;"><td>Nth Material</td><td>Mask</td><td>ON</td><td>OFF</td><td>Mask within selected material - Selection</td></tr>
% <tr style="background: #F0F8FF;"><td>Any</td><td>NOT Mask</td><td>OFF</td><td>OFF</td><td>All Materials - Selection</td></tr>
% <tr style="background: #F0F8FF;"><td>Nth Material</td><td>NOT Mask</td><td>ON</td><td>OFF</td><td>Selected material - Selection</td></tr>
% <tr style="background: #F0F8FF;"><td>Nth Material</td><td>NOT Mask</td><td>ON</td><td>ON</td><td>Selected material within the Mask - Selection</td></tr>
% </table>
% <br>
% </html>
%
% Shortcuts:
%
% * 'S', do subtraction for the current slice only
% * Shift+'S', do subtraction for all slices of the dataset
% * Shift+Alt+'S', do subtraction for all slices of dataset including the time
% dimension
% 
%
%%  *'R'* button
% Press to replace the selected in the |Add to| list box material (that
% could be either marerial of the model or the |Mask| layer) with the
% contents of the |Selection| layer. The |Add to| list box is located in the <ug_panel_segm.html Segmentation panel>. *_Note!_* The
% Replace is sensitive to the state of the |Masked area|
% checkbox in the <ug_panel_segm.html Segmentation panel>.
% 
% Shortcuts:
%
% * 'R', do replacement for the current slice only
% * Shift+'R', do replacement for all slices of the dataset
% * Shift+Alt+'R', do replacement for all slices of dataset including the time
% dimension
% 
%%  *'C'* button
% Press to clear the |Selection| layer.
% 
% Shortcuts:
%
% * 'C', clear the current slice only
% * Shift+'C', clear |Selection| for all slices of the dataset
% * Shift+Alt+'C', clear |Selection| for all slices of dataset including the time
% dimension
% 
%%  *'F'* button
% Press to fill holes in the |Selection| layer.
% 
% Shortcuts:
%
% * 'F', fill holes for the current slice only
% * Shift+'F', fill holes for all slices of the dataset
% * Shift+Alt+'F', fill holes for all slices of dataset including the time
% dimension
% 
%%  *'Erode'* button
% Press to perform binary erosion=shrinkage (|imerode| Matlab function) of the |Selection| 
% layer with the Strel size defined in the |Strel| edit box. 
% The erotion works also in 3D, check the |3D| check box.
% To get result as a difference between
% the current and the eroded selections check the |difference| checkbox. 
% 
% Shortcuts:
%
% * 'Z', erode |Selection| for the current slice only
% * Shift+'Z', erode |Selection| for all slices of the dataset
% * Shift+Alt+'Z', erode |Selection| for all slices of dataset including the time
% dimension
%
%%  *'Dilate'* button
% Press to perform binary dilation (expansion) (|imdilate| Matlab function) of the |Selection| layer with the 
% Strel size defined in the |Strel| edit box. To dilate in 3D check
% the |3D| checkbox in the |Selection| panel. To get result as a difference between
% the current and the dilated selections check the |difference| checkbox.
% 
% The dilation is also implemented in the _Adaptive mode_ (switched ON with the |Adapt| checkbox), when the amount of expansion is limited by the image intensities
% in the expanded areas. The magnitude of the adaptation parameter is
% regulated with an edit box next to the |Adapt.| check box. 
%
% Shortcuts:
%
% * 'X', dilate |Selection| for the current slice only
% * Shift+'X', dilate |Selection| for all slices of the dataset
% * Shift+Alt+'X', dilate |Selection| for all slices of dataset including the time
% dimension
%
%% Color channel combo box
% This combo box defines the color channel that will be used for the selection
% with the tools in the <ug_panel_segm.html |Segmentation| panel>.
%
%% *'3D'* checkbox
% Check it to do some of the image and |Mask/Model| manipulations in
% |3D|.
%
%% *'adapt.'* checkbox
%
% Select to perform adaptive dilation or selection of the supervoxels when using the <ug_panel_segm_tools.html Brush tool>. 
% When the shapes are dilated or supervoxels are selected the function calculates mean intensity values and standard deviation within
% the original shape. During dilation/brush only pixels that have intensities
% mean+-standard deviation multiplied with |Adapt.| coefficients are taken.
%
%%  *'difference'* checkbox
% When checked the results of |Erosion| and |Dilation| will be the differences
% between existing and eroded/dilated |Selection| layers.
%
%% *Strel* edit box
% Defines size of the structural element that is used during erosion (the *Erode* button) and dilation (the *Dilate* button). 
% The size of the |Strel| element can be specified as a single number or as two semi-colon separated numbers. For example
% entering [ *3; 5* ] defines size of the Strel element as *XY = 3 x 5* pixels for 2D, or as *3 x 3 x 5* pixels for 3D.
%
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
