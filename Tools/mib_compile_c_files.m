% This script will compile all the C files
% get MIB directory
mibDir = fileparts(which('mib'));

%% Compiling coherence filter
wb = waitbar(0, sprintf('Compiling Volume rendering\nPlease wait...'), 'Name', 'Compiling c files');

currDir = fullfile(mibDir, 'GuiTools','volren');
cd(currDir);
mex -compatibleArrayDims -v affine_transform_2d_double.c image_interpolation.c;

%% Compiling fast marching
waitbar(0.05, wb, sprintf('Compiling Fast Marching\nPlease wait...'));
currDir = fullfile(mibDir, 'Tools','FastMarching','functions');
cd(currDir);
%mex('msfm2d.c' ,'-v');
%mex('msfm3d.c' ,'-v');
mex -compatibleArrayDims -v msfm2d.c
mex -compatibleArrayDims -v msfm3d.c

currDir = fullfile(mibDir, 'Tools','FastMarching','shortestpath');
cd(currDir);
%mex('rk4.c' ,'-v');
mex -compatibleArrayDims -v rk4.c

%% Compiling Frangi
waitbar(0.1, wb, sprintf('Compiling Frangi\nPlease wait...'));
currDir = fullfile(mibDir, 'Tools','Frangi');
cd(currDir);
mex -compatibleArrayDims -v eig3volume.c
mex -compatibleArrayDims -v imgaussian.c

%% Compiling Membrane Detection 
waitbar(0.15, wb, sprintf('Compiling Membrane Detection\nPlease wait...'));
currDir = fullfile(mibDir, 'Tools','RandomForest','MembraneDetection');
cd(currDir);
mex('meanvar.c' ,'-v');
mex('transformImageFast.c' ,'-v');

%% Compiling SLIC superpixels
waitbar(0.2, wb, sprintf('Compiling SLIC and Maxflow\nPlease wait...'));
currDir = fullfile(mibDir, 'Tools','Supervoxels');
cd(currDir);
mex('slicmex.c' ,'-v');
mex('slicsupervoxelmex.c' ,'-v');
mex('slicsupervoxelmex_byte.c' ,'-v');
mex -v -largeArrayDims maxflowmex_v222.cpp maxflow-v2.22/adjacency_list_new_interface/graph.cpp maxflow-v2.22/adjacency_list_new_interface/maxflow.cpp
%mex -v -largeArrayDims maxflowmex_v301.cpp maxflow-v3.01/graph.cpp maxflow-v3.01/maxflow.cpp

%% Compiling patchnormals
% the patchnormals are not compiled because they
% the compiled patchnormals have some issues with memory, so it is not
% recommended to compile it
% waitbar(0.25, wb, sprintf('Compiling patchnormals\nPlease wait...'));
% currDir = fullfile(mibDir, 'Tools');
% cd(currDir);
% mex('patchnormals_double.c' ,'-largeArrayDims', '-v');

%% Compiling GetExeLocation to acquire path to deployed MIB
waitbar(0.25, wb, sprintf('Compiling GetExeLocation\nPlease wait...'));
currDir = fullfile(mibDir, 'Tools');
cd(currDir);
mex('GetExeLocation.c', '-v');

%% Compiling Region Growing
waitbar(0.3, wb, sprintf('Compiling Region Growing\nPlease wait...'));
currDir = fullfile(mibDir, 'Tools','RegionGrowing');
cd(currDir);
mex('RegionGrowing_mex.cpp' ,'-v');
waitbar(1, wb);
delete(wb);

nrrdPath = fullfile(mibDir, 'ImportExportTools','nrrd','compilethis.m');
forestPath1 = fullfile(mibDir, 'Tools','RandomForest','RF_Class_C');
forestPath2 = fullfile(mibDir, 'Tools','RandomForest','RF_Reg_C');
strText = '!!! Warning !!!\n\nThe following files have to be compiled manually:\n1) NRRD Reader\n%s\n\n2) Random Forest Classifier for Linux\n%s\n%s';
warndlg(sprintf(strText, nrrdPath, forestPath1,forestPath2));
disp('!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!')
disp('The following files have to be compiled manually:')
disp('1) NRRD Reader')
disp(nrrdPath)
disp('2) Random Forest Classifier for Linux')
disp(forestPath1)
disp(forestPath2)

