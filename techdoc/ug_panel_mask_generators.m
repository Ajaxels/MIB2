%% Mask Generators panel
% The Mask Generators panel is a feature that provides several methods for automatic mask generation. It allows users to generate masks automatically based on specific criteria or algorithms. 
% These masks can then be used for various purposes, such as segmentation or selecting specific areas of interest
% (<ug_gui_data_layers.html see more about masks>)
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
%% Common fields
%
% There are several common fields that do not depend on type of the selected mask
% generator.
%
% <<images\PanelsMaskGeneratorCommon.jpg>>
% 
% * 1. The [class.dropdown]Filter type &#9660;[/class], allows to select one of the possible mask
% generators
% * 2. The [class.kbd]&#9673; *Mode*[/class] radio buttons:
%
%
% <html>
% <ul style="position:relative; left:35px;">
% <li><span class="kbd">&#9673; <b>current</b></span>, this mode generates a mask specifically for the currently shown slice. It focuses on the selected slice and creates a mask based on the criteria or algorithm chosen</li>
% <li><span class="kbd">&#9673; <b>2D all</b></span>, in this mode, the mask is generated for the whole dataset using the 2D approach. It generates masks slice by slice, considering each slice individually</li>
% <li><span class="kbd">&#9673; <b>3D</b></span>, this mode generates a mask for the entire dataset using the 3D approach. It takes into account the entire volume of the dataset to create a comprehensive mask</li>
% </ul>
% </html>
%
% 3. The [class.kbd]Do it[/class] button:
%
%
% <html>
% <ul style="position:relative; left:35px;">
% <li><b>the left mouse click</b>, on the button starts the selected generator. The existing mask will be deleted</li>
% <li><b>right mouse click + Do new mask</b>, starts the selected generator. The existing mask will be deleted<br>
% <img src="images\PanelsMaskGeneratorDropdown.png"></li>
% <li><b>right mouse click + Generate new mask and add it to the existing mask</b>, the generated mask will be added to the existing mask.
% This option may be used for multi-dimensional filtering:
% <ol>
% <li>run Generator for XY</li>
% <li>Change dimension by pressing |'XZ'| or |'YZ'| button in the Toolbar</li>
% <li>Run Generator again with the |Generate new mask and add it to the existing mask| option</li>
% </ol>
% </li>
% </ul>
% </html>
%
%
%% Frangi Filter
% <http://www.mathworks.com/matlabcentral/fileexchange/24409-hessian-based-frangi-vesselness-filter
% Hessian based Frangi Vesselness filter>, written by Marc Schrijver and Dirk-Jan Kroon. This 
% function uses the eigenvectors of the Hessian to compute the likeliness 
% of an image region to contain vessels or other image ridges, 
% according to the method described by Frangi <http://www.dtic.upf.edu/~afrangi/articles/miccai1998.pdf 1998>, <http://www.tecn.upf.es/~afrangi/articles/tmi2001.pdf 2001>.
%
% *Note*, to work properly this function should be compiled. See details in
% <im_browser_system_requirements.html System Requirements>
% 
% <<images\PanelsMaskGeneratorFrangi.png>>
%
% [dtls][smry] *Parameters:* [/smry]
%
% * *Range*, the range of sigmas used, default [1-6]
% * *Ratio*, step size between sigmas, default [2]
% * *beta1*, the Frangi correction constant, default [0.9]
% * *beta2*, the Frangi correction constant, default [15]
% * *beta3*, the Frangi vesselness constant which gives the threshold between eigenvalues of noise and vessel structure. A thumb rule is dividing the the greyvalues of the vessels by 4 till 6, default [500];
% * *B/W threshold*, defines thresholding parameter for generation of the
% |Mask| layer. When set to 0 results in the filtered instead of binary
% image.
% * *Object size limit*, after the run of the Frangi filter removes all
% 2D objects that are smaller than this value.
% * [class.kbd][&#10003;] *Black on white*[/class] checkbox, if checked, detects black ridges on white background.
%
% [/dtls]
%
%% Morphological filters
% Set of MATLAB based morphological filters.
% 
% <<images\PanelsMaskGeneratorMorphFilters.png>>
%
% * *Extended-maxima transform* - based on |imextendedmax| function of
% MATLAB. Computes the extended-maxima transform, which is the regional maxima of the H-maxima transform. 
% Regional maxima are connected components of pixels with a constant intensity value, and whose external boundary pixels all have a lower value.
%%
% 
% <<images\PanelsMaskGeneratorMorphFiltersExtMaxTrans.jpg>>
% 
%
% * *Extended-minima transform* - based on |imextendedmin| function of
% MATLAB. Computes the extended-minima transform, which is the regional minima of the H-minima transform. Regional minima are connected components of pixels with a constant intensity value, and whose external boundary pixels all have a higher value.
%%
% 
% <<images\PanelsMaskGeneratorMorphFiltersExtMinTrans.jpg>>
% 
% * *H-maxima transform* - suppresses all maxima in the intensity image whose height is less than H-value. 
% Regional maxima are connected components of pixels with a constant intensity value, and whose external 
% boundary pixels all have a lower value. The resulting image is then
% thresholded using the provided |Threshold| value.
% 
% <<images\PanelsMaskGeneratorMorphFiltersHMaxTrans.jpg>>
%
% * *H-minima transform* - suppresses all minima in the grayscale image whose depth is less than H-value. 
% Regional minima are connected components of pixels with a constant intensity value (t) whose external boundary pixels all have a value greater than t. 
% The resulting image is then thresholded using the provided |Threshold| value.
%
% * *Regional maxima* - based on |imregionalmax| function of MATLAB. Returns the binary mask that identifies the locations of the regional 
% maxima in the image. In mask, pixels that are set to 1 identify regional
% maxima; all other pixels are set to 0. Regional maxima are connected components of pixels with a constant intensity value, and whose external boundary pixels all have a lower value.
%
% * *Regional minima* - based on |imregionalmin| function of MATLAB. The output binary mask has value 1 corresponding to the pixels of the image
% that belong to regional minima and 0 otherwise. Regional minima are connected components of pixels with a constant intensity value, and whose external boundary pixels all have a higher value. 
%
%
%% Strel Filter
% Generate mask based on morphological image opening and black-and-white
% thresholding. The function first performs morphological bottom-hat ([class.kbd][&#10003;] *Black on white*[/class] is checked)
% or top-hat ([class.kbd][&#10003;] *Black on white*[/class] is unchecked) filtering of the image. 
% The top-hat filtering computes the morphological opening of the image (using |imopen|)
% and then subtracts the result from the original image. The result is then
% black and white thresholded with parameter in the [class.dropdown]B/W threshold[/class] edit box.
%
% <<images\PanelsMaskGeneratorStrel.png>>
%
% # *Strel size*, defines size of the structural element (|disk| type) for |imtophat| and |imbothat|
% filtering. 
% # The [class.kbd][&#10003;] *Fill*[/class] checkbox, check it to fill holes in the resulted |Mask| image.
% # *B/W threshold*, specifies parameter for the black and white thresholding.
% # *Size limit*, limits the size of generated 2D objects so that objects smaller than this value are removed from the |Mask| during the
% filter run.
% # The [class.kbd][&#10003;] *Black on white*[/class] checkbox, when checked, the filter will use morphological bottom-hat filtering
% (|imbothat|). When unchecked - morphological top-hat filtering (|imtophat|).
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%%
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