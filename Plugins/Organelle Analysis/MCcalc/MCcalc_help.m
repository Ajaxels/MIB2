%% MCcalc - Detection of contacts between organelles in 2D images
%
% This plugin is designed to detect contacts (areas where two objects are
% closer than a predefined threshold to each other) between the materials
% (organelles). In addition, the plugin calculates the distance
% distribution between the two material and offers possibility to export
% results in Matlab or Excel formats or as graphical snapshots.
%
% This plugin was originally designed for contact detection for images
% taken with transmission electron microscopy (TEM) but in practice can
% work with any kind of light or electron microscopy datasets.
% 
% For details please refer to tutorial on
% <http://mib.helsinki.fi/tutorials_tools.html MIB-website->Tutorials->Tools->MCcalc section>
%
%
% 
% <<MCcalc_GUI.jpg>>
% 
%
%% Acknowledgments
%
% For calculation of the normal vectors the plugin is using LineNormals2D
% function from 2D Line Curvature and Normals package, written by Dirk-Jan
% Kroon, University of Twente / Focal Machine Vision en Optical Systems
% 2011 <https://se.mathworks.com/matlabcentral/fileexchange/32696-2d-line-curvature-and-normals https://se.mathworks.com/matlabcentral/fileexchange/32696-2d-line-curvature-and-normals>
%