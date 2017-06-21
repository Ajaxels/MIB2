%% Microscopy Image Browser Preferences
% This dialog provides access to preferences of Microscopy Image Browser. Allows to modify colors of the |Selection|, |Model| and |Mask|
% layers, default behaviour of the mouse wheel and keys, settings of Undo... 
%
% *Please note*, |MIB| stores its configuration parameters in a file that is automatically generated after closing of
% |MIB|:
%
% * *for Windows* - _c:\temp\mib.mat_ or when _c:\temp_ is unavailable in the Windows TEMP directory (_C:\Users\User-name\AppData\Local\Temp\_). 
% The TEMP directory can be found and accessed with |Windows->Start button->%TEMP%| command
% * *for Linux/MacOS* - in a directory where |MIB| is installed, or in the local |tmp| directory (_/tmp_)
%
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>
%% Preferences
% 
% <<images\MenuFilePreferences.png>>
% 
%% User Interface Tweaks
%
% # *Mouse Wheel* - allows to choose between two possible actions done with the mouse wheel. When |Zoom| is selected,
% rotation of the mouse wheel will result in zoom in/out action; when |scroll| is selected rotation of the mouse wheel will result in
% change of the shown slices. *Note!* the mouse wheel may be used together with |Shift| button to scroll more than one slice
% at the time, see more in <ug_panel_im_view.html Image View Panel/Extra parameters for the slider>
% # *Left Mouse Button*. Allows to select action for press of the left mouse button. When |pan| is selected the press and
% hold of the left mouse button will result in moving of the shown image to left-right and up/down directions. When |select| is
% selected the left mouse button can be used for making selections. *Note!* The left and right mouse buttons are mirrored, |i.e.| if
% one action (|pan| or |select|) is selected for the left mouse button, the right mouse button implements the second
% available action.
% # *Image Resize Method*. Modifies a way how image is resized during on screen zoom in/zoom out action. Use 'nearest' to see
% unmodified pixels and 'bicubic' for smooth appearance. *Note!* the |nearest| option gives the fastest and |bicubic| the
% slowest performance. It is also possible to toggle the this from a
% dedicated button in <ug_gui_toolbar.html the MIB toolbar>.
% # *Disable Selection*. When |Selection| is disabled it is not possible to use the |Selection| layer for segmentation. In
% this situation memory requirements are lower.
% # *Select Font* - this button starts a standard font selection dialog
% # *Font size edit box* - modifies default font size for all text panels
% # *Font size for dir contents* - modifies the font size for the list of
% files in the <ug_panel_dir.html Directory Contents panel>.
% # *Shortcuts* - shortcuts for keys may be customized using the *Define shortcuts for keys* dialog that
% is started with this button. The list of default shortcuts is available
% from <ug_gui_shortcuts.html *the Key & mouse shortcuts page*>.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/qrLyrP9f018"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/qrLyrP9f018</a>
% </html>
% 
% <<images\MenuFilePreferencesShortcuts.png>>
% 
% # *GUI Scaling* - starts an input dialog that allows to tweak scaling of
% varipous user interface widgets. This may be required when working with
% MIB on MacOS or Linux. *Operating system scaling factor* - this number is
% needed when the text size is increased on the operating system 
% (on Windows: Control Panel\All Control Panel Items\Display\Screen Resolution->Make text and other items larger or smaller)
% 
%
% 
%
%% Program Settings
%
% *Modification of Undo parameters*
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/PrY3Eo02gU8"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/PrY3Eo02gU8</a>
% </html>
%
% # *Enable* - enable/disable undo. When the memory is limited it may be recommended to set the |Enable| undo setting to the |no| state.
% # *History Steps* - maximal number of history steps to keep in memory. *Note!* requires restart of Microscopy Image Browser
% to apply this modification.
% # *3D History* - number of 3D datasets that can be stored. When memory is limited it is recommended to set this value to |0|. *Note!* requires restart of Microscopy Image Browser
% to apply this modification.
%
% *External dirs*, starts a dialog to specify installation directories for
% Fiji and Omero.  Please refer to the <im_browser_system_requirements.html System Requirements> pages for details.
% If there is no need to use any of these programs, remove all text from the path edit box.
% 
% <<images\MenuFilePreferencesExernalDirs.png>>
% 
% 
%
%% Segmentation Settings
%
% <html>
% <ul>
% <li> <b>Type of interpolation</b>, defines type and parameters of the interpolation for the Selection layer to use 
% (<em>i</em> - shortcut, or <em>Menu->Selection->Interpolate</em>).<br>
% A brief demonstration is available in the following videos:<br>
% <em>- Shape interpolation</em>: <a href="https://youtu.be/ZcJQb59YzUA?t=4m3s"><img
% style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/ZcJQb59YzUA?t=4m3s</a><br>
% <em>- Line interpolation</em>: <a href="https://youtu.be/ZcJQb59YzUA?t=2m22s"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/ZcJQb59YzUA?t=2m22s</a>
% </li>
% <li><b>Number of points</b> - number of points to use for the interpolation, more points give smoother results, white the less points is faster
% </li>
% <li><b>Line width</b> - defines width of the line after the
% interpolation</li>
% <li><b>Font size for annotations</b> - defines size of annotation text, the annotations may be accessed
% from the menu entry: <em>Menu->Models->Annotations</em><br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/3lARjx9dPi0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/3lARjx9dPi0</a>
% </li>
% </ul>
% </html>
% 
%
% 
%% Colors
%
% Modification of default colors of the |Annotations|, |Selection|, |Mask|, |Model| layers and defining color look-up table (LUT). 
% The upper table shows the list of predefined colors for Materials of the |Model| layer. The lower table shows LUT for
% colors of the color channels to use with the LUT mode (<ug_panel_view_settings.html View Settings Panel->LUT checkbox>)
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/A5HHVd5bfJ0"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/A5HHVd5bfJ0</a>
% </html>
%
% # *Modification of the |Model| and |LUT| colors*. The rows in tables represent color in Red:Green:Blue format in range from 0 to 255.
% The colors may be modified either by updating the numbers in the tables or by clicking on a color bar (fourth column) representing the defined color.
% # *Modification of the |Selection| colors*. Press the *Selection* button to start the color selection dialog.
% # *Modification of the |Mask| colors*. Press the *Mask* button to start the color selection dialog.
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td colspan=2 style="border: 0px">
% Some actions are available for the colors of materials. These actions
% are available via a popup menu called using the right mouse button click
% above the upper table.
% </td>
% </tr>
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuFilePreferencesColorPopup.jpg">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>Reverse colormap</b> reverses the existing colormap</li>
% <li><b>Insert color</b> inserts a random color to the colormap at position after the one that was selected</li>
% <li><b>Replace with random color</b> replaces the selected color with a random one</li>
% <li><b>Swap two colors</b> swaps two colors between each other</li>
% <li><b>Delete color(s)</b> deletes the selected color from the colormap. Multiple colors could be selected using the Shift+mouse click combination</li>
% <li><b>Import from Matlab</b> imports a colormap from the main Matlab workspace</li>
% <li><b>Export to Matlab</b> exports the colormap to the main Matlab workspace</li>
% <li><b>Load from a file</b> loads a colormap from a file. The colormap should be saved using the matlab format and <em>cmap</em> variable</li>
% <li><b>Save to a file</b> saves the colormap to a file. The colormap is saved using the matlab format and <em>cmap</em> variable</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% *Built-in color palettes*
% 
% There are several built-in palettes for coloring materials of models are
% available. The palettes may be selected using the |Palette| and |Number
% of colors| comboboxes. The Default color palette was selected so that
% each color appears as a distinctive shade to color-blind users. 
%
% *Description of palettes:*
%
%
% 
% <<images\MenuFilePreferencesColorBrewer.jpg>>
% 
% The color palettes done with help of following sources:
%
% * <http://jfly.iam.u-tokyo.ac.jp/color/ Yasuyo G. Ichihara, Masataka
% Okabe, Koichi Iga, Yosuke Tanaka, Kohei Musha, Kei Ito. Color Universal Design - The selection of four
% easily distinguishahle colors for all color vision types. Proc Spie 6807 (2008)> 
% * <http://colorbrewer2.org/ Cynthia Brewer, Mark Harrower, Ben Sheesley,
% Andy Woodruff, David Heyman. ColorBrewer 2.0>
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>