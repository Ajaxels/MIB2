%% Microscopy Image Browser
%
%%
% 
% <html>
% <table style="width: 550px; text-align: center; border-width: 0px;" cellspacing=2px cellpadding=2px>
% <tr style="font-weight: normal;">
%   <td width=260px><img src="images/im_browser_splash_sm2.jpg"></td>
%   <td><b>Microscopy Image Browser</b><br>
%   <em>image segmentation and beyond</em><br><br>
%   Microscopy Image Browser is a GUI tool that is written under MATLAB environment and can be used for 
%   segmentation of multidimentional datasets obtained by light or electron microscopy<br>
%   <br><br><b>Powered by MATLAB, <a href="https://www.mathworks.com/">The MathWorks, Inc.</a></b>
% </td>
% </tr>
% </table>
% <br>
% </html>
%
%%
% 
% <html>
% <table style="width: 550px; text-align: center; border-width: 0px;" cellspacing=2px cellpadding=2px bgcolor='white'>
% <tr style="font-weight: bold;background: #FFB74D;">
%   <td>General</td>
%   <td>User Guide</td>
%   <td>Tutorials</td>
% </tr>
% <tr style="font-weight: normal;">
%   <td>
%       <a href="im_browser_release_notes.html">Release Notes</a><br><br>
%       <a href="im_browser_features.html">Features</a><br><br>
%       <a href="im_browser_installation.html">Installation</a><br>
%       <a href="im_browser_system_requirements.html">System requirements</a><br><br>
%       <a href="im_browser_ack.html">Acknowledgements</a><br>
%       <a href="im_browser_license.html">License</a><br><br>
%       <a href="im_browser_troubleshooting.html">Troubleshooting</a><br>
%   </td>
%   <td>
%       <a href="im_browser_user_guide.html">User Guide starting page</a><br><br>
%       <a href="ug_gui_menu.html">Menus</a><br>
%       <a href="ug_gui_toolbar.html">Toolbar</a><br>
%       <a href="ug_gui_panels.html">Panels</a><br>
%       <a href="ug_gui_shortcuts.html">Key and mouse shortcuts</a><br>
%   </td>
%   <td>
%       <a href="http://mib.helsinki.fi/tutorials.html">Tutorials main web-page</a><br><br>
%       <ul style="line-height:90%">  
%           <li><a href='http://mib.helsinki.fi/tutorials_tools.html'>Introduction</a></li>
%           <li><a href='http://mib.helsinki.fi/tutorials_segmentation.html'>Image segmentation</a></li>
%           <li><a href='http://mib.helsinki.fi/tutorials_visualization.html'>Visualization</a></li>
%           <li><a href='http://mib.helsinki.fi/tutorials_tools.html'>Tools</a></li>
%           <li><a href='http://mib.helsinki.fi/tutorials_programming.html'>Programming</a></li>
%       </ul>
%   </td>
% </tr>
% </table>
% </html>
% 
% API class reference can be accessed from the
% [class.code]MIB->Menu->Help->Class reference[/class]
%
% Also see the <http://mib.helsinki.fi Microscopy Image Browser home page> 
%
%%
% 
% <html>
% Developed during 2010-2023 by<br>
% Core developer:<br>
% <a href="http://www.biocenter.helsinki.fi/~ibelev/">Ilya Belevich</a><br>
% Developers:<br>
% Merja Joensuu, Darshan Kumar, Helena Vihinen and Eija Jokitalo<br><br>
% <i><a href="http:\\www.biocenter.helsinki.fi/bi/em">Electron Microscopy Unit</a><br>
% Institute of Biotechnology<br>
% PO Box 56 (Viikinkaari 9)<br>
% 00014, University of Helsinki<br>
% Finland</i>
% </html>
% 
%
%
% *Back to* <im_browser_product_page.html *Index*>
% [themesEnabled]
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
