%% Microscopy Image Browser Troubleshooting
% 
% 
% *Back to* <im_browser_product_page.html *Index*>
%% |MIB| does not start
%%
% 
% * Check that |MIB| directory is in Matlab path: |File->Set path...|.
% If it is missing, add it with |->Add with Subfolders-> Save|.
% * Delete old configuration file:
% * *for Windows* - _C:\Users\Username\Matlab\mib.mat_ or in the Windows TEMP directory (_C:\Users\User-name\AppData\Local\Temp\_). 
% The TEMP directory can be found and accessed with |Windows->Start button->%TEMP%| command
% * *for Linux* - _/home/username/Matlab_ or local TEMP directory
% * *for MacOS* - _/Users/username/Matlab_ or local TEMP directory
% 
%% Out of memory
% 
% When working with large datasets it is normal to experience shortage of available memory. The following recommendations could be
% considered:
%%
% 
% * Use 64-bit operating system. The 32-bit operating system can use only up to 3.25 Gb.
% * Use 8-bit datasets. Convert from 16-bit to 8-bit via |Menu->Image->Mode->8 bit|.
% * Use Models with 63 maximal materials, |Menu->File->Preferences->Models->
% Number of materials in a model->63|.
% * Lower number of 3D Undo steps in the <ug_gui_menu_file_preferences.html Menu->File->Preference dialog>.
% * Lower number of maximal steps to keep in the Undo history <ug_gui_menu_file_preferences.html Menu->File->Preference dialog>.
% * Completely disable Undo history in the <ug_gui_menu_file_preferences.html Menu->File->Preference dialog>.
% * Turn off |Selection| layer from the |Disable selection| option of the <ug_gui_menu_file_preferences.html
% Menu->File->Preference dialog>. *Note!* when the |Selection| layer is switched off it is not possible to do the
% segmentation.
%
%% Fiji: reports Java3D is not installed.
% Most likely there are no write permissions to some folders required for automatic installation of Fiji 3D viewer. Please
% check carefully the Matlab command window, where Fiji reports required directories.
% 
% For example in standard case the following directories should have write permissions: 
%
% * _C:\Program Files\MATLAB\MATLAB Compiler Runtime\v81\sys\java\jre\win64\jre\lib\ext_
% * _C:\Program Files\MATLAB\MATLAB Compiler Runtime\v81\sys\java\jre\win64\jre\bin_
%
%% Fiji: Failed to retrieve Exception Message
%
% If the |Failed to retrieve Exception Message| error appears,
% please increase the heap space for the Java VM in Matlab,
% <http://www.mathworks.se/support/solutions/en/data/1-18I2C/index.html see
% details here>. 
%
% For example, rendering of 1818x1022x717 volume requires
% 4Gb heap size.
% 
%% Hotline
% For bug reports please use the im-browser issues system:
% <https://sourceforge.net/p/im-browser/tickets/ https://sourceforge.net/p/im-browser/tickets/>.
% 
% For additional support please use the mailing list: <https://lists.sourceforge.net/lists/listinfo/im-browser-support https://lists.sourceforge.net/lists/listinfo/im-browser-support>
%%
% 
% <html>
% Ilya Belevich (<a href="mailto:ilya.belevich -AT- helsinki.fi">ilya.belevich @ helsinki.fi</a>)<br>
% <a href="http://www.biocenter.helsinki.fi/~ibelev/">web site</a><br>
% <i>Institute of Biotechnology<br>
% University of Helsinki</i>
% </html>
% 
%
%
% *Back to* <im_browser_product_page.html *Index*>