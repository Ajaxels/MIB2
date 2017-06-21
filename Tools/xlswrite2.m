function [success, message]=xlswrite2(file, data, sheet, range)
% function [success,message]=xlswrite2(file,data,sheet,range)
% XLSWRITE Stores numeric array or cell array in Excel workbook.
%
% This is a wrapper function, please see details in xlswrite3 and xlwrite
% functions
%   

if nargin < 3
    sheet = Sheet1;
    range = '';
elseif nargin < 4
    range = '';
end

if ispc()
    [success, message]=xlswrite3(file, data, sheet, range);
else
    success=xlwrite(file, data, sheet, range);
	message = [];
end


