%% Dataset Menu
% Modify parameters such as voxel sizes and the bounding box for the
% dataset, start the Alignment tool, or do some other dataset related actions.
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*>
%
%%
% 
% <<images\menuDataset.png>>
% 
%% Alignment tool...
%
% Can be used to align the slices of the opened dataset or to align two
% separate datasets. See details <ug_gui_menu_dataset_alignment.html *here*>.
% 
% [dtls][smry] *Alignement window* [/smry]
%
% <<images/MenuDatasetAlignment.png>>
%
% [/dtls]
%
%
%% Crop dataset...
% Crop the image and corresponding Selection, Mask, and Model layers.
% Cropping can be done in the Interactive, Manual or using ROI mode. 
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/PQtpYUuJwG8"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/PQtpYUuJwG8</a>
% </html>
% 
% <<images/MenuDatasetCrop.png>>
% 
% When the interactive mode is selected it is possible to draw (by pressing and holding left mouse button) a rectangle
% area a top of the image. This area can then be used for cropping. 
%
% The values for cropping may also be provided directly by enabling the
% |Manual| mode. It is also possible to do cropping based on the selected
% ROI. Use the <ug_panel_roi.html ROI panel> to make them.
%
% The dataset can be just cropped (the [class.kbd]Crop[/class] button) or copied 
% to another buffer and cropped (the [class.kbd]Crop to[/class] button). The multiple buffer buttons buttons located at
% the top of the <ug_panel_dir.html Directory Contents panel>.
%
% The cropped datasets can be placed back to the original dataset using the
% _Fuse into existing_ mode of the _Chop image tool_ available at
% |Menu->File->Chop images...->Import...|. <ug_gui_menu_file_chop.html See more here.>
% 
% 
%% Resample...
% Resample image in any possible direction. 
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/26-HROwg_JM"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/26-HROwg_JM</a>
% </html>
%
%%
% 
% <<images/MenuDatasetResample.png>>
% 
%
%% Transform
% Transformation of dataset: image and all other layers. The following modes are possible
%
% <html>
% <table>
% <tr>
% <td><b>Add frame -> provide new width/height</b></td>
% <td>specify the frame by providing new width and height of the dataset.</td>
% </tr>
% <tr>
% <td><b>Add frame -> provide dX/dY</b></td>
% <td>pads dataset in X (<em>Frame width, px</em>) and Y (<em>Frame height,
% px</em>) directions with a distinct number (<em>Intensity pad value</em>)
% or using various repetition methods:<br>
% <ul>
% <li><em>replicate:</em> pad by repeating border elements of array</li>
% <li><em>circular:</em> pad with circular repetition of elements within the dimension</li>
% <li><em>symmetric:</em> pad array with mirror reflections of itself</li>
% </ul>
% Position of the frame can be specified with the direction parameter:
% <ul>
% <li><em>both:</em> pads before the first element and after the last array element along each dimension</li>
% <li><em>pre:</em> pad before the first array element along each dimension</li>
% <li><em>post:</em> pad after the last array element along each dimension</li>
% </ul>
% </td>
% </tr>
% <tr><td><b>Flip horizontally</b></td>
% <td>- flip dataset left to right, returns the dataset with columns flipped in the left-right direction, that is, about a vertical axis
% <tr><td><b>Flip vertically</b></td>
% <td>- flip dataset up to down, returns the dataset with rows flipped in the up-down direction, that is, about a horizontal axis</td></tr>
% <tr><td><b>Flip Z</b></td>
% <td>- flip dataset in the Z dimension, returns the dataset with slices flipped in the first-last direction, that is, about a middle slice of the dataset</td></tr>
% <tr><td><b>Flip Y</b></td>
% <td>- flip dataset in the T dimension, returns the dataset with time frames flipped in the first-last direction, that is, about a middle frame of the dataset</td></tr>
% <tr><td><b>Rotate 90 degrees</b></td>
% <td>- rotate dataset 90 degrees clockwise diirection</td></tr>
% <tr><td><b>Rotate -90 degrees</b></td>
% <td>- rotate dataset 90 degrees anti-clockwise diirection</td></tr>
% <tr><td><b>Transpose YX -> YZ</b></td>
% <td>- physically transpose the dataset, so that the YX orienation, becomes YZ. Repeat of this operation returns dataset back to the original configuration</td></tr>
% <tr><td><b>Transpose YX -> XZ</b></td>
% <td>- physically transpose the dataset, so that the YX orienation, becomes XZ. . Repeat of this operation twice to return dataset back to the original configuration</td></tr>
% <tr><td><b>Transpose YX -> XY</b></td>
% <td>- physically transpose the dataset, so that the YX orienation, becomes XY. Repeat of this operation returns dataset back to the original configuration</td></tr>
% <tr><td><b>Transpose YX -> ZX</b></td>
% <td>- physically transpose the dataset, so that the YX orienation, becomes ZX. Repeat of this operation returns dataset back to the original configuration</td></tr>
% <tr><td><b>Transpose Z <-> T</b></td>
% <td>- physically transpose the dataset, so that the Z orienation, becomes T</td></tr>
% <tr><td><b>Transpose Z <-> C</b></td>
% <td>- physically transpose the dataset, so that the Z (depth) orienation, becomes C (color)</td></tr>
% </table>
% A brief demonstration is available in the following videos:<br>
% Flip: <a href="https://youtu.be/lGjhB-NJZMk"><img style="vertical-align:middle;" src="images\youtube.png"> https://youtu.be/lGjhB-NJZMk</a><br>
% Rotate: <a href="https://youtu.be/WFbZn0rfb5I"><img style="vertical-align:middle;" src="images\youtube.png"> https://youtu.be/WFbZn0rfb5I</a><br>
% Transpose: <a href="https://youtu.be/PyEXX7j6pnc"><img style="vertical-align:middle;" src="images\youtube.png"> https://youtu.be/PyEXX7j6pnc</a><br>
% </html>
%
% [br8]
%
%% Slice
% Manipulations with individual slices of the dataset. 
%
% [dtls][smry] *The following actions are possible* [/smry]
% 
% <html>
% <ul>
% <li> <b>Copy slice...</b> - allows to copy slice from one
% position to another position within the same dataset (the 'Replace' options) or to insert one slice to another position in the dataset 
% (the 'Insert' option). <a href="https://youtu.be/iGA4US2PHXw"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/iGA4US2PHXw</a>. </li>
% <li> <b>Insert empty slice(s)...</b> - insert a uniformly colored slice (or slices) to any
% position inside the dataset <a href="https://youtu.be/iGA4US2PHXw"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/iGA4US2PHXw</a>.</li>
% <li> <b>Interval slicing...</b> - replace the current dataset with extract of each N-th slice from the dataset</li>
% <li> <b>Swap slices...</b> - spaw two or more slices</li>
% <li> <b>Delete slice(s)...</b> - removes desired slice(s) from a Z-stack of the
% dataset. For example, type <span class="code"> 5:10 </span> to delete all slices from slice 5 to slice 10.</li>
% <li> <b>Delete frame(s)...</b> - removes desired frame(s) from a time series of the dataset.</li>
% </ul>
% </html>
%
% [/dtls]
% [br8]
%
%% Scale bar
% Scale bar is a tool that allows to use a scale bar printed on the 
% image to calibrate physical size (X and Y) for pixels in MIB.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/NZO0HG1d8ys"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/NZO0HG1d8ys</a>
% </html>
% 
% 
%% Bounding Box...
% Bounding Box defines position of the dataset in the 3D space; the
% bounding box information is important for positioning
% of datasets in the visualization software, such as Amira.
% The bounding box can be shifted based
% on its minimal or centeral coordinates. The current coordinates of the bounding box 
% are shown under the _Current Bounding Box_ text.
% 
% *Attention!* For 3D images the bounding box is calculated as the smallest
% box containing all voxel centers, but not all voxels as is! _I.e._ it's defined by the voxel centers, which means 
% that a 1/2 voxel on both sides of the bounding box are subtracted, resulting in a bounding box that is 1 voxel smaller in all three directions.
% 
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/lY0XjNy4Dr8"><img style="vertical-align:middle;" src="images\youtube.png">  https://youtu.be/lY0XjNy4Dr8</a>
% </html>
%
% <<images/MenuDatasetBoundingBox.png>>
% 
% [dtls][smry] *Widgets and parameters* [/smry]
% 
% * *X, Y, Z, min* - defines minimal coordinates of the bounding box
% * *X, Y, center* - defines central coordinates of the dataset. When the
% central coordinates are used the |X, min| and |Y, min| coordinates are
% going to be recalculated.
% * **X, Y, Z max* - maximal values of the bounding box. When entered
% together with the *X, Y, Z min* coordinates - MIB recalculates the voxel sizes.
% * *Stage rotation bias, degrees* - implemented only when entering X, Y center coordinates. Allows recalculation of the
% coordinates for the cases when the stage has some rotation bias, for example, Gatan 3View has 45 degrees stage bias.
% * *Import from Clipboard*, parses text in the system clipboard and
% automatically extracts the following parameters (syntax: _[ParameterName] = [ParameterValue]_): 
%
%
% <html>
% <table style="width: 550px; text-align: center;" cellspacing=2px cellpadding=2px >
% <tr>
%   <td style="width=150px;"><b>Parameter Name</b></td><td><b>Description</b></td>
% </tr>
% <tr>
%   <td style="width=150px;">ScaleX</td><td>The physical size of pixels in X</td>
% </tr>
% <tr>
%   <td style="width=150px;">ScaleY</td><td>The physical size of pixels in Y</td>
% </tr>
% <tr>
%   <td style="width=150px;">ScaleZ</td><td>The physical size of pixels in Z</td>
% </tr>
% <tr>
%   <td style="width=150px;">xPos</td><td>Central position of the dataset in the X plane</td>
% </tr>
% <tr>
%   <td style="width=150px;">yPos</td><td>Central position of the dataset in the Y plane</td>
% </tr>
% <tr>
%   <td style="width=150px;">Z Position</td><td>Minimal Z coordinate</td>
% </tr>
% <tr>
%   <td style="width=150px;">Rotation</td><td>Rotation BIAS<br><b>Note!</b><br><em>Since it is designed for Gatan 3View system MIB adds 45 degrees to the detected rotation value</em></td>
% </tr>
% </table>
% </html>
%
% [/dtls]
%
% [dtls][smry] *Example for automatic detection of parameters* [/smry]
%
% Example of text that can be copied to the system clipboard for automatic
% detection of parameters:
% 
% <<images/menuDatasetBoundingBox2.jpg>>
% 
% [/dtls]
% [br8]
% 
%% Parameters
% Modifies parameters of the dataset: voxels sizes, frame rate for movies and
% units. Enter of new voxels results in recalculation of the bounding box.
%%
% 
% <<images/menuDatasetParameters.png>>
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
