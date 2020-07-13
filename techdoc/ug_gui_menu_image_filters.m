%% Image Filters dialog
% collection of image filters arranged into 4 categories: 
%
% * Basic image filtering in the spacial domain
% * Edge-preserving filtering
% * Contrast adjustment
% * Image binarization
%
% <html>
% A demonstration is available in the following video:<br>
% <a href="https://youtu.be/QZU3jSoEXJM"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/QZU3jSoEXJM</a>
% </html>
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_image.html *Image*>
%
%% Options
% Prior filtering of images the following options may be tweaked:
% 
% * *Dataset type* - specify whether the image filtering should be done for
% the shown slice, current 3D stack of the whole dataset
% * *Source layer* - allows to select a source layer which will be filtered
% * *Color channel* - list of existing color channels. It is possible to
% select a specific color channel, all shown color channels or just all
% color channels of the image
% * *Material index* - index of material to filter, only when |Source
% layer| is |Model|
% * *3D* - check to apply 3D filter
%
% The filtered image may additionally be post-processed (a dropdown at the bottom of the dialog window) as 
% 
% * *Filter image* - filter image and display it as result of the operation
% * *Filter and subtract* - filter image and subtract the result from the unfiltered image
% * *Filter and add* - filter image and add the result to the unfiltered image
%
%% Basic image filtering in the spacial domain
% table with the list of available filters
%
% <html>
% <table>
% <table style="width: 800px; text-align: left; border: 0px" cellspacing=2px cellpadding=2px >
% <tr>
%   <td><img src="images\image_filters_average.jpg"></td>
%   <td><b>Average filter</b><br>
%        average image signal using a rectanlular filter; the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">average</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>
%   </td>
%   <td>2D/3D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_average.jpg"></td>
%   <td><b>Circular averaging filter (pillbox)</b><br>
%        average image signal using a disk-shaped filter; the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">disk</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_elasticdist.jpg"></td>
%   <td><b>Elastic distortion filter</b><br>
%        Elastic distortion filter, based on Best Practices for Convolutional Neural Networks
%        Applied to Visual Document Analysis by Patrice Y. Simard, Dave Steinkraus, John C. Platt
%        <a href="http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.160.8494&rep=rep1&type=pdf">(link)</a><br><br>
%        and codes available:<br>
%        <a href="https://stackoverflow.com/questions/39308301/expand-mnist-elastic-deformations-matlab">stackoverflow</a><br>
%        <a href="https://se.mathworks.com/matlabcentral/fileexchange/66663-elastic-distortion-transformation-on-an-image">Elastic Distortion Transformation by David Franco</a><br>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_entropy.jpg"></td>
%   <td><b>Entropy filter</b><br>
%        Local entropy filter, returns an image, where each output pixel contains the entropy <em>(-sum(p.*log2(p)</em>, where <em>p</em> contains the normalized histogram counts) of the defined neighborhood around the corresponding pixel, see details in <a href="https://www.mathworks.com/help/images/ref/entropyfilt.html" target="_blank">entropyfilt</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_frangi.jpg"></td>
%   <td><b>Frangi filter</b><br>
%        Frangi filter to enhance elongated or tubular structures using Hessian-based multiscale filtering<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/fibermetric.html" target="_blank">fibermetric</a>
%   </td>
%   <td>2D/3D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_gaussian.jpg"></td>
%   <td><b>Gaussian smoothing filter</b><br>
%        Rotationally symmetric Gaussian lowpass filter of size (Hsize) with standard deviation (Sigma).<br>The 2D filtering is done with <a href="https://www.mathworks.com/help/images/ref/imgaussfilt.html" target="_blank">imgaussfilt</a> and 3D with <a href="https://www.mathworks.com/help/images/ref/imgaussfilt3.html" target="_blank">imgaussfilt3</a>
%   </td>
%   <td>2D/3D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_gradient.jpg"></td>
%   <td><b>Gradient filter</b><br>
%        Calculate image gradient<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/gradient.html" target="_blank">gradient</a> function and the acquired X,Y,Z components are converted to the resulting image as <em>sqrt(X<sup>2</sup> + Y<sup>2</sup> + Z<sup>2</sup>)</em>
%   </td>
%   <td>2D/3D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_LoG.jpg"></td>
%   <td><b>Laplacian of Gaussian filter</b><br>
%        Filter the image using the Laplacian of Gaussian filter, which highlights the edges<br>The resulting image is converted to unsigned integers by its multiplying with the NormalizationFactor and adding half of max class integer value.  The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">log</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>
%   </td>
%   <td>2D/3D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_motion.jpg"></td>
%   <td><b>Motion filter</b><br>
%        the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">motion</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_prewitt.jpg"></td>
%   <td><b>Prewitt filter</b><br>
%        Prewitt filter for edge enhancement<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">prewitt</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>
%   </td>
%   <td>2D/3D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_range.jpg"></td>
%   <td><b>Range filter</b><br>
%        Local range filter, returns an image, where each output pixel contains the range value (maximum value - minimum value) of the defined neighborhood around the corresponding pixel. See details in <a href="https://www.mathworks.com/help/images/ref/rangefilt.html" target="_blank">rangefilt</a>
%   </td>
%   <td>2D/3D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_salt_and_pepper.jpg"></td>
%   <td><b>Salt and pepper filter</b><br>
%        Remove salt & pepper noise from image<br>The images are filtered using the median filter, after that a difference between the original and the median filtered images is taken. Pixels that have threshold higher than IntensityThreshold are considered as noise and removed
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_sobel.jpg"></td>
%   <td><b>Sobel filter</b><br>
%        Sobel filter for edge enhancement<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "sobel" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_std.jpg"></td>
%   <td><b>Std filter</b><br>
%        Local standard deviation of image. The value of each output pixel is the standard deviation of a neighborhood around the corresponding input pixel. The borders are extimated via symmetric padding: i.e. the values of padding pixels are a mirror reflection of the border pixels. See details in <a href="https://www.mathworks.com/help/images/ref/stdfilt.html" target="_blank">stdfilt</a>
%   </td>
%   <td>2D</td>
% </tr>
% </table>
% </html>
% 
%% Edge-preserving filtering
% Remove noise while preserve the edges of the objects using one of the
% following filters
%
%
% <html>
% <table>
% <table style="width: 800px; text-align: left; " cellspacing=2px cellpadding=2px >
% <tr>
%   <td><img src="images\image_filters_ani_diff.jpg"></td>
%   <td><b>Anisotropic diffusion filter</b><br>
%        Edge preserving anisotropic diffusion filtering of images with Perona-Malik algorithm<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imdiffusefilt.html" target="_blank">imdiffusefilt</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_bilateral.jpg"></td>
%   <td><b>Bilateral filter</b><br>
%        Edge preserving bilateral filtering of images with Gaussian kernels<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imbilatfilt.html" target="_blank">imbilatfilt</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_dnn_denoise.jpg"></td>
%   <td><b>DNNdenoise filter</b><br>
%        Denoise image using deep neural network<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/denoiseimage.html" target="_blank">denoiseImage</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_median.jpg"></td>
%   <td><b>Median filter</b><br>
%        Median filtering of images in 2D or 3D. Each output pixel contains the median value in the specified neighborhood<br>The 2D filtering is done with <a href="https://www.mathworks.com/help/images/ref/medfilt2.html" target="_blank">medfilt2</a> and 3D with <a href="https://www.mathworks.com/help/images/ref/medfilt3.html" target="_blank">medfilt3</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_non_local_means.jpg"></td>
%   <td><b>Non-local means filter</b><br>
%        The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imnlmfilt.html" target="_blank">imnlmfilt</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_BMxD.jpg"></td>
%   <td><b>BMxD filter</b><br>
%        Filtering image using the block-matching and 3D collaborative
%        algorithm, please note that this filter is only licensed to be
%        used in non-profit organizations<br>
%        Please follow <a href="im_browser_system_requirements.html">the system requirements page</a> on details how to
%        install it.
%   </td>
%   <td>2D</td>
% </tr>
% </table>
% </html>
%
%% Contrast adjustment
% Here the list of filters that are intended to adjust the contrast of
% images
%
% <html>
% <table>
% <table style="width: 800px; text-align: left; " cellspacing=2px cellpadding=2px >
% <tr>
%   <td><img src="images\image_filters_addnoise.jpg"></td>
%   <td><b>Add noise filter</b><br>
%        Add noise to image<br>The filtering is done with <a
%        href="https://www.mathworks.com/help/images/ref/imnoise.html"
%        target="_blank">imnoise</a><br><br>
%        <ul>Several noising schemes are available:
%        <li>gaussian - Gaussian white noise</li>
%        <li>poisson - Poisson noise from the data</li>
%        <li>salt & pepper - adds salt and pepper noise</li>
%        <li>speckle - multiplicative noise using the equation <code>J = I+n*I</code>, where n is uniformly distributed random noise with mean 0 and variance 0.05.</li>
%        </ul>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_fast_loc_lap.jpg"></td>
%   <td><b>Fast Local Laplacian filter</b><br>
%        Fast local Laplacian filtering of images to enhance contrast, remove noise or smooth image details<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/locallapfilt.html" target="_blank">locallapfilt</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_flatfield.jpg"></td>
%   <td><b>Flat-field correction</b><br>
%        Flat-field correction to the grayscale or RGB image. The correction uses Gaussian smoothing with a standard deviation of sigma to approximate the shading component of the image<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imflatfield.html" target="_blank">imflatfield</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_local_bright.jpg"></td>
%   <td><b>Local Brighten filter</b><br>
%        Brighten low-light image<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imlocalbrighten.html" target="_blank">imlocalbrighten</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_loc_contrast.jpg"></td>
%   <td><b>Local Contrast filter</b><br>
%        Edge-aware local contrast manipulation of images<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/localcontrast.html" target="_blank">localcontrast</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_reducehaze.jpg"></td>
%   <td><b>Reduce Haze filter</b><br>
%        Reduce atmospheric haze<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imreducehaze.html" target="_blank">imreducehaze</a>
%   </td>
%   <td>2D</td>
% </tr>
% <tr>
%   <td><img src="images\image_filters_unsharpmask.jpg"></td>
%   <td><b>Unsharp mask filter</b><br>
%        Sharpen image using unsharp masking: when an image is sharpened by subtracting a blurred (unsharp) version of the image from itself<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imsharpen.html" target="_blank">imsharpen</a>
%   </td>
%   <td>2D</td>
% </tr>
% </table>
% </html>
%% Image binarization
% The image binarization filters process the image and generate bitmap mask
% that can be assigned to the selection or mask layers of MIB (use the |DestinationLayer| dropdown to specify it)
%
% <html>
% <table>
% <table style="width: 800px; text-align: left; " cellspacing=2px cellpadding=2px >
% <tr>
%   <td><img src="images\image_filters_edge.jpg"></td>
%   <td><b>Edge filter</b><br>
%        Find edges in intensity image;<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/edge.html" target="_blank">edge</a>
%        <br><br>
%        <ul>Several edge detection schemes are available:
%        <li><b>approxcanny</b> - finds edges using an approximate version of the Canny edge detection algorithm that provides faster execution time at the expense of less precise detection</li>
%        <li><b>Canny</b> - finds edges by looking for local maxima of the gradient of I. The edge function calculates the gradient using the derivative of a Gaussian filter. This method uses two thresholds to detect strong and weak edges, including weak edges in the output if they are connected to strong edges. By using two thresholds, the Canny method is less likely than the other methods to be fooled by noise, and more likely to detect true weak edges</li>
%        <li><b>log</b> - finds edges by looking for zero-crossings after filtering I with a Laplacian of Gaussian (LoG) filter</li>
%        <li><b>Prewitt</b> - finds edges at those points where the gradient of I is maximum, using the Prewitt approximation to the derivative</li>
%        <li><b>Roberts</b> - finds edges at those points where the gradient of I is maximum, using the Roberts approximation to the derivative</li>
%        <li><b>Sobel</b> - Finds edges at those points where the gradient of the image I is maximum, using the Sobel approximation to the derivative</li>
%        </ul>
%   </td>
%   <td>2D</td>
% </tr>
% </table>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_image.html *Image*>
%