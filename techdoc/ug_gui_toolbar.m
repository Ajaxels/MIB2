%% Microscopy Image Browser Toolbar
% Toolbar under the main menu. The toolbar offers fast access to few most frequently used
% functions.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
%
% 
% <<images/Toolbar.png>>
% 
%% Paste dataset from the system clipboard
%
% 
% <<images/toolbar_open.jpg>>
%
% Pastes image from the system clipboard. This functionality
% is implemented using <http://www.mathworks.com/matlabcentral/fileexchange/28708-imclipboard *IMCLIPBOARD*> function
% by  Jiro Doke, MathWorks, 2010.
%
%% Virtual mode switch
% 
% <<images/toolbar_virtmode.png>>
%
% By default MIB works in memory-resident mode, when each dataset is loaded
% completely to computer memory. For large datasets it may take long time
% to load the datasets, in this case the virtual (harddrive-resident) mode
% can be used to browser the datasets. The virtual mode is enabled when
% this button has a HDD icon. It is possible to open datasets in the HDF5
% format and datasets that are compatible with the
% <https://www.openmicroscopy.org/bio-formats Bio-Formats library>. In
% later case, please make sure that the Bio checkbox of the <ug_panel_dir.html Directory Contents panel> is enabled.
%
% The virtual mode is more limited comparing to the memory-resident mode
% and yet can't be used for image segmentation. The only segmentation tools
% available in the virtual mode for MIB version 2.40 are <ug_panel_segm_tools.html Annotations and 3D Lines>.
%
%% Development shortcut...
% 
% <<images/toolbar_development.jpg>>
%
% Reserved for the development purposes
%
%% Save model
%%
% 
% <<images/toolbar_save.jpg>>
%
% Saves model to a file in the Matlab format. The file name is not asked, which means that the |MIB| will use:
%%
% 
% * Default template such as |Labels_NAME_OF_THE_DATASET.model|
% * The name that was provided from the _Save model as..._ entry
% * The name that was obtained during the _Load model_ action
% The models can be saved also using the _Save model_ command in <ug_gui_menu_models.html Menu->Models>.
%
%% Zoom in
%
% 
% <<images/toolbar_zoomin.jpg>>
%
% Increases magnification in 1.5 times.
%
%% 1:1
%
% 
% <<images/toolbar_zoom100.jpg>>
%
% Magnifies to 100% magnification.
%% Fit to screen
% 
% <<images/toolbar_zoomfit.jpg>>
%
% Fits the image to the view image panel. 
%% Zoom out
% 
% <<images/toolbar_zoomout.jpg>>
%
% Decreases magnification by 1.5 times.
%% Fast pan mode
% 
% <<images/toolbar_fastpan.jpg>>
%
% Panning an image means moving the image displayed in the <ug_panel_im_view.html Image View panel>. This mode is enabled
% during pressing of the right mouse button. Normally to pan the image |MIB| gets full sized image of the
% currently shown slice. When the Width/Height of the image is high it results is a small lag. Enabling this mode reduces the
% lag, but does not allow to see the full image during the panning process.
%
%% Undo
% 
% <<images/toolbar_undo.jpg>>
%
% Does Undo operation (Ctrl+Z shortcut): restore the previous state of the dataset. The length of the Undo history can be set in the <ug_gui_menu_file_preferences.html Menu->File->Preferences>.
%
% <html>
% Demonstration of the undo/redo system is available in the following video:<br>
% <a href="https://youtu.be/PrY3Eo02gU8"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/PrY3Eo02gU8</a>
% </html>
%
%% Redo
% 
% <<images/toolbar_redo.jpg>>
%
% Does Redo operation: re-apply the last undone action.
%
%
%% Make snapshot
% 
% <<images/toolbar_snapshot.jpg>>
%
% Makes snapshot of the current slice. <ug_gui_menu_file_makesnapshot.html See more here>.
%%
% 
% <<images/MenuFileSnapshot.png>>
% 
%% YX, YZ, or XZ
%%
% 
% <<images/toolbar_xyz.jpg>>
%
% Changes the viewing plane orientation. Default is the |XY| plane. Some
% tools may not work if the dataset is not in the XY orientation. There are following key shortcuts that allow to switch the
% plane of the dataset. As shown on the image below, placing the mouse cursor in the XY view above the intersection of two
% colored lines and pressing Alt+3 will switch the orientation to the ZY plane. 
% 
% * *Alt+'1'*, switches the view to the XY plane using the image coordinates under the mouse cursor
% * *Alt+'2'*, switches the view to the ZX plane using the image coordinates under the mouse cursor
% * *Alt+'3'*, switches the view to the ZY plane using the image coordinates under the mouse cursor
%
% <html>
% A demonstration is available in the following video:<br>
% <a href="https://youtu.be/4NXSEkrhnts"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/4NXSEkrhnts</a>
% </html>
% 
% <<images/ToolbarPlaneChangeButtons.jpg>>
% 
%% Line measure tool
%%
% 
% <<images/toolbar_measure.jpg>>
%
% Measures linear distance. See more in the  <ug_gui_menu_tools.html Tools menu>.
%
%% Interpolation type
%
% 
% <<images/toolbar_interpolationBtn.png>>
%
% Changes type of the interpolator: for shapes, or for lines. See more in the <ug_gui_menu_selection.html Selection menu>.
%
%% Type of image rescaling for visualization
%%
% 
% <<images/toolbar_image_resizing.png>>
%
% Changes type of the image resizing for the visualization: use 'nearest' to see
% unmodified pixels and 'bicubic' for smooth appearance. *Note!* the |nearest| option gives the fastest and |bicubic| the
% slowest performance.
%
% <html>
% A demonstration is available in the following videos:<br>
% <a href="https://youtu.be/N7jFSUOrVCg"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/N7jFSUOrVCg</a>
% <br>
% <a href="https://youtu.be/T08fJeucn0U"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/T08fJeucn0U</a>
% </html>
%
%% Center marker toggle
%%
% 
% <<images/toolbar_center_marker.jpg>>
%
% Switch on/off marker for the center of the image axes. It is helpful when
% doing the graphcut segmentation using the grid mode.
%
%
%% Block-mode switch
%%
% 
% <<images/toolbar_blockmode.jpg>>
%
% When enabled the filters will only be applied to the part of the dataset
% shown on the screen. This speeds up performance and may be good
% for any kind of tests. *_Please note:_* this is not compatible with ROIs, _i.e._
% when the ROIs are shown MIB will work with the full dataset.
%
%% Show ROI switch
%%
% 
% <<images/toolbar_roi.jpg>>
%
% Turns ON/OFF visualization of ROIs
%
%% Volume Rendering
% 
% <<images/toolbar_volren.jpg>>
%
% Render the dataset using the shear-warp transform. Applicable to fairly
% small datasets. The electron microscopy datasets should be inverted for
% proper visualization.
%
% <html>
% A demonstration is available in the following video:<br>
% <a href="https://youtu.be/rCYSTKF0TsM"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/rCYSTKF0TsM</a>
% </html>
%
%% Turn on parallel processing
% 
% <<images/toolbar_parallel.jpg>>
%
% Starts matlab parallel processing routine. Requires the parallel
% processing toolbox. It seems that it is not really needed, Matlab handles the paralling of processing automatically in many
% cases.
%
%% Swap left and right mouse button
% 
% <<images/toolbar_swapmousebuttons.jpg>>
%
% In the default state the left mouse button is responsible for panning the
% image and the right mouse button for selection, when this button is pressed the mouse
% button behavior is swapped. These modes can also be set from the <ug_gui_menu_file_preferences.html  Menu->File->Preferences
% dialog>.
%% Mouse button
% 
% <<images/toolbar_swapmouse.jpg>>
%
% Switches the way of zooming and changing the slices of the dataset. When the button is not
% pressed the mouse wheel changes the magnification and the |Q| and |W|
% buttons change the slices. These modes can also be set from the <ug_gui_menu_file_preferences.html  Menu->File->Preferences
% dialog>.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 