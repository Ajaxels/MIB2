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
%% The *[class.kbd]A[/class]* button
% Press to add |Selection| layer to the selected |Model| or |Mask| layer, the destination layer is selected using |Add to|
% list box in the <ug_panel_segm.html Segmentation panel>.
% 
% <<images\SelectionPanelOperationsAdd.png>>
% 
% 
% [dtls][smry] *Shortcuts* [/smry]
%
% * [class.kbd]A[/class], do addition for the currently shown slice only
% * [class.kbd]&#8679; Shift[/class] + [class.kbd]A[/class], do addition for all slices of dataset
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]Alt[/class] + [class.kbd]A[/class], do addition for all slices of dataset including the time
% dimension
% 
% [/dtls]
% [br8]
% 
%%  The *[class.kbd]S[/class]* button
% Press to subtract |Selection| layer from the selected |Model| or |Mask| layer, the layer for subtraction is selected using |Add to|
% list box in the <ug_panel_segm.html Segmentation panel>.
% 
% 
% <<images\SelectionPanelOperationsSubtract.png>>
%
% [dtls][smry] *Possible useage combinations* [/smry]
%
% <html>
% <table style="width: 550px; text-align: left;" cellspacing=2px cellpadding=2px >
% <tr style="font-weight: bold;background: #FFB74D;">
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
% [/dtls]
% 
% [dtls][smry] *Shortcuts* [/smry]
%
% * [class.kbd]S[/class], do subtraction for the current slice only
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]S[/class], do subtraction for all slices of the dataset
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]Alt[/class]+[class.kbd]S[/class]', do subtraction for all slices of dataset including the time
% dimension
% 
% [/dtls]
% [br8]
%
%%  The *[class.kbd]R[/class]* button
% Press to replace the selected in the |Add to| list box material (that
% could be either marerial of the model or the |Mask| layer) with the
% contents of the |Selection| layer. The |Add to| list box is located in the <ug_panel_segm.html Segmentation panel>. *_Note!_* The
% Replace is sensitive to the state of the [class.kbd][&#10003;] *Masked area*[/class]
% checkbox in the <ug_panel_segm.html Segmentation panel>.
% 
% <<images\SelectionPanelOperationsReplace.png>>
% 
% [dtls][smry] *Shortcuts* [/smry]
%
% * [class.kbd]R[/class], do replacement for the current slice only
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]R[/class], do replacement for all slices of the dataset
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]Alt[/class]+[class.kbd]R[/class], do replacement for all slices of dataset including the time dimension
%
% [/dtls]
% [br8]
% 
%%  The *[class.kbd]C[/class]* button
% Press to clear the |Selection| layer.
% 
% <<images\SelectionPanelOperationsClear.png>>
%
% [dtls][smry] *Shortcuts* [/smry]
%
% * [class.kbd]C[/class], clear the current slice only
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]C[/class], clear |Selection| for all slices of the dataset
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]Alt[/class]+[class.kbd]C[/class], clear |Selection| for all slices of dataset including the time
% dimension
% 
% [/dtls]
% [br8]
%
%%  The *[class.kbd]F[/class]* button
% Press to fill holes in the |Selection| layer.
%  
% <<images\SelectionPanelOperationsFill.png>>
%
% [dtls][smry] *Shortcuts* [/smry]
%
% * [class.kbd]F[/class], fill holes for the current slice only
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]F[/class], fill holes for all slices of the dataset
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]Alt[/class]+[class.kbd]F[/class], fill holes for all slices of dataset including the time dimension
% 
% [/dtls]
% [br8]
%
%%  The *[class.kbd]Erode[/class]* button
% Press to perform binary erosion=shrinkage (|imerode| MATLAB function) of the |Selection| 
% layer with the Strel size defined in the |Strel| edit box. 
% The erotion works also in 3D, check the |3D| check box.
% To get result as a difference between
% the current and the eroded selections check the [class.kbd][&#10003;] *difference*[/class] checkbox. 
% 
% <<images\SelectionPanelOperationsErode.png>>
%
% [dtls][smry] *Shortcuts* [/smry]
%
% * [class.kbd]Z[/class], erode |Selection| for the current slice only
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]Z[/class], erode |Selection| for all slices of the dataset
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]Alt[/class]+[class.kbd]Z[/class], erode |Selection| for all slices of dataset including the time
% dimension
%
% [/dtls]
% [br8]
%
%%  The *[class.kbd]Dilate[/class]* button
% Press to perform binary dilation (expansion) (|imdilate| MATLAB function) of the |Selection| layer with the 
% Strel size defined in the |Strel| edit box. To dilate in 3D check
% the [class.kbd][&#10003;] *3D*[/class] checkbox in the |Selection| panel. To get result as a difference between
% the current and the dilated selections check the [class.kbd][&#10003;] *difference*[/class] checkbox.
%  
% <<images\SelectionPanelOperationsDilate.png>>
%
% The dilation is also implemented in the _Adaptive mode_ (switched ON with the [class.kbd][&#10003;] *Adapt*[/class] checkbox), when the amount of expansion is limited by the image intensities
% in the expanded areas. The magnitude of the adaptation parameter is
% regulated with an edit box next to the |Adapt.| check box. 
%
% [dtls][smry] *Shortcuts* [/smry]
%
% * [class.kbd]X[/class], dilate |Selection| for the current slice only
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]X[/class], dilate |Selection| for all slices of the dataset
% * [class.kbd]&#8679; Shift[/class]+[class.kbd]Alt[/class]+[class.kbd]X[/class], dilate |Selection| for all slices of dataset including the time
% dimension
%
% [/dtls]
% [br8]
%
%% Color channel combo box
% This combo box defines the color channel that will be used for the selection
% with the tools in the <ug_panel_segm.html |Segmentation| panel>.
%
%% The [class.kbd][&#10003;] *3D*[/class] checkbox
% Check it to do some of the image and |Mask/Model| manipulations in
% |3D|.
%
%% The [class.kbd][&#10003;] *adapt.*[/class] checkbox
%
% Select to perform adaptive dilation or selection of the supervoxels when using the <ug_panel_segm_tools.html Brush tool>. 
% When the shapes are dilated or supervoxels are selected the function calculates mean intensity values and standard deviation within
% the original shape. During dilation/brush only pixels that have intensities
% mean+-standard deviation multiplied with |Adapt.| coefficients are taken.
%
%%  The [class.kbd][&#10003;] *difference*[/class] checkbox
% When checked the results of |Erosion| and |Dilation| will be the differences
% between existing and eroded/dilated |Selection| layers.
%
%% The *Strel* edit box
% Defines size of the structural element that is used during erosion (the *Erode* button) and dilation (the *Dilate* button). 
% The size of the |Strel| element can be specified as a single number or as two semi-colon separated numbers. For example
% entering [ *3; 5* ] defines size of the Strel element as *XY = 3 x 5* pixels for 2D, or as *3 x 3 x 5* pixels for 3D.
%
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
% [cssClasses]
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
