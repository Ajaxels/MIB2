%% Model Menu
% Actions that can be applied to the |Model| layers. The |Model layer| is one
% of three main segmentation layers (|Model, Selection, Mask|) which can be
% used in combibation with other layer. See more about segmentation layers
% in <ug_gui_data_layers.html the Data layers of Microscopy Image Browser section>.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
%%
% 
% <<images\menuModel.png>>
% 
%% Convert type
% Convert model to a different type; the current type of the model is checked in the menu.
%
% [dtls][smry] *Types of models in MIB* [/smry]
%
% * *63 materials*, [_default_], allows to store Models, Selection and Mask layers in a single memory container, 
%   reduces memory requirements and improves performance, but limits the
%   number of materials to 63
% * *255 materials*, allows to have up to 255 materials in the model, but requires additional computer memory to keep
%   Selection and Mask layers, which doubles memory requirements
% * *65535 materials*, allows to have up to 65535 materials in the model,
% requres ~1.25 times more memory than models with 255 materials. *Please
% note* that when using this mode the look of the <ug_panel_segm.html segmentation panel> will
% be different. <https://youtu.be/r3lpmWyvrJU Click here to see a short demonstration>
% * *4294967295 materials*, allows to have up to 4294967295 materials in
% the model, requires twice more memory than 65535.
% * *Indexed objects->2D objects conn4*, detect all 2D objects (connectivity 4) in all materials of the current model and generate a new model, where each object has an unique index
% * *Indexed objects->2D objects conn8*, detect all 2D objects (connectivity 8) in all materials of the current model and generate a new model, where each object has an unique index
% * *Indexed objects->3D objects conn6*, detect all 3D objects (connectivity 6) in all materials of the current model and generate a new model, where each object has an unique index
% * *Indexed objects->3D objects conn26*, detect all 3D objects (connectivity 26) in all materials of the current model and generate a new model, where each object has an unique index
%
% [/dtls]
%
% [dtls][smry] *An example of standard model conversion into the model with indexed objects* [/smry]
%
% <<images\menuModelsConvertIndexedObjects.png>>
% 
% [/dtls]
% 
% [dtls][smry] *How to work with models having more than 255 materials*[/smry]
%
% Materials should be named with numbers that represent the index of the
% current working material. For example, in the image below the current
% working material for the brush tool is 11555.
%  
% <<images\PanelsSegmentation_65535materials.png>>
%
% Selection of material for work can be done either by the right mouse
% click over the segmentation table and seletion of the |Rename...| entry in
% the menu; or by moving the mouse over the desired object in the Image
% View panel and press the [class.kbd]Ctrl[/class] + [class.kbd]F[/class] shortcut.
%
% [/dtls]
% [br8]
%
%% New model
% Allocate space for a new model. Use this menu entry when you want to start a new model or to delete the existing one.
% Alternatively it is possible to use the [class.kbd]Create[/class] button in the <ug_panel_segm.html Segmentation Panel>.
% [br8]
%
%% Load model
% Load model from the disk. By default |MIB| tries to read the models in the MATLAB format (.model), but it is also
% possible to specify other formats as well
% [br8]
%
% [dtls][smry] *List of compatible model types* [/smry]
% 
% * *.AM, Amira Mesh* - as Amira Mesh label field for models saved in <http://www.vsg3d.com/amira/overview Amira> format
% * *.NRRD, Nearly Raw Raster Data* - a data format compatible with <www.slicer.org 3D slicer>.
% * *.MRC, Medical Research Council format* - a data format compatible with
% IMOD <http://bio3d.colorado.edu/imod>. When using this mode, it is
% possible to provide a list of MRC files, where each object is encoded
% using its number in a separate MRC-file; after that MIB will assemble and merge all these
% individual objects together into a single model.
% * *.TIF, TIF format*
% 
% *Note!* almost any standard image format can be loaded as a model, please
% choose [class.code]All files (*.*)[/class] filter in the Open model dialog.
%
% [/dtls]
%
% Alternatively it is possible to use the [class.kbd]Load[/class] button in the <ug_panel_segm.html Segmentation Panel>.
% [br8]
%
%% Import model from MATLAB
%
% Imports model from the main MATLAB workspace. Please provide a variable name from the main MATLAB workspace with the model.
% The variable could be either a matrix with dimensions similar to those of
% the loaded dataset [class.code][1:height, 1:width, 1:no-slices][/class]
% of the [class.code]uint8[/class] class or a structure with fields
% specified below.
%
% [dtls][smry] *Fields of MIB model structure* [/smry]
%
% * *.model* - the field |model| is a matrix with dimensions similar to those of the loaded dataset [class.code][1:height,
% 1:width, 1:depth, 1:time][/class] of the [class.code]uint8[/class] class
% * *.modelMaterialNames* - [_optional_] the field |materials| a cell array with names of the materials used in the model
% * *.modelMaterialColors* - [_optional_] a matrix with colors (0-1) for the materials of the model, [1:materialIndex, Red Green Blue]
% * *.labelText* - [_optional_] a cell array containing labels for the annotations
% * *.labelPosition* - [_optional_] a matrix containing positions for the
% annotations [class.code][1:annotationIndex, x y z][/class]
%
% [/dtls]
% [br8]
%
%% Export model to...
% Exports model from MIB to other programs. 
%
% [dtls][smry] *List of options to export the models* [/smry]
% 
% * *MATLAB*, export to the main MATLAB workspace, as a structure (see above). The exported models may be later imported back to |MIB| using the _Import model
% from Matlab_ menu entry
% * *Imaris as volume*, export model to Imaris (if it is available, please
% see <im_browser_system_requirements.html#16 System Requirements
% section> for details
%
% [/dtls]
% [br8]
% 
%% Save model
% Saves model to a file in the MATLAB format; the file name is not asked
%
% [dtls][smry] *Model filename considerations, when using Save model* [/smry]
% 
% * Default template such as |Labels_NAME_OF_THE_DATASET.model|
% * the name that was provided from the _Save model as..._ entry
% * the name that was obtained during the _Load model_ action.
% The models can be saved also using the corresponding _Save model_ button in <ug_gui_toolbar.html Toolbar>
%
% [/dtls]
% [br8]
%
%% Save model as...
% Provide filename and file format and save the model to a file
%
% [dtls][smry] *List of model formats available for saving* [/smry]
% 
% * *.AM, Amira Mesh* - as Amira Mesh label field in RAW, RAW-ASCII and RLE
% compressed formats. (*Note!* the RLE compression is very slow).
% * *.MAT, MATLAB format* - MATLAB native data format for MIB version 1
% * *.MODEL, MATLAB format* - _[default]_, MATLAB native data format for MIB version 2
% * *.MOD, IMOD format* - contours for IMOD 
% * *.MRC, IMOD format* - volume for IMOD 
% * *.NRRD, Nearly Raw Raster Data* - a data format compatible with <www.slicer.org 3D slicer>.
% * *.STL, STL format* - triangulated mesh for use with visualization
% programs such as Blender.
% * *.TIF, TIF format*
%
% [/dtls]
% [br8]
%
%% Render model...
% The segmented models can be rendered directly from MIB using one of the
% following methods:
%
% [dtls][smry] *MIB rendering* [/smry]
%
% Starting from MIB (version 2.5) and MATLAB R2018b the materials can be
% directly visualized in MIB using hardware accelerated volume rendering
% engine. The datasets for visuzalization can be downsampled during the
% export. It is possible to make snapshots and animations.
% 
% Limitations:
% 
% * One material at the time
% * Scale bar is not yet available
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/4CrfdOiZebk"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/J70V33f7bas</a>
% </html>
% 
% [/dtls]
%
% [dtls][smry] *MATLAB isosurface*[/smry]
%
% MIB uses MATLAB engine to generate isosurfaces
% from the models and visualize those using a modification of the <http://www.mathworks.com/matlabcentral/fileexchange/334-view3d-m view3d> function 
% written by Torsten Vogel. 
% 
% 
% <html>
% <table style="width: 600px; text-align: left; margin-left: 60pt" cellspacing=2px cellpadding=2px >
% <tr style="font-weight: bold; background: #ff6600;">
%   <td colspan=2><b>The following controls are implemented:</b></td>
% </tr>
% <tr>
%   <td>Double click to restore the original view</td>
%   <td></td>
% </tr>
% <tr>
%   <td>Hit 'z' key over the figure to switch from <em>ROTATION</em> to <em>ZOOM</em></td>
%   <td>
%   <ul>In the <em>ZOOM</em> mode
%       <li>press and hold left mouse button to zoom in and out</li>
%       <li>press and hold middle mouse button to move the plot</li>
%   </ul>
% </td>
% </tr>
% <tr>
%   <td>Hit 'r' key over the figure to switch from <em>ZOOM</em> to <em>ROTATION</em></td>
%   <td>
%   <ul style="margin-left: 50pt">In the <em>ROTATION</em> mode
%       <li>press and hold left mouse button to rotate about screen xy axis</li>
%       <li>press and hold middle mouse button to rotate about screen z axis</li>
%   </ul>
% </td>
% </tr>
% <tr>
% <td colspan=2><img src="images\render_in_matlab.jpg"</img>
% </tr>
% <tr>
% <td colspan=2>A brief demonstration is available in the following videos:<br>
% <a href="https://youtu.be/svAFGBRfeoI"><img
% style="vertical-align:middle;" src="images\youtube.png"> https://youtu.be/svAFGBRfeoI</a><br>
% <a href="https://youtu.be/dMeoIZPaDS4?t=16m56s"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/dMeoIZPaDS4?t=16m56s</a>
% </tr>
% </table>
% <br>
% </html>
%
% [/dtls]
%
% [dtls][smry] *MATLAB isosurface and export to Imaris* [/smry]
%
% MIB uses MATLAB engine to generate isosurfaces
% from the models and export the resulting surfaces to Imaris for visualization. 
%
% <html>
% A demonstration is available in the following video:<br>
% <a href="https://youtu.be/nDpC8b8lqo4"><img style="vertical-align:middle;" src="images\youtube.png"> https://youtu.be/nDpC8b8lqo4</a>
% <br>
% </html>
%
% [/dtls]
%
% [dtls][smry] *MATLAB volume viewer* [/smry]
%
% *MATLAB volume viewer*, render the model using MATLAB volume viewer,
% available only for the MATLAB version of MIB and requires R2017b - R2019b or
% newer. For the release R2019b, the materials may be displayed together
% with the volume, but there are not control for lightning, so it is not very convenient. 
%
% <html>
% Demonstration of the visualization of models as Volumes:<br>
% <a href="https://www.youtube.com/watch?v=J70V33f7bas"><img style="vertical-align:middle;"
% src="images\youtube.png"> https://www.youtube.com/watch?v=J70V33f7bas</a><br>
% Demonstration of the visualization of models as materials together with the image dataset:<br>
% <a href="https://youtu.be/GM9V1IxNkTI"><img style="vertical-align:middle;"
% src="images\youtube.png"> https://youtu.be/GM9V1IxNkTI</a><br>
% </html>
% 
%
% <<images\MenuModelsRenderMatlabVolumeViewer.jpg>>
% 
% [/dtls]
%
% [dtls][smry] *Fiji volume* [/smry]
%
% MIB can use |Fiji 3D viewer| for visualization of the model as
% a volume (<http://mib.helsinki.fi/tutorials/VisualizationOverview.html click here for details>. (requires Fiji to be installed,
% <im_browser_system_requirements.html see here>).
%
% <html>
% A demonstration is available in the following video:<br>
% <a href="https://youtu.be/DZ1Tj3Fh2HM"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/DZ1Tj3Fh2HM</a>
% </html>
%
%%
% 
% <<images\MenuModelsRenderFiji.jpg>>
% 
% [/dtls]
%
% [dtls][smry] *Imaris surface* [/smry]
%
% *Imaris surface*, render the model in Imaris; requires Imaris and ImarisXT to be installed,
% <im_browser_system_requirements.html see here>
%
% <html>
% A demonstration is available in the following video:<br>
% Without ImarisXT <a href="https://youtu.be/MbK2JcTrZFw"><img style="vertical-align:middle;" src="images\youtube.png"> https://youtu.be/MbK2JcTrZFw</a><br>
% With ImarisXT <a href="https://youtu.be/yODGYJUzTr0"><img style="vertical-align:middle;" src="images\youtube.png"> https://youtu.be/yODGYJUzTr0</a><br>
% </html>
%
%%
% 
% <<images\MenuModelsRenderImarisLarge.jpg>>
% 
% The rendered material is specified in the Material list of the
% <ug_panel_segm.html Segmentation Panel>. 
%
% [/dtls]
% [br8]
%
%% Annotations...
% Use this menu to modify the |Annotations| layer
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/3lARjx9dPi0"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/3lARjx9dPi0</a>
% </html>
%%
% 
% * *List of annotations...* - starts an auxiliary window with a list of
% existing annotations, <ug_panel_segm_tools.html see more here> .
% * *Export to Imaris as Spots* - export all annotations to a Spot object
% in Imaris, please export first the dataset and only after that export
% annotations as spots
% * *Remove all annotations...* - deletes all annotations stored with the
% model.
%
%% Model Statistics...
% Get statistics for the selected material of the model. Statistical results may be used to filter the model based on properties of its objects. 
% The statistics dialog can also be reached from the <ug_panel_segm.html  Segmentation Panel> ->Materials List->Right mouse click->Get statistics...
% See more <ug_gui_menu_mask_statistics.html here>
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