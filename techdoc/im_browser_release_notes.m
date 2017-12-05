%% Microscopy Image Browser Release Notes
% 
%
% <im_browser_product_page.html Back to Index>
%
%
%
%% 2.21 / 04.12.2017
% * Added model with 4294967295 materials for tests
% * Improved object picker for models with 65535 materials
% * Fix compiling of certain function using the |-compatibleArrayDims| switch to be compatible with the new Matlab API
% * Fix of 'Fix selection to material' switch for models with more than 255 materials
% * Fix connection to Omero for the deployed version
%
%% 2.20 14.11.2017
% * Added a new 3D Grid mode to the Graphcut tool; when used the fast interactive performance can be achieved even with very large datasets
% * Added denoise of image using deep neural network (|Image Filters
% Panel->Filter->DNN Denoise|), requires Matlab R2017b or newer and Neural Network Toolbox
% * Added export annotations to Imaris (|Menu->Models->Annotations->Export to Imaris as Spots|)
% * Added possibility to do not calculate intensity profiles for measurements to make measurements faster
% * Added buttons to magnify snapshots in x2, x4, and x8 times using the Snapshot tool
% * Added reading of material names and colors when opening AmiraMesh models
% * Added insert of a dataset as a new time point: (|RMB over the file name -> Insert into the open dataset|)
% * Added utilization of the block mode for calculation of object properties for the 3D objects in the XY orientation
% * Rearranged the Graphcut, Watershed and Object separation tools to separate functions under |Menu->Tools|
% * Updated the Crop tool, the interactive mode allows to modify the selection of the area for cropping before accepting it
% * Updated calculation of curve lengths in the Get Statistics dialog, now the points are smoothed with average filter of 3
% * Updated connection to Imaris
% * Updated BioFormats to 5.7.1
% * Updated |inputdlg| to customizable |mibInputMultiDlg| function
% * Updated measure line/freehand length tool (|Menu->Tools->Measure|), now  after use of these tools the selection is not shown
% * Fixed disabling of the selection mode after modification of measurements
% * Fixed movement of measurements after their recalculation
% * Fixed recalculation of voxels after import of images from Matlab
% * Fixed resampling of a single slice RGB images
% * Fixed incorrect reading of the AmiraMesh header for the fuse mode of the Chop tool
% * [Programming] moved mibController.connImaris to mibModel.connImaris
% * [Programming] updated syntax of mibImage.clearMask
%
%% 2.12 18.09.2017
%
% * Added a new tool to detect a frame around images (Menu->Image->Tools
% for images->Select image frame...)
% * Added the auto-update mode for the graphcut segmentation
% * Added possibility to count annotations in the |List of annotations|
% window: Segmentation panel->Annotations->Annotation list->Right mouse
% click over the table with annotations
% * Added export of selected annotations to Amira as landmark points or to
% Matlab: Segmentation panel->Annotations->Annotation list->Right mouse
% click over the table with annotations
% * Added saving of annotations to Amira landmarks format (Segmentation panel->Annotations->Annotation list->Save)
% * Added sorting of annotations in the Annotation list window:
% Segmentation panel->Annotations->Annotation list->Sort table
% * Added possibility to remove branches during morphological thinning:
% Menu->Selection->Morphological 2D/3D opetations->Thin
% * Added clipping with Mask for image dilation
% * Added shift of annotations during resampling
% * [Programming] Added material names parameter to call of mibImage.createModel function
% * Improved performance when selecting objects in the Get Statistics window in the the Add and Replace modes
% * Improved resizing of the Log List window
% * Improved update of the graphcut window when switching datasets
% * Modified use of the 'E' key shortcut, now it toggles between two recently selected materials
% * Fixed reading of metadata for MRC files
% * Fixed loading of models when only the z-dimension is mismatched
% * Fixed use of the block mode, when options .x, .y, .z are present in mibModel.getDataXD/mibModel.setDataXD functions
% * Fixed erode and dilate for elongated kernels
% * Fixed backup before interpolation for the YZ and XZ orientations
% * Fixed access to the Class Reference documentation (Menu->Help->Class Reference)
% * Fixed import of annotations that are in a wrong orientation
% * Fixed export of TIF images in the sequential mode
%
%% 2.1 01.06.2017
%
% * Added materials with 65535 maximal number of materials
% * Added export to Excel for non-PC platforms via <https://se.mathworks.com/matlabcentral/fileexchange/38591-xlwrite--generate-xls-x--files-without-excel-on-mac-linux-win xlwrite: Generate XLS(X) files without Excel on Mac/Linux/Win>
% * Added automatic mode for interpolation of images shown in the Image
% View panel. When magnification is 100% or higher MIB is using the nearest
% method, otherwise bicubic
% * Added Median3D filter to the Image Filters panel (R2017a and newer)
% * Added to the Statistics dialog generation of new models, where each object has its own index
% * Added running average correction to the Alignment tool
% * Added find and select material under the mouse cursor using the Ctrl+F shortcut
% * Added pasting of selection to all layers (Menu->Selection->Selection to buffer->Paste to all slices (Ctrl+Shift+V)
% * Added indication of material index under the mouse cursor to the |Pixel info| of the |Path panel|
% * Added possibility to save models for MIB version 1 (File->Models->Save model as...->Matlab format for MIB ver. 1 (*.mat))
% * Modified use of Ctrl+C/Ctrl+V, now the stored dataset can be pasted to
% any other dataset in MIB assuming that the dataset have the same
% width/height. As result |storedSelection| property of |mibImage| class has been
% moved to |mibModel| class
% * Fixed export of models and masks to another MIB dataset for the compiled version
% * Fixed singleton running of MIB, now it is possible to have several
% instances of MIB run in parallel
%
%% 2.01 11.04.2017
%
% * Added selection of the model type to Menu->Models->Type and removed it
% from the Preferences dialog
% * Added 'Recalculate selected measurements' function to the Measure tool
% to recalculate distances and image intensities
% * Added possibility to exclude black or white intensities when using the
% contrast normalizaton of Z-stacks (Menu->Image->Contrast->Normalize layers->Z stack)
% * Added imresize3 function to resample datasets with R2017a (40-50% faster)
% * Added calculation of annotation labels occurrence in the Stereology tool
% * Moved mibView.disableSegmentation to mibModel.disableSegmentation
%
%% 2.000 20.03.2017 Official Release, 2.002 (02.04.2017)
%
% * With release 2.0 MIB has been rewritten to utilize Controller-View-Model
% architecture, which brings stability and ease of future development.
% However, because of that, the system requirements for Matlab were increased
% and MIB2 is only available for Matlab R2014b and older 
% (due to continuous development of Matlab, the most recent release is always recommended)
% * Added "Copy to clipboard" and "Open directory in the file explorer" for the right mouse button
% click over the current path edit box of the path panel (ver. 2.002)
% * Added adaptive black and white thresholding
% * Many other improvements
% * Added offset shift for the rechop mode (ver. 2.001)
% * Renamed Area to Volume for the Get Statistics tool for 3D objects (ver. 2.002)
% * Big fixes (ver. 2.001, 2.002)
%
% *Back to* <im_browser_product_page.html *Index*>
