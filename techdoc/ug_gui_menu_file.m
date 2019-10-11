%% File Menu
% Provides access to some file handling actions for image dataset
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
%%
% 
% <<images\menuFile.png>>
% 
%% Import image from...
% 
% 
% * *Matlab*  - import image from the main Matlab workspace into |im_browser|. It is possible to
% provide image description containers.Map together with the dataset, which
% allows to maintain parameters of the dataset when using the |Export
% image| command (see below). <https://youtu.be/zUJ1RUuTLVs [*brief demo*]>
% * *Clipboard* - paste image from the system clipboard. This functionality
% is implemented using <http://www.mathworks.com/matlabcentral/fileexchange/28708-imclipboard *IMCLIPBOARD*> function
% by  Jiro Doke, MathWorks, 2010. <https://youtu.be/kcN0Na_YC_U [*brief demo*]>
% * *Imaris* - import dataset from Imaris; requires <http://www.bitplane.com/ Imaris and ImarisXT>.
% This functionality is done with
% <http://www.scs2.net/next/index.php?id=110 IceImarisConnector> written
% by Aaron C. Ponti, ETH Zurich.
% <https://youtu.be/MbK2JcTrZFw?list=PLGkFvW985wz8cj8CWmXOFkXpvoX_HwXzj
% [*demo*]>
% * *URL* - open image from provided URL address. The link should contain
% the protocol type (_e.g._, http://). <https://youtu.be/FNEVgKzbGqQ
% [*brief demo*]>
% 
% 
%% OMERO Import
% Establish connection and load images from OMERO server. Requires <http://www.openmicroscopy.org/site OMERO server> files to
% be downloaded. Please refer to the <im_browser_system_requirements.html System Requirements> pages for details of installation.
%
% Selection of a server (_please do not copy/paste the password!_):
%
% <<images\menuFileImportOmero1.png>>
% 
% In the following dialog it is possible to select desired dataset and the range to take 
%
% <<images\menuFileImportOmero2.png>>
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/iR7OL0eJGuw"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/iR7OL0eJGuw</a>
% </html>
%
%% Batch processing...
% With the batch processing mode many of the image processing operations
% may be designed into an image processing workflow, which may
% automatically applied to multiple images. 
%
% Please refer to the <ug_gui_menu_file_batch.html Batch processing...> section for details.
%
%
%% Chopped images...
% This is a special mode that allows to split a large dataset into defined
% number of smaller ones and combine them back later. It is also possible
% to fuse the previously cropped dataset to the bigger one.
%
% Please refer to the <ug_gui_menu_file_chop.html Chopped images...> section for details.
%
%% Rename and shuffle
% Two tools placed under this menu entry allow to shuffle files for their
% blind modeling, when the user does not know which file belong to which
% condition. The models from the shuffled files can be converted back over
% the original filenames for analysis.
%
% Please refer to the <ug_gui_menu_file_rename_and_shuffle.html Rename and shuffle> section for details.
%
%% Export image to 
% Export images to the main Matlab workspace or Imaris.
%
% <html>
% <b>- Matlab</b><br>
% In addition to the image
% variable, another variable with parameters of the dataset (containers.Map class) is
% automatically created. This |containers.Map| can be imported back to |MIB| later together 
% with the modified dataset to restore parameters of the dataset.<br><br>
% A brief demonstration on Import/Export is available in the following video:<br>
% <a href="https://youtu.be/zUJ1RUuTLVs"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/zUJ1RUuTLVs</a>
% <br><br>
% <b>- Imaris</b><br>
% When Imaris is installed, the images can also be exported to Imaris. 
% </html>
%
%% Save image as
% Save the open dataset to a disk. The following image formats are implemented:
% 
% * *AM, Amira Mesh* - as Amira Mesh binary format
% * *JPEG, Joint Photographic Experts Group* - a method for saving lossy compressed RGB datasets
% * *HDF5, Hierarchical Data Format* - saves images in the Hierarchical Data Format, version 5
% * *MRC, MRC format for IMOD* - saves images in the MRC Format compatible with IMOD
% * *NRRD, Nearly Raw Raster Data* - a data format compatible with <www.slicer.org 3D slicer>
% * *PNG, Portable Network Graphics (*.png)* - saves images in the Portable Network Graphics format
% * *TIF format, LZW compressed*, as a multilayered tif-file (|3D-Tif option|) or as a sequence of tif-files
% (|Sequence of 2D files|). *Please note!* the TIF format uses 32-bit offsets, and
% that, in practice, limits the maximal size of the TIF-files to 2Gb. Matlab
% can create TIF files larger than 2Gb but those can't be opened later
% * *TIF format, non-compressed*, see above for details of saving datasets in the TIF format
%
%% Make movie
% Save dataset as a movie file. All objects that are shown in the image view window will be captured. *Note!* If the image width is too small the scale bar is not rendered.
% <ug_gui_menu_file_makevideo.html See more here>. 
% 
% <<images\menuFileMakeMovie.png>>
% 
%% Make snapshot
% Make snapshot of the current slice. All objects that are shown in the image view window will be captured.  <ug_gui_menu_file_makesnapshot.html See more here>.
%%
% 
% <<images/menuFileSnapshot.png>>
% 
%% Render volume
% 3D visualization of volumes is available using 3 different ways:
%
% <html><h3 style="color:#d45600;">MIB rendering</h3></html>
%
%
% Starting from MIB (version 2.5) and Matlab R2018b the volumes can be
% directly visualized in MIB using hardware accelerated volume rendering
% engine. The datasets for visuzalization can be downsampled during the
% export. It is possible to make snapshots and animations.
% 
% Limitations:
% 
% * One volume at the time
% * Only grayscaled 3D data, i.e. a single color channel
% * Scale bar is not yet available
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/4CrfdOiZebk"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/J70V33f7bas</a>
% </html>
%
% <html><h3 style="color:#d45600;">Matlab Volume Viewer</h3></html>
%
%
% When MIB is used with Matlab R2017a or newer it is possible to export the
% open dataset to Volume Viewer application. Please note that this feature
% is not available for the compliled version of MIB
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/J70V33f7bas"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/J70V33f7bas</a>
% </html>
% 
%
% <html><h3 style="color:#d45600;">Fiji 3D viewer</h3></html>
%
% Please refer to details in the 
% <im_browser_system_requirements.html Microscopy Image Browser System Requirements Fiji> section for installation of Fiji.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/DZ1Tj3Fh2HM"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/DZ1Tj3Fh2HM</a>
% </html>
%
% Additional dialog prompts for extra parameters for rendering:
%%
% 
% <<images/menuFileRenderFiji.png>>
% 
%%
% 
% * *Reduce the volume down to, max width pixels* - allows to reduce size of the dataset prior the rendering. This
% reduces memory consumption and improves performance. When this field
% contains *0* no volume resizing occurs.
% * *Smoothing 3d kernel, width* - smooth the volume
% with gaussian blur. No smoothing when 0.
% * *Invert? [0-no, 1-yes]* - invert the dataset, required for electron
% microscopy images.
% * *Transparency threshold* - all pixels with intensities below the
% provided value will appear transparent. Comma-separated numbers may
% be used here to provide specific transparency parameters for each color
% channel. In addition, the transparency threshold can also be tweaked in 
% the Fiji 3D viewer window: |3D Viewer->Edit->Attributes->Adjust threshold|. 
%
%
%% Preferences
% View and edit preferences of Microscopy Image Browser. Allows to modify colors of the |Selection|, |Model| and |Mask|
% layers, default behaviour of the mouse wheel and keys, settings of Undo.
% <ug_gui_menu_file_preferences.html *See more...*>
%
% *Please note*, |MIB| stores its configuration parameters in a file that is automatically generated after closing of
% |MIB|:
%
% * *for Windows* - _C:\Users\Username\Matlab\mib.mat_ or in the Windows TEMP directory (_C:\Users\User-name\AppData\Local\Temp\_). 
% The TEMP directory can be found and accessed with |Windows->Start button->%TEMP%| command
% * *for Linux* - _/home/username/Matlab_ or local TEMP directory
% * *for MacOS* - _/Users/username/Matlab_ or local TEMP directory
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>

