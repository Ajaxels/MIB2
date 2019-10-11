%% The Adjust display window
% This window allows to adjust the contrast of the dataset individually for each color channel. The intensity values for the 
% currently shown slice can be checked in the histogram at the bottom of the window.
%
% <html>
% A brief demonstration is available in the following video:<br>
% <a href="https://youtu.be/WhpzGMyslZU"><img style="vertical-align:middle;" src="images\youtube2.png">  https://youtu.be/WhpzGMyslZU</a>
% </html>
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*> |*-->*| <ug_panel_view_settings.html *View settings*>
%
%%
%
% <<images\PanelsViewSettingsDisplay.png>>
%
%% Parameters
% List of widgets:
% 
% * *Color channel combobox*, use to select a color channel to adjust.
% * *Min slider and editbox*, allow selection of the minimal intensity
% values. The |right mouse| click above the slider sets this value to 1. *Note!* it is also possible to set this value using the |left mouse click| on the histogram plot at the bottom of the window
% * *min button*, finds minimal value for intensity of the selected color channel and set it as 0
% * *Max slider and editbox*, allow selection of the maximal intensity
% values. The |right mouse| click above the slider sets this value to maximal. *Note!* it is also possible to set this value using the |right mouse click| on the histogram plot at the bottom of the window
% * *max button*, finds maximal value for intensity of the selected color channel and set it as maximal possible value
% * *Gamma*, allows modification of gamma parameters. Gamma values < 1 enhance
% high intensity values, and Gamma values > 1 enhance low intensity values.
% The |right mouse| click above the slider sets this value to 1
% * *Link checkbox*, links all color channel so that changing of the
% |Min/Max/Gamma| sliders and editboxes affects all color channels at the
% same time
% * *Log checkbox*, defines type of histogram representation in the histogram plot: linear or logarithmic scale
% * *Auto update*, switches ON automatic update of the histogram. If enabled the histogram is updated after each slice change.
%  *Warning!* Switching on the automatic update of the histogram may significantly decrease rendering of images
% * *Update button*, updates the histogram for the currently shown slice
% * *Current button*, _*recalculates*_ intensities of the selected color channel (the |Channel| combobox) with parameters
% specified in this dialog for the currently shown slice. The intensities below the |Min| value would become black and the intensities above the |Max| value
% would become white. The contrast adjustment of a single slice is not logged in the log list (<ug_panel_path.html see the *Log button* description>)
% * *All slices button*, _*recalculates*_ intensities of the selected color channel (the |Channel| combobox) with parameters
% specified in this dialog for all slices. The intensities below the |Min| value would become black and the intensities above the |Max| value
% would become white
%
%% Histogram at the bottom of the window
% The histogram shows the plot with intensity values in the X-axis and number of pixels for each intensity value in the
% Y-axis. *Note!* The histogram is calculated from the image shown in the <ug_panel_im_view.html Image View panel> - not from the full slice!
%
% The adjustments made with |Gamma| are not shown in the histogram plot.
%
% It is possible to change |Min| and |Max| values for the intensities by
% manual numerical input, using the slider or with the right and left mouse click within the histogram
% plot. 
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_panels.html *Panels*> |*-->*| <ug_panel_view_settings.html *View settings*>
