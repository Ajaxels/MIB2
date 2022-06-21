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
% |Model| is a matrix with dimensions equal to those of the opened |Image| dataset: _i.e._  [ |1:imageHeight,
% 1:imageWidth, 1:imageThickness| ]. The |Model| consists of Materials, each element of the |Model| matrix can belong only to
% a single material or to an exterior. So it is not possible to have several materials above the same pixel of the |Image| overlapping each other.
% Each material in the |Model| matrix is encrypted with own index
% 
% [dtls][smry] *Example of a model 4x4 pixels* [/smry]
Model = [1 1 0 0; 1 1 0 0; 0 0 2 2; 0 0 2 2];
Model
%%
%
% In this example, the shown matrix represents a Model with 2 materials
% encrypted with *1* (the upper left corner) and *2* (the lower right corner) for the |Image| of 4x4 pixels.
%
% [/dtls]
%
%% The Create button
% Starts a new model. The existing |Model| layer will be removed.
%
% 
% <<images\PanelsSegmentation_Create.png>>
% 
% <html>
% Whenever is possible is is recommended to use models with 63
% materials.[br]
% A short introduction about materials with more than 255 materials is
% available from here:<br>
% <a href="https://youtu.be/r3lpmWyvrJU"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/r3lpmWyvrJU</a>
% <br>
% Also see more about types of model on the <a href="ug_gui_menu_models.html">Menu->Models page</a>
% </html>
%
%% The Load button
% Loads model from the disk. The following formats are accepted:
%%
% 
% * MATLAB ([class.code]*.MAT[/class]), _default recommended format_
% * Amira Mesh binary ([class.code]*.AM[/class]); for models saved in <http://www.vsg3d.com/amira/overview Amira> format
% * Hierarchial Data Format ([class.code]*.H5[/class]); for data exchange with <http://ilastik.org/ Ilastik>
% * Medical Research Concil format ([class.code]*.MRC[/class]);  for data exchange with <http://bio3d.colorado.edu/imod/ IMOD>
% * NRRD format ([class.code]*.NRRD[/class]); for models saved in <http://www.slicer.org/ 3D slicer> format
% * TIF format ([class.code]*.TIF[/class]); 
% * Hierarchial Data Format with XML header ([class.code]*.XML[/class]); 
% * all standard file formats can be opened when selecting [class.code]All files(*.*)[/class]
% 
% Alternatively it is possible to use the <ug_gui_menu_models.html |Menu->Models->Load model|> or 
% directly drag-and-drop [class.code]*.model[/class] file to the *Image View* panel or the *Segmentation* table.
%
%% The +, -, and E buttons
%
% * the *[class.kbd]+[/class]* button, press to add a new material to the model (_only for models with 63 and 255 materials_)
% * the *[class.kbd]-[/class]* button, press to delete the selected material from the model (_only for models with 63 and 255 materials_)
% * the *[class.kbd]E[/class]* button, press to find and select the next empty index in the model (_only for models with more than 255 materials_)
%
%% The Filled/Contour combo box
% This combo box modifies visualization of materials in the <ug_panel_im_view.html Image View> panel.  
% 
% 
% * *Filled* - use to draw materials as the filled shapes (_faster_)
%
% <<images\PanelsSegmentation_filled.png>>
%
% * *Contour* - use to draw only the contours of materials (_slower_)
% 
% <<images\PanelsSegmentation_contour.png>>
% 
% 
%
%% The Segmentation table
% The Segmentation table displays the list of materials of the model. 
%
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/_iwQI2DIDjk"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/_iwQI2DIDjk</a>
% <br><br>
% The segmentation table has 3 columns:
% <ul>
% <li>Column <b>"C"</b> shows the colors for each material. The mouse click on the first column starts a dialog for color selection</li>
% <li>Colimn <b>"Material"</b> has a list of all materials. The right mouse click starts a popup menu with additional options for the selected material: </li>
% <ul>
% <li><b>Show selected material only</b> a toggle that switches visualization of materials in the Image View panel, when checked only the selected material is shown</li>
% <li><b>Rename</b> rename the selected material</li>
% <li><b>Set color</b> change color for the selected material</li>
% <li><b>Get statistics</b> calculate properties for objects that belong to the selected material. Please refer to the <a href="ug_gui_menu_mask_statistics.html">Menu->Models->Model statistics...</a> section for details</li>
% <li><b>Material to Selection</b> a copies objects of the selected material to the Selection layer with the following options:</li>
% <ul>
% <li><em>NEW (2D, Slice)</em> generates a new Selection layer from the selected material for the currently shown slice</li>
% <li><em>ADD (2D, Slice)</em> adds the selected material to the Selection layer for the currently shown slice</li>
% <li><em>REMOVE (2D, Slice)</em> removes the selected material from the Selection layer for the currently shown slice</li>
% <li><em>NEW (3D, Stack)</em> generates a new Selection layer from the selected material for the current stack</li>
% <li><em>ADD (3D, Stack)</em> adds the selected material to the Selection layer for the current stack</li>
% <li><em>REMOVE (3D, Stack)</em> removes the selected material from the Selection layer for the current stack</li>
% <li><em>NEW (4D, Dataset)</em> generates a new Selection layer from the selected material for the whole dataset</li>
% <li><em>ADD (4D, Dataset)</em> adds the selected material to the Selection layer for the whole dataset</li>
% <li><em>REMOVE (4D, Dataset)</em> removes the selected material from the Selection layer for the whole dataset</li>
% </ul>
% <li><b>Material to Mask</b> copy the selected material to the Mask layer with the options similar to <b>Material to Selection</b> section</li>
% <li><b>Mask to Material</b> copy the Mask layer to the selected material with the options similar to <b>Material to Selection</b> section</li>
% <li><b>Show as volume (MIB)..</b> visualize the selected material using
% MIB rendering, available for MATLAB R2018b and newer</li>
% <li><b>Show isosurface (MATLAB)...</b> visualize the model or only the selected material (when <em>Show selected material only</em> is selected), as an isosurface. This functionality is powered by 
% MATLAB and <a href="http://www.mathworks.com/matlabcentral/fileexchange/334-view3d-m">view3d</a> function written by  Torsten Vogel. Use the <b>"r"</b> shortcut to rotate and <b>"z"</b> to zoom. 
% See more in the <a href="ug_gui_menu_models.html">Render model...</a>section</li>
% <li><b>Show as volume (Fiji)...</b> visualization of the model or selected material (when <em>Show selected material only</em> is selected) using volume rendering with Fiji 3D viewer,
% please refer to the <a href="im_browser_system_requirements.html">Microscopy Image Browser System Requirements Fiji</a> for details</li>
% <li><b>Unlink material from Add to</b> when unlinked, the Add to column is not changing its status during selection of Materials</li>
% </ul>
% <li>Column <b>"Add to"</b> defines destination material for the Selection layer during the <em>Add</em> and <em>Replace</em> actions. 
% By default, this field is linked to the selected material, but it is unlinked when the 
% <span class="kbd">[&#10003;] <b>Fix selection to material</b></span> checkbox is selected or the <em>Unlink material from Add to</em> option is enabled</li>
% </ul>
% </html>
%
% The [class.kbd]Ctrl+A[/class] and [class.kbd]Alt+A[/class] <ug_gui_shortcuts.html shortcuts> can be used to highlight selected in the Segmentation table material. 
% The [class.kbd]Ctrl+A[/class] shortcut selects objects only on the shown slice, while [class.kbd]Alt+A[/class] does that for
% the whole dataset. The selection is sensitive to the |Fix selection to material|  
% and the |Masked area| switches.
% 
% <html>
% <b>To select a combination of the Mask and any other layer:</b>
% <ul> 
% <li>select the Mask entry in the table</li>
% <li>check the <span class="kbd">[&#10003;] <b>Fix selection to material </b></span> checkbox</li>
% <li>select the second material in the Add to column</li>
% <li>Press the Alt+A or Ctrl+A shortcut</li>
% </ul>
% </html>
%
%% The [class.kbd][&#10003;] *Fix selection to material*[/class] checkbox
% This check box ensures that all segmentation tools will be performed only
% for material selected in the table.
%
%% The [class.kbd][&#10003;] *Masked area*[/class] checkbox
% This check box ensures that all segmentation tools will be limited only
% within the masked areas of the image.
%
%
%% The [class.kbd][&#10003;] *"D"*[/class] checkbox, to select fast access tools 
% This checkbox marks the favorite selection tools that are selected using the *[class.kbd]D[/class]* key shortcut. 
% The chosen fast access tools are highlighted
% with orange background in the |Selection type| popup menu. Any tool can
% be selected as a favorite one.
%
%
%% Segmentation tools combo box
% This  combo box hosts different tools for the segmentation.
% <ug_panel_segm_tools.html See more here>.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
% [cssClasses]
% .kbd { 
%     font-family: monospace;
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