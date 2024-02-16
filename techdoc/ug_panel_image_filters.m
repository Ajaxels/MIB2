%% Image Filters Panel
% Filter image using different image filters.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*>
%
%%
%
% <<images\PanelsImageFilters.png>>
% 
%% Brief video demonstration
%
% <html>
% Use of filters in a brief video demonstration:<br>
% <a
% href="https://youtu.be/VwEPZxObA5U"><img
% src="images\youtube2.png"> MIB in brief: image filters (https://youtu.be/VwEPZxObA5U)</a>
% </html>
%
% [class.h3]Image filters were heavily updated and it is recommended to use new
% filters dialog available upon press of the [class.kbd]New filters[/class] button[br]
% or from [class.code] <ug_gui_menu_image_filters.html Menu->Image->Image
% filters> [/class][/class]
%
%% The [class.dropdown]Image Filter &#9660;[/class] dropdown
% Allows selection of a filter from a list of 2D and 3D image filters. Depending on the filter type some additional parameters
% should be specified in the [class.dropdown]HSize[/class],
% [class.dropdown]Sigma[/class], [class.dropdown]lambda[/class],
% [class.dropdown]Type[/class], [class.dropdown]Angle[/class], and [class.dropdown]Iter[/class]
% edit boxes.
%
%
% [dtls][smry] *List of available filters:* [/smry]
%
% * *Average*, (*2D*) MATLAB Averaging filter, see more in the MATLAB documentation for |fspecial|
% and |imfilter|
% * *Disk*, (*2D*) MATLAB circular averaging filter (pillbox), see more in the MATLAB documentation for |fspecial|
% and |imfilter|
% * *DNN Denoise*, (*2D*) denoise images using deep neural network,
% available for MATLAB R2017b and newer, requires Neural Network Toolbox
% and good GPU
% * *Gaussian*, (*2D*) MATLAB a rotationally symmetric Gaussian lowpass filter, see more in the MATLAB documentation for |fspecial|
% and |imfilter|
% * *Gaussian*, (*3D*) is based on <http://www.mathworks.com/matlabcentral/fileexchange/25397-imgaussian
% Dirk-Jan Kroon implementation> and uses the fact that a Gaussian kernel can be 
% implemented as several 1D kernels. 
% * *Gradient*, (*2D/3D*) generates gradient image
% * *Frangi*, (*2D/3D*), Hessian based Frangi Vesselness filter. This function uses the eigenvectors of the Hessian to compute the 
% likeliness of an image region to contain vessels or other image ridges , according to the method described by Frangi <http://www.dtic.upf.edu/~afrangi/articles/miccai1998.pdf 1998>, <http://www.tecn.upf.es/~afrangi/articles/tmi2001.pdf 2001>.
% Implementation is based on <http://www.mathworks.com/matlabcentral/fileexchange/24409-hessian-based-frangi-vesselness-filter
% Hessian based Frangi Vesselness filter>, written by Marc Schrijver and Dirk-Jan Kroon.
% * *Motion*, (*2D*) MATLAB filter to approximate the linear motion of a camera, see more in the MATLAB documentation for |fspecial|
% and |imfilter|.
% * *Median*, (*2D*) MATLAB 2D median filter. Median filtering is a nonlinear operation often used in image processing to 
% reduce "salt and pepper" noise. The median filter is more effective than convolution when the goal is to simultaneously
% reduce noise and preserve edges. See more in the MATLAB documentation for |medfilt2|.
% * *Median*, (*3D*) MATLAB 3D median filter (_*Release 2017a and later*_). Median filtering is a nonlinear operation often used in image processing to 
% reduce "salt and pepper" noise. The median filter is more effective than convolution when the goal is to simultaneously
% reduce noise and preserve edges. See more in the MATLAB documentation for
% |medfilt3|. <https://youtu.be/7wZbjyVY5s4 A short youtube demo>
% * *Perona Malik anisotropic diffusion*, (*2D*) - a filter written by
% <http://www.csse.uwa.edu.au/~pk/Research/MatlabFns/#anisodiff Peter Kovesi> to perform anisotropic diffusion of an 
% image following Perona and Malik's algorithm. This process smoothes the regions while preserving, and enhancing the contrast 
% at sharp intensity gradients.
% * *Unsharp*, (*2D*) MATLAB sharpens image using unsharp masking (|imsharpen| function, R2013a and above) or unsharpens contrast
% enhancement filter (|fspecial| and |imfilter|, R2012b and older).
% * *Wiener*, (*2D*) MATLAB 2D 2-D adaptive noise-removal filtering (|wiener2| function). |wiener2| lowpass-filters a grayscale image that 
% has been degraded by constant power additive noise. |wiener2| uses a pixel wise adaptive Wiener method based on statistics estimated from a local neighbourhood of each pixel.
% * *External: BMxD*, (*2D/3D*) an optional filtering by block-matching and
% 3D collaborative algorithm. The filters are not supplied with MIB and
% should be intalled separately, please refer to the installation
% instruction in the <im_browser_system_requirements.html System
% Requirements section>. *Reference:* K. Dabov, A. Foi, V. Katkovnik, and K. Egiazarian, "Image Denoising by Sparse 3D Transform-Domain Collaborative Filtering," 
% IEEE Transactions on Image Processing, vol. 16, no. 8, August, 2007. preprint at <http://www.cs.tut.fi/~foi/GCF-BM3D http://www.cs.tut.fi/~foi/GCF-BM3D>. 
% And M. Maggioni, V. Katkovnik, K. Egiazarian, A. Foi, "A Nonlocal Transform-Domain Filter for Volumetric Data Denoising and
% Reconstruction", IEEE Trans. Image Process., vol. 22, no. 1, pp. 119-133, January 2013.  doi:10.1109/TIP.2012.2210725 
%
% [/dtls]
%
% *Note!* If [class.dropdown]HSize[/class] is specified with a single number then
% the size of the 3D Kernel is calculated based on pixel size of the dataset <ug_gui_menu_dataset.html
% Menu->Dataset->Parameters>. If [class.dropdown]HSize[/class] is specified with 2 numbers
% (_i.e._ 3;3) then the Kernel size is [3 x 3 x 3].
%
%% The [class.dropdown]Mode &#9660;[/class] dropdown
% The [class.dropdown]Mode &#9660;[/class] dropdown allows to select part of the open dataset to apply the
% filters.
% 
% 
% * [class.dropdown]2D, shown slice &#9660;[/class], apply filter only for the currently shown slice
% * [class.dropdown]3D, current stack &#9660;[/class], apply filter only for the currently shown stack
% * [class.dropdown]4D, complete volume &#9660;[/class], apply filter for complete dataset
% 
%% The [class.dropdown]Options &#9660;[/class] dropdown
% The [class.dropdown]Options &#9660;[/class] dropdown allows to choose what to do with the dataset after
% filtration
% 
% * [class.dropdown]Apply filter &#9660;[/class], this option filters the image and shows the result on the screen. It applies the selected filter to the image and displays the filtered image as the output
% * [class.dropdown]Apply and add to the image &#9660;[/class], this option filters the image and adds the result to the original image. 
% It applies the selected filter to the image and combines the filtered image with the original image, resulting in a modified image 
% that includes the filtered effect
% * [class.dropdown]Apply and subtract from the image &#9660;[/class], this option filters the image and subtracts the result 
% from the original image. It applies the selected filter to the image and subtracts the filtered image from the 
% original image, resulting in a modified image that removes or reduces the filtered effect
% 
%
%% Various settings for the filters
% Here is a set of edit boxes (3D, Type, HSize, lambda, Sigma, beta2, beta3) that define additional parameters for the filters.
% Depending on the selected filter one or more of these edit boxes may be disabled.
%
%% The [class.kbd]Filter[/class] button
% Press this button to start the filtering process.
%
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