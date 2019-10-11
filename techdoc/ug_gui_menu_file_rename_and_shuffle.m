%% Rename and shuffle (randomize files)...
% Two tools placed under this menu entry allow to shuffle files for their
% blind modeling, when the user does not know which file belong to which
% condition. The models from the shuffled files can be converted back over
% the original filenames for analysis.
%
% <html>
% A demonstration is available in the following video:<br>
% <a href="https://youtu.be/be3p7FZc-X8"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/be3p7FZc-X8</a>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>
%
%%
% 
% <<images\menuFileRandomize.png>>
%
% <<images\Rename_and_Shuffle.jpg>>
% 
%% Rename and shuffle...
% Rename and shuffle files in the input directories to number of output directories
%
% 
% <<images\menuFileRandomizeDlg.png>>
% 
% *Requirements*
% 
% * Files taken at each condition should be placed to a separate folder
% * Images in each folder should have the same width/height
% * It is recommended that each file has only a single image, _i.e._ no
% stacking
% * [MODELS/MASKS/ANNOTATIONS] when shuffling also models, masks, annotation only a single model/mask/annotation file per directory is allowed
% * [MODELS] all model files should contain same materials
% * 
% 
%
% To start the process, copy images that belong to different conditions into
% separate directories. For example, place images taken for the control condition to the |Control| folder.
% Create a new folder and copy there images that belong to the corresponsing treatment. 
% There are may be multiple conditions processed at the same
% time. The only requirement is to have separate conditions in its own directory. 
% 
% 
% * *Add directory...*, use this button to populate the list of input
% directories containing images taken under different conditions
% * *Remove directory...*, remove selected directory from the input list
% * *Include model*, when model is already present for the input images, it
% can also be randomized according to the shuffled image files. *Note!* It
% is important that each folder contains only a single file in the
% _*.model_ format
% * *Include mask*, same as above but for masks. *Note!* It
% is important that each folder contains only a single file in the
% _*.mask_ format
% * *Include annotations*, same as above but for annotations. *Note!* It
% is important that each folder contains only a single file in the
% _*.ann_ format
% * *Filename extension*, provide extension for filenames with images
% * *Filename templalte*, define filename template for the shuffled images
% * *Output directory*, define the output directory
% * *Number of output sub-directories*, specify to how many output
% directories the images should be shuffled. Each subdirectory will be
% named as |Subset_001|, |Subset_002|, |Subset_003|, _etc_ and placed under
% the output directory
% * *Rename and shuffle* press to start shuffling of the files
%
%
%% Restore...
% Restore the shuffled models and masks such that they correspond to the
% original image files
%
%
% <<images\menuFileRandomizeRestoreDlg.png>>
% 
% *Requirements*
% 
% * Images in each folder should have the same width/height
% * [MODELS/MASKS/ANNOTATIONS] only a single model/mask/annotation file per directory is allowed
% 
%
% To start the process it is required to select the project file by
% pressing the '...' button and selection a project file that was stored
% under the directory, where the images were originally shuffled. The
% project file has |*.mibShuffle| extension.
%
% Upon the loading of the project file the |Directory with shuffled
% images| and |Destination directories| list boxes are populated. It is
% possible to use the right mouse button to start a popup menu to modify
% the directory names. 
%
% 
% When the masks or annotation are also present in the directories with the shuffled
% image files, they can also be restored to the destination directories.
%
% Press the *Restore shuffled* button to start the process. As result, 
% new '_Labels_RestoreRand_YYMMDD.model_' and
% '_Mask_RestoreRand_YYMMDD.mask_' files will be created at each of the
% descination directories. The 'YYMMDD' string denotes a date when the
% restore procedure is done.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>