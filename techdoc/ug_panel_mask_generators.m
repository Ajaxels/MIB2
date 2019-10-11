%% Mask Generators panel
% This panel hosts several ways of automatic mask generation. Specific areas of interest from the generated mask may 
% further be selected for segmentation. <ug_gui_data_layers.html See more about masks>.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%% Common fields
% There are several common fields that do not depend on type of the selected mask
% generator.
%
% <<images\PanelsMaskGeneratorCommon.jpg>>
% 
% * 1. The *Filter type* combo box, allows to select one of the possible mask
% generators
% * 2. The *Mode* radio buttons:
%
%
% <html>
% <ul style="position:relative; left:35px;">
% <li><b>current</b>, generate mask for the currently shown slice;</li>
% <li><b>2D all</b>, generate mask for the whole dataset using the 2D mode,
% <em>i.e.</em> slice by slice;</li>
% <li><b>3D</b>, generate mask for the whole dataset using the 3D mode;</li>
% </ul>
% </html>
%
% the whole dataset in the 2D mode, _i.e._ slice by slice; _3D_ use the 3D mode for the mask generation
%
% 3. *Do it* button:
%
%
% <html>
% <ul style="position:relative; left:35px;">
% <li> 
% -<b>left mouse click</b>, starts the selected generator. The existing mask will be deleted.
% </li>
% <li> 
% -<b>right mouse click + Do new mask</b>, starts the selected generator.
% The existing mask will be deleted.
% </li>
% <li> 
% -<b>right mouse click + Generate new mask and add it to the existing mask</b>, the generated mask will be added to the existing mask.
% This option may be
% used for multi-dimensional filtering: 1. run Generator for XY; 2. Change
% dimension by pressing |'XZ'| or |'YZ'| button in the Toolbar; 3. Run Generator again with the |Generate new mask and add it to the existing mask| option.
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
% *Parameters:*
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
% * *Black on white* checkbox, if checked, detects black ridges on white background.
%
%% Morphological filters
% Set of Matlab based morphological filters.
% 
% <<images\PanelsMaskGeneratorMorphFilters.png>>
%
% * *Extended-maxima transform* - based on |imextendedmax| function of
% Matlab. Computes the extended-maxima transform, which is the regional maxima of the H-maxima transform. 
% Regional maxima are connected components of pixels with a constant intensity value, and whose external boundary pixels all have a lower value.
%%
% 
% <<images\PanelsMaskGeneratorMorphFiltersExtMaxTrans.jpg>>
% 
%
% * *Extended-minima transform* - based on |imextendedmin| function of
% Matlab. Computes the extended-minima transform, which is the regional minima of the H-minima transform. Regional minima are connected components of pixels with a constant intensity value, and whose external boundary pixels all have a higher value.
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
% * *Regional maxima* - based on |imregionalmax| function of Matlab. Returns the binary mask that identifies the locations of the regional 
% maxima in the image. In mask, pixels that are set to 1 identify regional
% maxima; all other pixels are set to 0. Regional maxima are connected components of pixels with a constant intensity value, and whose external boundary pixels all have a lower value.
%
% * *Regional minima* - based on |imregionalmin| function of Matlab. The output binary mask has value 1 corresponding to the pixels of the image
% that belong to regional minima and 0 otherwise. Regional minima are connected components of pixels with a constant intensity value, and whose external boundary pixels all have a higher value. 
%
%
%% Strel Filter
% Generate mask based on morphological image opening and black-and-white
% thresholding. The function first performs morphological bottom-hat (|Black on white| is checked)
% or top-hat (|Black on white| is unchecked) filtering of the image. 
% The top-hat filtering computes the morphological opening of the image (using |imopen|)
% and then subtracts the result from the original image. The result is then
% black and white thresholded with parameter in the |B/W threshold| edit
% box.
%
% <<images\PanelsMaskGeneratorStrel.png>>
%
% # *Strel size*, defines size of the structural element (|disk| type) for |imtophat| and |imbothat|
% filtering. 
% # *Fill* checkbox, check it to fill holes in the resulted |Mask| image.
% # *B/W threshold*, specifies parameter for the black and white thresholding.
% # *Size limit*, limits the size of generated 2D objects so that objects smaller than this value are removed from the |Mask| during the
% filter run.
% # *Black on white* checkbox, when checked, the filter will use morphological bottom-hat filtering
% (|imbothat|). When unchecked - morphological top-hat filtering (|imtophat|).
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
