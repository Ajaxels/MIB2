%% Selection Menu
% Actions that can be applied to the |Selection| layer. The |Selection| is one
% of three main segmentation layers (|Model, Selection, Mask|) which can be
% used in combibation with other layer. See more about segmentation layers
% in <ug_gui_data_layers.html the Data layers of Microscopy Image Browser section>.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
%%
% 
% <<images\menuSelection.png>>
% 
%% Selection to Buffer
% Allows to Copy ([class.kbd]Ctrl[/class]+[class.kbd]C[/class] shortcut) the |Selection| of the currently shown slice to a buffer, which later can be pasted 
% to any other slice with the [class.kbd]Ctrl[/class]+[class.kbd]V[/class] shortcut or to all slices ([class.kbd]Ctrl[/class]+[class.kbd]&#8679; Shift[/class]+[class.kbd]V[/class]).
% In addition there is an option to clear the buffer
% (|Menu->Selection->Selection to Buffer->Clear|); this action clears only
% the buffer and does not affect any of the other layers (|Selection, Mask,
% Model|).
%% ..->Mask
% Allows the modification of the |Mask| layer by the contents of the |Selection| layer. It
% is possible to replace the mask with the selection, add selection to the
% mask, or remove selection from the mask. This action can be applied
% for the currently shown slice or for the whole volume.
%% Morphological 2D/3D operations
%
% <html>
% A brief demonstration is available in the following videos:<br>
% <a href="https://youtu.be/L-w8eGDfUkU"><img
% style="vertical-align:middle;" src="images\youtube2.png">
% https://youtu.be/L-w8eGDfUkU</a><br>
% <a href="https://youtu.be/Au4vb7max9Q"><img style="vertical-align:middle;" src="images\youtube2.png"> Skeleton for 3D objects, https://youtu.be/Au4vb7max9Q</a>
% </html>
%
% <<images\MenuSelectionMorphOps.png>>
%
% Performs morphological operations for 2D and 3D objects of the |Selection| layer. See more in the description of MATLAB |bwmorph|, |bwmorph3| and |bwskel|
% functions. 
%
% [dtls][smry] *List of available morphological operations* [/smry]
%
% <html>
% <ul>
% <li> <b>Branch points</b> - (2D/3D) find branch points of skeleton;</li>
% <li> <b>Clean</b> - (3D) remove isolated voxels;</li>
% <li> <b>Diagonal fill</b> - (Diag) uses diagonal fill to eliminate 8-connectivity of thebackground;</li>
% <li> <b>End points</b> - (2D/3D)finds end points of skeleton;</li>
% <li> <b>Fill</b> - (3D) Fill isolated interior voxels, setting them to 1.<br>Isolated interior voxels are individual voxels that are set to 0 that are surrounded (6-connected) by voxels set to 1;</li>
% <li> <b>Majority</b> - (3D) Keep a voxel set to 1 if 14 or more voxels (the majority) in its 3-by-3-by-3, 26-connected neighborhood are set to 1; otherwise, set the voxel to 0;</li>
% <li> <b>Remove</b> - (3D) Remove interior voxels, setting it to 0.\nInterior voxels are individual voxels that are set to 1 that are surrounded (6-connected) by voxels set to 1;</li>
% <li> <b>Skeleton</b> - (Skel, 2D/3D) with n = Inf, removes pixels on the boundaries of objects but does not allow objects to break apart. The 
% remaining pixels make up the image skeleton. This option preserves the Euler number;</li>
% <li> <b>Spur</b> - removes spur pixels, <em>i.e.</em> the pixels that have exactly one 8-connected neighbor. For example, spur essentially removes the endpoints of lines</li>
% <li> <b>Thin</b> - with n = Inf, thins objects to lines. It removes pixels so that an object without holes shrinks to a
% minimally connected stroke, and an object with holes shrinks to a
% connected ring halfway between each hole and the outer boundary;
% this option preserves the Euler number. Use the "remove branches" option
% to remove small branches from each line profile <a href="https://youtu.be/rqZbH3Jpru8"><img style="vertical-align:middle;" src="images\youtube.png"></a></li>
% <li> <b>Ultimate erosion</b>, (2D/3D) performs ultimate erosion, <em>i.e.</em> object -> to point</li>
% </ul>
% </html>
%
% [/dtls]
%
%
%% Expand to mask borders
% Each selected area will be expanded to match the borders of the mask that
% contains selected area.
%
%% Interpolate
% Interpolation of the |Selection| layer is a method to reconstruct
% |Selection| on empty slices between two slices containing the |Selection|
% layer. Shortcut for this action is [class.kbd]i[/class]. 
%
% There are two types of interpolators. Select the best suitable interpolator in the <ug_gui_menu_file_preferences.html Preferences dialog> 
% or by pressing the Interpolator type button in the <ug_gui_toolbar.html Toolbar>
%
% [dtls][smry] *Shape interpolation example* [/smry]
% 
% * *shape* - good for interpolation of the blobs (filled structures).
%
% 
% <<images/MenuSelectionInterpolationShape.jpg>>
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=4m3s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=4m3s</a>
% </html>
%
% [/dtls]
%
% [dtls][smry] *Line interpolation example* [/smry]
%
% * *line* - good for interpolation of the *not closed* lines (such as membranes).
%%
% 
% <<images/MenuSelectionInterpolationLine.jpg>>
% 
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/ZcJQb59YzUA?t=2m22s"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/ZcJQb59YzUA?t=2m22s</a>
% </html>
% 
% [/dtls]
%
% *_Please note!_* there should be only one object in the |Selection| layer on the starting and ending slices.
% [br8]
%
%% Replace selected area in the image
% Replaces image intensities in the selected areas with new values. A new
% dialog will ask to provide new intensities, slices, and the color channels.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/fNz1vGq7Hb0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/fNz1vGq7Hb0</a>
% </html>
%
%% Smooth selection
% Smoothes the |Selection| layer in 2D or 3D space.
%
%% Invert selection
% Inverts the current selection for the whole dataset.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
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