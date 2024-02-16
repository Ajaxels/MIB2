%% Segmentation Panel
% The segmentation panel is the main panel used for segmentation. It allows creating models, 
% modifying materials and selecting different segmentation tools. 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
%%
%
% <<images\PanelsSegmentation.png>>
%
%% What are the Models
% A model is a matrix with dimensions equal to those of the opened Image dataset , i.e., 
% [class.code][1:imageHeight, 1:imageWidth, 1:imageThickness][/class]. The model consists of materials, and each element of the 
% model matrix can belong only to a single material or to an exterior. Therefore, it is not possible 
% to have several materials above the same pixel of the image overlapping each other. Each material in 
% the model matrix is encoded with its own index.
% 
% [dtls][smry] *Example of a model 4x4 pixels* [/smry]
Model = [1 1 0 0; 1 1 0 0; 0 0 2 2; 0 0 2 2];
Model
%%
%
% In this example, the shown matrix represents a Model with 2 materials
% encrypted with *1* (the upper left corner) and *2* (the lower right
% corner) for the |Image| of 4x4 pixels. Index *0* encodes background
% (Exterior)
%
% [/dtls]
%
%% The [class.kbd]Create[/class] button
%
% The [class.kbd]Create[/class] button is used to start a new model. 
% When this button is clicked, the existing Model layer will be removed.
% 
% <<images\PanelsSegmentation_Create.png>>
% 
% <html>
% Whenever is possible is is recommended to use models with 63 materials.<br>
% If you need to work with materials that exceed 255, you can find a short introduction about this topic in the following video:<br>
% <a href="https://youtu.be/r3lpmWyvrJU"><img style="vertical-align:middle;" src="images\youtube.png">
% MIB 2.1: compatible with models with more than 255 materials
% (https://youtu.be/r3lpmWyvrJU)</a>
% <br>
% For more information about the different types of models, you can visit the <a href="ug_gui_menu_models.html">Menu->Models page</a>
% </html>
%
%% The [class.kbd]Load[/class] button
%
% The [class.kbd]Load[/class] button is used to load a model from the disk. The following formats are accepted:
% 
% * MATLAB ([class.code]*.MAT[/class]), this is the default and recommended format
% * Amira Mesh binary ([class.code]*.AM[/class]); for models saved in <http://www.vsg3d.com/amira/overview Amira> format
% * Hierarchial Data Format ([class.code]*.H5[/class]); for data exchange with <http://ilastik.org/ Ilastik>
% * Medical Research Concil format ([class.code]*.MRC[/class]);  for data exchange with <http://bio3d.colorado.edu/imod/ IMOD>
% * NRRD format ([class.code]*.NRRD[/class]); for models saved in <http://www.slicer.org/ 3D slicer> format
% * TIF format ([class.code]*.TIF[/class]); 
% * Hierarchial Data Format with XML header ([class.code]*.XML[/class]); 
% * all standard file formats can be opened when selecting [class.code]All files(*.*)[/class]
% 
% Alternatively, you can also use the <ug_gui_menu_models.html [class.code]Menu->Models->Load model[/class]> option or 
% directly drag-and-drop [class.code]*.model[/class] file to the *Image View* panel or the *Segmentation* table.
%
%% The [class.kbd]+[/class], [class.kbd]-[/class], [class.kbd]>|[/class], [class.kbd]Squeeze[/class], [class.kbd]Recolor[/class] buttons
%
% <html>
% <ul>
% <li> the <span class="kbd">+</span> button, press to add a new material to the model (<em>only for models with 63 and 255 materials</em>)</li>
% <li> the <span class="kbd">-</span> button, press to delete the selected material(s) from the model (<em>only for models with 63 and 255 materials</em>)</li>
% <li> the <img src="images\PanelsSegmentation_next_empty_button.png"> button, press to find and select the next empty index in the model (<em>only for models with more than 255 materials</em>)</li>
% <li> the <img src="images\PanelsSegmentation_squeeze_button.png"> button, press to squeeze the model - remove all empty indices and select 
% next available empty index (<em>only for models with more than 255 materials</em>)</li>
% <li> the <img src="images\PanelsSegmentation_recolor_button.png"> button, press to regenerate colors of materials (<em>only for models with more than 255 materials</em>)</li>
% </ul>
% </html>
%
%% The [class.dropdown]Filled/Contour &#9660;[/class] dropdown 
%
% This dropdown modifies visualization of materials in the <ug_panel_im_view.html Image View> panel.  
% 
% 
% * *Filled* - use to draw materials as the filled shapes (_faster_)
%
% <<images\PanelsSegmentation_filled.png>>
%
% * *Contour* - use to draw only the contours of materials (_slower_). [br]
% It is also possible to tweak the thickness of the contour lines using
% settings in [class.code]Menu->File->Preferences->Colors and styles->Contours[/class]
% 
% <<images\PanelsSegmentation_contour.png>>
% 
% <<images\PanelsSegmentation_filled_contours.png>>
%
%
%% The Segmentation table
%
% The Segmentation table displays the list of materials in the model.
% 
% <html>
% A brief demonstration of the Segmentation table is available in the following video:<br>
% <a href="https://youtu.be/_iwQI2DIDjk"><img style="vertical-align:middle;" src="images\youtube.png"> MIB in brief: Segmentation Table (https://youtu.be/_iwQI2DIDjk)</a>
% <br>
% <img src="images\PanelsSegmentation_table.png"><br>
% <br>
% The segmentation table has 3 columns:
% <ul>
% <li>Column <b>"C"</b> this column shows the colors for each material. Clicking on the first column will open a dialog for color selection</li>
% <li>Column <b>"Material"</b> lists all the materials of the model. <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right mouse click</span> on a 
% material in this column will open a context menu with additional options for the selected material</li>
% [dtls][smry] Additional options available via the context menu [/smry]
% <img src="images\PanelsSegmentation_table_cm.png"><br>
% <ul>
% <li><b>Show selected material only</b> this is a toggle that switches the visualization of materials in the <ug_panel_im_view.html Image View> panel. When checked, only the selected material is shown</li>
% <li><b>Rename</b> this option allows you to rename the selected material</li>
% <li><b>Set color</b> this option allows you to change the color for the selected material</li>
% <li><b>Color scheme</b> this option updates the material colors using a list of predefined color palettes. 
% More tools to work with the palettes are available from <span class="code">Menu -> File -> Preferences -> Colors</span>. 
% If the model has more materials than the loaded color scheme, additional colors will be randomly generated.</li>
% <li><b>Get statistics</b> this option calculates properties for objects that belong to the selected material. 
% For more details, please refer to the <a href="ug_gui_menu_mask_statistics.html">Menu -> Models -> Model statistics...</a> section</li>
% <li><b>Material to Selection</b> use this option to copy objects of the selected material to the Selection layer with the following options:</li>
% <ul>
% <li><em>NEW (2D, Slice)</em> generates a new Selection layer from the selected material for the currently shown slice. It creates a new layer that contains only the objects with the selected material for the current 2D slice</li>
% <li><em>ADD (2D, Slice)</em> adds the selected material to the Selection layer for the currently shown slice. It adds the objects with the selected material to the existing Selection layer for the current 2D slice</li>
% <li><em>REMOVE (2D, Slice)</em> removes the selected material from the Selection layer for the currently shown slice. It removes the objects with the selected material from the existing Selection layer for the current 2D slice</li>
% <li><em>NEW (3D, Stack)</em> generates a new Selection layer from the selected material for the current 3D stack</li>
% <li><em>ADD (3D, Stack)</em> adds the selected material to the Selection layer for the current 3D stack</li>
% <li><em>REMOVE (3D, Stack)</em> removes the selected material from the Selection layer for the current 3D stack</li>
% <li><em>NEW (4D, Dataset)</em> generates a new Selection layer from the selected material for the whole dataset</li>
% <li><em>ADD (4D, Dataset)</em> adds the selected material to the Selection layer for the whole dataset</li>
% <li><em>REMOVE (4D, Dataset)</em> removes the selected material from the Selection layer for the whole dataset</li>
% </ul>
% <li><b>Material to Mask</b> allows you to copy the selected material to the Mask layer with options similar to the <b>Material to Selection</b> section above</li>
% <li><b>Mask to Material</b> llows you to copy the Mask layer to the selected material with options similar to the <b>Material to Selection</b> section above</li>
% <li><b>Show as volume (MIB)..</b> vallows you to visualize the selected material using MIB rendering. This feature is available for MATLAB R2018b and newer versions. By selecting this option, you can render the selected material as a volume, providing a three-dimensional representation of the material within the software</li>
% <li><b>Show isosurface (MATLAB)...</b> allows you to visualize the model or only the selected material 
% (when <span class="kbd">[&#10003;] <b>Show selected material only</b></span> is selected) as an isosurface. 
% This functionality is powered by MATLAB and the <a href="http://www.mathworks.com/matlabcentral/fileexchange/334-view3d-m">view3d</a> 
% function written by Torsten Vogel. By selecting this option, you can view the model or selected material as an isosurface, which provides a three-dimensional representation of the material's surface
% <br> To interact with the rendered model or material, you can use the <span class="kbd">R</span> shortcut to rotate and 
% the  <span class="kbd">Z</span> shortcut to zoom. See more in the <a href="ug_gui_menu_models.html">Render model...</a>section</li>
% <li><b>Show as volume (Fiji)...</b> allows you to visualize the model or selected material 
% (when <span class="kbd">[&#10003;] <b>Show selected material only</b></span> is selected) using volume rendering with the Fiji 3D viewer. 
% Please refer to the <a href="im_browser_system_requirements.html">Microscopy Image Browser System Requirements Fiji</a> for details</li>
% <li><b>Unlink material from Add to</b> when unlinked, the <b>Add to</b> column is not changing its status during selection of Materials</li>
% </ul>
% [/dtls]
% <li>Column <b>"Add to"</b>, this column defines the destination material for the Selection layer during the 
% <em>Add</em> and <em>Replace</em> actions. By default, this field is linked to the selected material. However, it can be unlinked 
% when the <span class="kbd">[&#10003;] <b>Fix selection to material</b></span> checkbox is selected or when the 
% <span class="kbd">[&#10003;] <b>Unlink material from Add to</b></span> option is enabled</li>
% </ul>
% </html>
%
% [class.h3]Keyboard shortcuts[/class]
%
% The Segmentation table also provides various shortcuts and options for selecting materials and working with layers. For example:
%
% * The [class.kbd]^ Ctrl[/class]+[class.kbd]A[/class] and [class.kbd]Alt[/class]+[class.kbd]A[/class] <ug_gui_shortcuts.html shortcuts> 
% can be used to highlight the selected material using the Selection layer. [class.kbd]^ Ctrl[/class]+[class.kbd]A[/class] selects 
% objects only on the shown slice, while [class.kbd]Alt[/class]+[class.kbd]A[/class] does that for the whole dataset. 
% The selection is sensitive to the [class.kbd][&#10003;] *Fix selection to material*[/class] and [class.kbd][&#10003;] *Masked area*[/class] switches
% 
% <html>
% <b>To select a combination of the Mask and any other layer, you can:</b>
% <ul> 
% <li>select the Mask entry in the table</li>
% <li>check the <span class="kbd">[&#10003;] <b>Fix selection to material </b></span> checkbox</li>
% <li>select the second material in the <b>Add to</b> column</li>
% <li>Press the [class.kbd]^ Ctrl[/class]+[class.kbd]A[/class] or [class.kbd]Alt[/class]+[class.kbd]A[/class] shortcut</li>
% </ul>
% </html>
%
% [class.h3]Drag and drop models[/class]
%
% * Model files with can be drag-and-dropped from a system file explorer application into the Segmentation table 
% to be loaded as a new model.
% * Annotation (*.ann) files can also be drag-and-dropped to the Segmentation table to be automatically opened
%
%
%% The [class.kbd][&#10003;] *Fix selection to material*[/class] checkbox
%
% The [class.kbd][&#10003;] *Fix selection to material*[/class] checkbox ensures that all segmentation tools will only be applied to 
% the material selected in the table. When this checkbox is selected, any segmentation operations performed 
% will be limited to the specific material that has been chosen in the table. This can be useful when you
% want to focus on a specific material within an image and apply segmentation techniques only to that material.
%
%% The [class.kbd][&#10003;] *Masked area*[/class] checkbox
%
% The [class.kbd][&#10003;] *Masked area*[/class] checkbox ensures that segmentation tools 
% will be limited to the areas of the image that have been masked. When this checkbox is selected, any segmentation 
% operations performed will only affect the areas of the image that have been designated as masked.
% This can be useful when you want to isolate certain regions of the image and apply segmentation techniques only within those areas
%
%% The [class.kbd][&#10003;] *"D"*[/class] checkbox, to select fast access tools 
%
% The [class.kbd][&#10003;] *D*[/class] checkbox is used to mark the favorite selection tools that can be accessed quickly using 
% the [class.kbd]D[/class] key shortcut. When this checkbox is selected, the chosen fast access tools will be highlighted 
% with an orange background in the [class.dropdown]Selection type &#9660;[/class] dropdown. This allows you to easily access 
% and use your preferred selection tools without having to navigate 
% through menus or options. You can select any tool as a favorite by checking the [class.kbd][&#10003;] *D*[/class] checkbox next to it.
%
%% The [class.dropdown]Segmentation tools &#9660;[/class] dropdown
%
% The [class.dropdown]Segmentation tools &#9660;[/class] dropdown provides a selection of different tools 
% that can be used for segmentation. These tools are designed to help you separate and identify different 
% regions or objects within an image, <ug_panel_segm_tools.html See more here>.
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