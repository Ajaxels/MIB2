function mibBioformatsCheck_Callback(obj)
% function mibBioformatsCheck_Callback()
% Bioformats that can be read with loci BioFormats toolbox
% this function updates the list of file filters in obj.mibView.handles.mibFileFilterPopup
%

% %| 
% @b Examples:
% @code mibController.mibBioformatsCheck_Callback();  //  @endcode

% Copyright (C) 04.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

position = obj.mibView.handles.mibFileFilterPopup.UserData;     % get previous position in the list
obj.mibView.handles.mibFileFilterPopup.UserData = obj.mibView.handles.mibFileFilterPopup.Value; % update position in the list

if obj.mibView.handles.mibBioformatsCheck.Value == 1     % use bioformats reader
    extentions = {'mov','pic','ics','ids','lei','stk','nd','nd2','sld','pict'...
        ,'lsm','mdb','psd','img','hdr','svs','dv','r3d','dcm','dicom','fits','liff'...
        ,'jp2','lif','l2d','mnc','mrc','oib','oif','pgm','zvi','gel','ims','dm3','naf'...
        ,'seq','xdce','ipl','mrw','mng','nrrd','ome','amiramesh','labels','fli'...
        ,'arf','al3d','sdt','czi','c01','flex','ipw','raw','ipm','xv','lim','nef','apl','mtb'...
        ,'tnb','obsep','cxd','vws','xys','xml','dm4'};
    extentions = ['all known',sort(extentions)];
    obj.mibView.handles.mibFileFilterPopup.String = extentions;
    obj.mibView.handles.mibFileFilterPopup.Value = position;
else
    image_formats = imformats;  % get readable image formats
    if obj.matlabVersion < 8.0
        video_formats = mmreader.getFileFormats(); %#ok<DMMR> % get readable image formats
    else
        video_formats = VideoReader.getFileFormats(); % get readable image formats
    end
    extentions = ['all known' sort([image_formats.ext 'mrc' 'rec' 'am' 'nrrd' 'h5' 'xml' 'st' 'preali' {video_formats.Extension}])];
    obj.mibView.handles.mibFileFilterPopup.String = extentions;
    obj.mibView.handles.mibFileFilterPopup.Value = position;
end
obj.updateFilelist();
end