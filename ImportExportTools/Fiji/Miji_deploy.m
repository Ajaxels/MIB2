function Miji_deploy(open_imagej)
% function Miji_deploy(open_imagej)
% is a modified Miji.m function adapted for the deployed version of im_browser. Mainly the javaaddpath is removed
%
% @note requires Fiji to be installed (http://fiji.sc/Fiji)
% @note requires mib_java_path.txt file in the directory of im_browser
%
% Parameters:
% open_imagej: a parameter of the original Miji function

% Copyright (C) 12.08.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% based based on Miji written by Jacques Pecreaux, Johannes Schindelin, Jean-Yves Tinevez \<jeanyves.tinevez at gmail.com\.

% 
% This script sets up the classpath to Fiji and optionally starts MIJ
    % Author: Jacques Pecreaux, Johannes Schindelin, Jean-Yves Tinevez

    if nargin < 1
        open_imagej = true;
    end

    %% Maybe open the ImageJ window
    if open_imagej
        %cd ..;
        fprintf('\n\nUse MIJ.exit to end the session\n\n');
        MIJ.start();
    else
        % initialize ImageJ with the NO_SHOW flag (== 2)
        ij.ImageJ([], 2);
    end

    % Make sure that the scripts are found.
    % Unfortunately, this causes a nasty bug with MATLAB: calling this
    % static method modifies the static MATLAB java path, which is
    % normally forbidden. The consequences of that are nasty: adding a
    % class to the dynamic class path can be refused, because it would be
    % falsy recorded in the static path. On top of that, the static
    % path is fsck in a weird way, with file separator from Unix, causing a
    % mess on Windows platform.
    % So we give it up as now.
    % %    fiji.User_Plugins.installScripts();
   
end
