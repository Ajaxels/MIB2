%% Alignment and Drift Correction
% The Alignment and Drift Correction tool can be used either to align slice of the opened dataset or to align two
% separate datasets. 
% 
% <html>
% A demonstration is available in the following videos:<br>
% <a href="https://youtu.be/-qwoO5z02aA"><img style="vertical-align:middle;" src="images\youtube2.png"> https://youtu.be/-qwoO5z02aA</a><br>
% <a href="https://youtu.be/rlXoyZcTpJs"><img style="vertical-align:middle;" src="images\youtube2.png"> Multi-point landmarks,  https://youtu.be/rlXoyZcTpJs</a><br>
% <a href="https://youtu.be/-en5zD5Ou9s"><img style="vertical-align:middle;" src="images\youtube2.png"> Automatic feature-based</a><br>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_dataset.html *Dataset*>
%
%% Current dataset panel
% 
% The *Current dataset panel* displays details of the currently opened
% dataset, such as its filename, dimensions and pixel size
% 
% <<images/menuDatasetAlignTool_1.jpg>>
% 
%
%% Align panel
% The *Align panel* allows to select main parameters for the alignment and
% drift correction.
% 
% <<images/menuDatasetAlignTool_2.jpg>>
%
%
% <html>
% <ul>
%   <li>
%     <b>The Mode panel</b> - selection of alignment mode:
%       <ul>
%           <li><b>Current dataset</b>, align the opened dataset</li>
%           <li><b>Two stacks</b>, align two stacks. The second stack can either be loaded or imported from Matlab</li>
%       </ul>
%   </li>
%   <li>
%     <b>Algorithm</b> - selection of method to be used for the alignment:
%     <table style="width: 550px; text-align: center; margin-left: 50px;" cellspacing=2px cellpadding=2px >
%     <tr>
%       <td style="width=250px;"><b>Drift correction</b></td>
%       <td>The Drift correction mode is recommended for small shifts or comparably sized images<br>
%           It is recommended for most situations
%       </td>
%     </tr>
%     <tr>
%       <td><b>Template matching</b></td>
%       <td>The Template matching mode is best when aligning two stacks and the second stack is smaller than the main stack.<br>
%           It is <b>not</b> recommended for alignment of the currently opened stack
%       </td>
%       </td>
%     </tr>
%     <tr>
%       <td><b>Automatic feature-based</b></td>
%       <td><a href="https://www.youtube.com/embed/-en5zD5Ou9s"><img src="images/youtube.png"></a> The automatic image alignement based on features (blobs,
%       regions or corners) detected on consecutive slices.<br>
%       The available
%       transfomations are 'similarity', 'affine', or 'projective' (see
%       below for details). The resulting datasets can be cropped to the
%       size and around the position of the first image (the cropped mode)
%       or extended.<br>
%       Use the Preview button to check the number and
%       positions of the detected points.<br>
%       Please refer to the documentation of the <a href="https://se.mathworks.com/help/vision/ref/matchfeatures.html">matchFeatures</a> function of
%       Matlab for more details.
%       </td>
%     </tr>     
%     <tr>
%       <td><b>Single landmark point</b></td>
%       <td>The Single landmark point mode is a manual mode, where user marks
%       corresponding areas on two consequetive slices using the brush tool with
%       a spot. During alignment the images will be translated to align the
%       marked areas
%       </td>
%     </tr>
%     <tr>
%       <td><b>Landmarks, multi points</b></td>
%       <td>Landmarks, multi points align datasets based on marked points.
%       The points for alignment can be selected using the Selection layer or Annotations
%       (<em>recommended</em>), where the corresponding points should have
%       the same name. A table below indicates various transformation
%       types:<br>
%       <img src="images/menuDatasetAlignToolLandmarkModes.jpg">
%       </td>
%     </tr>
%     <tr>
%       <td><b>Three landmark points</b></td>
%       <td><b>It is recommended to use the <em>Landmarks, multi points mode</em> instead!</b><br>
%           Three landmark points mode is another manual mode, where user should mark
%           three corresponding areas on two consequetive slices using the brush tool. 
%           During alignment the images will be translated/scaled/rotated to
%           align the marked areas 
%       </td>
%       <tr>
%       <td><b>Color channels, multi points</b></td>
%       <td>Use landmarks, to register individual color channels. The
%       landmarks are defined using MIB annotations (<em>Segmentation
%       panel->Annotations</em>) as <br>
%       <b>a)</b> the annotation text is used to identify the corresponding points
%       (i.e. two corresponding points should have the same annotation
%       text);<br>
%       <b>b)</b> the annotation value is used to identify the fixed color
%       channel (as number 1) and the color channel that needs to be
%       transformed (as number 2)<br><br>
%       <img src="images/Alignment_Colorchannels.jpg">
%       </td>
%     </tr>
%     </tr>
%     </table>
%   </li>
%   <li>
%     <b>Correlate with</b> - three different options for the reference slide:
%       <ul>
%           <li><b>Previous slice</b>, align each slice to the previous one</li>
%           <li><b>First slice</b>, align all images to the first Z-slice of the sequence; it is good from fixing drift correction problems, when dataset is not changing much</li>
%           <li><b>Relative to</b>, align each slice to another slice with is earlier in the sequence, the number in the <b>Step</b> edit box defines this shift</li>
%       </ul>
%   </li>
%   <li>
%     <b>Color channel</b> - selection of the color channel to use for the alignment process
%   </li>
%   <li>
%     <b>use intensity gradient</b> sometimes better alignement can be
%     achieved when correlating intensity gradients of the original images.
%     Select this checkbox to use the gradients instad of raw images.
%   </li>
%   <li>
%     <b>Background</b> define type of the background after image alignment
%       <ul>
%           <li><b>White</b>, all background pixels of the aligned dataset will be white</li>
%           <li><b>Black</b>, all background pixels of the aligned dataset will be black</li>
%           <li><b>Mean</b>, all background pixels of the aligned dataset will be calculated as an average value of all pixels of the original dataset</li>
%           <li><b>Custom</b>, provide a custom intensity for the background colors</li>
%       </ul>
%   </li>
% </ul>
% </html>
%
%
%% Options panel
% The Options panel is shown only during alignment of the currently
% opened dataset.
%
% 
% <<images/menuDatasetAlignTool_3.jpg>>
%
%
% <html>
% <ul>
%   <li>
%     <b>use Mask/Selection</b> check this to force the alignment tool to
%     calculate correlation only from the masked or selected areas of the
%     dataset. To benefit from this mode use the brush tool to select the
%     most distict area on the first and last slices; after that
%     interpolate one area to another using the I-key shortcut (or from the
%     <em>Menu->Selection->Interpolate as Shape</em>)
%   </li>
%   <li>
%     <b>use subwindow</b> for large uniform images use of subwindow can
%     speed up the alignment significantly. Use the <em>minX, minY, maxX,
%     maxY</em> edit boxes or the <em>Get from Selection</em> button to
%     define the subwindow. 
%   </li>
%   <li>
%     <b>Save/Load shifts to file</b> using this option it is possible to
%     save and load the translation shifts to a disk
%   </li>
% </ul>
% </html>
%
%
%% Second stack panel
% The Options panel is shown only during alignment of two stacks
% 
% <<images/menuDatasetAlignTool_4.jpg>>
%
%
% <html>
% <ul>
%   <li>
%     <b>Directory of images</b> select directory where images of the
%     second stack are located
%   </li>
%   <li>
%     <b>Volume in a single file</b>, use this option when the second stack
%     is embedded into a single file
%   </li>
%   <li>
%     <b>Import from Matlab</b>, if another stack is already open in Matlab
%     it can be imported and aligned with the currently open.
%   </li>
%   <li>
%     <b>Automatic mode</b>, when selected the aligment is done
%     automatically. Alternatively, it is possible to provide parameters
%     manually into the <em>ShiftX</em> and <em>ShiftY</em> edit boxes.
%   </li>
% </ul>
% </html>
%
%% Reference and Acknowledgements
% The alignment algorithm is based on 
% 
% * JC Russ, The image processing handbook, CRC Press, Boca Raton, FL, 1994
% * JD Sugar, AW Cummings, BW Jacobs, DB Robinson, A Free Matlab Script For Spatial Drift Correction, Microscopy Today — Volume 22, Number 5, 2014
% <https://se.mathworks.com/matlabcentral/fileexchange/45453-drifty-shifty-deluxe-m https://se.mathworks.com/matlabcentral/fileexchange/45453-drifty-shifty-deluxe-m>
% * <http://onlinedigeditions.com/publication/?i=223321&p=40 http://onlinedigeditions.com/publication/?i=223321&p=40>
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_dataset.html *Dataset*>
