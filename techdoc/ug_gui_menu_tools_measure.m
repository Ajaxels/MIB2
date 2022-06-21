%% Microscopy Image Browser Measure Tool
% Measure Tool of MIB is based on <http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility Image Measurement Utility>
% written by Jan Neggers, Eindhoven University of Technology. Using this
% tool it is possible to perform number of different length measurements and generate intensity profiles that correspond to these measurements.
%
%
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
% 
%
%% Overview
% <<images\MenuToolsMeasureTool.png>>
% 
% *Note*: the measurements can be switched on and off using the
% [class.kbd][&#10003;] *Annotation*[/class] checkbox in the |View Settings panel|.
%
%% Measure panel
% Define type of the measurement to perform, each measurement is started
% using the *Add* button. The color channel for intensity profile
% calculation can be specified using the |Color channel| combo box.
%
% [dtls][smry] *Examples of tools for manual measurement* [/smry]
% 
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuToolsMeasureOverviewAngle.jpg">
% </td>
% <td style="border: 0px">
% <b>1. Angle</b>: the angle of the intersection of two lines<br>
% a) place the intersection point;<br>
% b) place the second point that together with the intersection point form the first line; <br>
% c) place the third point that together with the intersection point form the second line; <br>
% d) adjust if needed; and double click above the line to accept<br>
% </td>
% </tr>
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuToolsMeasureOverviewCaliper.jpg">
% </td>
% <td style="border: 0px">
% <b>2. Caliper</b>: the perpendicular distance between a line and a point <br>
% a) place two points that define the line;<br>
% b) adjust if needed; and double click above the line to accept;<br>
% c) place the point; <br>
% d) adjust if needed; and double click above the point to accept;<br>
% </td>
% </tr>
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuToolsMeasureOverviewCircle.jpg">
% </td>
% <td style="border: 0px">
% <b>3. Circle</b>: the radius of the circle<br>
% a) place a point at the center of a circle;<br>
% b) place a point at the edge of the circle;<br>
% c) adjust if needed; and double click above the circle to accept; <br>
% </td>
% </tr>
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuToolsMeasureOverviewFreehand.jpg">
% </td>
% <td style="border: 0px">
% <b>4. Distance (freehand)</b>: the length of a path<br>
% a) define type of interpolation using the <b>Interpolation</b> combo box;<br>
% b) press the <b>Add</b> button;<br>
% c) draw a path that should be measured;<br>
% d) convert path to a polyline; provide a factor to reduce number of vertices;<br>
% e) adjust if needed; and double click above the path to accept; <br>
% </td>
% </tr>
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuToolsMeasureOverviewLinear.jpg">
% </td>
% <td style="border: 0px">
% <b>5. Distance (linear)</b>: the between two points<br>
% a) place the first point;<br>
% b) place the second point;<br>
% c) adjust if needed; and double click above the line to accept; <br>
% </td>
% </tr>
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuToolsMeasureOverviewFreehand.jpg">
% </td>
% <td style="border: 0px">
% <b>5. Distance (polyline)</b>:  the length of a path defined with predefined number of vertices<br>
% a) define number of vertices using the <b>Number of points</b> edit box;<br>
% b) define type of interpolation using the <b>Interpolation</b> combo box;<br>
% c) press the <b>Add</b> button;<br>
% d) place defined number of points; <br>
% e) adjust the path if needed; press the "a" key and use the left mouse button to add a vertice to the path. Finally double click above the path to accept;<br>
% </td>
% </tr>
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuToolsMeasureOverviewPoint.jpg">
% </td>
% <td style="border: 0px">
% <b>6. Point (polyline)</b>:  place a point<br>
% a) place a point; <br>
% b) adjust the point if needed; double click above the point to accept;<br>
% </td>
% </tr>
% </table>
% </html>
% 
% [/dtls]
% 
% * The [class.kbd][&#10003;] *Fine-tuning*[/class] checkbox: when selected positions of the measurements can be
% adjusted during the placement
% * The [class.kbd][&#10003;] *Calculate intensities*[/class] checkbox: when enabled, an intensity
% profile is calculated for each measurement
% * *Preview intenity (only for Distance, linear)* - instantly shows an
% intensity profile while placing the measurements
% * *Integrate (only for Distance, linear)* - allows to use integration of
% several points for calculation of intensity profile, the number if points
% used with the integration can be specified using the *Width* editbox.
% * [class.kbd][&#10003;] *fixed number of points (freehand mode only)*[/class], use this checkbox to keep number of points
% fixed, meaning that there will be no dialog offering reduction of the
% points after placing of the measurement
% * *Number of points (freehand and polyline modes):*, define number of
% points to place in one of these modes.
% 
%
%% Plot panel
% The |Plot panel| defines which parts of measurements should be displayed
% in the |Image View panel|. Using the |Options| button look of these lines
% and markers can be specified.
%
%% Volel sizes panel
% The |Voxel sizes panel| shows dimensions of voxels of the opened dataset.
% The voxels can be adjusted by pressing the |Update| button.
%
%% Results panel
% This panel displays results of measurements. It is possible to filter
% types of the displayed measurements using the |Filter combo box|.
% The intensity profiles for the selected measurements are shown in a plot
% under the table. When the [class.kbd][&#10003;] *Jump on selection*[/class] checkbox is selected the
% view in the |Image View panel| is automatically shifted to put selected
% measurement into the center of the panel.
%
% Right click above the selected item starts a context menu with following options:
%
% 
% <<images\MenuToolsMeasureContext.png>>
% 
% [dtls][smry] *List of context menu operations* [/smry]
% 
% * *Jump to measurement*, select to shift the shown image so that the selected
% measurement is centered in the |Image View panel|;
% * *Modify measurement*, select to trigger the edit mode to modify the shape and size of
% the measurement;
% * *Recalculate selected measurements...*, recalculate distances and
% intensity profiles for the selected measurements, in case if the pixel
% size or selection of color channels was changed
% * *Duplicate measurement*, select to duplicate the measurement;
% * *Generate kymograph*, use this option to generate a kymograph, which
% is an image of a depth projection through the stack under the profile
% (only available for linear, polyline and freehand measurements). The
% resulting kymograph may be previewed on a screen or saved in TIF, Matlab,
% or CSV formats. See more in a <https://youtu.be/ifr6bWtcnUg video
% tutorial>.
% * *Plot intensity profile*, select to plot profile of intensities in a
% new figure.
% * *Delete measurement*, select to remove measurement from the list
% 
% [/dtls]
% [br8]
%
%% Buttons at the bottom of the window
%
%%
% 
% * *Load* - press to load from a file or import from the main MATLAB
% workspace a structure with measurements;
% * *Save* - press to save to a file (MATLAB or Excel format) or export to
% the main MATLAB workspace results of the measurements. The saved results
% contain both the measurements and intensity profiles;
% * *Refresh table* - press to refresh the table with measurements;
% * *Delete all* - press to remove all measurements;
% * *?* - press to call this help page
% * *Add* - press to add a new measurement of the selected in the |Measure
% panel| type;
% * *Close* - close the tool
% 
%
%
%% Reference
% 
% * <http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility/ Image Measurement Utility by Jan Neggers>
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools Menu*>
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
