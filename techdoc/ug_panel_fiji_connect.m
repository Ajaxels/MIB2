%% Fiji Connect Panel
% The *Fiji Connect Panel* is a feature that allows communication with <http://fiji.sc/Fiji Fiji>, an image processing software. 
% To use the Fiji Connect Panel, you need to have Fiji installed on your system. The Fiji Connect Panel utilizes a Java package 
% called <http://bigwww.epfl.ch/sage/soft/mij/ MIJ> for bi-directional communication and data exchange between MATLAB and ImageJ/Fiji.
%
% MIJ was developed by Daniel Sage, Dimiter Prodanov, Jean-Yves Tinevez, and Johannes Schindelin. 
% It is important to ensure that the MIJ package is integrated into your Fiji installation 
% for the Fiji Connect Panel to function properly. Please refer to the 
% <im_browser_system_requirements.html System Requirements> section for
% details.
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
% href="https://youtu.be/DZ1Tj3Fh2HM?list=PLGkFvW985wz8cj8CWmXOFkXpvoX_HwXzj"><img
% src="images\youtube2.png"> Visualization of datasets and models using Fiji</a>
% </html>
%
%% 1. The [class.kbd]Start Fiji[/class] button
% The [class.kbd]Start Fiji[/class] button is used to start an instance of Fiji from MATLAB. 
% It is necessary to start Fiji from MATLAB in order for communication between MATLAB and Fiji to work.
% *_Before performing any other actions, press this button to start Fiji!_*
%
%% 2. The [class.kbd]Stop Fiji[/class] button 
% The [class.kbd]Stop Fiji[/class] button is used to stop Fiji after you have finished your work. 
% Press this button at the end of your Fiji usage to properly close Fiji
%
%% 3. The [class.dropdown]Image Type &#9660;[/class] dropdown
% The [class.dropdown]Image Type &#9660;[/class] dropdown allows you to define the type of layer that should be exchanged with Fiji. 
% For example, if you select the [class.dropdown]Image &#9660;[/class] entry in this menu, you can send the currently opened image to Fiji 
% by pressing the [class.kbd]Export[/class] button. This dropdown allows you to specify the type of data you want to exchange with Fiji. 
%
% For more details on how to use this feature, you can refer to the section titled *Finding Edges using Fiji* below.
%
%% 4. The [class.kbd]Export[/class] button
%
% The [class.kbd]Export[/class] button is used to send the currently opened dataset (Image, Model, Mask, Selection) to Fiji. 
% The specific type of dataset that is sent depends on the settings in the [class.dropdown]Image Type &#9660;[/class] dropdown. 
% Pressing [class.kbd]Export[/class] will transfer the selected dataset to Fiji for further processing or analysis
%
%% 5. The [class.kbd]Import[/class] button
%
% The [class.kbd]Import[/class] button allows you to transfer datasets from Fiji to MIB. 
% You can import datasets to the Image, Model, Mask, or Selection layers. The destination for the 
% imported dataset can be set using the [class.dropdown]Image Type &#9660;[/class] dropdown. It is important 
% to ensure that the size of the Model, Mask, and Selection layers match the size of the Image 
% layer that is opened in MIB.
%
%% 6. The [class.dropdown]Run macro[/class] edit box
%
% The [class.dropdown]Run macro[/class] edit box allows you to run a macro on Fiji. You can type a macro command into this edit box. 
% By default, a template for the command is shown in the edit box. For
% example, the command [class.code]"run('Flip Z')"[/class]
% will flip the Z-dimension of the selected dataset in Fiji. Press the [class.kbd]Run[/class] button to execute the macro command.
%
% You can obtain the syntax for the macro command from the corresponding reference page of <http://fiji.sc/Miji Miji>. 
% Additionally, you can provide a list of macros in a filename in text format. In this case, enter 
% the path to the file into the [class.dropdown]Run macro[/class] edit box or use the [class.kbd]Select file...[/class] button
% to choose the file.
%
%% 7. The [class.kbd]Select file...[/class] button
%
% The [class.kbd]Select file...[/class] button allows you to choose a file that contains a list of macro commands 
% to use with Fiji. Pressing this button opens a file selection dialog where you can browse and select the desired file. 
% This file can contain multiple macro commands that will be executed when
% you press the [class.kbd]Run[/class] button. 
% 
% You can obtain the syntax for the macro command from the corresponding reference page of <http://fiji.sc/Miji Miji>
%    
%% 8. The [class.kbd]Run[/class] button
%
% The [class.kbd]Run[/class] button is used to execute a macro written in the [class.dropdown]Run macro[/class] edit box.
% If the edit box contains a path to a text file with a set of macros, the [class.kbd]Run[/class] button will load that 
% file and execute all the macros written in that script file. Pressing this button triggers 
% the execution of the macro commands and performs the desired actions in Fiji.
%
%% 9. The [class.kbd]Help[/class] button
% The [class.kbd]Help[/class] button provides access to the help page. 
% Clicking on this button will open the help documentation, where you can find detailed information and 
% instructions on how to use the various features and functions of the software
%
%% Example: Finding Edges using Fiji
% This example demonstrates how to use the Fiji software to find edges in a 3D grayscale dataset and generate 
% a binary mask from them. 
%
% [dtls][smry] *Assuming that Fiji is installed and configured correctly, you can follow these steps* [/smry]
%
% # The test dataset can be obtained from [class.code]Menu->File->Example datasets->SBEM->Huh7 and model[/class]
% # Open a dataset for tests
% # Press [class.kbd]Start Fiji[/class] to open an instance of Fiji
% # If you want to send the opened image to Fiji, select |image| in the [class.dropdown]Image Type &#9660;[/class] dropdown 
% and press the [class.kbd]Export[/class] button
% # In a appearing dialog enter name for the dataset to be used in Fiji
% # Find edges: [class.code]Fiji->Menu->Process->Find Edges[/class]
% # Generate binary image from the edges: [class.code]Fiji->Menu->Image->Adjust->Auto Threshold[/class], set the |Method| to |Mean|, 
% and check the [class.kbd][&#10003;] *Stack*[/class] check box. Press [class.kbd]OK[/class] to do thresholding
% # In |MIB| select [class.code]Fiji Connect->Image Type->mask[/class] and press the [class.kbd]Import[/class] button
% # Now |MIB| should have a new |Mask| layer imported from Fiji
%
% [/dtls] 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #fff; 
% 	background-color: #e0f5ff; 
% 	background-color: #e8f5e8; 
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