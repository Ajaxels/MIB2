%% Surface Area 3D plugin  
% This plugin was designed for calculation of planar surface areas from 3D
% datasets (see an image below)
% 
% *Features:*
%
%
% * Detection of 3D objects using 26 points connectivity
% * For each of the detected 3D object the plugin calculates its surface area, which is defined from the centerlines of each cross section
% * Export results and resulting surfaces to Matlab, Imaris, Amira or save as CSV, Excel spreadsheets or Matlab binary structure file
% * Visualize the surfaces in Matlab 
%
%
%%
%
% 
% <<SurfaceArea3D_overview.jpg>>
%
%% Parameters
%
% 
% <html>
% <ul>
% <li><b>Material with surfaces</b> - select material from which the objects have
% to be detected and analysed. The object detection is done in 3D using the 26-edge connectivity, the surfaces are generated for separately for each of the detected objects</li>
% <li><b>XY smoothing</b> - each profile of the detected 3D object is thinned to a
% single centerline and the points of that centerline are detected. Coordinates of the
% detected points may be smoothed using this smoothing factor</li>
% <li><b>XY sampling</b> - to generate the surface the detected points are
% triangulated, the <em>XY sampling</em> parameter allows to increase size of
% triangles by skipping points. When <em>XY sampling</em> is 3, each 3rd of the
% detected points will be used for triangulation</li>
% <li><b>Z sampling</b> - similar to <em>XY sampling</em>, but applied to the Z-dimensions</li>
% <li><b>show points</b> - the detected points are displayed as the <em>Selection</em>
% layer in MIB, which gives an easy way to check the points. <b>Important:</b>
% remember to clear the <em>Selection</em> layer after the check (<code><em>Shift+C</em></code> shortcut), otherwise you
% may accidentally add/subtract those areas to/from the model!</li>
% <li><b>Export results to Matlab</b> - generate a structure in Matlab with the
% following fields:
% <ul>
% <li><em>.pixSize</em>, contains info about pixel size of the dataset (first element only). To access it type: <code>SurfaceArea(1).pixSize</code></li>
% <li><em>.MaterialName</em>, name of the analysed material (first element only). To access it type: <code>SurfaceArea(1).MaterialName</code></li>
% <li><em>.xySmoothValue</em>, smoothing in XY (first element only)</li>
% <li><em>.xySamplingStep</em>, xy sampling value (first element only)</li>
% <li><em>.zSamplingStep</em>, z sampling value (first element only)</li>
% <li><em>.SumAreaTotal</em>, the total area of each contact. To access it type: <code>SurfaceArea(N).SumAreaTotal</code>, where N should be replaced with index of the surface</li>
% <li><em>.PointsVector</em>, indices of the detected points for each profile as .PointsVector{SliceId}{IndexOfProfile}[x,y,z]</li>
% <li><em>.PointCloud</em>, matrix with all detected points as [index of the point](x,y,z)</li>
% <li><em>.Centroid</em>, coordinates of centroids for each object</li>
% <li><em>.Area</em> area between each z and z+1 slices, as a cell array, where z is defined from the first slice of the object</li>
% </ul>
% </li>
% <li><b>Save results in Matlab, Excel or CSV format</b> - specify filename to save the results; use the <em>Filename for export</em> button or an editbox below to provide it</li> 
% <li><b>add material name</b> - add name of the processed material to the filename</li>
% <li><b>generate a model for each contact</b> - specify a folder to save generated surfaces in AmiraMesh format</li>
% <li><b>Export contacts to Imaris</b> - export contact surfaces to Imaris, requires Imaris version 8 and ImarisXT connection</li>
% </ul>
% </html>
%
%
%% How to Use:
%
% An example shows the general use of the plugin: the contacts between mitochondria and ER are
% automatically generated from two materials and measured.
% 
% Normally, the
% preferrable way is to draw the contact with a mouse rather than use this
% automatic procedure, since the automatic way may result "bad" profiles as
% on the image above.
%
% 
% Link to youtube.com video: <https://youtu.be/z0jxNHIOipA
% https://youtu.be/z0jxNHIOipA>, please note that the plugin in the video
% named as ContactArea3D and demonstrates application of the plugin for
% analysis of contacts between organelles.
%
% Link to the dataset: <http://mib.helsinki.fi/tutorials/3D_Modeling_files/Huh7.tif http://mib.helsinki.fi/tutorials/3D_Modeling_files/Huh7.tif>
%
% Link to the model: <http://mib.helsinki.fi/tutorials/3D_Modeling_files/Labels_Huh.model http://mib.helsinki.fi/tutorials/3D_Modeling_files/Labels_Huh.model>
%
% Usage of this plugin is also explained in <https://andreapaterlini.github.io/Plasmodesmata_dist_wall/surfaces.html#run_the_surfacearea3d_plugin this work>
%
%% Credits and Acknowledgements
%
% <html>
%  Written by Ilya Belevich, University of Helsinki<br>
%  version 1.00, 13.02.2020<br>
%  email: <a href="mailto:ilya.belevich @ helsinki.fi">ilya.belevich @ helsinki.fi</a><br>
%  web: <a href="https://www.mv.helsinki.fi/home/ibelev">https://www.mv.helsinki.fi/home/ibelev</a><br>
% </html>
%
% *Big thanks to David Legland (Institut National de la Recherche
% Agronomique, France) for discussion about triangulation of points: function
% mibTriangulateCurvePair.m is based on triangulateCurvePair.m from
% <https://github.com/mattools/matGeom/releases MatGeom tools> by David Legland*
%
%% How to cite
% 
% If you used this code please cite it as
%
% Paterlini A., Belevich I., Jokitalo E., Helariutta Y., Novel
% computational approaches to study plasmodesmata and their environment.
% *Journal name*, 
%
% <https://andreapaterlini.github.io/Plasmodesmata_dist_wall/index.html https://andreapaterlini.github.io/Plasmodesmata_dist_wall/index.html> 
%