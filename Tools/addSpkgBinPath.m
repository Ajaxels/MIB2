%Function to add "C:\ProgramData\MATLAB\SupportPackages\R2021a\bin\win64" to
%System Path
function addSpkgBinPath
    mlock
    persistent pathSet
    if isempty(pathSet)
        pathSet = true;
        spPath = matlabshared.supportpkg.getSupportPackageRoot;
        if ~isempty(spPath)
            archStr = computer('arch');
            dllPath = fullfile(spPath, 'bin', archStr);
            if strcmp(archStr, 'win64')
                sysPath = getenv('PATH');
                setenv('PATH',[sysPath pathsep dllPath]);
            end
        end
    end
end