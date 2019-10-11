%% Batch processing...
% This mode allows automate many of the image processing steps in MIB, the steps may be assigned into a protocol, which may be applied
% to multiple images. 
%
% <html>
% A demonstration is available in the following video:<br>
% <a href="https://youtu.be/P6Rivp713qM"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/P6Rivp713qM</a>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>
%
%
% <html>
% <table>
% <tr>
% <td><img src="images\menuFileBatchMode.png"></td>
% <td>
% <ul>
% There are two general modes of usage:<br><br>
% <li>when the <b>Listen for MIB actions</b> checkbox is checked, all recordable MIB operations are
% automatically detected and displayed as the current protocol step.
% <br>When the <b>Auto add to protocol</b> checkbox is checked the detected action are automatically added to the protocol.<br>
% <em><b>Please note</em></b> that not all available operations are detected
% some of them (for example, loading or saving of images) can only be added manually</li>
% <li>alternatively, possible operations can be manually selected using the <b>Protocol steps->Section</b> and 
% <b>Protocol steps->Action</b> comboboxes. The selected action with default parameters is acquired and can be added to the protocol</li>
% </ul>
% <br><br>
% Start the protocol by pressing the <b>Run protocol</b> button or,
% whenever is need the protocol may be started from the currently selected
% step (<b>Start from selected</b> button).
% </td>
% </tr>
% </table>
% <br>
% In addition, to the normal image operations, the Batch processing tool
% has also the <b>Service steps</b> section, which allows to stop protocol
% at each moment or to generate Directory or File loops to load images in
% sequence. 
% </html>
%
%% Protocol panel
% This section shows the steps of the protocol and allows basic operations
% with it.
%
% <html>
% <table>
% <tr>
% <td><img src="images\menuFileBatchMode_2.png"></td>
% <td>
% <ul>
% The right mouse click over the list of actions brings a popup menu with additional options:<br><br>
% <li><b>Show settings</b> displays the parameters for the selected action
% in the Protocol panel at the lower part of the window; from there the the specific parameters may be modified.
% <b><em>Please note</b></em>, when the <b>Show parameters on click</b>
% checkbox is checked the parameters of the selected action are
% automatically displayed in the Protocol steps panel</li>
% <li><b>Duplicate</b> - duplicate the selected action and place it as the
% next step of the protocol</li>
% <li><b>Insert STOP EXECTUTION event</b>, adds a new step (STOP
% EXECTUTION) that stops the protocol allowing to perform any operation
% that can't be implemented with the Batch processing</li>
% <li><b>Move up</b> - move selected action up in the list</li>
% <li><b>Move down</b> - move selected action down in the list</li>
% <li><b>Delete from protocol</b> - delete selected action from the list of
% the protocol steps</li>
% </ul>
% </td>
% </tr>
% <tr>
% <td colspan=2>
% <ul>
% <li><img src="images\menuFileBatchMode_runstep.png" style="vertical-align: text-bottom"> perform the selected step of the protocol</li>
% <li><img src="images\menuFileBatchMode_runstep_advance.png" style="vertical-align: text-bottom"> perform the selected step of the protocol and advance to the next</li>
% <li><b>Listen for MIB actions</b>, when checked automatically detect image processing steps and display them to the Protocol steps panel</li>
% <li><b>Auto add to protocol</b>, when checked automatically detected actions to the list of the protocol steps</li>
% <li><b>Show parameters on click</b>, when checked parameters of the selected action are automatically displated in the Protocol steps panel, 
% otherwise please use the <b>Show settings</b> option in the popup menu, see above</li>
% <li><img src="images\menuFileBatchMode_load_save_delete.png" style="vertical-align: text-bottom"> press the buttons to load, save or delete the protocol. Saving of the protocol is
% also available in the Microsoft Excel format</li>
% <li><b>Undo, Redo</b>, press to undo or redo any recent modification of the protocol</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
% 
%% Protocol steps panel
% Individual steps of the protocol can be modified using this panel. 
%
% <html>
% <ul>
% <li><b>Section</b>, allows to select section with the desired action. Sections are groups of actions, defined mostly by their location 
% within the main GUI of MIB. 
% <br>In addition, there is an extra section
% "Service steps", using this section it is possible to generate loops for
% files or/and directories to load and process images one after another. It
% is important that the LOOP START is followed with LOOP STOP action.
% </li>
% <li><b>Action</b>, allows to select particular action within the list of possible actions of the selected section</li>
% <li><b>Parameters</b> table, displays possible options for each action. Options for the selected parameters are displayed and can be modified 
% using widgets on the right hand of the Parameters table</li>
% <li><b>Update protocol</b>, press of this button updates selected entry in the protocol list with the current Protocol step</li>
% <li><b>Add to protocol</b>, adds current protocol step to the end of the protocol list</li>
% <li><b>Insert into protocol</b>, press to insert current protocol step into highlighed step of the protocol list</li>
% </ul>
% </html>
%
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>