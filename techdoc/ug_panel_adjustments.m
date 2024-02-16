%% The Adjust display window
% This window allows to adjust the contrast of the dataset individually for each color channel. The intensity values for the 
% currently shown slice can be checked in the histogram at the bottom of the window.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/WhpzGMyslZU"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/WhpzGMyslZU</a>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*> |*-->*| <ug_panel_view_settings.html *View settings*>
%
%%
%
% <<images\PanelsViewSettingsDisplay.png>>
%
%% Parameters
% [class.h3]List of widgets:[/class]
%
% <html>
% <table>
% <table style="width: 800px; text-align: left; border: 0px; line-height: 1.5" cellspacing=2px cellpadding=2px >
% <tr>
%   <td style="width:280px"><b>Color channel combobox</b></td>
%   <td>choose color channel for adjustment
%   </td>
% </tr>
% <tr>
%   <td><b>Min slider and editbox</b><br>
%       <em>define the black point</em><br>
%       <img src="images\panelsDisplayAdj_min.png"></td>
%   <td>selection the black point; all intensities below this value will be
%   rendered as black.<br>
%   The <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right mouse click</span> above the slider sets its value to 1.<br>
%   <b>Note!</b><br>
%   it is also possible to set this value using the <span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> left mouse click</span> on the 
%   histogram plot at the bottom of the window<br><br>
%   Use the <span class="kbd">min</span> button to find minimal intensity value for the selected color
%   channel and assign it to black. Additionally, <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right mouse click</span> over the button 
%   opens a menu allowing to define the black point by excluding % of
%   points from the from the historam of intensities.<br>
%   The black point intensity can be directly entered in the editbox above
%   the slider; the negative values can also be used.
%   </td>
% </tr>
% <tr>
%   <td><b>Max slider and editbox</b><br>
%   <em>define the black point</em><br>
%       <img src="images\panelsDisplayAdj_max.png"></td>
%   <td>selection the white point; all intensities above this value will be rendered as pure color or white. 
%   The <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right mouse click</span> above the slider sets its value to maximal posible 
%   for the current image class.<br>
%   <b>Note!</b><br>
%   it is also possible to set this value using the <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right
%   mouse click</span> on the histogram plot at the bottom of the
%   window<br><br>
%   Use the <span class="kbd">max</span> button to find maximal intensity value for the selected color
%   channel and assign it to white. <br>
%   Additionally, <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right mouse click</span> over the button opens a menu allowing to define the
%   white point from the historam of intentities. <br>
%   The white point intensity can be directly entered in the editbox above
%   the slider; values above the maximal value of the image class can also be used.
%   </td>
% </tr>
% <tr>
%   <td><b>Gamma</b></td>
%   <td>allows modification of gamma parameters. Gamma values below 1 enhance
%       high intensity values, and Gamma values above 1 enhance low intensity
%       values.<br>
%       The <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right mouse click</span> above the slider sets this value to 1%   </td>
% </tr>
% <tr>
%   <td><span class="kbd">[&#10003;] <b>Link</b></span> checkbox</td>
%   <td>links all color channel so that changing of the
%       <code>Min/Max/Gamma</code> sliders and editboxes affects all color channels at the same time
%   </td>
% </tr>
% <tr>
%   <td><span class="kbd">[&#10003;] <b>Log</b></span> checkbox</td>
%   <td>defines type of histogram representation in the histogram plot: linear or logarithmic scale
%   </td>
% </tr>
% <tr>
%   <td><span class="kbd">[&#10003;] <b>Auto update</b></span> checkbox</td>
%   <td>switches ON automatic update of the histogram.<br>When enabled the
%   histogram is updated after each slice change.<br>
%  <b>Warning!</b> Switching on the automatic update of the histogram may significantly decrease rendering of images
%   </td>
% </tr>
% <tr>
%   <td><b>The <span class="kbd">Update</span> button</b></td>
%   <td>update the histogram for the currently shown slice
%   </td>
% </tr>
% <tr>
%   <td><b>The <span class="kbd">Current</span> button</b></td>
%   <td><b><em>recalculate</b></em> intensities of the selected color channel (the <code>Channel</code> combobox) 
%   with parameters specified in the dialog for the currently shown slice. 
%   The intensities below the <code>Min</code> value become black and the intensities above the <code>Max</code> value
%   become white. <br>
%   The contrast adjustment of a single slice is not logged in the log list
%   <a href="ug_panel_path.html"> see the <span class="kbd">Log</span> button description</a>.
%   </td>
% </tr>
% <tr>
%   <td><b>The <span class="kbd">All slices</span> button</b></td>
%   <td><b><em>recalculate</b></em> intensities of the selected color channel (the <span class="dropdown">Channel &#9660;</span> dropdown) with parameters
%   specified in this dialog for all slices. The intensities below the <span class="dropdown">Min</span> value become black 
%   and the intensities above the <span class="dropdown">Max</span> value become white
%   </td>
% </tr>
% </table>
% </html>
% 
% [br8]
%
%% Histogram at the bottom of the window
%
% The histogram shows the plot with intensity values in the X-axis and number of pixels for each intensity value in the
% Y-axis. *Note!* The histogram is calculated from the image shown in the <ug_panel_im_view.html Image View panel> - not from the full slice!
%
% The adjustments made with |Gamma| are not shown in the histogram plot.
%
% It is possible to change |Min| and |Max| values for the intensities by
% manual numerical input, using the slider or with the right and left mouse click within the histogram
% plot. 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*> |*-->*| <ug_panel_view_settings.html *View settings*>
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
