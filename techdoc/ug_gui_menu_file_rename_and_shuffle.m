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
% [dtls][smry] *Prerequisites* [/smry]
% 
% * Files taken at each condition should be placed to a separate folder
% * Images in each folder should have the same width/height
% * It is recommended that each file has only a single image, _i.e._ no
% stacking
% * [MODELS/MASKS/ANNOTATIONS] when shuffling also models, masks, annotation only a single model/mask/annotation file per directory is allowed
% * [MODELS] all model files should contain same materials
% 
% [/dtls]
%
% To start the process, copy images that belong to different conditions into
% separate directories. For example, place images taken for the control condition to the |Control| folder.
% Create a new folder and copy there images that belong to the corresponsing treatment. 
% There are may be multiple conditions processed at the same
% time. The only requirement is to have separate conditions in its own directory. 
% 
% [dtls][smry] *Description of widgets and parameters* [/smry]
% 
% * [class.kbd]Add folder...[/class], use this button to populate the list of input
% directories containing images taken under different conditions
% * [class.kbd]Remove folder...[/class], remove selected directory from the input list
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
% * *Include measurements*, same as above but for measurements. *Note!* It
% is important that each folder contains only a single file in the
% _*.measure_ format
% * *Random seed*, a positive number defining a seed for random number
% generator; the files will be sorted in the same way when the random seed
% value stays unchanged
% * *Filename extension*, provide extension for filenames with images
% * *Filename templalte*, define filename template for the shuffled images
% * *Output directory*, define the output directory
% * *Number of output sub-directories*, specify to how many output
% directories the images should be shuffled. Each subdirectory will be
% named as |Subset_001|, |Subset_002|, |Subset_003|, _etc_ and placed under
% the output directory
% * [class.kbd]Rename and shuffle[/class] press to start shuffling of the files
%
% [/dtls]
%
%% Restore...
% Restore the shuffled models and masks such that they correspond to the
% original image files
%
%
% <<images\menuFileRandomizeRestoreDlg.png>>
% 
% [dtls][smry] *Prerequisites* [/smry]
% 
% * Images in each folder should have the same width/height
% * [MODELS/MASKS/ANNOTATIONS] only a single model/mask/annotation file per directory is allowed
%
% [/dtls]
%
% To start the process it is required to select the project file by
% pressing the [class.kbd]...[/class] button and selection a project file that was stored
% under the directory, where the images were originally shuffled. The
% project file has |*.mibShuffle| extension.
%
% Upon the loading of the project file the |Directory with shuffled
% images| and |Destination directories| list boxes are populated. It is
% possible to use the right mouse button to start a popup menu to modify
% the directories, copy directory name to the system clipboard or to open
% the directory in file explorer.
%
% The updated project with the new directory names can be saved to a disk
% using the [class.kbd]Save[/class] button.
% 
%
% When the masks or annotation are also present in the directories with the shuffled
% image files, they can also be restored to the destination directories.
%
% Press the [class.kbd]Restore shuffled[/class] button to start the process. As result, 
% new '_Labels_RestoreRand_YYMMDD.model_' and
% '_Mask_RestoreRand_YYMMDD.mask_' files will be created at each of the
% descination directories. The 'YYMMDD' string denotes a date when the
% restore procedure is done.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>
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