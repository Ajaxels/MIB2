%% Image Filters Panel
% Filter image using different image filters.
%
% <<images\PanelsImageFilters.png>>
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
%% Brief video demonstration
%
% <html>
% Use of filters in a brief video demonstration:<br>
% <a
% href="https://youtu.be/VwEPZxObA5U"><img
% src="images\youtube2.png"></a>
% </html>
%
%% Image Filter combo box.
% Allows selection of a filter from a list of 2D and 3D image filters. Depending on the filter type some additional parameters
% should be specified in the |HSize|, |Sigma|, |lambda|, |Type|, |Angle|, |Iter| edit boxes.
%
%
% *List of available filters:*
%
% * *Gaussian*, (*2D*) Matlab a rotationally symmetric Gaussian lowpass filter, see more in the Matlab documentation for |fspecial|
% and |imfilter|.
% * *Gaussian 3D*, (*3D*) is based on <http://www.mathworks.com/matlabcentral/fileexchange/25397-imgaussian
% Dirk-Jan Kroon implementation> and uses the fact that a Gaussian kernel can be 
% implemented as several 1D kernels. 
% * *Perona Malik anisotropic diffusion*, (*2D*) - a filter written by
% <http://www.csse.uwa.edu.au/~pk/Research/MatlabFns/#anisodiff Peter Kovesi> to perform anisotropic diffusion of an 
% image following Perona and Malik's algorithm. This process smoothes the regions while preserving, and enhancing the contrast 
% at sharp intensity gradients.
% * *Average*, (*2D*) Matlab Averaging filter, see more in the Matlab documentation for |fspecial|
% and |imfilter|.
% * *Disk*, (*2D*) Matlab circular averaging filter (pillbox), see more in the Matlab documentation for |fspecial|
% and |imfilter|.
% * *Gradient*, (*2D*) generates gradient image for the shown orientation.
% * *Gradient*, (*3D*) generates gradient image for the whole volume.
% * *Frangi 2D/3D*, Hessian based Frangi Vesselness filter. This function uses the eigenvectors of the Hessian to compute the 
% likeliness of an image region to contain vessels or other image ridges , according to the method described by Frangi <http://www.dtic.upf.edu/~afrangi/articles/miccai1998.pdf 1998>, <http://www.tecn.upf.es/~afrangi/articles/tmi2001.pdf 2001>.
% Implementation is based on <http://www.mathworks.com/matlabcentral/fileexchange/24409-hessian-based-frangi-vesselness-filter
% Hessian based Frangi Vesselness filter>, written by Marc Schrijver and Dirk-Jan Kroon.
% * *Motion*, (*2D*) Matlab filter to approximate the linear motion of a camera, see more in the Matlab documentation for |fspecial|
% and |imfilter|.
% * *Unsharp*, (*2D*) Matlab sharpens image using unsharp masking (|imsharpen| function, R2013a and above) or unsharpens contrast
% enhancement filter (|fspecial| and |imfilter|, R2012b and older).
% * *Median 2D*, (*2D*) Matlab 2D median filter. Median filtering is a nonlinear operation often used in image processing to 
% reduce "salt and pepper" noise. The median filter is more effective than convolution when the goal is to simultaneously
% reduce noise and preserve edges. See more in the Matlab documentation for |medfilt2|.
% * *Median 3D*, (*3D*) Matlab 3D median filter (_*Release 2017a and later*_). Median filtering is a nonlinear operation often used in image processing to 
% reduce "salt and pepper" noise. The median filter is more effective than convolution when the goal is to simultaneously
% reduce noise and preserve edges. See more in the Matlab documentation for
% |medfilt3|. <https://youtu.be/7wZbjyVY5s4 A short youtube demo>
% * *Wiener 2D*, (*2D*) Matlab 2D 2-D adaptive noise-removal filtering (|wiener2| function). |wiener2| lowpass-filters a grayscale image that 
% has been degraded by constant power additive noise. |wiener2| uses a pixel wise adaptive Wiener method based on statistics estimated from a local neighbourhood of each pixel.
%
%
% *Note!* If |HSize| is specified with a single number then
% the size of the 3D Kernel is calculated based on pixel size of the dataset <ug_gui_menu_dataset.html
% Menu->Dataset->Parameters>. If |HSize| is specified with 2 numbers
% (_i.e._ 3;3) then the Kernel size is [3 x 3 x 3].
%
%% Mode combobox
% The Mode combobox allows to select part of the open dataset to apply the
% filters.
% 
% 
% * *2D, shown slice*, apply filter only for the currently shown slice
% * *3D, current stack*, apply filter only for the currently shown stack
% * *4D, complete volume*, apply filter for complete dataset
% 
%% Options combobox
% The Options combobox allows to choose what to do with the dataset after
% filtration
% 
% * *Apply filter*, just filter the image and show result on the screen
% * *Apply and add to the image*, filter the image and add the result to
% the original image
% * *Apply and subtract from the image*, filter the image and subtract the
% result from the original image
% 
%
%% Various settings for the filters
% Here is a set of edit boxes (Type, HSize, lambda, Sigma, beta2, beta3) that define additional parameters for the filters. Depending on the selected filter one or more of
% these edit boxes may be disabled.
%
%% The Filter button
% Press this button to start the filtering.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
