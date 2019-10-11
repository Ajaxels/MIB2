function [pathname] = uigetfile_n_dir(start_path, dialog_title)
% Pick multiple directories and/or files
%
% Modified by Ilya Belevich
%

import javax.swing.JFileChooser;

if nargin < 2; dialog_title = 'Select directories'; end
if nargin < 1; start_path = []; end
if isempty(start_path); start_path = pwd; end

jchooser = javaObjectEDT('javax.swing.JFileChooser', start_path);
jchooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
jchooser.setDialogTitle(dialog_title);
jchooser.setMultiSelectionEnabled(true);

status = jchooser.showOpenDialog([]);

if status == JFileChooser.APPROVE_OPTION
    jFile = jchooser.getSelectedFiles();
    pathname{size(jFile, 1)}=[];
    for i=1:size(jFile, 1)
        pathname{i} = char(jFile(i).getAbsolutePath);
    end
elseif status == JFileChooser.CANCEL_OPTION
    pathname = [];
else
    error('Error occured while picking file.');
end
