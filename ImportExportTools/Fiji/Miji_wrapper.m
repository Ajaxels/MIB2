% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function Miji_wrapper(open_imagej)
% function Miji_wrapper(open_imagej)
% A wrapper function to start Miji. Start Fiji in the Matlab and deployed versions of im_browser.
%
% @note requires Fiji to be installed (http://fiji.sc/Fiji).
%
% Parameters:
% open_imagej: a @b open_imagej parameter of Miji
%
% Return values:

% Updates
% 


if ~isdeployed
    Miji(open_imagej);     % from Matlab, use original Miji script in the Fiji/scripts folder
    %MIJ.start;
else
    Miji_deploy(open_imagej);  % from deployed im_browser, use modified Miji script (Miji_deploy) in im_browser/Tools/Fiji
end