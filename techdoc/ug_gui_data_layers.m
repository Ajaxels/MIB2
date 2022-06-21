%% Data layers of Microscopy Image Browser (Image, Model, Mask, Selection)
% Microscopy Image Browser has a layered structure of keeping opened
% datasets in the memory. Each opened image dataset is stored in the |Image| 
% layer. The |Image| layer is supplemented with additional |Model|, |Mask|
% and |Selection| layers with equal to the |Image| layer X, Y,
% Z-dimensions. These additional layers are intended for the image segmentation process.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
%
%% General organization
%
% For the visualization, all the layers are assembled together to show 
% an image displayed in the <ug_panel_im_view.html Image View panel> of MIB. 
% Each layer may be switched on and off; transparency and colors may also be modified.  
%
% 
% <<images\DataLayersToFinalImage.jpg>>
% 
%
%
% To preserve the computer memory by default all additional layers
% (|Model|, |Mask|, and |Selection|) are kept in the same data block of the 
% 8-bit unsigned integer class. Which limits number of materials to 63, but
% reduce memory requirements. Alternatively, it is possible to increase
% number of materials to 255. However, in this case MIB will store each
% additional layer in a separate data block (variable), which increase
% memory requirements in two times. The type of the
% organization can be selected in <ug_gui_menu_file_preferences.html the
% Preferences dialog> (|Menu->File->Preferences|).
%
% [dtls][smry] *Image example* [/smry]
% 
% <<images\DataLayers.jpg>>
%
% [/dtls]
% [br8]
%
%% Image layer 
%
% The |Image| layer contains 2D-4D microscopy dataset. It is the basic
% layer that is always present. 
%
%% Selection layer
% The |Selection| layer is required for the image segmentation. It is a
% temporary layer that can be easily modified using manual or some of the
% automatic segmentation tools. By default, it is shown in the green color
% (the color can be selected from <ug_gui_menu_file_preferences.html the
% Preferences dialog>. 
%
% The segmentation routines affect only the |Selection| layer (except few 
% automatic routines that modify the |Mask| layer) and do not affect the |Model| layer that is
% defined to store final results of the segmentation. So any mistake done during the segmentation does not affect the existing
% model and can be potentially fixed using one of the following methods:
% 
% # Undone the recent actions using the [class.kbd]Ctrl[/class]+[class.kbd]Z[/class] shortcut, or the Undo button
% in the <ug_gui_toolbar.html toolbar>
% # Manually fixed using the brush tool in the eraser mode: use the brush
% with the [class.kbd]Control[/class] key pressed (see more in the <ug_panel_segm_tools.html description of the Brush tool>)
% # The |Selection| layer may be cleared completely using the [class.kbd]C[/class] shortcut
% (Use the [class.kbd]&#8679; Shift[/class]+[class.kbd]C[/class] shortcut to clear selection for the whole dataset).
%
% When selection is good enough to be accepeted it should be transferred to
% the |Model| layer (using the [class.kbd]A[/class]/[class.kbd]R[/class] or [class.kbd]&#8679; Shift[/class]+[class.kbd]A[/class]/[class.kbd]R[/class] shortcuts).
%
%% Model layer
% The |Model| layer contains the final results of the segmentation. It may
% be saved to a file, visualized and analysed. 
%
%% Mask layer
% The |Mask| layer is an auxiliary segmentation layer. The purpose of this
% layer is to define certain areas that may be further analyzed or filtered 
% (for example, using the Mask Statistics (Menu->Mask->Mask Statistics))
% independently from the |Selection| and |Model| layers. 
% 
% Also the |Mask| layer is used for local black-and-white thresholding,
% where the areas for thresholding are defined by the |Mask| layer.
% 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
%
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