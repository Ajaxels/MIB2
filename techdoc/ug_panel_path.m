%% Path Panel
% The Path Panel is a feature used to provide the path to the image dataset. It allows users to specify the location or 
% directory with the image files.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%%
% 
% <<images\PanelsPath.png>>
% 
%% The [class.dropdown]Logical drive &#9660;[/class] dropdown
%
% The Logical drive dropdown is a feature that allows for fast selection of logical drives. It is initialized during the start of 
% |MIB| and will show only those logical drives that were available during
% the initialization.[br]
% *Note!* on MacOS and Linux this combo box has only the [class.dropdown]*\* &#9660;[/class] option.
%
%% The [class.kbd]'...'[/class] button
% This button is one of the ways to select the current directory. It uses |uigetdir| MATLAB built-in function.
%
%% The [class.dropdown]Current path[/class] edit box
% Current path edit box shows the path of the current folder. The contents of the folder is
% shown in the <ug_panel_dir.html |Directory Contents panel|>. 
%
% The right mouse button click opens a context menu with the following
% options:
%
% 
% * *Copy to clipboard*, copy path to the system clipboard
% * *Open directory in the file explorer*, start system specific file explorer
%
% <<images\PanelsPathDropdown.png>>
% 
%
%% List of recent directories
% Opens the list of recent directories from where datasets were loaded.
% A brief demonstration is available in the following video:
%
% <html>
% <a href="https://youtu.be/xx7pGehTJXA"><img style="vertical-align:middle;" src="images\youtube2.png">  MIB in brief: list of recent directories (https://youtu.be/xx7pGehTJXA)</a>
% </html>
%
%% The Pixel Info field
% TThe Pixel Info field is a feature that provides information about the pixel location and intensity of pixels under 
% the mouse pointer in the <ug_panel_im_view.html the Image View panel>.[br]
% The format of the Pixel Info field is: [class.code]X, Y (Red channel:Green channel:Blue channel) / [index of material][/class]. 
% [br]
% By hovering the mouse pointer over an image in the Image View panel, the Pixel Info field updates 
% in real-time to display the information for the pixel under the cursor. This can be useful for analyzing 
% specific pixel values, identifying color information, or navigating to specific points in the dataset.
% [br]
% In addition to displaying pixel information, right-clicking within the Pixel Info field opens a context menu. 
% This menu may provide options for jumping to any point of the dataset:[br]
% <<images\PanelsPathJumpTo.png>>
% 
%
%% The [class.kbd]Log[/class] button
%
% The [class.kbd]Log[/class] button is a feature that shows the log of actions that were performed for the current dataset. 
% This log provides a record of the actions taken on the dataset, allowing users to track and review the history of changes made.
% The action log is stored in the |ImageDescription| field in the TIF files. Each entry in the log list has a date/time stamp.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/1ql4cRxZ334"><img style="vertical-align:middle;" src="images\youtube2.png">  MIB in brief: Log of performed actions (https://youtu.be/1ql4cRxZ334)</a>
% </html>
%
% <<images\PanelsPathLog.png>>
%
% There are number of actions that are possible to do with
% the action log:
% 
% * *Print to MATLAB*,  this action allows you to print the action log in the MATLAB command window. This can be useful for reviewing the log directly within the MATLAB environment
% * *Copy to Clipboard*, this action allows you to store the action log in the clipboard. Once copied, you can paste the log using the Ctrl+V command (on Windows OS) into another application or document. This can be useful for sharing or documenting the log
% * *Insert after*, this action allows you to insert a new entry after the one that is currently highlighted in the action log. This can be useful for adding additional information or recording new actions that were performed
% * *Modify*, this action allows you to modify the highlighted entry in the action log. You can make changes to the existing entry, such as updating the description or adding additional details
% * *Delete*, this action allows you to delete the highlighted entry from the action log. This can be useful for removing unnecessary or incorrect entries from the log
% * *Update*, under some circumstances the action log is may not be updated automatically, so pressing this button manually updates the log
% 
%% The [class.kbd]Info[/class] button
%
% The Info button opens a window with a tree list of parameters for the opened dataset. 
%
% The XY image resolution is stored in the |XResolution| and |YResolution|
% fields, and in the BoundingBox info in the |ImageDescription| field. The
% search field allows to search the metadata for specific value. 
% 
% <<images\PanelsPathInfo.png>>
% 
%
%% The [class.dropdown]Zoom[/class] edit box
% Zoom Edit box, allows selection of the desired zoom level.
%
% <<images\PanelsPathZoom.png>>
% 
%
%% Help
% Access to this help page
%
%% Right mouse click opens a dropdown menu
%
% When clicking on an empty area of within this panel an additiona menu
% appears allowing to hide/show the following panels. This allows to
% increase space occupied by the Image view panel
% 
% <<images\PanelsImageView_dropdown.jpg>>
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

