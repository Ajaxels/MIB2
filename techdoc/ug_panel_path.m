%% Path Panel
% This panel is used to provide the path to the image dataset.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%%
% 
% <<images\PanelsPath.png>>
% 
%% 1. Logical drive combo box.
% This combo box is used for fast selection of logical drives. It is initialized during the start of 
% |MIB| and will show only those logical drives that were available during
% the initialization. *Note!* on MacOS and Linux this combo box has only
% the '\' option.
%
%% 2. '...' button
% This button is one of the ways to select a folder. It uses |uigetdir| Matlab built-in function.
%
%% 3. Current path edit box
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
% 
%
%% 4. List of recent directories
% Opens the list of recent directories from where datasets were loaded.
% A brief demonstration is available in the following video:
%
% <html>
% <a href="https://youtu.be/xx7pGehTJXA"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/xx7pGehTJXA</a>
% </html>
%
%% 6. Pixel Info field
% Pixel info field provides information about pixel location and intensity of pixels under the
% mouse pointer in <ug_panel_im_view.html the Image View panel> . The format is: |X, Y (Red channel:Green channel:Blue
% channel) / [index of material]|. 
% 
% The right mouse click starts a context menu, that can be used for jumping
% to any point of the dataset.
% 
% <<images\PanelsPathJumpTo.png>>
% 
%
%% 7. Log button
% Shows the log of actions that were performed for the current dataset. The
% action log is stored in the |ImageDescription| field in the TIF files. Each entry in the log list has a date/time stamp.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/1ql4cRxZ334"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/1ql4cRxZ334</a>
% </html>
%
% <<images\PanelsPathLog.png>>
%
% There are number of actions that are possible to do with
% the action log:
% 
% * *Print to Matlab* - prints the action log in the Matlab command window
% * *Copy to Clipboard* - stores the action log in the clipboard, so it can be pasted with Ctrl+V (Windows OS) command.
% * *Insert after* - inserts a new entry after the one which is highlighted
% * *Modify* - modifies the highlighted entry
% * *Delete* - deletes the highlighted entry
% * *Update* - the log is not updated automatically, so press this button to update it manually
% 
%% 8. Info button
% The |Info| button opens a window with a tree list of parameters for the opened dataset. 
%
% The XY image resolution is stored in the |XResolution| and |YResolution|
% fields, and in the BoundingBox info in the |ImageDescription| field. The
% search field allows to search the metadata for specific value. 
% 
% <<images\PanelsPathInfo.png>>
% 
%
%% 9. Zoom Edit box
% Zoom Edit box, allows selection of the desired zoom level.
%
%% 9. Help
% Access to this help page
%
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>


