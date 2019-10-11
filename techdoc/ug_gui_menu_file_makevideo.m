%% Make movie
% This dialog provides access to different settings for making video files. 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>
%
%%
% 
% <<images\menuFileMakeMovie.png>>
% 
%% Crop
%
% * *Full image* - renders video of the whole dataset.
% * *Shown area* - renders video of the shown area only.
% * *ROI* - use selected ROI (the ROI may be defined using <ug_panel_roi.html the ROI panel> ) as area for the video.
%
%% Resize
% * *Width* - modify width of the video file (the width depends on aspect ratio of the voxels).
% * *Height* - modify height of the video file 
% * *Resizing method* - select one of possible resizing methods.
%%
% <html>
% <ul>
% <li><em>nearest</em> - Nearest-neighbor interpolation; the output pixel is assignedthe value of the pixel that the point falls within. No other pixels are considered.
% <li><em>bilinear</em> - Bilinear interpolation; the output pixel value is a weighted average of pixels in the nearest 2-by-2 neighborhood.
% <li><em>bicubic</em> - Bicubic interpolation; the output pixelvalue is a weighted average of pixels in the nearest 4-by-4 neighborhood.
% <li><em>lanczos2</em> - Lanczos-2 kernel.
% <li><em>lanczos3</em> - Lanczos-3 kernel.
% </ul>
% </html>
% 
%% Extras
%
% * *Scale bar*, select the |Scale bar| check box to add a scale bar to the video file. *Note!* if the width of the video is too small the
% scale bar is not rendered.
% * *Direction*, (only for 5D datasets), use it to select direction for
% video generation: "Z-stack" or "Time" for a time series
%
%% Options
%
% *Split channel* - generate a montage image, where each panel has only
% one color channel. 
%
% The dimensions of the montage image can be specified
% using the |Cols| (number of horizontal panels) and |Rows| (number of
% vertical panels) edit boxes. In addition, it is possible to force
% rendering of individual color channels in the grayscale mode (the
% |Grayscale| check box).
% 
% <<images\menuFileSnapshot_split.jpg>>
% 
%
% * *white Bg* - render background in white color for the split
% channel mode and the scale bars
%
%% Format
% Select one of the possible formats
%%
% 
% * *Archival* - Motion JPEG 2000 file with lossless compression
% * *Motion JPEG AVI* - Compressed AVI file using Motion JPEG codec 
% * *Motion JPEG 2000* - Compressed Motion JPEG 2000 file
% * *MPEG-4* - Compressed MPEG-4 file with H.264 encoding (Windows 7 systems only)
% * *Uncompressed AVI* - Uncompressed AVI file with RGB24 video
% 
%% Settings
% Select additional parameters for video rendering
%%
% 
% * *Frame rate* - Rate of playback for the video in frames per second. 
% * *Quality* - Number from 0 through 100. Higher quality numbers result in higher video quality and larger file sizes. Lower quality numbers result in lower video quality and smaller file sizes. 
% Only available for objects associated with the MPEG-4 or Motion JPEG AVI profile. 
% * *The first frame number editbox* - the number of the first frame for the video.
% * *The last frame number editbox* - the number of the last frame for the video.
% * *The back and forth checkbox* - complement the video with the same video rendered in the reverse direction.
% * *Output filename* - name and location of the destination file
% * *back and forth* - add reverse direction when rendering the movie
%  
%
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_file.html *File Menu*>