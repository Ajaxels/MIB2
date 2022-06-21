%% Image Menu
% Image processing functions
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
%%
% 
% <<images\menuImage.png>>
% 
%% Mode
% Allows to change mode and color depth of the shown dataset
% 
% 
% [dtls][smry] *The following options are available* [/smry]
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
% [/dtls]
% [br8]
%
%% Adjust Display/Image
% Starts a dialog to adjust display settings or resample image intensities.
% See more in the <ug_panel_adjustments.html Adjust display window section>
%
%% Color Channels
% Perform some actions with color channels of the image
% 
% <html>
% A brief demonstration is available in the following videos:<br>
% <ul>
% <li> General demonstration: <a href="https://youtu.be/gT-c8TiLcuY"><img
% style="vertical-align:middle;" src="images\youtube2.png">
% https://youtu.be/gT-c8TiLcuY</a></li>
% <li> Correction of color shifts between images: <a href="https://youtu.be/-J2P8a_z7pE"><img
% style="vertical-align:middle;" src="images\youtube2.png">
% https://youtu.be/-J2P8a_z7pE</a></li>
% </ul>
% </html>
%
% [dtls][smry] *List of operations with color channels* [/smry]
%
% * *Insert empty channel...*, insert an empty channel (intensity of all
% pixels is 0) to the specified position
% * *Copy channel...*, copy one channel to another position 
% * *Invert channel...*, invert intensities of the specified color channel
% * *Rotate channel...*, rotate the specified color channel
% * *Shift channel...*, allows to shift a channel by X and Y pixels
% * *Swap channels...*, allows to swap two color channels between each other
% * *Delete channel...*, deletes specified color channel from the dataset
%
% [/dtls]
%
% It is also possible to do color channel operations from the |Colors| table in the <ug_panel_view_settings.html View settings panel>.
% [br8]
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
%
% [dtls][smry] *List of contrast adjustment operations* [/smry]
% 
% * *Linear contrast*, is no longer available in MIB, please use the Display button in the <ug_panel_view_settings.html View Settings panel>.
% * *Contrast-limited adaptive histogram equalization*, CLAHE contrast equalization. CLAHE operates on small regions in the image, 
% called tiles, rather than the entire image. Each tile's contrast is enhanced, so that the histogram of the output region 
% approximately matches the histogram specified by the 'Distribution' parameter. The neighboring tiles are then combined using bilinear 
% interpolation to eliminate artificially induced boundaries. The contrast, especially in homogeneous areas, can be limited to avoid amplifying 
% any noise that might be present in the image. For details see documentation for MATLAB function |adapthisteq|. 
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
% [/dtls]
% [br8]
%
%% Invert image
% Invert image intensities, shortcut [class.kbd]Ctrl+i|[/class]
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/1DG2w5XYA18"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/1DG2w5XYA18</a>
% </html>
%
% [dtls][smry] *Invert operations available for* [/smry]
%
% * *Shown slice (2D)*, invert only the currently shown slice of the
% dataset
% * *Current stack (3D)*, invert the current stack of the dataset
% * *Complete volume (4D)*, invert complete dataset
%
% [/dtls]
% [br8]
%
%% Image filter
% Open a dialog with various image filters arranged into 4 categories: 
%
% * Basic image filtering in the spacial domain
% * Edge-preserving filtering
% * Contrast adjustment
% * Image binarization
%
% For further details, please refer to the <ug_gui_menu_image_filters.html Image Filters help page>.
%
%% Tools for images --> Content-aware fill
%
% Content aware fill can be used to reconstruct selected areas using
% information for neighboring regions.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/H_TVvgA_br4"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/H_TVvgA_br4</a>
% </html>
% 
% [dtls][smry] *Details of content-aware methods* [/smry]
%
% <html>
% <table>
% <tr>
% <td><img src="images\MenuImageToolsContentAwareFill.png"></td>
% <td>
% <h2><font color="#ef6c00">inpaintCoherent</font></h2>
% <b><em>only for MATLAB R2019a and newer</em></b><br>
% Restore specific image regions using coherence transport based image
% inpainting. <br><br>
% The areas for the content-aware fill can be specified using the Mask or
% Selection layers of MIB.<br><br>
% <ul>
% <li><b>Radius</b> - the inpainting radius denotes the radius of the circular
% neighborhood region centered on the pixel to be inpainted<br></li>
% <li><b>Smoothing Factor</b> - smoothing factor is used to compute the
% scales of the Gaussian filters while estimating the coherence
% direction</li>
% </ul>
% <b>References</b><br>
% [1] F. Bornemann and T. M?rz. "Fast Image Inpainting Based on Coherence Transport." Journal of Mathematical Imaging and Vision. Vol. 28, 2007, pp.259?278.
% </td>
% </tr>
% <tr>
% <td><img src="images\MenuImageToolsContentAwareFill2.png"></td>
% <td>
% <h2><font color="#ef6c00">inpaintExemplar</font></h2>
% <b><em>only for MATLAB R2019b and newer</em></b><br>
% Fill image regions using exemplar-based image inpainting<br><br>
% The areas for the content-aware fill can be specified using the Mask or
% Selection layers of MIB.<br><br>
% <ul>
% <li><b>PatchSize</b> - size of the image patch, for example, '9' or a
% pair of numbers as '9,9', where the image patches are the image regions
% considered for patch matching and inpainting</li>
% <li><b>FillOrder</b> - the filling order denotes the priority function to
% be used for calculating the patch priority. The patch priority value
% specifies the order of filling of the image patches in target
% regions</li>
% </ul>
% <b>References</b><br>
% [1]  A. Criminisi, P. Perez and K. Toyama. "Region Filling and Object Removal by Exemplar-Based Image Inpainting." IEEE Trans. on Image Processing. Vol. 13, No. 9, 2004, pp. 1200?1212.
% </td>
% </tr>
% </table>
% </html>
%
% [/dtls]
% [br8]
%
%% Tools for images --> Debris removal
%
% Automatically or manually restore areas of volumetric datasets that are corrupted with debris. The areas can either be automatically detected or manually selected into the Mask or Selection layers<br><br>
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/iM2nHBxTjRw"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/iM2nHBxTjRw</a>
% </html>
%
% <html>
% <table>
% <tr>
% <td><img src="images\MenuImageToolsDebrisRemoval2.png"><br>
% <img src="images\MenuImageToolsDebrisRemoval.png">
% </td>
% <td>
% <ul>
% <li><b>Automatic detection</b> - automatic detection of debris areas:
% <ul>
% <li>the tool takes a difference between the current and the previous and the following slices; </li>
% <li>the difference is summarized and thresholded using the <em>Intensity threshold</em> parameter</li>
% <li>the thresholded area that are smaller than the <em>Object size threshold</em> parameter are removed from the consideration</li>
% <li>all other areas are subjected to a series of erosion and dilation morphological operations with the strel size defined in the <em>Strel size</em> field</li>
% <li>finally the detected area is replaced with an average image generated using the previous and the following slice</li>
% </ul>
% <br>
% </li>
% <li><b>Masked areas</b> - the debris removal operation is performed on the specified in the Mask layer areas</li>
% <li><b>Selected areas</b> - the debris removal operation is performed on the specified in the Selection layer areas</li>
% </ul>
% </td>
% </tr>
% </table>
% </html>
%
% [br8]
%
%% Tools for images --> Image arithmetics
%
% <html>
% Use MATLAB syntax to apply custom arithmetic expression to Image, Model, Mask or Selection layers, see more in
% a brief video and examples below.<br>
% For MIB 2.60 and newer <a href="https://youtu.be/sDwvnJGLi8Q"><img
% style="vertical-align:middle;" src="images\youtube2.png">
% https://youtu.be/sDwvnJGLi8Q</a><br>
% For MIB 2.52 and older <a href="https://youtu.be/-puVxiNYGsI"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/-puVxiNYGsI</a>
% <br>
% <table>
% <tr>
% <td><img src="images\MenuImageToolsArithmetics.png"></td>
% <td>
% <ul>
% <b>Parameters and options:</b><br><br>
% <li><b>Coding:</b>,<br>
%   <ul>
%    <li><b>I, I1, I2 ...</b> -> use I letter to identify the image layer; a number indicates MIB container that has the image, without the number the currently selected dataset is taken</li>
%    <li><b>O, O1, O2 ...</b> -> use O letter to identify the model layer</li>
%    <li><b>M, M1, M2 ...</b> -> use M letter to identify the mask layer</li>
%    <li><b>S, S1, S2 ...</b> -> use S letter to identify the selection layer</li>
%  </ul>
% <li><b>Input variables:</b> list here all datasets that are used in the expression</li>
% <li><b>Output variable:</b> specify here the output variable</li>
% <li><b>Previous expresson</b>, a list of previous successfully executed expressions. Selection of any expression from this list will populate the expression edit box</li> 
% <li><b>Expression</b>, an expression with arithmetic operation to perform, see below for some examples</li> 
% </ul>
% <br>
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *Examples* [/smry]
%
% <html>
% <ul>
% <li><b>I = I * 2</b>, increase intensity of all pixels of the current image in 2 times</li>
% <li><b>I2 = I2 + 100</b>, increase intensity of all pixels in image 2 by 100</li>
% <li><b>I1 = I1 + I2</b>, add image from container 2 to an image in container 1 and return result back to container 1</li>
% <li><b>I3 = I3 + mean(I3(:))</b>, add mean value of image 3 to image 3</li>
% <li><b>I1 = I1 - min(I1(:))</b>, decrease intensity of pixels in the image 1 by the min value of the dataset</li>
% <li><b>I(:,:,2,:) = I(:,:,2,:)*1.4</b>, increase image intensity of the second color channel in 1.4 times</li>
% <li><b>I(I==0) = I(I==0)+100</b>, increase image intensity of the black areas by 100 intensity counts</li>
% <li><b>disp(sum(abs(single(I1(:))-single(I2(:)))))</b>, find the difference between two images loaded to container 1 and 2 and print it to console; or use <em>msgbox(num2str())</em> instead of <em>disp</em> to show result as a message box</li>
% <li><b>M2 = M1</b>, copy mask layer from image 1 to image 2</li>
% <li><b>for z=1:size(I, 4)<br>
%           slice = I(:,:,2,z);<br>
%           mask = M(:,:,z);   <br>
%           slice(mask==1) = 0;<br>
%           I(:,:,2,z) = slice;<br>
%        end</b> - replace intensity of the second color channel in the masked area to 0
% </ul>
% </html>
% 
% [/dtls]
% [br8]
%
%% Tools for images --> Intensity projection
%
% Generate intensity projection actoss any dimension of the loaded dataset
%
% <html>
% <table>
% <tr>
% <td><img src="images\MenuImageToolsIntensityProjection.png"></td>
% <td>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/hwFpS_3eP9U"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/hwFpS_3eP9U</a>
%
% </td>
% </tr>
% </table>
% </html>
%
% [dtls][smry] *List of available projection calculations* [/smry]
%
% <html>
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
% </ul>
% </html>
%
% [/dtls]
% [br8]
%
%% Tools for images --> Select image frame
%
% <html>
% Detects the frame (which is an area of the same intensity that touches edge
% of the image) of the image. The detected area can be assinged to the
% <em>Selection</em> or <em>Mask</em> layers, or that area can be replaced with another
% color for the <em>Image</em> layer.
% <table>
% <tr>
% <td><img src="images\image_border_detection.png"></td>
% <td>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/sWjipmeU5eA"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/sWjipmeU5eA</a>
% </td>
% </tr>
% </table>
% </html>
%
% [br8]
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
% [dtls][smry] *List of available morphological operations* [/smry]
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
% [/dtls]
% [br8]
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
% 
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


