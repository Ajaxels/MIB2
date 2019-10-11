%% Fiji Connect Panel
% Allows communication with <http://fiji.sc/Fiji Fiji>. Requires Fiji to be installed, please refer to the 
% <im_browser_system_requirements.html System Requirements> section for
% details. *Fiji Connect* uses
% <http://bigwww.epfl.ch/sage/soft/mij/ MIJ> , a Java package for bi-directional communication and data exchange from Matlab to ImageJ/Fiji,
% developed by Daniel Sage, Dimiter Prodanov, Jean-Yves Tinevez and Johannes Schindelin. This package should be integrated into
% Fiji.
% 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%%
% 
% <<images\PanelsFiji.png>>
% 
%% Video tutorial
%
% <html>
% Detailed demonstration on data exchange between MIB and Fiji can be seen
% in a video tutorial:<br>
% <a
% href="https://youtu.be/DZ1Tj3Fh2HM?list=PLGkFvW985wz8cj8CWmXOFkXpvoX_HwXzj">Visualization of datasets and models using Fiji <img
% src="images\youtube2.png"></a>
% </html>
%
%% 1. The Start Fiji button
% Start an instance of Fiji by pressing this button. In order for communication between Matlab and Fiji to work, Fiji 
% should be started from Matlab using this button. *_Press this button before doing anything else!_*
%
%% 2. The Stop Fiji 
% After finishing work, Fiji may be stopped using this button. Press it at the end use of Fiji.
%% 3. The Image Type combo box
% The combo box defines type of the layer that should be exchanged with Fiji. For example, selection of the |image| entry in
% this menu allows to send the the currently opened image to Fiji after press of the |Export| button (*4*). 
% See _Example: Finding Edges using Fiji_ below for details.
%% 4. The Export button
% Press of this button sends the currently opened dataset (|Image|, |Model|, |Mask|, |Selection|, depending on settings in the 
% |Image type| combo box *3*) to Fiji.
%% 5. The Import button
% The |Import| button allows to transfer datasets from Fiji to
% |MIB|. The dataset can be imported as |Image|, |Model|, |Mask|, or
% |Selection| layer, set the distination using the Image Type combo box (*3.*). It is important that the size of the |Model|, |Mask|, |Selection| 
% layers should match the size of the opened in |MIB| |Image| layer.
%% 6. The Run macro edit box
% It is possible to run a macro on Fiji. For that please type a macro command into this edit box. A template for the command
% is shown in the edit box by default. The command |run('Flip Z')| will Flip the Z-dimension of the selected in Fiji dataset.
% The execution of the macro is called by pressing the |Run| button (*8*).
%
% The syntax for the macro command can be obtained from the corresponding reference page of <http://fiji.sc/Miji Miji>.
%
% It is also possible to provide a list of macros in a filename in text format. In this case please enter a path to such file
% into this field. The file can be also selected using the |Select file...| button (*7*)
%% 7. The |Select file...| button
% It is possible to provide list of macro commands to use with Fiji. Press of this button allows selecting of such files. The
% execution of the script is done by pressing the |Run| button (*8*)
%% 8. The Run button
% Execute a macro written in the |Run macro| edit box (*6*). When edit box has a path to a text file with a set of macros the
% |Run| button loads that file and executes all the macros written in that script file.
%% 9. The Help button
% Access to the help page.
%% Example: Finding Edges using Fiji
% Assuming that Fiji is installed and configured... 
%
% Let's try to use _Fiji Find Edges_ function with a 3D grayscale dataset to find edges and generate a binary mask out of
% them.
% The test dataset can be obtained from <http://www.biocenter.helsinki.fi/~ibelev/projects/im_browser/tutorials/3D_Modelling_files/Huh7.tif here>
%
% # Open a dataset for tests
% # Press the |Start Fiji| button to open an instance of Fiji
% # If you want to send the opened image to Fiji, select |image| in the |Image Type| combo box and press the |Export| button
% # In a appearing dialog enter name for the dataset to be used in Fiji
% # Find edges: |Fiji->Menu->Process->Find Edges|
% # Generate binary image from the edges: |Fiji->Menu->Image->Adjust->Auto Threshold|, set the |Method| to |Mean|, and check
% the |Stack| check box. Press |OK| to do thresholding
% # In |MIB| select |Fiji Connect->Image Type->mask| and press the |Import| button
% # Now |MIB| should have a new |Mask| layer imported from Fiji
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>