%% Chopped images...
% This mode allows to chop a large dataset to smaller pieces and restore
% them back. This feature may be useful when needed to parallel
% segmentation of the large dataset to several workstations.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>
%
%%
% 
% <<images\menuFileChopmode.jpg>>
% 
%% Export...
% The export command chops the large dataset into smaller pieces. 
%
% 
% <<images\menuFileChopExport.png>>
% 
%%
% 
% * *Number of tiles in X/Y/Z*, define number of resulting datasets. For example, when
% _number of tiles in X: 2, in Y: 1 and in Z: 1_ the original dataset will be chopped in two
% smaller datasets. The first dataset will have dimensions [1: _width_ /2] and
% the second [ _width_ /2: _width_], where _width_ is the width of the
% original dataset
% * *Chop model*, when model is present it can also be chopped into
% corresponding blocks, if this checkbox is selected
% * *Chop mask*, when the Mask layer is present it can also be chopped into
% corresponding blocks, if this checkbox is selected 
% * *Output directory* use this button or the editbox to define directory
% where the chopped datasets should be saved
% * *Filename template*, defines a template for saving the chopped datasets.
% During the saving MIB will add "_Znn_Xnn_Ynn" tag to each block, where _nn_ is the index of the block.
% * *Output format for images*, datasets can be saved in Amira Mesh, NRRD, 
% 3D-TIF formats, or HDF5 with XML header formats. 
% * *Output format for models*, models can also be stored in several formats: Matlab, AmiraMesh, NRRD, TIF or HDF5. 
% When the models are saved a "Labels_" prefix is added to the beginning of the filename.
%
% The masks saved in the Matlab format with |Mask_[FN].mask| template, where [FN] is a filename of the corresponding image dataset.
%
%% Import...
% The import command restores previously chopped or cropped datasets.
%
% 
% <<images\menuFileChopImport.png>>
% 
% There are two modes available: 
%%
% 
% * *Generate new stack*, generates a new stack (for images), or imports
% models or masks for the opened datasets. When using this mode it is
% important to have proper filenames. The images should have the
% "_Znn_Xnn_Ynn" tag at the end of the filename; the models should have the "Labels_" prefix (see the _Export_ section
% for details). This is default mode for combining files that were chopped
% using the Menu->File->Chopped images...->Export... command
% * *Fuse into existing*, uses the BoundingBox information that is normally
% stored in the ImageDescription field to fuse the selected datasets into
% the opened dataset. This mode can be used to import previously cropped
% datasets and models. Three additional edit boxes (offset X, Y, Z) allows
% to specify an additional offset in pixels for each dimension.
%
% To proceed please choose the mode and types of the files to combine.
% After that press the |Select files| button to choose the files. The
% filenames for the models and masks are automatically generated from the
% filenames of the selected images:
%
%%
% 
% * *Filename of the selected image:* |Huh7_CmVTag1_R2_Pos5_crop_chop_Z01-X01-Y01.am|
% * *Generated filename of the model:* |Labels_Huh7_CmVTag1_R2_Pos5_crop_chop_Z01-X01-Y01.model|
% * *Generated filename of the mask:* |Mask_Huh7_CmVTag1_R2_Pos5_crop_chop_Z01-X01-Y01.mask|
% 
% *Important!* If the |Images| checkbox is selected please select only
% files with images and do not select models nor mask files. The filenames
% for models and masks will be automatically generated. However, if models
% or masks are combined for the opened dataset (_i.e._ the |Images|
% checkbox is unselected) the actual model or mask filenames have to be
% selected.
% 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>