%% The View Settings Panel
% The View Settings panel gives basic tools for visualization of the
% dataset.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%%
% 
% <<images\PanelsViewSettings.png>>
% 
%% 1. The Colors table and the [class.kbd][&#10003;] *LUT*[/class] checkbox
% This table contains a list of color channels of the dataset.
% The color channels may be switched on and off (a combination of [class.kbd]Ctrl[/class]+[class.kbd]left mouse click[/class] 
% above checkboxes turns on selection of a single color channel). 
% The image is generated depending on selection state of the |LUT checkbox|. When the [class.kbd][&#10003;] *LUT*[/class] checkbox is selected |MIB|
% generates the final image based on defined colors (the third column in this table).
% *Note!* When the [class.kbd][&#10003;] *LUT*[/class] checkbox is unchecked the maximal number of colors that can be shown simultaneously is limited to 3. If more than 3
% colors are selected then only the first 3 color channels are shown. 
%
% <html>
% A brief demonstration of work with color channels is available in the following video:<br>
% <a href="https://youtu.be/gT-c8TiLcuY"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/gT-c8TiLcuY</a>
% </html>
%
% [dtls][smry] *The right mouse button gives access to additional color channel actions* [/smry]
% 
% * *Insert empty channel...*, insert an empty channel (intensity of all pixels is 0) to the specified position
% * *Copy channel*, to copy the selected color channel to a new channel (available also from <ug_gui_menu_image.html Menu-Image-Color Channels>)
% * *Invert channel*, to invert the selected color channel (available also from <ug_gui_menu_image.html Menu-Image-Color Channels>)
% * *Rotate channel*, rotate the specified color channel (available also from <ug_gui_menu_image.html Menu-Image-Color Channels>)
% * *Shift channel*, allows to shift a channel by X and Y pixels (available also from <ug_gui_menu_image.html Menu-Image-Color Channels>)
% * *Swap channels*, to swap the selected color channel with another one (available also from <ug_gui_menu_image.html Menu-Image-Color Channels>)
% * *Delete channel*, to delete the selected color channel (available also from <ug_gui_menu_image.html Menu-Image-Color Channels>)
% * *Set LUT color*, to set colors for use with the [class.kbd][&#10003;] *LUT*[/class] checkbox (available also from <ug_gui_menu_file_preferences.html Menu-File-Preferences>)
% 
% [/dtls]
% [br8]
%
%% 2. The Show Model check box
% Switch on/off the |Model| layer. This check box has a shortcut [class.kbd]space[/class]. 
% [br8]
%
%% 3. The Show Mask check box
% Switch on/off |Mask| layer. This check box has a shortcut [class.kbd]Ctrl[/class] + [class.kbd]space[/class]. 
% [br8]
%
%% 4. The Hide image check box
% Switch on/off display of the |Image| layer.
% [br8]
%
%% 5. The Annotations check box
% Switch on/off <ug_panel_segm_tools.html#3 Annotation layer> and <ug_gui_menu_tools_measure.html measurements>.
% [br8]
%
%% 6. Display
% Press to start display adjustments GUI tool, <ug_panel_adjustments.html *see more here*>. 
%
% <<images\PanelsViewSettingsDisplay.png>>
%
%% 7. The Auto button and checkboxes
%
% *The Auto button*
% Auto brightness adjustment of complete dataset. The function asks
% for saturation parameters for both low and high intensity borders. As
% a result, the image intensities are _*recalculated*_ to increase the contrast.
% *Note*, the function behaviour is affected by the |stack|
% switch. When the |stack| switch is |off| the brightness
% is individually adjusted for each frame of the dataset. Alternatively, when checked,
% the function first finds minimal and maximal stretching parameters for
% the whole dataset and then uses these values to adjust the contrast.
%
% *The [class.kbd][&#10003;] *on fly*[/class] checkbox automatically adjust contrast for each shown image without recalculation
% of intensities of the actual data.
% [br8]
%
%
%% 8. The Transparency sliders
% * *The top trasparency slider* regulates transparency of the |Model| layer 
% from opaque (slider in the left position) to transparent (slider in the right position). 
% * *The middle transparency slider* changes transparency values for
% the |Mask| layers from opaque to transparent.
% * *The lower trasparency slider* change transparency values for
% the |Selection| layer from opaque to transparent.
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

