%% Directory Contents Panel
% This panel displays a list of files in the selected directory and provides the option to
% filter them based on known image and video formats.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
%%
% 
% <<images\PanelsDirContents.png>>
%
%% 1. Multiple buffer buttons
% Multiple buffer buttons at the upper part of the panel provide fast access to several datasets stored in the memory. 
% Each button represents a dataset, and the green color indicates that a dataset is loaded in that buffer. 
% When you hover your cursor over a button, a tooltip with the full file name of the loaded dataset appears, 
% helping you identify the dataset.
%
% You can switch between datasets by clicking the left mouse button on the desired buffer button. 
%
% Additionally, clicking the left mouse button on a buffer button opens a
% popup menu with additional options:
% 
% <<images\PanelsDirContentsBuffers.png>>
% 
%%
% 
% <html>
% <ul>
% <li> <b>Duplicate dataset</b>, creates a duplicate of the currently shown dataset
% and put it behind one of the available buffers</li>
% <li> <b>Sync view, (xy) with...</b>, synchronizes the view with another dataset in the XY coordinates</li>
% <li> <b>Sync view, (xyz) with...</b>, synchronizes the view with another dataset in the XYZ coordinates, specifically for 4D-5D datasets</li>
% <li> <b>Sync view, (xyzt) with...</b>, synchronizes the view with another dataset in the XYZT coordinates, specifically for 5D datasets</li>
% <li> <b>Link view with</b>, pressing this option links the views in two MIB buffers. 
% When the views are linked, any shift in one view automatically shifts the other view. 
% The buffers can be toggled using the <span class="kbd">^ Ctrl</span> + <span class="kbd">E</span> key shortcut. 
% You can find more information and a demonstration of this feature in the provided link
% <a href="https://youtu.be/DvSBBSuEiDo"><img style="vertical-align:middle;" src="images\youtube.png"></a></li>
% <li> <b>Close dataset</b>, removes the selected dataset from the computer memory</li>
% <li> <b>Close all stored datasets</b>, removes all stored datasets from the computer memory</li>
% </ul>
% </html>
%
% These buffer buttons and their associated options provide convenient ways to manage and interact with 
% multiple datasets in MIB, allowing you to switch between datasets, duplicate them, synchronize views, 
% link views, and remove datasets from memory as needed
% 
%% 2. File list box
% The major part of the panel is occupied by a list box that displays a list of files in the selected directory. 
% The directory can be chosen from the <ug_panel_path.html Path Panel>.  
% The files in the list are filtered based on the specified filter. Selecting *Filter:* [class.dropdown]all known &#9660;[/class] 
% displays all readable formats.
%
% [class.h3]Navigating Folders[/class]
%
% * Double-clicking on the [class.dropdown][.][/class] line changes the folder to the top level of the current logical drive.
% * Double-clicking on the [class.dropdown][..][/class] line changes the folder to one level up.
%
% [class.h3]Selecting and Loading Datasets[/class]
% 
% * Double-clicking on a file in the list loads it into MIB and displays it in the <ug_panel_im_view.html Image View panel>
% * Individual datasets can be selected by holding down [class.kbd]&#8679; Shift[/class] or [class.kbd]Ctrl[/class] and left-clicking 
% on the desired files. They can then be loaded via a context menu accessed
% by right-clicking (see below for the options)
%
% [class.h3]Selecting and Loading Datasets[/class]
%
% * Right-clicking above the scroll bar will scroll the list to the top
% * The context menu, accessible with the right mouse button, provides access to various operations on the selected datasets, 
% such as combining, loading specific parts, inserting, renaming, and
% deleting files, as well as accessing file properties:
% 
% <<images\PanelsDirContentsFileList.png>>
% 
% <html>
% <ul style="padding-left: 30px">
%   <li><b>Combine selected datasets</b>, combine selected datasets into a single 3D stack</li>
%   <li><b>Load part of the dataset (AM and TIF)</b>, loads a specific part of a larger dataset. You can define the 
% starting and ending points, z-step, and XY binning. This option is available for Amira Mesh (AM) and TIF files</li>
%   <li><b>Load each N-th dataset</b>, assembles every N-th file into a 3D stack
%   <li><b>Insert into the open dataset...</b>, inserts selected files into the currently open dataset
%   <li><b>Combine as color channels...</b>, combines selected datasets into a single 2D slice, with each dataset assigned to its own color channel
%   <li><b>Add as a new color channel</b>, adds images as a new color channel to the existing dataset. 
% The color channels to show can be selected in the <a href="ug_panel_view_settings.html">View Settings panel</a>
%   <li><b>Adds each N-th dataset as a new color channel</b>, adds images with an N-step as a new color channel to the existing dataset
%   <li><b>Renames selected file</b>, renames the selected file
%   <li><b>Deletes selected files</b>, permanently deletes the selected files from the disk
%   <li><b>File properties</b>, provides information about the file, such as date/time and size in bytes 
% </ul>
% </html>
%
%% 3. Filter
% The [class.dropdown]Filter dropdown &#9660;[/class] allows you to filter the list of files based on available image type filters. 
% The available extensions in the filter list depend on whether the standard or 
% <https://www.openmicroscopy.org/bio-formats/ Bio-Formats reader> (see below) is used and 
% whether or not the virtual mode is enabled. There are four different configurations for image format filters.
%
%%
% 
% <<images\PanelsDirContents_Filters.png>>
% 
%
% <html>
% <b>To modify the list of filters, follow these steps:</b><br>
% <ol>
% <li> Press the right mouse key over <span class="dropdown">Filter dropdown &#9660;</span></li>
% <li> Select one of the options:<br>
% <ul>
% <li><b>Register extension</b> - this option allows you to add extensions to the filter list</li>
% <li><b>Remove selected extension</b> - this option allows you to remove a selected extension from the filter list</li>
% </ul>
% </li>
% </ol>
% </html>
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
% When the Bio checkbox is selected in MIB, the <http://openmicroscopy.org/info/bio-formats Bio-formats reader> is called to load 
% desired datasets. MIB is capable of opening specific biological image formats, which are typically the native file 
% formats for different microscopes.
%
% The reader for these formats is obtained from Bio-formats and is based on the connected MIB Bio-formats Java library. 
% The library is stored in the
% [class.code]mib\ImportExportTools\BioFormats[/class] directory.[br8]
% Please note that perfomance of the Bio-Formats reader may be slower than
% the standard native readers due to Java-related overheads.
%
%% 8. ?.
% Access to this help page
%
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