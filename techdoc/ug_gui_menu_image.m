%% Image Menu
% Image processing functions
%
% 
% <<images\menuImage.png>>
% 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%% Mode
% Allows to change mode of the shown dataset, the following options are available:
% 
% * *Grayscale*, converts image to grayscale by removing any color
% information
% * *RGB Color*, converts image to the RGB color space
% * *HSV Color*, converts image to the HSV (hue, saturation, value) color space
% * *Indexed*, converts image to the indexed colors (|not implemented for True
% Color images|)
% * *8 bit*, convert dataset to the 8 bit format, the image intensities are
% scaled to preserve the adjusted from the |View Settings Panel->Display
% dialog|
% * *16 bit*, convert dataset to the 16 bit format, the image intensities are
% scaled to preserve contrast of the original dataset
% * *32 bit*, convert dataset to the 32 bit format, the image intensities are
% scaled to preserve contrast of the original dataset
% 
%% Color Channels
% Perform some actions with color channels of the image
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/gT-c8TiLcuY"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/gT-c8TiLcuY</a>
% </html>
%
% * *Insert empty channel...*, insert an empty channel (intensity of all
% pixels is 0) to the specified position
% * *Copy channel...*, copy one channel to another position 
% * *Invert channel...*, invert intensities of the specified color channel
% * *Rotate channel...*, rotate the specified color channel
% * *Swap channels...*, allows to swap two color channels between each other
% * *Delete channel...*, deletes specified color channel from the dataset
%
% It is also possible to do color channel operations from the |Colors| table in the <ug_panel_view_settings.html View settings panel>.
%
%% Contrast
% Adjust contrast of the dataset. For the linear contrast stretching it is
% recommended to use Image Adjustment dialog available via the <ug_panel_adjustments.html Display
% button> in the <ug_panel_view_settings.html View Settings panel>.
%
% <html>
% A tutorial on image normalization is available in the following video:<br>
% <a href="https://youtu.be/MmBmdGtuUdM"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/MmBmdGtuUdM</a>
% </html>
%%
% 
% * *Linear contrast*, is no longer available in MIB, please use the Display button in the <ug_panel_view_settings.html View Settings panel>.
% * *Contrast-limited adaptive histogram equalization*, CLAHE contrast equalization. CLAHE operates on small regions in the image, 
% called tiles, rather than the entire image. Each tile's contrast is enhanced, so that the histogram of the output region 
% approximately matches the histogram specified by the 'Distribution' parameter. The neighboring tiles are then combined using bilinear 
% interpolation to eliminate artificially induced boundaries. The contrast, especially in homogeneous areas, can be limited to avoid amplifying 
% any noise that might be present in the image. For details see documentation for Matlab function |adapthisteq|. 
% * *Normalize layers*, normalization of image intensities between the
% slices.  A) calculates mean intensity and standard deviation (std) for the whole dataset;
% B) calculates mean intensities and standard deviation for each image; C) shifts each image 
% based on difference between mean values of that image and the whole dataset, 
% plus stretches it based on ratio between standard deviation of the whole
% dataset and each image. For the 4D datasets it is possible to perform
% normalization also via the time dimension. For the Z stack it is possible
% to exclude black or white pixels from consideration
% * *Normalize layers based on masked areas*, essentially similar to the _Normalize layers_ mode, except that all values are
% calculated from the masked areas only.
% * *Normalize based on masked background*, normalizes image intensities between the
% slices using background areas that should be masked. A) calculates mean 
% intensity for the masked area for the whole dataset; B) calculates mean 
% intensities for the masked area for each image; C) shifts each image based 
% on difference between mean values of the image and the whole dataset
% 
%% Invert image
% Invert image intensities, shortcut |Ctrl+i|.
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/1DG2w5XYA18"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/1DG2w5XYA18</a>
% </html>
%
% * *Shown slice (2D)*, invert only the currently shown slice of the
% dataset
% * *Current stack (3D)*, invert the current stack of the dataset
% * *Complete volume (4D)*, invert complete dataset
%
%% Tools for images
% In this section, MIB has tools that are targeted for manipulation of the
% image layer.
%
% 
% <html>
% <table>
% <tr>
% <td colspan = 2><b>Image arithmetics</b><br>
% Use Matlab syntax to apply custom arithmetic expression with one, two or
% three open datasets. The expression should start with "A = ", see more in
% a brief video below and some examples.<br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/-puVxiNYGsI"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/-puVxiNYGsI</a>
% </td>
% </tr>
% <tr>
% <td><img src="images\MenuImageToolsArithmetics.png"></td>
% <td>
% <ul>
% <b>Parameters and options:</b><br><br>
% <li><b>Input A</b>, specify index of the MIB container with the source image. The image in the specified container will be referenced as "A"</li>
% <li><b>Input B</b>, an optional input to specify a second MIB container to use. The image in the specified container will be referenced as "B"</li>
% <li><b>Input C</b>, an optional input to specify a third MIB container to use. The image in the specified container will be referenced as "C"</li>
% <li><b>Destination container</b>, the result of the operation will be stored in container with this index</li>
% <li><b>Destination class</b>, the result of the operation will be stored in one of these image classes</li>
% <li><b>Convert via uint32</b>, use this checkbox to ensure that before the operations images are converted to unit32 class so that the highlights are not clipped away</li>
% <li><b>Previous expresson</b>, a list of previous successfully executed expressions. Selection of any expression from this list will populate the expression edit box</li> 
% <li><b>Expression</b>, an expression with arithmetic operation to perform, see below for some examples</li> 
% </ul>
% <br>
% <ul>
% Examples:
% <li><b>A = A + 100</b>, increase intensity of all pixels in image A by 100</li>
% <li><b>A = A * 2</b>, increase intensity of all pixels in image A in 2 times</li>
% <li><b>A = A + B - C</b>, add image B to image A and subtract image C from the result</li>
% <li><b>A = A + mean(B(:))</b>, add mean value of image B to image A</li>
% <li><b>A = A - min(B(:))</b>, subtract the min-value of image B from image A</li>
% <li><b>A(:,:,2,:) = A(:,:,2,:)*1.4</b>, increase image intensity of the second color channel in 1.4 times</li>
% <li><b>A(A==0) = A(A==0)+100</b>, increase image intensity of the black areas by 100 intensity counts</li>
% </ul>
% </td>
% </tr>
% </table>
% <br>
% <br>
% <table>
% <tr>
% <td colspan = 2><b>Intensity projection</b><br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/hwFpS_3eP9U"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/hwFpS_3eP9U</a>
% </td>
% </tr>
% <tr>
% <td><img src="images\MenuImageToolsIntensityProjection.png"></td>
% <td>
% <ul>
% Calculate one of the following intensity projections:
% <li><b>maximum intensity projection</b>, project the voxel with the highest value on every view throughout the volume onto a 2D image</li>
% <li><b>minimum intensity projection</b>, project the voxel with the smallest value on every view throughout the volume onto a 2D image</li>
% <li><b>mean intensity projection</b>, project the mean value of voxels on every view throughout the volume onto a 2D image</li>
% <li><b>median intensity projection</b>, project the median value of voxels on every view throughout the volume onto a 2D image</li>
% <li><a href="https://youtu.be/5L0xMSFVxiU"><img style="vertical-align:middle;" src="images\youtube.png"></a> <b>focus stacking</b>, Generate extended depth-of-field image from focus sequence using noise-robust selective all-in-focus algorithm (<a href="https://ieeexplore.ieee.org/document/6373725">Pertuz et. al. "Generation of all-in-focus images by
%   noise-robust selective fusion of limited depth-of-field
%   images" IEEE Trans. Image Process, 22(3):1242 - 1251, 2013</a>)
% </li>
% </td>
% </tr>
% </table>
% <br>
% <br>
% <table>
% <tr>
% <td colspan = 2><b>Select image frame</b><br>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/sWjipmeU5eA"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/sWjipmeU5eA</a>
% </td>
% </tr>
% <tr>
% <td><img src="images\image_border_detection.png"></td>
% <td>
% Detects the frame (which is an area of the same intensity that touches edge
% of the image) of the image. The detected area can be assinged to the
% <em>Selection</em> or <em>Mask</em> layers, or that area can be replaced with another
% color for the <em>Image</em> layer.
% </td>
% </tr>
% </table>
% </html>
%
%% Morphological operations
% This section contains number of morphological operations that can be
% applied to images. The processed image may be also added or subtracted
% from the existing image (see the settings in the |Additional action to
% the result| panel).
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/itbVLFm0FKQ"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/itbVLFm0FKQ</a>
% </html>
% 
% <<images\MenuImageMorphOps.png>>
% 
% List of available morphological operations
%
% * *Bottom-hat filtering (imbothat)* computes the morphological closing of the image (using imclose`) and then subtracts the result from the original image 
% * *Clear border (imclearborder)* suppresses light structures connected to image border
% * *Morphological closing (imclose)* morphologically closes the image: a dilation followed by an erosion
% * *Dilate image (imdilate)* 
% * *Erode image (imerode)* 
% * *Fill regions (imfill)* fills holes in the image, where a hole is defined as an area of dark pixels surrounded by lighter pixels
% * *H-maxima transform (imhmax)* suppresses all maxima in the image whose height is less than H
% * *H-mminima transform (imhmin)* uppresses all minima in the image whose depth is less than H
% * *Morphological opening (imopen)* morphologically opens image: an erosion followed by a dilation
% * *Top-hat filtering (imtophat)* computes the morphological opening of the image (using imopen) and then subtracts the result from the original image
%
%% Intensity profile
% Generate an intensity profile of the image data. The profiles can be
% obtained in two modes:
%
% * *Line* 
% * *Arbitrary* 
% 
% For intensity profiles it is recommended to use the <ug_gui_menu_tools_measure.html Measure length tool>.
%
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>


