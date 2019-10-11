function mibChannelMixerTable_CellEditCallback(obj, Indices, PreviousData, modifier)
% function mibChannelMixerTable_CellEditCallback(obj, Indices, PreviousData, modifier)
% a callback edit of a cell in obj.mibView.handles.mibChannelMixerTable
%
% Parameters:
% Indices: row and column indices of the cell(s) edited
% PreviousData: previous data for the cell(s) edited
% modifier: a pressed key modifier, [], 'control', 'shift'

% Copyright (C) 07.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
if nargin < 4; modifier = []; end

data = obj.mibView.handles.mibChannelMixerTable.Data;

selected = find(cell2mat(data(:,2))==1)';
if isempty(selected)
    data{Indices(1), 2} = PreviousData;
    obj.mibView.handles.mibChannelMixerTable.Data = data;
    return;
end
if strcmp(modifier, 'control') % toggle between two color channels using the Ctrl modifier
    for i=1:size(data,1);        data{i,2} = 0;    end    % clear selected channels
    data{Indices(1,1),2} = 1;
    obj.mibView.handles.mibChannelMixerTable.Data = data;
end

obj.mibModel.I{obj.mibModel.Id}.slices{3} = find(cell2mat(data(:,2))==1)';

if numel(obj.mibModel.I{obj.mibModel.Id}.slices{3}) == 1
    obj.mibView.handles.mibColChannelCombo.Value = obj.mibModel.I{obj.mibModel.Id}.slices{3}+1;    % update color channel combo box in the Selection panel
    obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel = obj.mibModel.I{obj.mibModel.Id}.slices{3};
end
obj.redrawMibChannelMixerTable();
obj.plotImage(0);
end