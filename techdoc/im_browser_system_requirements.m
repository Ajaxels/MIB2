%% Microscopy Image Browser System Requirements
%
% *Back to* <im_browser_product_page.html *Index*>
%
%% Computer
% Microscopy Image Browser is a program written under Matlab environment and it
% was tested to work under Windows/Linux/Mac installation of Matlab.
%
%
% In addition compiled (standalone) versions of MIB are available for Windows and Mac 64-bit OS. 
% The standalone versions of MIB may not have complete functionality of the original program but do not require to purchase Matlab license. 
% The standalone MIB requires
% <http://www.mathworks.se/products/compiler/mcr/ MATLAB Compiler Runtime
% (MCR)> that will be automatically installed during installation. 
%
% It is highly recommended to use 64-bit operating system with sufficient amount of memory.
%% MATLAB
% *MATLAB, Release 2014b*, (_and newer_). MIB was tested with Matlab R2014b - R2017b.
% 
%% Toolboxes
%%
%
% * <http://www.mathworks.com/products/image/ *Matlab Image Processing
% Toolbox*>, V7.0 (R2010a) or newer is _*REQUIRED*_
% * <http://se.mathworks.com/products/statistics/ Statistics and Machine Learning Toolbox> (_optional_) for alternative to the Random Forest classifiers
% * <http://se.mathworks.com/products/statistics/ Statistics Toolbox> (_optional_) for alternative to the Random Forest classifiers
% * <http://se.mathworks.com/products/optimization/ Optimization Toolbox> (_optional_) for alternative to the Random Forest classifiers
% * <https://se.mathworks.com/help/vision/index.html Computer Vision System Toolbox> for automatic alignement using detected image features
% 
%% Bio-Formats
% The Bio-Formats library brings support of multiple microscopy image formats. To use the library check the Bio checkbox in the Directory Contents panel of MIB.
%
% *<http://openmicroscopy.org/info/bio-formats Bio-formats>* java library (_optional_) is provided in the
% |ImportExportTools/BioFormats| folder.
%
%% BMxD Image Filters
% When installed MIB can use BM3D and BM4D filters to filter datasets. The
% filters are not supplied with MIB due to license limitations and have to
% be installed separetly (*_only for Matlab version of MIB!_*).
% 
% *Installation instructions:*
%
% 
% * Download *BM3D MATLAB software* and *BM4D MATLAB software* from
% <http://www.cs.tut.fi/~foi/GCF-BM3D/ Image and video denoising by sparse
% 3D transform-domain collaborative filtering> webpage.
% * Unzip the files to directory with Matlab scripts. For example,
% _c:\MATLAB\Scripts\BMxD\BM3D_ and _c:\MATLAB\Scripts\BMxD\BM4D_
% * Start MIB and specify these folders in MIB preferences:
% |MIB->Menu->File->Preferences->External dirs|. Alternatively, the
% directories can be added to Matlab path.
% * Restart MIB
% 
%
%% FIJI: volume rendering and connection
% Microscopy Image Browser can use Fiji 3D Viewer plugin for visualization
% of volumes and models. In addition, there is a <ug_panel_fiji_connect.html Fiji Connect panel> that allows interaction between |MIB| and Fiji.
%
% *!!! Warning !!!*
%
% It seems that Fiji 3D viewer is not compatible with Matlab on MacOS, please do not change write permission for the |sys\java\jre\win64\jre\lib\ext| on the MacOS
%
% Below are the datails of the installation process.
%
% * Download Fiji, *Please use the Fiji Life-Line version, 2015 December 22*  <http://fiji.sc/wiki/index.php/Downloads [link]>
% * Unzip and start Fiji  (fiji-win32.exe or fiji-win64.exe) 
% * Update Fiji: Fiji->Menu->Help->Update Fiji  (it may be required to repeat this step one more time after restart of Fiji)
% * In the Fiji folder should appear a folder |scripts| with the |Miji.m| file
% * The |scripts| sub-folder containing |Miji.m| should appear within the Fiji folder
% * Start Matlab
% * Start MIB and open the Preferences Window:
% |MIB->Menu->Preferences->External dir|. Add path to the Fiji installation
% folder there, for example as _C:\Tools\Fiji.app_ for Windows or _/Applications/Fiji.app/_ for Mac OS
% 
% *Note 1*, the following Matlab path should be open for writing:
%
% |...\Matlab\sys\java\jre\win64\jre\lib\ext| and |...\Matlab\sys\java\jre\win64\jre\bin|
%
% *Note 2*, if the |Failed to retrieve Exception Message| error appears,
% please increase the heap space for the Java VM in Matlab,
% <http://www.mathworks.se/support/solutions/en/data/1-18I2C/index.html see
% details here>. For example, rendering of 1818x1022x717 volume requires
% 4Gb heap size.
%
% *Note 3*, the Fiji 3D viewer may not work when started for the first
% time. In this case, Matlab should be restarted.
%
%% FRANGI: compiled Frangi mask filter
% Compiled Frangi Mask filter is recommended for faster run. Please compile it for your OS.
% Most of C-functions can be compiled using a single script:
%%
% 
% * In Matlab command window change directory to _mib\Tools\_, where _mib_ is the path where MIB was installed, 
%   for example _c:\MATLAB\Scripts\mib_
% * To compile, type in Matlab command window _mib_compile_c_files_
%
% *Note!* These files should be already pre-compiled for win32, win64 and mac64.
%
%% IMARIS: connection to Imaris
% Microscopy Image Browser can be used together with
% <http://www.bitplane.com/imaris Imaris>. This functionality is achieved
% with <http://www.scs2.net/next/index.php?id=110 IceImarisConnector>
% written by Aaron C. Ponti, ETH Zurich. 
% 
% *Requirements:*
%
% # Installed Imaris and ImarisXT
% # Add path of Imaris installation to a system environment variable
% *IMARISPATH*. _Start->Computer->right mouse click->Properties->Advanced
% system settings->Environment Variables...->New..._. For example,
% |IMARISPATH = c:\Tools\Science\Imaris\|. Also path to Imaris can be
% specified from the MIB preferences: |Menu->File->Preferences->External dirs|
% # Restart Matlab
%
% *Note:* it is recommended to put |ImarisLib.jar| to the static Java
% path of Matlab. To do that:
%
% # Start Matlab and note the start-up (home) directory. For example: _c:\Users\UserName\Documents\MATLAB_
% # Create |javaclasspath.txt| in this home directory and add path to
% |ImarisLib.jar| to this file (for example, _c:\Program Files\Bitplane\Imaris x64 8.0.2\XT\matlab\ImarisLib.jar_). 
% One way to do that (Windows) is to type in the Matlab command prompt:
% |system('notepad javaclasspath.txt')|; add the path; and save the file
% # Restart Matlab
%
%% Membrane Click Tracker
% Compiled files are required to use Membrane Click Tracker tool. Please compile them for your OS. Most of C-functions can be compiled using a single script:
%%
% 
% * In Matlab command window change directory to _mib\Tools\_, where _mib_ is the path where MIB was installed, 
%   for example _c:\MATLAB\Scripts\mib_
% * To compile, type in Matlab command window _mib_compile_c_files_
%
% *Note!* These files should be already pre-compiled for win32, win64 and mac64.
%
%% NRRD: read NRRD format
% Microscopy Image Browser uses an own function for saving data in the NRRD
% format, but relies on <http://www.na-mic.org/Wiki/index.php/Projects:MATLABSlicerExampleModule
% *Projects:MATLABSlicerExampleModule*> by John Melonakos for reading it.
% On Windows OS the files should be already pre-compiled, but for Linux it
% may be needed to compile them. 
%
% Please refer to details in |im_browser\ImportExportTools\nrrd\compilethis.m|.
%
%% OMERO: connection to OMERO server
% Connection to <http://www.openmicroscopy.org/site OMERO server> requires the download of OMERO API bindings for
% Matlab.
%
% * Download Matlab plugin for OMERO 
% <http://www.openmicroscopy.org/site/products/omero/ from here>.
% It should be listed in the *OMERO->OMERO Downloads, Plugins/Matlab*
% section. (*Note!* Make sure that the version of Matlab plugin corresponds
% to the version of OMERO server you are going to login. Old OMERO
% downloads are listed in the _Previous versions_ section at the bottom of
% the page.
% * Unzip the file to your scripts directory, for example
% |C:\Matlab\Scripts\OMERO_5|
% * *FOR MATLAB VERSION* Add this directory (|C:\Matlab\Scripts\OMERO_5|) with subfolders to Matlab path (|Matlab->Home tab->Set Path...->Add with Subfolders...|) or run
% |pathtool| in Matlab command window
% * *FOR DEPLOYED VERSION* Add path to the OMERO installation using the MIB Preferences dialog: |MIB->Menu->Preferences->External dirs|. For example,
% _|C:\Matlab\Scripts\OMERO_5\libs\|_ for Omero version 5, or
% _|C:\Matlab\Scripts\OMERO_4\libs\|_ for Omero verison 4
%
%
% When using Omero, MIB stores servers and ports in _mib_omero.mat_ file
% located in 'c:\temp\mib_omero.mat' or in the system |temp| folder.
%
%% Random Forest Classifier
% Compiled files are required to use Random Forest Classifier. Microscopy Image Browser uses 
% <https://code.google.com/p/randomforest-matlab/ randomforest-matlab> by Abhishek Jaiantilal which is already compiled for win32, win64. 
%
% For all other OS the files have to be compiled manually: 
% Please refer to details in 
%%
% 
% * _mib\Tools\RandomForest\RF_Class_C\README.txt_
% * _mib\Tools\RandomForest\RF_Reg_C\README.txt_
% 
%
%% SLIC superpixels, supervoxels and maxflow the Brush tool with supervoxels and for Graph-cut and Classifier
% The brush tool can be used to select not individual pixels but rather groups of pixels (superpixels). 
% This functionality is implemented using the <http://ivrl.epfl.ch/supplementary_material/RK_SLICSuperpixels/index.html SLIC (Simple Linear Iterative Clustering)> 
% algorithm written by Radhakrishna Achanta et al., 2015. In addition the SLIC superpixels and supervoxels 
% are used for the Graph-cut segmentation and Classifier.
%
% For the Graph-cut segmentation MIB is utilizing <http://pub.ist.ac.at/~vnk/software.html maxflow 2.22> written by Yuri Boykov and Vladimir Kolmogorov. 
%
%%
% 
% * In Matlab command window change directory to _mib\Tools\_, where _mib_ is the path where MIB was installed, 
%   for example _c:\MATLAB\Scripts\mib_
% * To compile, type in Matlab command window _mib_compile_c_files_
%
% *Note!* These files should be already pre-compiled for win32, win64 and mac64.
%
%% Software Volume Rendering in MIB
% Compiled |affine_transform_2d_double.c| function is required for volume rendering. Please compile it for your OS.
% Most of C-functions can be compiled using a single script:
% 
% * In Matlab command window change directory to _mib\Tools\_, where _mib_ is the path where MIB was installed, 
%   for example _c:\MATLAB\Scripts\mib_
% * To compile, type in Matlab command window _mib_compile_c_files_
%
% *Note!* This file is already pre-compiled for win64.
%
% *Back to* <im_browser_product_page.html *Index*>