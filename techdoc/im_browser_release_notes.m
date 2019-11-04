%% Microscopy Image Browser Release Notes
% 
%
% <im_browser_product_page.html Back to Index>
%
%
%
%% 2.601 / 10.10.2019
%
% * The deployed version of MIB comes with R2019b instead of R2017a
% * Added the Batch mode for repetitive processing of images (Menu->File->Batch processing)
% * Added visualization of models using Matlab Volume Viewer app (Menu->Models->Render model->Matlab volume viewer, R2019 or newer, Matlab version only)
% * Added Drag & Drop materials to the segmentation tools (Segmentation panel->Drag and Drop materials, https://youtu.be/NGudNrxBbi0)
% * Added alignment of color channels using landmark multi points (Menu->Dataset->Alignment->Algorithm:Color channels, multi points
% * Added content-aware fill using coherence transport (Menu->Image->Tools for images->Content-aware fill), for R2019a/R2019b or newer
% * Added debris removal tool to automatically or menually remove debris from volumetric datasets (Menu->Image->Tools for images->Debris removal)
% * Added use of Oriented FAST and rotated BRIEF (ORB) points for automatic alignment (R2019 or newer)
% * Added optional correction for instant jumps during running average correction of the drift alignment algorithm
% * Added possibility to add material name and object id during export of quantitation results from the Statistics Dialog to the annotation layer
% * Added export of results from the Statistics Dialog to comma-separated values
% * Added copy to the system clipboard the columns from the the Statistics Dialog (right mouse click over the table and select Copy column(s) to clipboard)
% * Added batch modification of values and coordinates for the annotations
% * Added 4D options to "Material to Selection" and "Material to Mask" options for the context menu of the Segmentation table 
% * Added calculation of quantile for automatic contrast stretching (View settings->Display->Right click over the min/max buttons)
% * Added "Ctrl+e" key shortcut to toggle between current and previous image container
% * Added export of graphs from the graphcut workflow to 3D Lines for visualization
% * Rewritten Image arithmetics to include mask, model, and selection layers (|Menu->Image->Tools for images->Image arithmetic...|)
% * Updated use of xlswrite, for R2019a or newer writecell function will be used
% * Updated data conversion from 32-bit to 8- and 16-bit; from 8-bit to 16-bit
% * Updated Bio-Formats to 6.2.1 (Requires Matlab R2017b or newer)
% * [2.601] Bug fixed
% * [2.601] Added export of annotations to CSV format
%
%
%% 2.51 / 13.03.2019
% * Added methods for automatic global black-and-white thresholding (|Menu->Tools->Semi-automatic segmentation->Global thresholding|)
% * Added selection of materials for rendering of Matlab Isosurface models (|Menu->Models->Render model->Matlab isosurface|)
% * Added calculation of images with extended depth-of-field focus stacking
% (|Menu->Image->Tools for images->Intensity projection->Focus stacking|)
% * Added saving of HDF5 format in the virtual mode without loading of complete stack
% * Added saving of AmiraMesh files as a sequence 2D sections (|Menu->File->Save image as->Amira Mesh binary file sequence|)
% * Added an option to display an orthoslice during visualization of 3D lines
% * Added tip of the day window (|Menu->Help->Tip of the day|)
% * Added H-maxima and H-minima transforms to Mask generators (|Mask generators panel->Morphological filters|)
% * Added |Single Mask object per dataset| option when cropping objects from the Get Statistics dialog
% * Added export of the supervoxels from Graphcut to a model
% * Improved performance when several materials are removed from the model
% * Improved the Image arithmetics dialog (|Menu->Image->Tools for images->Image arithmetic...|)
% * Updated BioFormats reader to use Memoizer class, this should hopefully
% fix Java memory leaks; temporary directory can be specified in
% |Menu->File->Preferences->External dirs|
% * Updated sorting of the Get Statistics dialog
% * Fixed initialization of 3D hardware rendering of models
% * Fixed pixel size when combining 2D images with different dimensions
% * Fixed adding icons to buttons when MIB is installed in network path that starts from  "//"
%
%% 2.501 / 21.12.2018
% * Added swap slices option (Menu->Dataset->Slice->Swap slices)
% * Fixed rendering of combined image in the split color channel mode with Lut enabled in Snapshot and Make movie tools
% * Fixed Copy Slice for the Insert mode
%
%% 2.50 / 17.12.2018
% * Added hardware accelerated 3D volume rendering (Menu->File->Render
% volume->MIB rendering). The volume rendering can be used also for making
% snapshots and animations. Requires Matlab R2018b or newer!
% * Added automatic image alignment using detected features
% * Added 20 distinct colors palette
% * Added center point marker for the image axes (Toolbar -> center point button)
% * Added shuffling of annotations to the randomizer tool (Menu->File->Rename and shuffle)
% * Added delete multiple materials from the model at once (the '-' button in the Segmentation panel)
% * Added split color channel mode for videos (Menu->File->Make movie)
% * Added possibility to change default filters for images (Directory contents panel->Filter combobox->Right mouse click)
% * Added contrast normalization for all layers 
% * Added fuse of annotations during fusing of cropped models (Menu->File->Chopped images->Import->Fuse)
% * Added auto removal of spaces in material names when exporting models to Amira
% * Added loading of masks that are smaller or larger than the depth of the dataset
% * Added alternative way to specify a frame around the dataset (Menu->Dataset->Transform->Add frame)
% * Improved Lasso mode in the segmentation tools
% * Updated Bio-Formats to version 5.9.2
% * Fixed some compatibility issues with R2018b
% * Fixed a bug in the object separator tool
% * Fixed instructions how to calibrate dataset using the scale bar tool
% * Fixed update of the current color channel after conversion to grayscale
% * Fixed conversion from multicolors to grayscale
% * Fixed insert of a new datasets into the open dataset
% * Fixed a bug of non working scroll wheel after aligning two datasets
% * Fixed combine files as color channels mode
% * Fixed missing values for annotations when imported from matlab workspace together with the model
% * Fixed computation of statistics for the models with 255 materials
% * Fixed of cropping of the selection layer for models with more than 63 materials
% * Fixed alignment for models with more than 63 materials
%
%% 2.40 / 31.08.2018
% * Added virtual mode for datasets that are compatible with the BioFormats
% library or in HDF5 format
% * Added shift of annotations when inserting a slice
% * Added shift of annotations when deleting a slice or a frame
% * Added Segment All function to the graphcut image segmentation in the
% grid mode to enable segmentation of all subvolumes
% * Improved performance when showing multiple 3D lines
% * Updated BioFormats to 5.9.1
% * Bug fixes
%
%% 2.302 / 18.05.2018 (03.07.2018)
% * Added Lines3D class for 3D measurements and generation of 3D skeletons and graphs 
% * Added the Image arithmetics dialog (|Menu->Image->Tools for images->Image arithmetics...|)
% * Added the Rename and Shuffle tool (|Menu->File->Rename and Shuffle|) to
% shuffle images for blind modeling and restore the models back to the
% original sets of images
% * Added alignment using multi-point landmarks (|Menu->Dataset->Alignment|)
% * Added modification of Imaris path from MIB preferences:
% |Menu->File->Preferences->External dirs|, please remove IMARISPATH
% variable from the system environmental variables
% * Added calculation of 3D skeleton and morphological operations for 3D
% objects: |Menu->Selection->Morphological 2D/3D operations|, (_only for Matlab R2018a and newer_)
% * Added export of volumes and models for rendering to Matlab VolumeViewer
% application (|Menu->File->Render volume->Matlab volume viewer| or |Menu->Models->Render model->Matlab volume viewer|, (_only the Matlab version of MIB, requires Matlab R2017a and newer_)
% * Added quantitation of objects in physical units (|Menu->Models->Model statistics...|)
% * Added options to insert an empty slice into the dataset (|Menu->Dataset->Slice->Insert an empty slice|) and to insert
% an existing slice into another position (|Menu->Dataset->Slice->Copy slice...|)
% * Added recentering the view after click for the Membrane ClickTracker tool
% * Added export of TransformationMatrix with AmiraMesh files
% * Fix of cropping objects to files from the Get Statistics tool
% * [2.301] Added filter for filenames to the Shuffle and rename tool
% * [2.302] Fixed export of 3D lines to Amira Mesh format
% * [2.302] Fixed recalculation of pixels into the physical units when initializing 3D lines programically
%
%% 2.22 / 16.03.2018
% * Added value field for the annotations, thus each annotation can be weighted based on its value
% * Added possibility to do deep neural network denoising on GPUs with
% small memory, use the |GPU block| parameter in |Image filters->DNN Denoise|
% * Added the Simplify button to the Dataset Info window to allow remove most of metadata
% * Added rendering with Imaris models generated in Matlab
% (|Menu->Models->Render model->Matlab isosurface and export to Imaris|),
% require Imaris 8.
% * Added rendering snapshots with white background (|Toolbar->Snapshot tool->white Bg|)
% * Added rendering of annotations as scaled spots in Imaris
% * Added Get Statistics for models with more than 255 materials
% * Added calculation of Min/Max/Mean/Median intensity projection (Menu->Image->Tools for images->Intensity projection...)
% * Added use of external BMxD filters [Matlab version only!] (Image filters panel->External: BMxD)
% * Added Add Frame tool that can be used to generate a frame around
% dataset with a distinct color or using various repetition methods (Menu->Dataset->Transform->Add frame)
% * Added renaming of annotations (|Menu->Models->Annotations->Annotation list->RMB over the list of selected annotations->Rename selected annotations...|)
% * Improved movie rendering performance for the ROI mode
% * Updated the Image Filter panel
% * Fix of error when opening Images->MorphOps->Morph Closing
% * Fix callback when selecting color channels in the Selection panel
% * Fix of opening of AmiraMesh files with extended headers
%
%% 2.211 / 21.12.2017
% * Updated TripleAreaIntensity plugin
% * Fix, the |contains| function replaced with ismember for compatibility with Matlab 2014b-2016a
% * Fix of lost key press callbacks after modification of the segmentation table
% * Fix of loading hdf5 datasets with time dimension
% * Few other minor bug fixes
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
