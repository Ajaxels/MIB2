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
% * *MATLAB*  - import image from the main MATLAB workspace into |MIB|. It is possible to
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

%% Example datasets
% This menu entry provides quick access to several MIB demo datasets and
% full projects for image segmentation using deep learning. The datasets
% are grouped by techniques used for data collection. 
%
% [dtls][smry] *DeepMIB projects->Synthetic 2D large spots* [/smry]
% 
% <html>
% A complete DeepMIB project with a synthetic dataset generated for quick tests of semantic
% segmentation approaches.<br>
% The dataset includes a trained DeepLabV3-Resnet18 network for detection
% of large spots on a black background. The network can be opened by loading
% "2D_LargeSpots_2cl_DeepLabV3.mibCfg" file via<br>
% <span class="code">Menu->Tools->Deep learning segmentation->Options tab->Config files->Load</span>
% <br>
% <table><tr>
%   <td><img src = "images\examplesDeepMIB_large_spots_tree.png"></td>
%   <td><img src = "images\examplesDeepMIB_large_spots.png"></td>
% </tr></table>
% <br>
% <b>Reference:</b><br>
% <a href="https://doi.org/10.5281/zenodo.10203188"><img src="images\zenodo.10203188.svg" alt="https://doi.org/10.5281/zenodo.10203188"></a>
% </html>
%
% [/dtls]
%
% [dtls][smry] *DeepMIB projects->Synthetic 2D small spots* [/smry]
%
% <html>
% A complete DeepMIB project with a synthetic dataset generated for quick tests of semantic
% segmentation approaches.<br>
% The dataset includes a trained U-net network for detection
% of small random spots of 2 colors on a black background. The network can be opened by loading
% "2D_SmallSpots_3cl_Unet.mibCfg" file via<br>
% <span class="code">Menu->Tools->Deep learning segmentation->Options tab->Config files->Load</span>
% <br>
% <table><tr>
%   <td><img src = "images\examplesDeepMIB_small_spots_tree.png"></td>
%   <td><img src = "images\examplesDeepMIB_small_spots.png"></td>
% </tr></table>
% <br>
% <b>Reference:</b><br>
% <a href="https://doi.org/10.5281/zenodo.10203764"><img src="images\zenodo.10203764.svg" alt="https://doi.org/10.5281/zenodo.10203764"></a>
% </html>
%
% [/dtls]
%
% [dtls][smry] *DeepMIB projects->Synthetic 2.5D large spots* [/smry]
% 
% <html>
% A complete DeepMIB project with a synthetic dataset generated for quick tests of 2.5D depth-to-color semantic
% segmentation approaches<br>
% The dataset includes a trained 2.5D DeepLabV3-Resnet18 and 2.5D U-net networks, where the 5-slice subvolumes 
% were used for segmentation of large 3D spots on a black background. In
% addition, there are 2D spots that should not be segmented.<br><br>
% The trained networks are<br>
% <ul>
% <li><b>Spots_25D_DLv3RN18_Z2C_xy200z5</b> - DeepLabV3-based
% 2.5D Depth-to-Color network with patches of 200x200x5</li>
% <li><b>Spots_25D_Unet_Z2C_xy200z5</b> - U-net-based
% 2.5D Depth-to-Color network with patches of 200x200x5</li>
% </ul>
% The networks can be loaded by opening their config files by
% <ul>
% <li><span class="code">Menu->Tools->Deep learning segmentation->Options
% tab->Config files->Load</span></li>
% <li>Drag and drop of the config file into DeepMIB window</li>
% </ul>
% <br>
% <table><tr>
%   <td><img src = "images\examplesDeepMIB_25D_large_spots_tree.png"></td>
%   <td><img src = "images\examplesDeepMIB_25D_large_spots.png"></td>
% </tr></table>
% <br>
% <b>Reference:</b><br>
% <a href="https://doi.org/10.5281/zenodo.10212417"><img src="images\zenodo.10212417.svg" alt="https://doi.org/10.5281/zenodo.10212417"></a>
% </html>
%
% [/dtls]
%
% [dtls][smry] *DeepMIB projects->Synthetic 2D patch-wise* [/smry]
%
% <html>
% A complete DeepMIB project with a synthetic dataset generated for quick tests of the patch-wise segmentation approaches<br>
% The dataset includes a trained Resnet18 network for detection of patches that
% belong to large white spots on black background.<br>
% The network can be opened by loading
% "2D_LargeSpots_Patchwise_Resnet18.mibCfg" file via<br>
% <span class="code">Menu->Tools->Deep learning segmentation->Options tab->Config files->Load</span>
% <br>
% <table><tr>
%   <td><img src = "images\examplesDeepMIB_patchwise_tree.png"></td>
%   <td><img src = "images\examplesDeepMIB_patchwise.png"></td>
% </tr></table>
% <br>
% <b>Reference:</b><br>
% <a href="https://doi.org/10.5281/zenodo.10203861"><img src="images\zenodo.10203861.svg" alt="https://doi.org/10.5281/zenodo.10203861"></a>
% </html>
%
% [/dtls]
%
% [dtls][smry] *DeepMIB projects->2D EM membranes* [/smry]
%
% <html>
% A complete DeepMIB project with a segmentation of membranes from serial-section TEM images<br>
% The dataset includes a trained U-net and DeepLabV3-Resnet18 networks for
% semantic segmentation. This is an updated project that has been published
% with the DeepMIB paper: <a href="https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1008374">DeepMIB: User-friendly and open-source
% software for training of deep learning network for biological image
% segmentation</a>, Figure 1a. Check readme.txt file for details.<br>
% The network can be opened by loading
% "2D_EM_membranes_Unet.mibCfg" or "2D_EM_membranes_DLabRN18.mibCfg" file via<br>
% <span class="code">Menu->Tools->Deep learning segmentation->Options tab->Config files->Load</span>
% <br><br>
% <table><tr>
%   <td><img src = "images\examplesDeepMIB_2DEM_tree.png"></td>
%   <td><img src = "images\examplesDeepMIB_2DEM.jpg"></td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [dtls][smry] *DeepMIB projects->2D LM nuclei* [/smry]
%
% <html>
% A complete DeepMIB project with a segmentation of nuclei, their boundaries and touching edges<br>
% The dataset includes a trained U-net network for semantic segmentation. This is an updated project that has been published
% with the DeepMIB paper: <a href="https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1008374">DeepMIB: User-friendly and open-source
% software for training of deep learning network for biological image
% segmentation</a>, Figure 1b. Check readme.txt file for details.<br>
% The network can be opened by loading
% "valid_252px_32patches_50ep.mibCfg" file via<br>
% <span class="code">Menu->Tools->Deep learning segmentation->Options tab->Config files->Load</span>
% <br><br>
% <table><tr>
%   <td><img src = "images\examplesDeepMIB_2DLM_tree.png"></td>
%   <td><img src = "images\examplesDeepMIB_2DLM.jpg"></td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [dtls][smry] *DeepMIB projects->3D EM mitochondria* [/smry]
%
% <html>
% A complete DeepMIB project with a segmentation of mitochondria<br>
% The dataset includes a trained 3D U-net network for semantic segmentation. This is an updated project that has been published
% with the DeepMIB paper: <a href="https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1008374">DeepMIB: User-friendly and open-source
% software for training of deep learning network for biological image
% segmentation</a>, Figure 1c. Check readme.txt file for details.<br>
% The network can be opened by loading
% "NoValidation_valid_Aug_128px_256pat.mibCfg" file via<br>
% <span class="code">Menu->Tools->Deep learning segmentation->Options tab->Config files->Load</span>
% <br><br>
% <table><tr>
%   <td><img src = "images\examplesDeepMIB_3DEM_tree.png"></td>
%   <td><img src = "images\examplesDeepMIB_3DEM.jpg"></td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [dtls][smry] *DeepMIB projects->3D LM inner hair cells* [/smry]
%
% <html>
% A complete DeepMIB project with a segmentation of inner hear cells, nuclei and synapses<br>
% The dataset includes a trained 3D anisotropic U-net network for semantic segmentation. This is an updated project that has been published
% with the DeepMIB paper: <a href="https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1008374">DeepMIB: User-friendly and open-source
% software for training of deep learning network for biological image
% segmentation</a>, Figure 1d. Check readme.txt file for details.<br>
% The network can be opened by loading
% "InnerEar3D_Hybrid_Same_136x64px_120ep.mibCfg" file via<br>
% <span class="code">Menu->Tools->Deep learning segmentation->Options tab->Config files->Load</span>
% <br><br>
% <table><tr>
%   <td><img src = "images\examplesDeepMIB_3DLM_tree.png"></td>
%   <td><img src = "images\examplesDeepMIB_3DLM.jpg"></td>
% </tr></table>
% </html>
%
% [/dtls]
%
% [dtls][smry] *LM->3D SIM ER* [/smry]
%
% <html>
% A 3D super-resolution structured illumination light microscopy dataset of endoplasmic
% reticulum
% <br>
% <img src = "images\examplesLM_3D_SIM.jpg">
% </html>
%
% [/dtls]
%
% [dtls][smry] *LM->3D STED* [/smry]
%
% <html>
% A 3D super-resolution Stimulated emission depletion (STED) microscopy dataset
% <br><br>
% <img src = "images\examplesLM_3D_STED.jpg">
% </html>
%
% [/dtls]
%
% [dtls][smry] *LM->WF ER photobleaching* [/smry]
%
% <html>
% A wide-field time-lapse imaging of endoplasmic reticulum with visible
% photo-bleaching effect
% <br><br>
% <img src = "images\examplesLM_WF_photobleaching.jpg">
% </html>
%
% [/dtls]
%
% [dtls][smry] *SBEM->Huh-7 and model* [/smry]
%
% <html>
% A small fragment of serial block face scanning electron microscopy
% dataset featuring a Huh-7 cell and a model of nuclei, endoplasmic
% reticulum, mitochondria and lipid droplets.
% <br><br>
% <img src = "images\examplesSBEM_Huh7.jpg">
% </html>
%
% [/dtls]
%
% [dtls][smry] *SBEM->Trypanosoma and model* [/smry]
%
% <html>
% A fragment of serial block face scanning electron microscopy
% dataset featuring a cell of Trypanosoma brucei and a model of nuclei, endoplasmic
% reticulum, mitochondria, vesicles, lipid droplets and cytoplasm.
% <br>
% <img src = "images\examplesSBEM_trypanosoma.jpg">
% </html>
%
% [/dtls]
%
% [dtls][smry] *MRI->MATLAB Brain and model* [/smry]
%
% <html>
% One of test brain datasets from MATLAB taken with magnetic resonance
% imaging (MRI) and a model of tumor. This dataset is only available in MIB
% for MATLAB.
% <br><br>
% <img src = "images\examplesMRI_brain.jpg">
% </html>
%
% [/dtls]
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
% Export images to the main MATLAB workspace or Imaris.
%
% <html>
% <b>- MATLAB</b><br>
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
% Save the open dataset to a disk. 
% 
% [dtls][smry] *The following image formats are implemented* [/smry]
%
% * *AM, Amira Mesh* - as Amira Mesh binary format
% * *JPEG, Joint Photographic Experts Group* - a method for saving lossy compressed RGB datasets
% * *HDF5, Hierarchical Data Format* - saves images in the Hierarchical Data Format, version 5
% * *MRC, MRC format for IMOD* - saves images in the MRC Format compatible with IMOD
% * *NRRD, Nearly Raw Raster Data* - a data format compatible with <www.slicer.org 3D slicer>
% * *OME-TIFF 5D (*.ome.tiff)* - use BioFormats libraty to save the dataset as a 5D stack using OME-TIFF format 
% * *PNG, Portable Network Graphics (*.png)* - saves images in the Portable Network Graphics format
% * *TIF format, LZW compressed*, as a multilayered tif-file (|3D-Tif option|) or as a sequence of tif-files
% (|Sequence of 2D files|). *Please note!* the TIF format uses 32-bit offsets, and
% that, in practice, limits the maximal size of the TIF-files to 2Gb. MATLAB
% can create TIF files larger than 2Gb but those can't be opened later
% * *TIF format, non-compressed*, see above for details of saving datasets in the TIF format
%
% [/dtls]
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
% 3D visualization of volumes is available using 3 different ways
%
% <html><h3 style="color:#d45600;">MIB rendering</h3></html>
% 
% <ug_gui_menu_file_3D_viewer.html *Click to open documentation about the new 3D volume viewer is available*> 
%
% Starting from MIB (version 2.5) and MATLAB R2018b the volumes can be
% directly visualized in MIB using hardware accelerated volume rendering
% engine. The datasets for visuzalization can be downsampled during the
% export. It is possible to make snapshots and animations.
%
% MIB version 2.84 comes with the updated 3D volume rendering that allows
% to render volumes with 1-3 color channels together with the models. As
% for MIB 2.84 the new 3D viewer is only available in MIB for MATLAB.
% 
% [dtls][smry] *Volume rendering engines of MIB* [/smry]
%
% <html>
% <table><tr>
%   <td>MIB 2.84, R2022b or newer<br>Volumes (1-3 colors) and models</td>
%   <td>MIB 2.5, R2018b or newer<br>only 1-channel volumes or single material models</td>
%   </tr><tr>
%   <td><img src = "images\menuFileRenderingMIB_R2022b.jpg"></td>
%   <td><img src = "images\menuFileRenderingMIB_R2018b.jpg"></td>
%   </tr><tr>
%   <td><b>Limitations</b><br>
%   <ul>
%   <li>Available only for MIB for MATLAB (at least in MIB 2.84)</li>
%   <li> One volume at the time</li>
%   </ul></td>
%   <td><b>Limitations</b><br>
%   <ul>
%  <li> One volume at the time; it can be image or a material of the model</li>
%  <li> Only grayscaled 3D data, i.e. a single color channel</li>
%  <li> Scale bar is not yet available </li>
%  </ul></td>
% </tr></table>
% </html>
%
% [/dtls]
%
% The version of MIB rendering engine can be selected from preferences:
%
% [class.code]MIB->Menu->File->Preferences->User interface->3D rendering engine[/class]
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/4CrfdOiZebk"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/J70V33f7bas</a>
% </html>
%
% <html><h3 style="color:#d45600;">MATLAB Volume Viewer</h3></html>
%
%
% When MIB is used with MATLAB R2017a or newer it is possible to export the
% open dataset to Volume Viewer application. Please note that this feature
% is not available for the compliled version of MIB
%
% [dtls][smry] *Snapshot of MATLAB volume renderer* [/smry]
% 
% <<images\menuFileRenderingMatlabVolRen.jpg>>
% 
% [/dtls]
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/J70V33f7bas"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/J70V33f7bas</a>
% </html>
%
% <html><h3 style="color:#d45600;">Fiji 3D viewer</h3></html>
%
% Please refer to details in the 
% <im_browser_system_requirements.html Microscopy Image Browser System Requirements Fiji> section for installation of Fiji.
%
% [dtls][smry] *Snapshot of volume renderering in Fiji* [/smry]
% 
% <<images\menuFileRenderingFiji.jpg>>
% 
% [/dtls]
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
% |MIB|
% 
% [dtls][smry] *Location of the configuration file* [/smry]
%
% * *for Windows* - [class.code]C:\Users\Username\MATLAB\mib.mat[/class] or in the Windows TEMP directory ([class.code]C:\Users\User-name\AppData\Local\Temp\[/class]). 
% The TEMP directory can be found and accessed with |Windows->Start button->%TEMP%| command
% * *for Linux* - [class.code]/home/username/Matlab[/class] or local TEMP directory
% * *for MacOS* - [class.code]/Users/username/Matlab[/class] or local TEMP directory
%
% [/dtls]
% [br8]
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #fffce8; 
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


