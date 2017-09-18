function updateImgInfo(obj, addText, action, entryIndex)
% function updateImgInfo(obj, addText, action, entryIndex)
% Update action log
%
% This function updates the image log with recent events done to the dataset; it updates the contents of
% mibImage.meta(''ImageDescription'') key.
%
% Parameters:
% addText: a string that should be added to the log
% action: [@em optional] - defines additional actions that may be performed with the log:
% - ''delete'' - delete entry defined with 'entryIndex'
% - ''insert'' - insert new entry after the one defined with 'entryIndex'
% - ''modify'' - modify entry with 'entryIndex'
% entryIndex: [@em optional] - index of the entry to delete, modify or insert
%
% Return values:
%

%| 
% @b Examples:
% @code slice = mibImage.updateImgInfo('Image was filtered');      // Add 'Image was filtered' text into the mibImage.meta('ImageDescriotion')  @endcode
% @code slice = mibImage.updateImgInfo('','delete',4);      // Delete entry number 4 from the log  @endcode
% @code slice = mibImage.updateImgInfo('New entry inserted','insert',4);      // Insert new entry into the log at position 4 @endcode
% @code slice = mibImage.updateImgInfo('Updated text','modify',4);      // Modify text at position 4 @endcode

% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

add_switch = 0;
if nargin < 3; add_switch = 1; end    % adding addText to the end of the list

if isnan(addText) == 1; add_switch = 0; end
curr_text = obj.meta('ImageDescription');
if add_switch   % add text
    if isempty(curr_text)
        obj.meta('ImageDescription') = [curr_text sprintf('|MIB(') datestr(now,'yymmddHHMM') '): ' addText];    
    else
        if strcmp(curr_text(end),sprintf('|'))
            obj.meta('ImageDescription') = [curr_text sprintf('MIB(') datestr(now,'yymmddHHMM') '): ' addText];
        else
            obj.meta('ImageDescription') = [curr_text sprintf('|MIB(') datestr(now,'yymmddHHMM') '): ' addText];
        end
    end
else            % insert or delete entry
    % generate list of entries
    linefeeds = strfind(curr_text,sprintf('|'));
    %if numel(curr_text) > 1 && isempty(linefeeds)
    %    linefeeds =
    if isempty(linefeeds)
        linefeeds = [1 numel(curr_text)+1];
    else
        linefeeds = [1 linefeeds numel(curr_text)+1];
    end
    for entryId = 1:numel(linefeeds)-1
        entry{entryId} = curr_text(linefeeds(entryId):linefeeds(entryId+1)-1); %#ok<AGROW>
    end
    if strcmp(action, 'delete')     % delete entry
        newIndex = 1;
        for i=1:numel(entry)
            if i~=entryIndex
                entryOut(newIndex) = entry(i); %#ok<AGROW>
                newIndex = newIndex + 1;
            end
        end
        entry = entryOut;
    elseif strcmp(action, 'insert')  % insert entry
        entry(entryIndex+1:numel(entry)+1) = entry(entryIndex:end);
        entry(entryIndex) = cellstr([sprintf('|MIB(') datestr(now,'yymmddHHMM') '): ' addText]);
    elseif strcmp(action, 'modify')  % modify entry
        entry(entryIndex) = cellstr([sprintf('|MIB(') datestr(now,'yymmddHHMM') '): ' addText]);
    end
    curr_text = '';
    for i=1:numel(entry)
        curr_text = [curr_text entry{i}]; %#ok<AGROW>
    end
    obj.meta('ImageDescription') = curr_text;
end

% notify mibModel about updated meta property of mibImage
%notify(obj, 'updateImgInfo');
end