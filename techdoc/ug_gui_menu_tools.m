%% Tools Menu
% Additional tools 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
%%
% 
% <<images\menuTools.png>>
% 
%% Measure length
% Allows measuring the length on the image.
%
% [class.h3]Measure Tool[/class]
%
% Measure Tool of MIB is based on <http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility Image Measurement Utility>
% written by Jan Neggers, Eindhoven Univeristy of Technology. Using this
% tool it is possible to perform number of different length measurements and generate intensity profiles that correspond to these measurements.
% <ug_gui_menu_tools_measure.html Press here for details>.
% 
%
% [class.h3]Line measure[/class]
%
% Measures the linear distance between two points. Press and hold left mouse
% button to draw a line that connects two object. The result will be shown
% in the pop-up and MATLAB main window. Also the length of the measurement is copied to the system clipboard and can be pasted using the |Ctrl+V| key shortcut.
% The linear measuring tool can also be called from the <ug_gui_toolbar.html toolbar>. The pixel sizes are
% defined in the <ug_gui_menu_dataset.html Dataset parameters>.
%
% [class.h3]Free hand measure[/class]
%
% Similar to the line measure tool, except that the measured distance can
% be drawn arbitrarily.
%
% 
%% Deep learning segmentation
% The deep learning tool provides access to training of deep convolutional
% networks over the user data and utilization of those networks for image
% segmentation tasks.
% 
% Please refer to the corrsponding section for details: <ug_gui_menu_tools_deeplearning.html click here>.
%
%% Classifiers
% In this section MIB has two classifiers. One is designed for membrane
% detection but works for other objects as well. The second classifier is
% based on SLIC superpixels/supervoxels for the classification. 
%
% 
% * *Membrane detection*, a method for automatic segmentation of images using Random Forest
% classifier. The current version of the classifier is based on 
% <http://www.kaynig.de/demos.html Random Forest for Membrane Detection by Verena Kaynig> 
% and utilize <https://code.google.com/p/randomforest-matlab/ randomforest-matlab> by Abhishek Jaiantilal.
% Please refer to the <ug_gui_menu_tools_random_forest.html help section> of the corresponding
% function.
% * *Superpixels classification*, is good for objects that have distinct
% intensity properties. In this method, MIB first calculates SLIC
% superpixels for 2D or supervoxels for 3D and classify them based on set
% of provided labels that mark object of interest and the background. <ug_gui_menu_tools_random_forest_superpixels.html See
% more in this example>.
% 
%
%% Semi-automatic segmentation
% Methods for automated image segmentation and object separation. 
%
%
% * <ug_gui_menu_tools_global_thresholding.html *Global thresholding*>
% * <ug_gui_menu_tools_graphcut.html *Graphcut segmentation* (_recommended_)>
% * <ug_gui_menu_tools_watershed.html *Watershed segmentation*>
% 
% [dtls][smry] *Graphcut and watershed example* [/smry]
%
% <<images\menuToolsGraphcutWatershed.jpg>>
%
% [/dtls]
% [br8]
%
%% Object separation
% Tools for separation of objects that can be as materials of the current
% model, the mask or selection layers.
%
% * <ug_gui_menu_tools_objseparation.html *Object separation*>
%
% [dtls][smry] *Example of seeded watersheding of cells* [/smry]
% 
% <<images/menuToolsWatershedExample.jpg>>
%
% [/dtls]
% [br8]
%
%% Stereology
% The stereology tool of MIB counts number of intersections between materials of the opened
% model and the grid lines. The spacing between grid lines can be defined
% in pixels or in the image units. The results of the stereology analysis
% can be exported to MATLAB or Microsoft Excel.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/5gOiyVNr2vY"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/5gOiyVNr2vY</a>
% </html>
% 
%
% [dtls][smry] *Details and parameters* [/smry]
%
% <<images\menuToolsStereology.png>>
% 
% To calculate the grid use the |Generate| button in the |Grid options
% panel|. The analysis is started by pressing the |Do stereology| button. 
%
% The [class.kbd][&#10003;] *Include annotations*[/class] checkbox is selected the Stereology tool also 
% calculates occurances of the annotation labels (Segmentation Panel->Annotations tool)
%
%
% *Important note!* When the thickness of the grid is 1 pixel (the |grid extra thickness is
% 0|) the grid may not be shown properly at the magnifications that are
% lower than 100%. To see the grid also at low magnification, increase the
% |extra grid thickness| value.
%
% [/dtls]
% [br8]
%
%% Wound healing assay
% The wound healing assay is designed to measure migration parameters of
% cells. It was tested on Imagen Cell-IQ platform that allows to obtain a
% grid of images taken with 0-pixel overlaps
%
% <html>
% A demonstration is available in the following video:<br>
% <a href="https://youtu.be/D9hvyXMyNfU"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/D9hvyXMyNfU</a>
% </html>
% 
% <<images\menuToolsWoundHealing.png>>
% 
%
% [dtls][smry] *Details and parameters* [/smry]
%
% The tool has two parts:
% 
% <html>
% <table style="width: 750px; text-align: center;" cellspacing=2px cellpadding=2px >
% <tr>
%   <td style="width=250px;"><b>Stitching</b></td>
%   <td>
%   <ul>
%   <li>Use the Stitching settings panel to specify number of cells in a
%   grid; each cell defined by an own directory with images. The directory
%   names have to be in a sequence starting from upper-left corner and
%   progressing horizontally to the bottom-right corner</li>
%   <li>Specify filename extension</li>
%   <li>Select direcotries with the grid images for stitching (the
%   <em>Select directories...</em> button)</li>
%   <li>Specify the output directrory for results (The <em>Output...</em> button)</li>
%   <li>Press the <em>Stitch</em> button to start stitching</li>
%   </ul>
%   </td>
% </tr>
% <tr>
%   <td><b>Wound healing analysis</b></td>
%   <td>
%   <ul>
%   <li>Populate the <em>Wound healing settings</em> panel: set the pixel size, time step and optional downsampling of resulting images for evaluation. 
% When the <span class="kbd">[&#10003;] <b>show interactive graph</b></span> checkbox is checked, the tool will generate an interactive plot with results after each time point</li>
%   <li>Select directories with the stitched images for the wound healing
%   assay (the <em>Select directories...</em> button)</li>
%   <li>Press the <em>Wound healing</em> button to start</li>
%   </ul>
%   </td>
% </tr>
% <tr>
% <td></td>
% <td><b>Results:</b><br>
% <ul>
%   <li>A plot showing minimal, average and maximal width of the wound</li>
%   <li>A sheet in Microsoft Excel format and a file in MATLAB format with the wound width values</li>
%   <li>A directory with snapshots of the detected wound</li>
%   <li>A text file with time stamps of the original images used during
%   stitching</li>
%   </ul>
% </td>
% </tr>
% <tr>
% <td><b>Reference</b></td>
% <td>The function is based on a Cell Migration in Scratch Wound Assays code provided by 
% Constantino Carlos Reyes-Aldasoro (<a
% href="https://se.mathworks.com/matlabcentral/fileexchange/67932-cell-migration-in-scratch-wound-assays">see more</a>)<br>
%     <b>Cite as</b><br>
%     CC Reyes-Aldasoro, D Biram, GM Tozer, C Kanthou
%     Electronics Letters 44 (13), 791-793<br><br>
%     The code is also available from github: <a
%     href="">https://www.github.com/reyesaldasoro/Cell-Migration</a>
% </td>
% </tr>
% </table>
% </html>
%
% [/dtls]
% [br8]
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
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
