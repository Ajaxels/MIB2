%% Tools Menu
% Additional tools 
% 
% <<images\menuTools.png>>
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
%% Measure length
% Allows measuring the length on the image.
%
% *Measure Tool*
%
% Measure Tool of MIB is based on <http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility Image Measurement Utility>
% written by Jan Neggers, Eindhoven Univeristy of Technology. Using this
% tool it is possible to perform number of different length measurements and generate intensity profiles that correspond to these measurements.
% <ug_gui_menu_tools_measure.html Press here for details>.
% 
%
% *Line measure*
%
% Measures the linear distance between two points. Press and hold left mouse
% button to draw a line that connects two object. The result will be shown
% in the pop-up window and the line that connects the two selected points
% will be added to the |Selection| layer. Press |Ctrl+Z| to undo the
% modification of the |Selection| layer or press |C or Shift+C| to clear the |Selection| layer.
% The linear measuring tool can also
% be called from the <ug_gui_toolbar.html toolbar>. The pixel sizes are
% defined in the <ug_gui_menu_dataset.html Dataset parameters>.
%
% *Free hand measure*
%
% Similar to the line measure tool, except that the measured distance can
% be drawn arbitrarily.
%
% 
%
%% Stereology
% The stereology tool of MIB counts number of intersections between materials of the opened
% model and the grid lines. The spacing between grid lines can be defined
% in pixels or in the image units. The results of the stereology analysis
% can be exported to Matlab or Microsoft Excel.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/5gOiyVNr2vY"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/5gOiyVNr2vY</a>
% </html>
% 
% <<images\menuToolsStereology.png>>
% 
% To calculate the grid use the |Generate| button in the |Grid options
% panel|. The analysis is started by pressing the |Do stereology| button. 
%
% The include annotations checkbox is selected the Stereology tool also 
% calculates occurances of the annotation labels (Segmentation Panel->Annotations tool)
%
%
% *Important note!* When the thickness of the grid is 1 pixel (the |grid extra thickness is
% 0|) the grid may not be shown properly at the magnifications that are
% lower than 100%. To see the grid also at low magnification, increase the
% |extra grid thickness| value.
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
%% Watershed/Graphcut segmentation
% Two methods for automated image segmentation and object separation. Both
% methods available for both 2D and 3D objects.
%
% <ug_gui_menu_tools_watershed.html *SEE DETAILS HERE*>
% 
% <<images/menuToolsWatershed.png>>
% 
% Example of seeded watersheding of cells:
%
% 
% <<images/menuToolsWatershedExample.jpg>>
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
