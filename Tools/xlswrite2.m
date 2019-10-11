function [success, message]=xlswrite2(file, data, sheet, range)
% function [success,message]=xlswrite2(file,data,sheet,range)
% XLSWRITE Stores numeric array or cell array in Excel workbook.
%
% This is a wrapper function, please see details in xlswrite3 and xlwrite
% functions
%   
success = 0;
message = '';

if nargin < 3
    sheet = 'Sheet1';
    range = '';
elseif nargin < 4
    range = '';
end

if verLessThan('matlab', '9.6')
    if ispc()
        [success, message]=xlswrite3(file, data, sheet, range);
    else
        success=xlwrite(file, data, sheet, range);
        message = [];
    end
else
    try
        if strcmp(range, '')
            writecell(data, file, 'Sheet', sheet);
        else
            writecell(data, file, 'Sheet', sheet, 'Range', range);
        end
        success = 1;
    catch err
        message = err;
        success = 0;
        errordlg(sprintf('!!! Error !!!\n\nExport to Excel has a problem:\n%s', err.message), 'Export to Excel');
    end
end

