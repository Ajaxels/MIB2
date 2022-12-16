%% MIB 3D Volume Rendering
% Starting from MIB version 2.84 a new 3D volume rendering engine is
% available. This engine requires MATLAB R2022b or newer and at least for
% R2022b available on in MIB for MATLAB.
%
% <html>
% A brief demonstration is available in the following video:<br>
% Introduction to an updated 3D viewer:   <a href="https://youtu.be/840o6zni3KE"><img style="vertical-align:middle;" src="images\youtube2.png">   https://youtu.be/840o6zni3KE</a>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File*> 
%
%% How to enable the new 3D viewer for MATLAB R2022b or newer
% 
% [dtls][smry] *Expand this section to see details* [/smry]
%
% Use MIB Preferences dialog (
% [class.code]MIB->Menu->File->Preferences->User interface->3D rendering
% engine[/class]) to select default rendering engine.
%
% <<images\menuFileRenderingPreferences.jpg>>
% 
% * *Viewer3d, R2022b*, selects the new version of the viewer described on this page
% * *Volshow, R2018b*, selects an older version of the viewer available from R2018b
%
% [/dtls]
%
%% Downsampling of datasets 
%
% [dtls][smry] *Expand this section to see details* [/smry]
%
% Whenever 3D volume rendering is selected, the current image volume is
% transferred into the 3D viewer. During the transfer, it is possible select color channels or to
% downsample the dataset to improve rendering performance:
% 
% <<images\menuFileRenderingMIB_downsample.jpg>>
% 
% [/dtls]
%
%% Composition of the 3D viewer
%
% The 3D viewer has 2 main window:
%
% * *3D Controls*, the main window that is allowing to set parameters of
% the volume viewer, generate surfaces, make snapshots and animations. Most
% of controls are grouped under corresponding tabs in the window.
% * *3D Viewer*, the visualization window used to render volumes and
% models
% 
% [dtls][smry] *User interface of the 3D viewer* [/smry]
%
% <<images\menuFileRenderingMIB_R2022b.jpg>>
%
% [/dtls]
%
% Please refer to the corresponding sections for details.
%
%% 3D Controls ->  Menu
% 
% [dtls][smry] *Expand to see details of the menu entries* [/smry]
%
% Menu gives access to the following operations:
%
% <html>
% <table>
% <tr><td style="background: #FFCC66;"><b>File section</b></td><td style="background: #FFCC66;"></td></tr>
% <tr><td><b>Load animation path</b></td><td>animations that are created using the 3D viewer can be saved and loaded back using this operation</td></tr>
% <tr><td><b>Save animation path</b></td><td>save the current animation path to the disk</td></tr>
% <tr><td><b>Make snapshot</b></td><td>starts the <a href="ug_gui_menu_file_makesnapshot.html">MIB snapshot tool</a> to create an image snapshot of the current view shown in the <b>3D Viewer</b> window</td></tr>
% <tr><td><b>Make spin movie</b></td><td>starts the <a href="ug_gui_menu_file_makevideo.html">MIB movie maker tool</a> to create a movie of a camera spin around the object displayed in the <b>3D Viewer</b> window</td></tr>
% <tr><td><b>Make animation movie</b></td><td>starts the <a href="ug_gui_menu_file_makevideo.html">MIB movie maker tool</a> to create an animation movie, when the camera is following a predefined path. The path can be set using the *Animation tab* explained below</td></tr>
% <tr><td style="background: #FFCC66;"><b>View section</b></td><td style="background: #FFCC66;"></td></tr>
% <tr><td><b>Default view</b></td><td>press to reset the view in the scene to its default state. The same can be achieved by pressing the <span class="kbd">Home</span> button in the upper-right corner of the <b>3D Viewer</b> window</td></tr>
% <tr><td><b>XY view</b></td><td>press to set the view in the scene from above. The same can be achieved by pressing the <span class="kbd">Z</span> button in the axes in the lower-left corner of the <b>3D Viewer</b> window</td></tr>
% <tr><td><b>XZ view</b></td><td>press to set the view in the scene from the Y-side. The same can be achieved by pressing the <span class="kbd">Y</span> button in the axes in the lower-left corner of the <b>3D Viewer</b> window</td></tr>
% <tr><td><b>YZ view</b></td><td>press to set the view in the scene from the X-side. The same can be achieved by pressing the <span class="kbd">X</span> button in the axes in the lower-left corner of the <b>3D Viewer</b> window</td></tr>
% <tr><td style="background: #FFCC66;"><b >Settings section</b></td><td style="background: #FFCC66;"></td></tr>
% <tr><td><b>Background color</b></td><td>press to set the background color for the scene rendered in the <b>3D Viewer</b> window</td></tr>
% <tr><td><b>Background gradient color</b></td><td>press to set the secondary background color to generate a gradient of background colors</td></tr>
% <tr><td><b>Background gradient</b></td><td>enable to render background as a gradient of two colors selected using the menu items described above</td></tr>
% </table>
% </html>
%
% [/dtls]
%
% [br8]
%
%% 3D Controls ->  Viewer
%
% [dtls][smry] *Expand to see details of the Viewer tab* [/smry]
%
% <html>
% <table><tr>
%   <td width=395px><img src="images\menuFileRenderingMIB_R2022b_3DControls_Viewer.jpg"></td>
%   <td>The Viewer tab is allowing to control the following widgets and parameters of the viewer:
%   <br><br>
%   <ul>
%   <li><span class="kbd">[&#10003;] <b>show scale</b></span> use to show or hide scale bar that is shown in the 3D viewer window</li>
%   <li><span class="kbd">[&#10003;] <b>show axes</b></span> use to show or hide 3D axes in the 3D viewer window. Click on the axes changes orientation of the 3D viewer</li>
%   <li><span class="kbd">[&#10003;] <b>show box</b></span> use to show or hide bounding box drawn around the volume in the 3D viewer window</li>
%   <li><span class="kbd"><b>Help</b></span> press to open this help section of MIB</li>
%   </ul>
%   <ul><b>Camera</b><br>
%       use these widgets to specify position of the camera; these values are interactively updated upon interaction with the 3D viewer<br>
%   <li><b>Zoom</b> camera zoom level</li>
%   <li><b>Distance</b> distance from camera to the center of the scene</li>
%   <li><b>Position</b> camera position or viewpoint as a 3-element vector of the form [x y z]. The camera is oriented along the view axis, which is a straight line that connects the camera position and the camera target. Changing the CameraPosition property changes the point from which you view the volume. For an illustration, see <a href="https://se.mathworks.com/help/matlab/creating_plots/defining-scenes-with-camera-graphics.html">Camera Graphics Terminology</a></li>
%   <li><b>Target</b> camera target as a 3-element vector of the form [x y z]. The camera is oriented along the view axis, which is a straight line that connects the camera position and the camera target.</li>
%   <li><b>Up vector</b> upwards direction for the camera as a 3-element vector of the form [x y z]. By default, the z-axis is the up direction ([0 0 1]).</li>
%   </ul>
%   </td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [br8]
%
%
%% 3D Controls ->  Volume
%
% The Volume tab contains tools for interaction with the shown volume.
%
% [dtls][smry] *Expand to see details of the Volume tab* [/smry]
%
% <html>
% <table><tr>
%   <td width=395px><img src="images\menuFileRenderingMIB_R2022b_3DControls_Volume.jpg"></td>
%   <td>List of widgets for tweaking the visualization settings for the loaded volume:
%   <br><br>
%   <ul>
%   <li><span class="kbd">[&#10003;] <b>show volume</b></span>, toggle whether both the volume and the model are shown or hidden. This checkbox does not affect visualization of surfaces</li>
%   <li><span class="kbd">[&#10003;] <b>transparent volume</b></span>, toggle visualization of the volume. This checkbox does not affect visualization of models and surfaces</li>
%   <li><span class="dropdown">Renderer &#9660;</span> 
%   <ul>
%   <li><b>VolumeRendering</b>, render the volume using volume rendering technique based on the specified color and transparency for each voxel</li>
%   <li><b>GradientOpacity</b>, render the volume based on the specified color and transparency with an additional transparency applied if the voxel is similar in intensity (grayscale volumes) or luminance (RGB volumes) to the previous voxel along the viewing ray. When a volume with uniform intensity is rendered using "GradientOpacity", the internal portion of the volume appears more transparent than the "VolumeRendering" rendering style, enabling better visualization of the intensity or luminance gradients in the volume. Use the <b>Opacity</b> slider to fine-tune the visualization</li>
%   <li><b>SlicePlanes</b>, use orthogonal slice planes for visualization. The slices can be changed using the <b>Slices</b> sliders or interactively using mouse</li>
%   <li><b>Isosurface</b>, show an isosurface of the volume specified by the value in the <b>iso-value</b> slider</li>
%   <li><b>MaximumIntensityProjection</b>, render the voxel with the highest intensity value for each ray projected through the data. For RGB volumes, the luminance of the voxel in CIE 1976 L*a*b* color space</li>
%   <li><b>MinimumIntensityProjection</b>, render the voxel with the lowest intensity value for each ray projected through the data. For RGB volumes, the luminance of the voxel in CIE 1976 L*a*b* color space</li>
%   </ul>
%   </li>
%   <li><b>Opacity / iso-value</b>, use the slider to tweak settings of the <b>GradientOpacity</b> and <b>Isosurface</b> modes</li>
%   <li><span class="dropdown">Color map&#9660;</span>, use this dropdown to update the colormap for visualization of the volume. The <span class="kbd">[&#10003;] <b>Invert</b></span> checkbox can be used to invert the color map and <span class="dropdown">Black point</span> and <span class="dropdown">White point</span> to set intensities for contrast adjustment</li>
%   <li><b>Slices</b> [<em>only for <span class="dropdown">SlicePlanes &#9660;</span></em>], contains sliders to change positions of the orthogonal slices</li>
%   <li><b>Alpha curve</b> allows to define transparency for the volume. 
%   Intensities matching the alpha curve values of 1 are opaque, while
%   intensities, where the alpha curve values are 0 are transparent.<br>
%   <ul>The points can be modified using mouse clicks:
%   <li><b>Right mouse click</b> select the point</li>
%   <li><b>Left mouse click</b> change position of the selected point</li>
%   <li><b><span class="kbd">&#8679; Shift</span> + left mouse click</b> add a point at the clicked position</li>
%   <li><b><span class="kbd">^ Ctrl</span> + left mouse click</b> remove the closest point</li>
%   </ul>
%   The alpha curve can be inverted (<span class="kbd">Invert</span>) or
%   reset to the default state (<span class="kbd">Reset</span>)
%   </li>
%   </ul>
%   </td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [br8]
%
%% 3D Controls ->  Model
%
% The Model tab contains tools for visualization of the model loaded into MIB.
%
% [dtls][smry] *Expand details of the Model tab* [/smry]
%
% <html>
% <table><tr>
%   <td width=395px><img src="images\menuFileRenderingMIB_R2022b_3DControls_Model.jpg"></td>
%   <td>List of widgets for tweaking the visualization settings for the model overlay:
%   <br><br>
%   <ul>
%   <li><span class="kbd">Update overlay</span>, press the button to grab layer specified in <span class="dropdown">Overlay source &#9660;</span> and visualize it in the 3D Viewer</li>
%   <li><span class="dropdown">Overlay source &#9660;</span> specify type of the layer for visualization as a model</li>
%   <li><span class="kbd">[&#10003;] <b>Hide all</b></span>, toggle show/hide all selected in the table materials of the model</li>
%   <li><b>Table with materials</b>, the table contains the list of materials of the model. Each material can be shown/hidden and visualized using own transparency value (<b>Alpha</b> from 0 to 1). The right mouse click opens a dropdown menu, where the <span class="dropdown">Generate surface(s) &#9660;</span> option can be used to generate surfaces that are shown using the <b>Surfaces</b> tab</li>
%   </ul>
%   </td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [br8]
%
%
%% 3D Controls ->  Surfaces
%
% Surfaces that are generated using a right mouse click over the table with
% materials in the *Model* tab are visualized using settings specified
% in this tab.
%
% [dtls][smry] *Expand to see details of the Surfaces tab* [/smry]
%
% <html>
% <table><tr>
%   <td width=395px><img src="images\menuFileRenderingMIB_R2022b_3DControls_Surfaces.jpg"></td>
%   <td>List of widgets for tweaking the visualization settings for surfaces:
%   <br>
%   <ul>
%   <li><b>Table</b>
%   <ul>
%   <li><b>C</b>, click to set color for the selected surface</li>
%   <li><b>Name</b>, double click to change name of the surface </li>
%   <li><b>Alpha</b>, tweak transparency for the selected surface (0-1)</li>
%   <li><span class="kbd">[&#10003;] <b>show</b></span>, toggle show/hide the selected surface </li>
%   <li><span class="kbd">[&#10003;] <b>wire</b></span>, toggle show/hide visualization of the selected surface as a wired model</li>
%   <li><span class="dropdown">Additional settings via right mouse click &#9660;</span>:
%   <ul>
%   <li><b>Save surface(s)</b>, export the selected surface(s) to a file in SLT format</li>
%   <li><b>Remove surface(s)</b>, remove the selected surface from the 3D viewer</li>
%   </ul>
%   </li>
%   </ul>
%   </td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [br8]
%
%
%% 3D Controls ->  Animation
%
% The *Animation* tab allows to set key frames for making movies with
% volume animations. The rendering of animations is done using [class.code]Menu->File->Make animation movie[/class]
%
% Animations can be saved and loaded back from [class.code]Menu->File->Load animation path[/class] and [class.code]Menu->File->Save animation path[/class]
%
% [dtls][smry] *Expand to see details of the Animation tab* [/smry]
%
% <html>
% <table><tr>
%   <td width=395px><img src="images\menuFileRenderingMIB_R2022b_3DControls_Animation.jpg"></td>
%   <td>List of widgets for designing of animations:
%   <br>
%   <ul>
%   <li><b>Keyframes table</b>, animations are based on a set of key frames
%   that are added using <span class="kbd">Add</span>. Upon right mouse
%   click a menu with additional operations is displayed:
%   <ul>
%   <li><b>Jump to the keyframe</b>, click to jump to the selected keyframe and update the viewer to visualize it</li>
%   <li><b>Insert a keyframe</b>, insert the currently shown scene into the keyframe sequence</li>
%   <li><b>Replace keyframe</b>, replace the selected keyframe with the current view</li>
%   <li><b>Remove keyframe</b>, remove the selected keyframe from the sequence</li>
%   </ul>
%   </li>
%   <li><span class="kbd">Add keyframe</span>, press to add a keyframe to the sequence of keyframes</li>
%   <li><span class="kbd">[&#10003;] <b>Auto jump</b></span>, when checked a press over a keyframe automatically updates the scene in the 3D viewer to match the one stored in the keyframe</li>
%   <li><span class="kbd">Preview</span>, press to preview the animation</li>
%   <li><span class="kbd">Spin test</span>, press to test spinning of the volume around specified axis: <span class="dropdown">Z-axis &#9660;</span> </li>
%   <li><span class="dropdown">No. frames</span>, define number of frames for the preview</li>
%   <li><span class="kbd">Delete all</span>, delete all keyframes</li>
%   </ul>
%   </td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [br8]
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File*> 
%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #fffce8; 
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

