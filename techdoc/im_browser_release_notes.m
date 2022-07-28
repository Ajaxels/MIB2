%% Microscopy Image Browser Release Notes
% 
%
% <im_browser_product_page.html Back to Index>
%
%
%
%% 2.831 / 21.06.2022 (blockedImage and 2D patch-wise)
% 
% * Added Destination: Current to Crop in the batch processing mode
%
%% 2.831 / 21.06.2022; 2.83 / 19.06.2022 (blockedImage and 2D patch-wise)
%
% [dtls][smry] *2.83 / 19.06.2022 (blockedImage and 2D patch-wise)* [/smry]
% 
% * Added generation of image 2D and 3D patches around annotation labels ([class.code]Annotation list->Crop out patches around selected annotations[/class])
% * Added possibility to load part of the dataset for TIF files ([class.code]right click over selected filenames->Load part of the dataset (AM and TIF)[/class])
% * Added Info field to measurements to supplement them with additional information ([class.code]Menu->Tools->Measure length->Measure tool[/class])
% * Added generation of pyramidal TIF files and batch processing of BioFormat files ([class.code]Menu->Plugins->File processing->Image converter[/class])
% * Added the "show prompt" option to the Annotations tool ([class.code]Segmentation panel->Annotations->show prompt[/class])
% * Added [InheritLastDIR] tag to inherit directory name from DIR LOOP when saving images using the Protocol organizer ([class.code]Menu->File->Batch processing->DIRECTORY LOOP START[/class])
% * Added "end" tag to the crop operation for the Protocol organizer ([class.code]Menu->File->Batch processing->Crop dataset[/class])
% * Added Drag-and-drop model files to the Segmentation table to load them
% * [2.831] Added Destination: Current to Crop in the batch processing mode
% * Correction of pixel size for pyramidal formats when levels are not multiplied by factor of 2
% * Fixed loading of partial AM files, when step was set to 1
% * Fixed loading of TIF files with YCbCr color space
% * [2.831] MATLAB versions compatibility bug fixes
% * Updated Bio-Formats to 6.10.0 
% * [DeepMIB] Rearranged Architecture into Workflow and Architecture parameters ([class.code]DeepMIB->Network panel[/class])
% * [DeepMIB] Optimized to work without preprocessing of images
% * [DeepMIB] Added blockedImage mode and set it as default processing engine ([class.code]DeepMIB->Predict->Prediction engine[/class])
% * [DeepMIB] Added dynamic masking for the blockedImage processing mode ([class.code]DeepMIB->Predict->Dynamic masking[/class])
% * [DeepMIB] Added 2D Patch-wise mode to process images in patches ([class.code]DeepMIB->Network->Workflow->2D Patch-wise[/class])
% * [DeepMIB] Added Resnet18, Resnet50, Resnet101, Xception networks for the patch-wise mode
% * [DeepMIB] Added alternative arrangement of files for 2D Patch-wise mode where each class is stored in its own directory
% * [DeepMIB] Added "Load models" to the Options tab to skip loading of images when they are already preloaded ([class.code]DeepMIB->Predict->Load models[/class])
% * [DeepMIB] Added possibility to specify frequency of saving checkpoint networks (R2022a or newer), ([class.code]DeepMIB->Train->Save checkpoint networks[/class])
% * [DeepMIB] Added percentage parameter to the overlapping tiles mode ([class.code]DeepMIB->Predict->Overlapping tiles->%%[/class])
% * [DeepMIB] Added possibility to select a single augmentation to preview ([class.code]DeepMIB->Train->Augmentations->Preview[/class])
% * [DeepMIB] Added new 3D augmentations reaching 18 operations ([class.code]DeepMIB->Train->Augmentations->3D[/class])
% * [DeepMIB] Added DeepLabV3-Resnet50 to 2D semantic segmentation (MATLAB MIB only)
% * [DeepMIB] Fixed preview of some patches and contrast stretch in Activation Explorer
%
% [/dtls]
%
%% 2.82 / 12.04.2022 (DeepLabV3, kymographs, key callbacks)
%
% [dtls][smry] *2.82 / 12.04.2022 (DeepLabV3, kymographs, key callbacks)* [/smry]
%
% * Added generation of kymographs to Measure tool
% * Added indexing of objects in a model to generate a new model, where
% each object has own index (Menu->Models->Convert type->Indexed objects)
% * Added main window keypress callbacks to Statistics, Measure tools,
% Image adjustments, Dataset Info, Log, Batch processing, Make movie, Snapshot, Crop, Resample,
% Bounding box, Image filters, Image arithmetics, MorphOps, Image MorphOps, Graphcut,
% Stereology, Object separation, Global black-and-white thresholding, Watershed segmentation,
% Supervoxel classifier, Membrane detection; when these tools are in focus,
% the key shortcuts of the main window are triggered
% * Added reading of pixel size from Zeiss SmartSEM and Atlas TIF files
% * Added automatic extraction of metadata from Zeiss Atlas and SmartSEM TIF files (Menu->Plugins->File processing->Image converter: TIF->XML)
% * Added "Selected files in Directory contents" option into "Load and combine images" option of the Batch processing tool
% * Added 'ndpi' format to the list of BioFormats extensions
% * Added new options for faster placing measurements (Menu->Tools->Measure length->Measure tool)
% * Added Esc key shortcut to stop placing measurements
% * Added Shift+Alt+RMB key shortcut to pan the image
% * Fixed loading of the selected series from a container file using BioFormats
% * Fixed starting of Fiji volume viewer directly from MIB
% * Fixed usage of Shift+LMB operations
% * Fixed of delete operation of a single tree in 3D lines
% * Fixed resize in batch processing mode, when z-value was kept fixed with the percentageXY option
% * Bug fixes
% * [DeepMIB] Added 2D DeepLabV3-Resnet18 architecture for semantic segmentation
% * [DeepMIB] Added selection of the output format as MIB Model or TIF
% * [DeepMIB] Added possibility to return the trained network with the best validation loss (Training settings, required R2021b or newer)
% * [DeepMIB] Added indicator of the iteration with the selected network and rendering of training and validation final loss values that were missing on the progress training plot 
% * [DeepMIB] Fixed probability of generation of an augmented patch
% * [MCcalc] Added calculation of areas and average min thickness for the main objects
% * [MCcalc] Added calculation contacts between objects of the same material
%
% [/dtls]
%
%% 2.81 / 14.10.2021
%
% [dtls][smry] *2.81 / 14.10.2021* [/smry]
%
% * Added contrast adjustment, when 16-bit is converted to 16-bit
% * Added import of annotations from CSV files (Segmentation table->Annotations->Annotation list->Load
% * Added conversion of annotations to the mask layer (Annotations->Annotation list->List of annotations->Convert selected annotations to Mask)
% * Added save of models to mibCat categorical format (Menu->Models->Save model as)
% * Added automatic closing of all windows in Fiji when stopping FijiConnect
% * Added information about "Call4Help" sessions (Menu->Help->Call for help)
% * Fixed a bug with generation of grids in the Stereology tool
% * Fixed automatic feature based alignment, when the Selection is disabled
% * Updated Bio-Formats to 6.7.0
% * [DeepMIB] added counting of labels in model files (Options->Count labels)
% * [DeepMIB] fixed bug with selection of 'Multi GPU' for prediction
%
% [/dtls]
%
%% 2.802 / 01.06.2021
%
% [dtls][smry] *2.802 / 01.06.2021* [/smry]
%
% * Added HDD mode to align datasets that can not be fit into memory (Menu->Dataset->Alignment tool->HDD)
% * Added new preference dialog (Menu->File->Preferences)
% * Added exclusion of Stretch and Shear peaks into the automatic alignment using image features
% * Added re-ordering of annotations in the Annotation list via a popup menu
% * Added precision edit box into the Annotation panel
% * Added "Extra depth to show annotations" (Annotations->Annotation list->Settings)
% * Added saving of models as 2D sequence MIB MATLAB format (Menu->Models->Save model as->MATLAB format 2D sequence (*.model))
% * Added Mode filter (Menu->Image->Image mibfilters...)
% * Added "File and Directory operations" to batch processing
% * Added plugin for converting images between different formats
% (Menu->Plugins->File Processing->ImageConverter)
% * Added <http://mib.helsinki.fi/tutorials_tools.html plugin> detection of contacts in 2D images
% (Menu->Plugins->Organelle analysis->MCcalc)
% * Added shift of color channels in X and Y (Menu->Image->Color channels->Shift channel)
% * Added check for a new version for MIB compiled for Linux 
% * [DeepMIB] Added selection of GPU/CPU/Multi-GPU
% * [DeepMIB] Added GPU Info window (Network panel->?)
% * [DeepMIB] Added possibility for training and prediction without preprocessing
% * [DeepMIB] Added parallel pre-processing
% * [DeepMIB] Added compatibility with models in TIF and PNG formats
% * [DeepMIB] Added masking
% * [DeepMIB] Added 19 2D augmentation operations with individual configuration settings
% * [DeepMIB] Added configurable preview of augmentation patches (Train tab->Augmentation->Preview and ->Settings)
% * [DeepMIB] Added configurable (Options tab->Custom training plot) preview of augmented patches during training
% * [DeepMIB] Added possibility to select various activation layers
% * [DeepMIB] Added Transfer Learning to update models to different number of classes (Prediction tab->Evaluate segmentation)
% * [DeepMIB] Added setting of mini-batch size for prediction
% * [DeepMIB] Added options for export of prediction scores
% * [DeepMIB] Added calculation of occurrence and Sørensen-Dice similarity for comparison of ground truth and generated models
% * [DeepMIB] Added filenames and export to CSV to evaluate segmentation operation
% * [DeepMIB] Added export of trained models to ONNX format (MATLAB version of MIB)
% * Updated reading of NRRD files for MacOS (mibGetImages & mibModel.loadModel, nhdr_*.m nrrd_* files)
% * Updated export statistics to annotations to keep settings during current session
% * Updated Bio-Formats to 6.6.1
% * Updated for MATLAB R2021a
% * Fixed missing the "Add to" checkbox Ctrl+F operation 
% * Fixed loading of AM files on virtual machines due to encoding
% * Fixed preview behavior for image filters in 3D
% * Fixed 3d backup operation when number of 3D dataset == 0
% * Fixed vertical flip of MRC datasets
% * Replaced quantile function with a custom code
% * Bug fixes for interpolation, crop
% * [DeepMIB] Fixed loading of config on various OS
% * [DeepMIB] Updated training progress plot and added configuration parameters
% * [DeepMIB] Improved performance of image preprocessing for AmiraMesh
%
% [/dtls]
%
%% 2.70 / 18.05.2020
%
% [dtls][smry] *2.70 / 18.05.2020* [/smry]
% 
% * Added Deep MIB for training and prediction of datasets using
% deep convolutional networks
% * Added 2D Elastic Distortion filter (Menu->Image->Image Filters)
% * Added resizing of the Image Arithmetics window
% * Added selection of a seed for random generator for Rename and Shuffle
% tool
% * Fixed issues with importing of chopped cropped datasets
%
% [/dtls]
%
%% 2.66 / 25.04.2020
%
% [dtls][smry] *2.66 / 25.04.2020* [/smry]
%
% * Added direct conversion from Mask to Model layer (Segmentation
% panel->Material table->right click->Mask to Material)
% * Added drag-and-drop for opening of *.model files by dragging them from
% elsewhere to the Image View panel
%
% [/dtls]
%
%% 2.651 / 25.04.2020
%
% [dtls][smry] *2.651 / 25.04.2020* [/smry]
%
% * Added smoothing of multiple materials of models via batch processing
% * Fixed definition of the starting point for the Membrane ClickTracker tool
% * Fixed setData method for specific materials of the model
%
% [/dtls]
%
%% 2.65 / 23.03.2020
% 
% [dtls][smry] *2.65 / 23.03.2020* [/smry]
%
% * Added Drag and drop files into the Image View panel 
% * Added dialog with 30 new image filters (Menu->Image->Image filters...)
% * Added dataset alignment using AMST: Align to Median Smoothed Template (Menu->Dataset->Alignment)
% * Added wound healing assay (Menu->Tools->Wound healing assay)
% * Added transformation of Z to C (Menu->Dataset->Transform...)
% * Added additional options to the batch processing: file loop/combine
% files -> current MIB directory; selection/removal of multiple directories in the
% Directrory loops
% * Added backup of the full mibImage class
% * Added full backup for dataset transform, resize, crop operations
% * Added squeezing of material indices for models with more than 255 materials (Segmentation panel->Squeeze button)
% * Added a new key shortcut ('n') to increase index of the active material by 1 for the models with more than 255 materials
% * Added saving snapshots in PNG format
% * Added measurements to restore shuffled datasets
% * Updated resampling for batch processing mode
% * Updated Bio-Formats to 6.4.0 (Requires MATLAB R2017b or newer)
% * Swapped Log and Info buttons in the Path panel
% * Tweaked names of plugins to include spaces between capital letters
% * Optimized handling of Java classes
% * Plugins: Surface Area 3D - a plugin for analysis of 3D surfaces and
% contacts (Menu->Plugins->Organelle analysis->Surface area3D)
% * Plugins: Spacial Control Points to generate a set of random points over the masked area (Menu->Plugins->Plasmodesmata->SpatialControlPoints)
% * Plugins: Cell Wall Thickness to calculate thickness of cell walls (Menu->Plugins->Plasmodesmata->Cell wall thickness)
%
% [/dtls]
%
%% 2.601 / 04.11.2019
%
% [dtls][smry] *2.601 / 04.11.2019* [/smry]
%
% * The deployed version of MIB comes with R2019b instead of R2017a
% * Added the Batch mode for repetitive processing of images (Menu->File->Batch processing)
% * Added visualization of models using MATLAB Volume Viewer app (Menu->Models->Render model->MATLAB volume viewer, R2019 or newer, MATLAB version only)
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
% * Updated Bio-Formats to 6.2.1 (Requires MATLAB R2017b or newer)
% * [2.601] Bug fixes
% * [2.601] Added export of annotations to CSV format
%
% [/dtls]
%
%% 2.51 / 13.03.2019
%
% [dtls][smry] *2.51 / 13.03.2019* [/smry]
%
% * Added methods for automatic global black-and-white thresholding (|Menu->Tools->Semi-automatic segmentation->Global thresholding|)
% * Added selection of materials for rendering of MATLAB Isosurface models (|Menu->Models->Render model->MATLAB isosurface|)
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
% [/dtls]
%
%% 2.501 / 21.12.2018
%
% [dtls][smry] *2.501 / 21.12.2018* [/smry]
%
% * Added swap slices option (Menu->Dataset->Slice->Swap slices)
% * Fixed rendering of combined image in the split color channel mode with Lut enabled in Snapshot and Make movie tools
% * Fixed Copy Slice for the Insert mode
%
% [/dtls]
%
%% 2.50 / 17.12.2018
%
% [dtls][smry] *2.50 / 17.12.2018* [/smry]
%
% * Added hardware accelerated 3D volume rendering (Menu->File->Render
% volume->MIB rendering). The volume rendering can be used also for making
% snapshots and animations. Requires MATLAB R2018b or newer!
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
% [/dtls]
%
%% 2.40 / 31.08.2018
%
% [dtls][smry] *2.40 / 31.08.2018* [/smry]
%
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
% [/dtls]
%
%% 2.302 / 18.05.2018 (03.07.2018)
%
% [dtls][smry] *2.302 / 18.05.2018 (03.07.2018)* [/smry]
%
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
% objects: |Menu->Selection->Morphological 2D/3D operations|, (_only for MATLAB R2018a and newer_)
% * Added export of volumes and models for rendering to MATLAB VolumeViewer
% application (|Menu->File->Render volume->MATLAB volume viewer| or |Menu->Models->Render model->MATLAB volume viewer|, (_only the MATLAB version of MIB, requires MATLAB R2017a and newer_)
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
% [/dtls]
%
%% 2.22 / 16.03.2018
%
% [dtls][smry] *2.22 / 16.03.2018* [/smry]
%
% * Added value field for the annotations, thus each annotation can be weighted based on its value
% * Added possibility to do deep neural network denoising on GPUs with
% small memory, use the |GPU block| parameter in |Image filters->DNN Denoise|
% * Added the Simplify button to the Dataset Info window to allow remove most of metadata
% * Added rendering with Imaris models generated in MATLAB
% (|Menu->Models->Render model->MATLAB isosurface and export to Imaris|),
% require Imaris 8.
% * Added rendering snapshots with white background (|Toolbar->Snapshot tool->white Bg|)
% * Added rendering of annotations as scaled spots in Imaris
% * Added Get Statistics for models with more than 255 materials
% * Added calculation of Min/Max/Mean/Median intensity projection (Menu->Image->Tools for images->Intensity projection...)
% * Added use of external BMxD filters [MATLAB version only!] (Image filters panel->External: BMxD)
% * Added Add Frame tool that can be used to generate a frame around
% dataset with a distinct color or using various repetition methods (Menu->Dataset->Transform->Add frame)
% * Added renaming of annotations (|Menu->Models->Annotations->Annotation list->RMB over the list of selected annotations->Rename selected annotations...|)
% * Improved movie rendering performance for the ROI mode
% * Updated the Image Filter panel
% * Fix of error when opening Images->MorphOps->Morph Closing
% * Fix callback when selecting color channels in the Selection panel
% * Fix of opening of AmiraMesh files with extended headers
%
% [/dtls]
%
%% 2.211 / 21.12.2017
%
% [dtls][smry] *2.211 / 21.12.2017* [/smry]
%
% * Updated TripleAreaIntensity plugin
% * Fix, the |contains| function replaced with ismember for compatibility with MATLAB 2014b-2016a
% * Fix of lost key press callbacks after modification of the segmentation table
% * Fix of loading hdf5 datasets with time dimension
% * Few other minor bug fixes
% 
% [/dtls]
%
%% 2.21 / 04.12.2017
%
% [dtls][smry] *2.21 / 04.12.2017* [/smry]
%
% * Added model with 4294967295 materials for tests
% * Improved object picker for models with 65535 materials
% * Fix compiling of certain function using the |-compatibleArrayDims| switch to be compatible with the new MATLAB API
% * Fix of 'Fix selection to material' switch for models with more than 255 materials
% * Fix connection to Omero for the deployed version
%
% [/dtls]
%
%% 2.20 / 14.11.2017
%
% [dtls][smry] *2.20 / 14.11.2017* [/smry]
%
% * Added a new 3D Grid mode to the Graphcut tool; when used the fast interactive performance can be achieved even with very large datasets
% * Added denoise of image using deep neural network (|Image Filters
% Panel->Filter->DNN Denoise|), requires MATLAB R2017b or newer and Neural Network Toolbox
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
% * Fixed recalculation of voxels after import of images from MATLAB
% * Fixed resampling of a single slice RGB images
% * Fixed incorrect reading of the AmiraMesh header for the fuse mode of the Chop tool
% * [Programming] moved mibController.connImaris to mibModel.connImaris
% * [Programming] updated syntax of mibImage.clearMask
%
% [/dtls]
%
%% 2.12 / 18.09.2017
%
% [dtls][smry] *2.12 / 18.09.2017* [/smry]
%
% * Added a new tool to detect a frame around images (Menu->Image->Tools
% for images->Select image frame...)
% * Added the auto-update mode for the graphcut segmentation
% * Added possibility to count annotations in the |List of annotations|
% window: Segmentation panel->Annotations->Annotation list->Right mouse
% click over the table with annotations
% * Added export of selected annotations to Amira as landmark points or to
% MATLAB: Segmentation panel->Annotations->Annotation list->Right mouse
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
% [/dtls]
%
%% 2.10 / 01.06.2017
%
% [dtls][smry] *2.10 / 01.06.2017* [/smry]
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
% * Added possibility to save models for MIB version 1 (File->Models->Save model as...->MATLAB format for MIB ver. 1 (*.mat))
% * Modified use of Ctrl+C/Ctrl+V, now the stored dataset can be pasted to
% any other dataset in MIB assuming that the dataset have the same
% width/height. As result |storedSelection| property of |mibImage| class has been
% moved to |mibModel| class
% * Fixed export of models and masks to another MIB dataset for the compiled version
% * Fixed singleton running of MIB, now it is possible to have several
% instances of MIB run in parallel
%
% [/dtls]
%
%% 2.01 / 11.04.2017
%
% [dtls][smry] *2.01 / 11.04.2017* [/smry]
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
% [/dtls]
%
%% 2.00 / 20.03.2017 Official Release, 2.002 (02.04.2017)
%
% [dtls][smry] *2.00 / 20.03.2017 Official Release, 2.002 (02.04.2017)* [/smry]
%
% * With release 2.0 MIB has been rewritten to utilize Controller-View-Model
% architecture, which brings stability and ease of future development.
% However, because of that, the system requirements for MATLAB were increased
% and MIB2 is only available for MATLAB R2014b and older 
% (due to continuous development of MATLAB, the most recent release is always recommended)
% * Added "Copy to clipboard" and "Open directory in the file explorer" for the right mouse button
% click over the current path edit box of the path panel (ver. 2.002)
% * Added adaptive black and white thresholding
% * Many other improvements
% * Added offset shift for the rechop mode (ver. 2.001)
% * Renamed Area to Volume for the Get Statistics tool for 3D objects (ver. 2.002)
% * Big fixes (ver. 2.001, 2.002)
%
% [/dtls]
%
% *Back to* <im_browser_product_page.html *Index*>
%
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