function dirOut = obtainDirectoryForAction(obj, dirModeField, filenameField, stepId, stepOptions)
% obtain directory for the actions, supporting function that is
% used in doBatchStep function
%
% Parameters:
% dirModeField: name of a field in obj.Protocol(stepId).Batch. that defines diretory mode to use
% filenameField: name of a in obj.Protocol(stepId).Batch. that defines directory name
% stepId: step index of the protocol
% stepOptions: support structure used in dir and file loops

warning('off', 'MATLAB:MKDIR:DirectoryExists'); % disable warning of existing directories

dirOut = [];
switch obj.Protocol(stepId).Batch.(dirModeField){1}
    case 'Absolute'
        if ~isfolder(obj.Protocol(stepId).Batch.(filenameField))
            try
                mkdir(obj.Protocol(stepId).Batch.(filenameField));
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Problem with directory');
                warning('on', 'MATLAB:MKDIR:DirectoryExists'); % enable warning of existing directories
                return;
            end
        end
        dirOut = obj.Protocol(stepId).Batch.DirectoryName;
    case 'Relative to current MIB path'
        % search for ".."
        pos = strfind(obj.Protocol(stepId).Batch.(filenameField), '..');
        if ~isempty(pos)
            cPath = obj.mibModel.myPath;
            for i=1:numel(pos)
                cPath = fileparts(cPath);
            end
            dirOut = obj.Protocol(stepId).Batch.(filenameField)(pos(end)+3:end);
            dirOut = fullfile(cPath, dirOut);
            if ~isfolder(dirOut)
                try
                    mkdir(dirOut);
                catch err
                    errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Problem with directory');
                    warning('on', 'MATLAB:MKDIR:DirectoryExists'); % enable warning of existing directories
                    return;
                end
            end
        else
            dirOut = fullfile(obj.mibModel.myPath, obj.Protocol(stepId).Batch.(filenameField));
            if ~isfolder(dirOut); mkdir(dirOut); end    % create a new folder if needed
        end
    case 'Inherit from Directory loop'
        if ~isfield(stepOptions, 'DirectoryName')
            errordlg(sprintf('!!! Error !!!\n\nWrong settings: Inherit from Directory loop parameter requires Directory loop before this action!'));
            warning('on', 'MATLAB:MKDIR:DirectoryExists'); % enable warning of existing directories
            return;
        end
        dirOut = stepOptions.DirectoryName;
    case 'Inherit dirs +Dirname'    % get directory from the loop and add subfolder
        if ~isfield(stepOptions, 'DirectoryName')
            errordlg(sprintf('!!! Error !!!\n\nWrong settings: Inherit from Directory loop parameter requires Directory loop before this action!'));
            warning('on', 'MATLAB:MKDIR:DirectoryExists'); % enable warning of existing directories
            return;
        end
        dirOut = fullfile(stepOptions.DirectoryName, obj.Protocol(stepId).Batch.DirectoryName);
end
end
