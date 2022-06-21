%% Microscopy Image Browser System Requirements
%
% *Back to* <im_browser_product_page.html *Index*>
%
%% Computer
% Microscopy Image Browser is a program written under MATLAB environment and it
% was tested to work under Windows/Linux/Mac installation of MATLAB.
%
%
% In addition compiled (standalone) versions of MIB are available for Windows and Mac 64-bit OS. 
% The standalone versions of MIB may not have complete functionality of the original program but do not require to purchase 
% MATLAB license when used for academic research. [br]
% The standalone MIB requires
% <http://www.mathworks.se/products/compiler/mcr/ MATLAB Compiler Runtime
% (MCR)> that is automatically installed during installation. 
%
% It is highly recommended to use 64-bit operating system with sufficient amount of memory.
%% MATLAB
% *MATLAB, Release 2014b*, (original MIB version 2.00; the newer versions of MIB may require R2017a or newer). 
% [br]MIB was tested with MATLAB R2014b - R2022a.
% [br]DeepMIB is available for R2019b but the newer releases are
% recommended
% 
%% Toolboxes
%%
%
% * <http://www.mathworks.com/products/image/ *Image Processing Toolbox*>, V7.0 (R2010a) or newer is _*REQUIRED*_
% * <https://se.mathworks.com/products/parallel-computing.html *Parallel Computing Toolbox*>, R2019b or newer is _*recommended*_
% * <https://se.mathworks.com/products/computer-vision.html *Computer Vision Toolbox*>, (*required for DeepMIB*, MATLAB R2019b and newer) for training of 2D, 3D CNNs and segmentation of datasets
% * <https://se.mathworks.com/products/deep-learning.html *Deep Learning Toolbox*>, (*required for DeepMIB*, MATLAB R2019b and newer) for training of 2D, 3D CNNs and segmentation of datasets
% * <http://se.mathworks.com/products/statistics/ Statistics and Machine Learning Toolbox> (_optional_) for alternative to the Random Forest classifiers
% * <http://se.mathworks.com/products/statistics/ Statistics Toolbox> (_optional_) for alternative to the Random Forest classifiers
% * <http://se.mathworks.com/products/optimization/ Optimization Toolbox> (_optional_) for alternative to the Random Forest classifiers
% * <https://se.mathworks.com/help/vision/index.html Computer Vision System
% Toolbox> for automatic alignement using detected image features and for
% Deep MIB (MATLAB R2019b or newer, MIB version 2.70)
% 
% 
%% Bio-Formats
% The Bio-Formats library brings support of multiple microscopy image formats. To use the library check the [class.kbd][&#10003;] *Bio*[/class] checkbox in the Directory Contents panel of MIB.
%
% *<http://openmicroscopy.org/info/bio-formats Bio-formats>* java library (_optional_) is provided in the
% |ImportExportTools/BioFormats| folder.
%
%% BMxD Image Filters
% When installed MIB can use BM3D and BM4D filters to filter datasets. The
% filters are not supplied with MIB due to license limitations and have to
% be installed separetly.
% 
% [dtls][smry] *Installation instructions* [/smry]
%
% 
% * Download *BM3D MATLAB software* and *BM4D MATLAB software* from
% <http://www.cs.tut.fi/~foi/GCF-BM3D/ Image and video denoising by sparse
% 3D transform-domain collaborative filtering> webpage.
% * Unzip the files to directory with MATLAB scripts. For example,
% [class.code]c:\MATLAB\Scripts\BMxD\BM3D[/class] and [class.code]c:\MATLAB\Scripts\BMxD\BM4D[/class]
% * Start MIB and specify these folders in MIB preferences:
% [class.code]MIB->Menu->File->Preferences->External dirs[/class]
% * Restart MIB
%
% [/dtls]
%
%% FIJI: volume rendering and connection
% Microscopy Image Browser can use Fiji 3D Viewer plugin for visualization
% of volumes and models. In addition, there is a <ug_panel_fiji_connect.html Fiji Connect panel> that allows interaction between |MIB| and Fiji.
%
% *!!! Warning !!!*
%
% It seems that Fiji 3D viewer is not compatible with MATLAB on MacOS, please do not change write permission for the |sys\java\jre\win64\jre\lib\ext| on the MacOS
%
% [dtls][smry] *Installation process* [/smry]
%
% * Download Fiji <http://fiji.sc/wiki/index.php/Downloads [link]> (_for MIB older than 2.60 use the Fiji Life-Line version, 2015 December 22_)
% * Unzip and start Fiji  (fiji-win32.exe or fiji-win64.exe) 
% * Update Fiji: Fiji->Menu->Help->Update Fiji  (it may be required to repeat this step one more time after restart of Fiji)
% * In the Fiji folder should appear a folder [class.code]scripts[/class] with the [class.code]Miji.m[/class] file
% * The [class.code]scripts[/class] sub-folder containing [class.code]Miji.m[/class] should appear within the Fiji folder
% * Start MATLAB
% * Start MIB and open the Preferences Window:
% [class.code]MIB->Menu->Preferences->External dir[/class]. Add path to the Fiji installation
% folder there, for example as [class.code]C:\Tools\Fiji.app[/class] for Windows or [class.code]/Applications/Fiji.app/[/class] for Mac OS
%
% [/dtls]
% 
% [dtls][smry] *Important notes* [/smry]
%
% *Note 1*, the following MATLAB path should be open for writing:
%
% [class.code]...\MATLAB\sys\java\jre\win64\jre\lib\ext[/class] and [class.code]...\MATLAB\sys\java\jre\win64\jre\bin[/class]
%
% *Note 2*, if the |Failed to retrieve Exception Message| error appears,
% please increase the heap space for the Java VM in MATLAB,
% <http://www.mathworks.se/support/solutions/en/data/1-18I2C/index.html see
% details here>. For example, rendering of 1818x1022x717 volume requires
% 4Gb heap size.
%
% *Note 3*, the Fiji 3D viewer may not work when started for the first
% time. In this case, MATLAB should be restarted.
% [/dtls]
%
%% FRANGI: compiled Frangi mask filter
% Compiled Frangi Mask filter is recommended for faster run. Please compile it for your OS.
% Most of C-functions can be compiled using a single script:
%
% [dtls][smry] *Compilation details* [/smry]
% 
% * In MATLAB command window change directory to [class.code]mib\Tools\[/class], where [class.code]mib[/class] is the path where MIB was installed, 
%   for example [class.code]c:\MATLAB\Scripts\mib[/class]
% * To compile, type in MATLAB command window [class.code]mib_compile_c_files[/class]
%
% *Note!* These files should be already pre-compiled for win32, win64 and mac64.
% [/dtls]
%
%% IMARIS: connection to Imaris
% Microscopy Image Browser can be used together with
% <http://www.bitplane.com/imaris Imaris>. This functionality is achieved
% with <http://www.scs2.net/next/index.php?id=110 IceImarisConnector>
% written by Aaron C. Ponti, ETH Zurich. 
% 
% [dtls][smry] *Requirements:* [/smry]
%
% # Installed Imaris and ImarisXT
% # Add path of Imaris installation to a system environment variable
% *IMARISPATH*. [class.code]Start->Computer->right mouse click->Properties->Advanced
% system settings->Environment Variables...->New...[/class]. For example,
% [class.code]IMARISPATH = c:\Tools\Science\Imaris\[/class]. Also path to Imaris can be
% specified from the MIB preferences: [class.code]Menu->File->Preferences->External dirs[/class]
% # Restart MATLAB
%
% [/dtls]
%
% [dtls][smry] *Additiona notes* [/smry]
%
% *Note:* it is recommended to put |ImarisLib.jar| to the static Java
% path of MATLAB. To do that:
%
% # Start MATLAB and note the start-up (home) directory. For example: [class.code]c:\Users\UserName\Documents\MATLAB[/class]
% # Create [class.code]javaclasspath.txt[/class] in this home directory and add path to
% |ImarisLib.jar| to this file (for example, [class.code]c:\Program Files\Bitplane\Imaris x64 8.0.2\XT\matlab\ImarisLib.jar[/class]). 
% One way to do that (Windows) is to type in the MATLAB command prompt:
% [class.code]system('notepad javaclasspath.txt')[/class]; add the path; and save the file
% # Restart MATLAB
%
% [/dtls]
%
%% Membrane Click Tracker
% Compiled files are required to use Membrane Click Tracker tool. 
% Please compile them for your OS. Most of C-functions can be compiled using a single script
%
% [dtls][smry] *Compilation details* [/smry]
% 
% * In MATLAB command window change directory to [class.code]mib\Tools\[/class], where [class.code]mib[/class] is the path where MIB was installed, 
%   for example [class.code]c:\MATLAB\Scripts\mib[/class]
% * To compile, type in MATLAB command window [class.code]mib_compile_c_files[/class]
%
% *Note!* These files should be already pre-compiled for win32, win64 and mac64.
%
% [/dtls]
% 
%% NRRD: read NRRD format
% Microscopy Image Browser uses an own function for saving data in the NRRD
% format, but relies on <http://www.na-mic.org/Wiki/index.php/Projects:MATLABSlicerExampleModule
% *Projects:MATLABSlicerExampleModule*> by John Melonakos for reading it.
% On Windows OS the files should be already pre-compiled, but for Linux it
% may be needed to compile them. 
%
% Please refer to details in [class.code]mib\ImportExportTools\nrrd\compilethis.m[/class].
%
%% OMERO: connection to OMERO server
% Connection to <http://www.openmicroscopy.org/site OMERO server> requires the download of OMERO API bindings for
% MATLAB.
%
% [dtls][smry] *Installation details* [/smry]
%
% * Download MATLAB plugin for OMERO 
% <http://www.openmicroscopy.org/site/products/omero/ from here>.
% It should be listed in the *OMERO->OMERO Downloads, Plugins/MATLAB*
% section. (*Note!* Make sure that the version of MATLAB plugin corresponds
% to the version of OMERO server you are going to login. Old OMERO
% downloads are listed in the _Previous versions_ section at the bottom of
% the page.
% * Unzip the file to your scripts directory, for example
% [class.code]C:\MATLAB\Scripts\OMERO_5[/class]
% * *FOR MATLAB VERSION* Add this directory ([class.code]C:\MATLAB\Scripts\OMERO_5[/class]) with subfolders to MATLAB path
% ([class.code]MATLAB->Home tab->Set Path...->Add with Subfolders...[/class]) or run
% [class.code]pathtool[/class] in MATLAB command window
% * *FOR DEPLOYED VERSION* Add path to the OMERO installation using the MIB Preferences dialog: [class.code]MIB->Menu->Preferences->External dirs[/class].
% For example, 
% [class.code]C:\MATLAB\Scripts\OMERO_5\libs\[/class] for Omero version 5, or
% [class.code]C:\MATLAB\Scripts\OMERO_4\libs\[/class] for Omero verison 4
%
% [/dtls]
%
% When using Omero, MIB stores servers and ports in [class.code]mib_omero.mat[/class] file
% located in [class.code]c:\temp\mib_omero.mat[/class] or in the system |temp| folder.
%
%% Random Forest Classifier
% Compiled files are required to use Random Forest Classifier. Microscopy Image Browser uses 
% <https://code.google.com/p/randomforest-matlab/ randomforest-matlab> by Abhishek Jaiantilal which is already compiled for win32, win64. 
%
% [dtls][smry] *Compilation details* [/smry]
%
% For all other OS the files have to be compiled manually: 
% Please refer to details in 
%%
% 
% * [class.code]mib\Tools\RandomForest\RF_Class_C\README.txt[/class]
% * [class.code]mib\Tools\RandomForest\RF_Reg_C\README.txt[/class]
%
% [/dtls]
%
%% SLIC superpixels, supervoxels and maxflow the Brush tool with supervoxels and for Graph-cut and Classifier
% The brush tool can be used to select not individual pixels but rather groups of pixels (superpixels). 
% This functionality is implemented using the <http://ivrl.epfl.ch/supplementary_material/RK_SLICSuperpixels/index.html SLIC (Simple Linear Iterative Clustering)> 
% algorithm written by Radhakrishna Achanta et al., 2015. In addition the SLIC superpixels and supervoxels 
% are used for the Graph-cut segmentation and Classifier.
%
% For the Graph-cut segmentation MIB is utilizing <http://pub.ist.ac.at/~vnk/software.html maxflow 2.22> written by Yuri Boykov and Vladimir Kolmogorov. 
%
% [dtls][smry] *Compilation details* [/smry]
% 
% * In MATLAB command window change directory to [class.code]mib\Tools\[/class], where [class.code]mib[/class] is the path where MIB was installed, 
%   for example [class.code]c:\MATLAB\Scripts\mib[/class]
% * To compile, type in MATLAB command window [class.code]mib_compile_c_files[/class]
%
% *Note!* These files should be already pre-compiled for win32, win64 and mac64.
%
% [/dtls]
%
%% Software Volume Rendering in MIB
% Compiled [class.code]affine_transform_2d_double.c[/class] function is required for volume rendering. Please compile it for your OS.
% Most of C-functions can be compiled using a single script. This file is already pre-compiled for win64.
%
% [dtls][smry] *Compilation details* [/smry]
% 
% * In MATLAB command window change directory to [class.code]mib\Tools\[/class], where [class.code]mib[/class] is the path where MIB was installed, 
%   for example [class.code]c:\MATLAB\Scripts\mib[/class]
% * To compile, type in MATLAB command window [class.code]mib_compile_c_files[/class]
%
% *Note!* This file is already pre-compiled for win64.
%
% [/dtls]
%
% *Back to* <im_browser_product_page.html *Index*>
%
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