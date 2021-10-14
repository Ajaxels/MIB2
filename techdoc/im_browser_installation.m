%% Microscopy Image Browser (MIB) Installation
% 
% *Back to* <im_browser_product_page.html *Index*>
%% Run Microscopy Image Browser under MATLAB environment
% 
% # Download MATLAB distribution of the program (<http://mib.helsinki.fi/web-update/MIB2_Matlab.zip MIB2_Matlab.zip>)
% # Unzip and copy MIB files to |MIB| directory in your
% |Scripts| folder. For example, |c:\MATLAB\Scripts\mib\|
% # Start MATLAB
% # Add |MIB| starting directory (for example, |c:\MATLAB\Scripts\mib\|) into MATLAB path
% |MATLAB->Home tab->Set path...->Add folder...->Save|, or alternatively use the |pathtool| function from MATLAB command window
% # Type |mib| in the matlab command window and hit the Enter button to start the program
% # Check <im_browser_system_requirements.html System Requirements> for further details about optional
% steps, such as use of <http://fiji.sc/Fiji Fiji>, or <http://www.openmicroscopy.org/site OMERO>>
% # Access help and tutorials from the MIB menu: |MIB->Menu->Help->Help| 
%
%% Run Microscopy Image Browser as standalone (Windows, x64 bit)
% 
% # Download a single executable file that installs MIB (<http://mib.helsinki.fi/web-update/MIB2_Win.exe MIB2_Win.exe>). 
% # Run |MIB2_Win.exe| to install MIB to your computer (_requires
% administrative privileges_). The required MATLAB Compiler Runtime
% (MCR) environment will be automatically installed during the process.
% <http://mib.helsinki.fi/downloads_installation_windows.html Click here for detailed instructions> .
% # To start, please type MIB in the Start menu
% # Check <im_browser_system_requirements.html System Requirements> for further details about optional
% steps, such as use of <http://fiji.sc/Fiji Fiji>, or <http://www.openmicroscopy.org/site OMERO>>
% # Access help and tutorials from the MIB menu: |MIB->Menu->Help->Help|
% 
%
%% Run Microscopy Image Browser as standalone (MacOS, x64 bit)
% _Tested with Mac OS X (Yosemite), version 10.10.3 and MATLAB R2016a._
% 
% # Download standalone distribution of the program for Mac OS (<http://mib.helsinki.fi/web-update/MIB2_Mac.dmg MIB2_Mac.dmg>). 
% # Follow the datailed instructions from MIB website
% <http://mib.helsinki.fi/downloads_installation_macos.html MIB for Mac OS> 
% 
%
%% Additional info
% |im_browser| stores its configuration parameters:
%
% * *for Windows* - _C:\Users\Username\MATLAB\mib.mat_ or in the Windows TEMP directory (_C:\Users\User-name\AppData\Local\Temp\_). 
% The TEMP directory can be found and accessed with |Windows->Start button->%TEMP%| command
% * *for Linux* - _/home/username/Matlab_ or local TEMP directory
% * *for MacOS* - _/Users/username/Matlab_ or local TEMP directory
%
% The configuration file is automatically created/updated when closing |MIB|.
%
% If |MIB| does not start check MATLAB path
% and/or delete the configuration _mib.mat_ file.
%
%
% *Back to* <im_browser_product_page.html *Index*>