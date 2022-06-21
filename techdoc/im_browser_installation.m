%% Microscopy Image Browser (MIB) Installation
% 
% *Back to* <im_browser_product_page.html *Index*>
%% Run Microscopy Image Browser under MATLAB environment
% 
% * Download MATLAB distribution of the program (<http://mib.helsinki.fi/web-update/MIB2_Matlab.zip MIB2_Matlab.zip>)
% * Unzip and copy MIB files to |MIB| directory in your
% |Scripts| folder. For example,
% [class.code]c:\MATLAB\Scripts\mib\[/class]
% * Start MATLAB
% * Add |MIB| starting directory (for example,
% [class.code]c:\MATLAB\Scripts\mib\[/class]) into MATLAB path:[br]
% [class.code]MATLAB->Home tab->Set path...->Add folder...->Save[/class]
% [br] alternatively use the [class.code]pathtool[/class] function from MATLAB command window
%
% * Type [class.code]mib[/class] in the MATLAB command window and hit the Enter button to start the program
% * Check <im_browser_system_requirements.html System Requirements> for further details about optional
% steps, such as use of <http://fiji.sc/Fiji Fiji>, or <http://www.openmicroscopy.org/site OMERO>
% * Access help and tutorials from the MIB menu: [class.code]MIB->Menu->Help->Help[/class]
%
%% Run Microscopy Image Browser as standalone (Windows, x64 bit)
% 
% # Download a single executable file that installs MIB (<http://mib.helsinki.fi/web-update/MIB2_Win.exe MIB2_Win.exe>). 
% # Run [class.code]MIB2_Win.exe[/class] to install MIB to your computer (_requires
% administrative privileges_). The required MATLAB Compiler Runtime
% (MCR) environment will be automatically installed during the process.
% <http://mib.helsinki.fi/downloads_installation_windows.html Click here for detailed instructions> .
% # To start, please type MIB in the Start menu of Windows
% # Check <im_browser_system_requirements.html System Requirements> for further details about optional
% steps, such as use of <http://fiji.sc/Fiji Fiji>, or <http://www.openmicroscopy.org/site OMERO>
% # Access help and tutorials from the MIB menu: [class.code]MIB->Menu->Help->Help[/class]
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
% MIB stores its configuration parameters:
%
% * *for Windows* - [class.code]C:\Users\Username\MATLAB\mib.mat[/class] or in the Windows TEMP directory ([class.code]C:\Users\User-name\AppData\Local\Temp\[/class]). 
% The TEMP directory can be found and accessed with |Windows->Start button->%TEMP%| command
% * *for Linux* - [class.code]/home/username/Matlab[/class] or local TEMP directory
% * *for MacOS* - [class.code]/Users/username/Matlab[/class] or local TEMP directory
%
% The actual path to the configuration file is dispayed in the command prompt during MIB startup. The configuration file is automatically created/updated when closing |MIB|.
%
% If |MIB| does not start check MATLAB path
% and/or delete the configuration [class.code]mib.mat[/class] file.
%
%
% *Back to* <im_browser_product_page.html *Index*>
%
% [cssClasses]
% .code {
% font-family: monospace;
% font-size: 10pt;
% background: #eee;
% padding: 1pt 3pt;
% }
% [/cssClasses]