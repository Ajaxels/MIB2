%% Statistics for Mask or Model objects 
% This dialog provides access to statistic values for shapes and intensities for model and mask objects.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_models.html *Models Menu*> *---* <ug_gui_menu_mask.html *Mask Menu*>
% 
%% Parameters and Options
%
%
% <html>
% <table style="width: 800px; border: 0px">
% <tr>
% <td style="border: 0px">
%   <img src = "images\MenuMaskStatistics.png">
% </td>
% <td style="border: 0px">
% <ul>
% <li><b>1. The Objects panel</b> - using combo boxes of this panel it is possible to select material for analysis and type of the dataset: 
% current slice (<em>2D Slice</em>), current Z-stack (<em>3D Stack</em>) or for the whole volume (<em>4D Dataset</em>).<br>
% For the models with more than 255 materials the upper combo box has a 'Model' option. 
% When this option is used, the tool quantifies all materials of the model at once; as result each material is described with a single value</li>
% <li><b>2. The Shape panel</b> - allows selection of type of objects to detect: |2D| or |3D|</li>
% <li><b>3. The Mode panel</b> - when the <em>Object mode</em> is selected the dialog returns
% statistic that is based on shape properties of objects, otherwise (<em>Intensity mode</em>) based
% on image intensities behind the objects</li>
% <li><b>4. Select properties to detect</b>. *Note!* The <em>EndpointsLength</em> requires the objects to be lines with diameter of 1 pixel; in
% addition, the 8/26 connectivity should be selected. See below for available properties to measure</li>
% <li><b>5.</b> Define <b>connectivity parameter</b> that will be used for separation of
% objects. The connectivity |4/6| means that the objects that are touching
% eachother at the corners will be separated into two individual objects</li>
% <li><b>6. The first color channel combobox </b> is used to specify color channel for image intensity analysis</li>
% <li><b>7. The second color channel combobox</b> for correlation intensity analysis</li>
% <li><b>8. The Units combobox</b> specify units for the results: pixels or physical units.
% <b>Important!</b> some parameters can only be calculated in pixels;
% in addition, calculation of certain properties (such as <em>MeridionalEccentricity, EquatorialEccentricity, MajorAxisLength, SecondAxisLength, ThirdAxisLength, EquivDiameter, Surface Area</em>) of 3D objects 
% in physical units is correct only for isotropic voxels</li>
% <li><b>8. The multiple properties checkbox</b> allows detection of several object properties at the same time. The properties can be selected using <b>the Define properties button</b>
% <img src="images\MenuMaskStatisticsMultiple.png"></li>
% <li><b>9. The Statistics table</b> contains calculated values. The objects in this window may be sorted
% (*16.*) or selected. Please press the right mouse button button for a
% context menu with selection parameters:</li>
% </ul>
% <table style="width: 600px; text-align: center; border: 0px;">
% <tr style="font-weight: bold; background-color: #FF9258;">
%   <td style="border: 0px;">Context menu entry</td>
%   <td style="border: 0px;">Description</td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFF4BE;">
%   <td style="font-weight: bold; border: 0px">New selection<br></td>
%   <td style="border: 0px">Makes new selection based on the highlighted objects<br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFF4BE;">
%   <td style="font-weight: bold; border: 0px">Add to selection<br></td>
%   <td style="border: 0px">Adds highlighted objects to the selection<br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFF4BE;">
%   <td style="font-weight: bold; border: 0px">Remove from selection<br></td>
%   <td style="border: 0px">Removes highlighted objects from the selection<br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFCC80;">
%   <td style="font-weight: bold; border: 0px">Copy column(s) to clipboard<br></td>
%   <td style="border: 0px">Copy the content of the highlighted column(s) to the system clipboard<br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFE4BE;">
%   <td style="font-weight: bold; border: 0px">New annotations<br></td>
%   <td style="border: 0px">Makes a new annotation list: adds a label to the selected objects. The annotations can be accessed via <a href="ug_gui_menu_models.html#12">Menu->Models->Annotations</a> or <a href="ug_panel_segm_tools.html#3">Segmentation panel->Selection type->Annotations</a><br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFE4BE;">
%   <td style="font-weight: bold; border: 0px">Add to selection<br></td>
%   <td style="border: 0px">Adds highlighted objects to the annotation list<br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFE4BE;">
%   <td style="font-weight: bold; border: 0px">Remove from annotations<br></td>
%   <td style="border: 0px">Removes highlighted objects from the annotation list<br><br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFF4BE;">
%   <td style="font-weight: bold; border: 0px">Calculate Mean<br></td>
%   <td style="border: 0px">Calculates average value of the highlighted objects and copy it into clipboard<br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFF4BE;">
%   <td style="font-weight: bold; border: 0px">Calculate Sum<br></td>
%   <td style="border: 0px">Calculates sum of the highlighted objects and copy it into clipboard<br></td>
% </tr>
% <tr style="font-weight: normal; background-color: #FFF4BE;">
%   <td style="font-weight: bold; border: 0px">Calculate Min<br></td>
%   <td style="border: 0px">Calculates minimal value of the highlighted objects and copy it into clipboard<br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFF4BE;">
%   <td style="font-weight: bold; border: 0px">Calculate Max<br></td>
%   <td style="border: 0px">Calculates maximal value of the highlighted objects and copy it into clipboard<br></td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFE4BE;">
%   <td style="font-weight: bold; border: 0px">Crop to a file/matlab<br></td>
%   <td style="border: 0px">Crops the dataset based on detected 3D objects.
%   It is possible to add margins during the crop and crop both Model and
%   Mask layers. The results can be saved to a file or exported to
%   Matlab<br><br>
%   <img src="images/MenuMaskStatisticsCropObj.png"><br><br>
%   <ul><b>Parameters</b>
%   <li><b>Target:</b> where to crop the objects</li>
%   <li><b>MarginXY:</b> extend the bounding box around the object by the specified number of pixels</li>
%   <li><b>MarginZ:</b> extend the bounding box around the object by the specified number of pixels in the Z dimension</li>
%   <li><b>Crop Model:</b> also include cropping of the model</li>
%   <li><b>Crop Mask:</b> also include cropping of the mask</li>
%   <li><b>Single Mask object per dataset:</b> keep only a main object in the crop of the Mask, enabled only when the objects were identified from the mask layer</li>
%   </ul>
%   <br>
%   <ul>The data is exported to Matlab as a structure
%   [Filename_IndexOfTheObject] with the following fields:
%   <li><b>.img</b> - cropped image [1:height, 1:width, 1:colors, 1:stacks]</li>
%   <li><b>.meta</b> - meta data for the cropped image [1:height, 1:width, 1:colors, 1:stacks]</li>
%   <li><b>.Model</b> - a structure with the Model, including <em>.model, .modelMaterialNames, .modelMaterialColors</em> fields</li>
%   <li><b>.labelText</b> - cell array with annotations</li>
%   <li><b>.labelPosition</b> - a matrix with coordinates for the annotations [z, x, y]</li>
%   <li><b>.Mask</b> - a matrix with the Mask layer [1:height, 1:width, 1:stacks] that corresponds to the cropped image</li>
%   </ul>
%   The exported data can be imported back to MIB using the
%   <code>Menu->File->Import image from...->Matlab</code> and providing variables to
%   import, for example <em>Filename_IndexOfTheObject.img</em> and
%   <em>Filename_IndexOfTheObject.meta</em>.<br>
%   Or for the Model:
%   Menu->Models->Import model from Matlab-> and providing variable with
%   the model, for example <em>Filename_IndexOfTheObject.Model</em>.
%   </td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFE4BE;">
%   <td style="font-weight: bold; border: 0px">Objects to a new model<br></td>
%   <td style="border: 0px">Generate a new model, where each of the selected objects will be assigned to an own index<br>
%       <a href="https://youtu.be/xZhuv659JrY"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/xZhuv659JrY</a>
% </td>
% </tr>
% <tr style="font-weight: normal;background-color: #FFE4BE;">
%   <td style="font-weight: bold; border: 0px">Plot histogram<br></td>
%   <td style="border: 0px">Draws a histogram bar plot from the selected data<br></td>
% </tr>
% </table>
% </td>
% </tr>
% </table>
% </html>
%
% 
% * *10. A histogram plot* that shows distribution of statistic parameters
% from *8.*. The plot may be shown on a normal or logarithmic scale
% depending on selection of the |Log scale| check box (*13.*). Clicks with the left and
% right mouse allows to make selections. 
% * *11. The Auto highlight on a click checkbox* - when checked, each time
% the object in the table (*8.*) is selected it is highlighted in the Image
% View panel.
% * *12. The Sorting combobox* can be used to change the sorting of the main table.
% * *13. The Log scale checkbox* is for showing the histogram (*8.*) in the logarithmic scale.
% * *14.* Two edit boxes are used to provides minimal and maximal values for highlighting after press of the |Do| button.
% * *15. The Run button* starts quantification.
% * *16. The Details panel* defines a way of object selection: the selected
% objects may be added, removed or used for replacement of the |Selection|
% layer.
% * *17. The Export button* allows export of the statistic values to Excel or
% Matlab.
%
%
%% Statistical properties of 3D objects
% Calculate properties of 3D objects of the dataset.
%
% * *Area* - calculates total number of pixels (~volume) within the 3D objects.
% * *Endpoints Length* - calculates the distance between two end points of a *line* segment. Please note that the width of the line
% should be 1. It is recommended to use <ug_panel_segm_tools.html Membrane ClickTracker tool> in the <ug_panel_segm.html Segmentation panel> with the option |Straight line| and Width=1.
% *Note!* The resulting numbers are calculated in the image units.
% * *EquatorialEccentricity* - returns the Equatorial Eccentricity, defined
% as the eccentricity of the section through the second longest and the
% shortest axes. The resulted values between 1 (line) and 0 (sphere)
% * *FilledArea* - calculates total number of pixels (~volume) within the filled 3D objects.
% * *Holes Area* - finds cavities within 3D objects and calculate their total number of pixels (~volume).
% * *MajorAxisLength* - returns the length of the major axis in pixels
% * *MeridionalEccentricity* - returns Meriodional Eccentricity, defined as the eccentricity of the section through the longest and the shortest axes
% * *SecondAxisLength* - returns the length of the second major axis in pixels
% * *ThirdAxisLength* - returns the length of the minor axis in pixels
%
%% Statistical properties of 2D objects
%
% Calculate properties of 3D objects of the dataset.
%
% * *Area* - calculates total number of pixels within the 2D objects.
% * *ConvexArea* - calculates total number of pixels of the smallest convex polygon that can contain the object.
% * *CurveLengthInPixels* - calculate the length of curve objects in pixels. It is possible to measure the length of both closed and non-closed curves. 
% *Please note!* It is required that the curves are thinned (|Menu->Selection->Morphological operations|) and the branch
% points are removed (The branch points may be found by selecting material and run |branch point| detection, Menu->Selection->Morphological operations|).
% * *CurveLengthInUnits* - calculates the length of curved objects in physical units of the dataset. It is possible to measure the length of both closed and non-closed curves. 
% *Please note!* It is required that the curves are thinned (|Menu->Selection->Morphological operations|) and the branch
% points are removed (The branch points may be found by selecting material and run |branch point| detection, Menu->Selection->Morphological operations|). 
% * *Eccentricity* - calculates eccentricity of the ellipse that has the same second-moments as the object. 
% The eccentricity is the ratio of the distance between the foci of the ellipse and its major axis length. The value is between 0 and 1.
% (0 and 1 are degenerate cases; an ellipse whose eccentricityis 0 is actually a circle, while an ellipse whose eccentricity is 1 is a line segment.)
% * *Endpoints Length* - calculates the distance between two end points of a *line* segment. Please note that the width of the line
% should be 1. It is recommended to use <ug_panel_segm_tools.html Membrane ClickTracker tool> in the <ug_panel_segm.html Segmentation panel> with the option |Straight line| and Width=1.
% If the lines were drawn with the |Brush| tool they have to be thinned. The thinning may be achieved with the |Brush tool| size 1 or/and Thinning the objects using
% |Menu->Selection->Morphological 2D operations->Thin|. *Note!* The resulting numbers are calculated in the image units.
% * *EquivDiameter* - calculates the diameter of a circle with the same area as the object. Computed as |sqrt(4*Area/pi)|.
% * *EulerNumber* - calculates the number of objects in the region minus the number of holes in those objects, _i.e._ the
% object with 1 hole has the Euler number 0, while the object with 2 holes has the Euler number -1.
% * *Extent* - calculates the ratio of pixels in the object to pixels in the total bounding box. Computed as the Area divided by the area of the bounding box.
% * *FirstAxisLength* - length of the major 2D axis of the object, in contrast to |MajorAxisLength| this property returns the real length of the object rather than that for the ellipse
% * *FilledArea* - calculates the number of pixels of the filled object.
% * *Holes Area* - finds holes and calculates total number of pixels within them.
% * *MajorAxisLength* - calculates the length (in pixels) of the major axis of the ellipse that has the same normalized second
% central moments as the object.
% * *MinorAxisLength* - calculate the length (in pixels) of the minor axis of the ellipse that has the same normalized second central moments as the object. 
% * *Orientation* - calculates the angle (in degrees ranging from -90 to +90 degrees) between the x-axis and the major axis of
% the ellipse that has the same second-moments as the object.
% * *Perimeter* - calculates the distance around the boundary of the object. It is computed as the perimeter by calculating the 
% distance between each adjoining pair of pixels around the border of the region
% * *SecondAxisLength* - length of the minor 2D axis of the object, in contrast to |MinorAxisLength| this property returns the real length of the object rather than that for the ellipse
% * *Solidity* - calculates the proportion of the pixels in the convex hull that are also in the object. Computed as
% |Area/ConvexArea|.
%
%% Statistical properties of intensities of 2D/3D objects
%
% These properties are calculated when the Intensity radio button in the Mode panel (*3.*) is selected.
%
% * *MinIntensity* - detects minimal value of the image intensity within 2D or 3D objects.
% * *MaxIntensity* - detects maximal value of the image intensity within 2D or 3D objects.
% * *MeanIntensity* - calculates average intensity of the image within 2D or 3D objects.
% * *StdIntensity* - calculates standard deviation intensity of the image within 2D or 3D objects.
% * *SumIntensity* - calculates sum of the image intensities within 2D or 3D objects.
% * *Correlation* - calculates correlation between image intensities of the two selected color channels. See more in the help
% of Matlab |corr2| function.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_models.html *Models Menu*> *---* <ug_gui_menu_mask.html *Mask Menu*>
%


