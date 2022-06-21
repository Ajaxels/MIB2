%% Directory Contents Panel
% This panel provides the listing of files in the selected directory with a
% possibility to filter them based on known image and video formats. 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
%%
% 
% <<images\PanelsDirContents.png>>
%
%% 1. Multiple buffer buttons
% These buttons allow fast access to several datasets stored in the memory. The green color of the button indicates that
% there is a dataset loaded. When cursor is above the button a tooltip with the full file name appears to help with
% identification of the loaded dataset. The datasets may be switched using the left mouse button press on the desired button.
% The left mouse button shows a popup menu with additional options:
%
% 
% <<images\PanelsDirContentsBuffers.png>>
% 
%%
% 
% * *Duplicate dataset*, creates a duplicate of the currently shown dataset
% and put it behind one of the available buffers
% * *Sync view, (xy) with...*, synchronizes the view with another dataset in the XY
% coordinates
% * *Sync view, (xyz) with...*, synchronizes the view with another dataset in the
% XYZ coordinates, for 4D-5D datasets
% * *Sync view, (xyzt) with...*, synchronizes the view with another dataset in the
% XYZT coordinates, for 5D datasets
% * *Close dataset*, removes selected dataset from the memory
% * *Close all stored datasets*, removes all stored datasets from the memory
% 
%% 2. Main list box
% The major part of the panel is occupied with this list box that shows
% list of files in the selected directory (the directory can be selected from the <ug_panel_path.html Path Panel>). 
% The files are filtered with the specified filter (*Filter*). Value |all known| displays all readable formats.
%%
% 
% * Double click on a file, loads it into |MIB| and displays it in the
% <ug_panel_im_view.html Image View panel>. If |sequence| (*8*) is checked then all shown files
% are assembled into a single multi-layered dataset
% * Double click on the *[.]* line changes the folder to the top level of the current
% logical drive
% * Double click on the *[..]* line changes the folder to one level up
% * Individual datasets can be selected using [class.kbd]&#8679; Shift[/class]/[class.kbd]Ctrl[/class] + [class.kbd]left
% mouse button[/class] and loaded via a context menu accessible with the right mouse button
% * The right mouse click above the scroll bar will scroll the list to the
% top
% * The context menu is accessible with the right mouse button:
%
% 
% <<images\PanelsDirContentsFileList.png>>
% 
% <html>
% <ul style="padding-left: 30px">
%   <li><b>Combines selected datasets</b>, combine selected datasets into a single 3D stack</li>
%   <li><b>Load part of the dataset (AM and TIF)</b>, loads part of the bigger dataset. It is possible to define starting, ending 
% points, z-step and the XY binning. This option is implemented only for Amira Mesh and TIF files</li>
%   <li><b>Load each N-th dataset</b>, defines a step to assemble each N-th file into a 3D stack
%   <li><b>Insert into the open dataset...</b>, allows to insert selected
%   files into the open dataset.
%   <li><b>Combine as color channels...</b>, combines selected datasets into a single 2D slice where each dataset is assigned to own color channel.
%   <li><b>Add as a new color channel</b>, adds images as a new color
%   channel to the existig dataset. The color channels to show may be selected in the <a href="ug_panel_view_settings.html">View Settings panel</a>.
%   <li><b>Adds each N-th dataset as a new color channel</b>, add images with N-step as a new color channel to the existing dataset
%   <li><b>Renames selected file</b>, rename selected file
%   <li><b>Deletes selected files</b>, permanently delete selected files from the disk
%   <li><b>File properties</b>, information about the file: date/time and size in bytes. 
% </ul>
% </html>
%
%% 3. Filter
% Filter list of files with available image type filters.
% The lost of available extensions depends on whether the standard or
% bioformats reader is used and whether or not the virtual mode is enabled.
% All together there are 4 different configurations for image format
% filters. 
%
% The list of filters can be modified by pressing the right mouse key over
% the |Filter| combobox and select one of the options:
%
% 
% * 'Register extension' - to add extensions to the lists
% * 'Remove selected extension' - to remove selected extension from the list
% 
% 
%% 4. The [class.kbd]Update[/class] button
% Updates the file list in the Directory contents window.
%
%% 5. Left Interchangeable Panels
% Selected panel will be shown in the lower left part of |MIB|
%
% * <ug_panel_segm.html Segmentation panel>
% * <ug_panel_roi.html ROI panel>
% 
%% 6. Right Interchangeable Panels
% Selected panel will be shown in the right bottom part of |MIB|.
%
% * <ug_panel_image_filters.html Image Filters>
% * <ug_panel_mask_generators.html Mask Generators>
% * <ug_panel_fiji_connect.html Fiji Connect>
%
%
%% 7. [class.kbd][&#10003;] *Bio*[/class] checkbox
% |MIB| can also open some specific biological image
% formats. Usually these are the native file formats for different
% microscopes. The reader for these formats is obtained from 
% <http://openmicroscopy.org/info/bio-formats Bio-formats>
% and is based on connected to |MIB| Bio-formats Java library (the library is stored in the 
% |mib\ImportExportTools\BioFormats| directory). When the [class.kbd][&#10003;] *Bio*[/class] checkbox is selected the 
% Bio-formats reader is called to select desired datasets.
%
%% 8. ?.
% Access to this help page
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
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
% 	padding: 0.1em 0.3em; 
% 	font-family: inherit; 
% 	font-size: 0.95em;
% }
% .h3 {
% color: #E65100;
% font-size: 12px;
% font-weight: bold;
% }
% [/cssClasses]