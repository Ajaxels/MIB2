function exportONNXNetwork(Network, filename, varargin)
%exportONNXNetwork  Export network or graph of layers to ONNX model format.
%
% exportONNXNetwork(net,filename) exports the trained network or graph of network layers (net) 
% with weights to the ONNX format file specified by filename. If filename exists, then exportONNXNetwork overwrites the file.
%
%  Inputs:
%  -------
%
%  Network      - Trained network or graph of network layers, specified as a SeriesNetwork, DAGNetwork, dlnetwork, or layerGraph.
%
%  filename     - Name of file, specified as a character vector or string.
%
%  exportONNXNetwork(...,Name,Value) specifies additional name-value pairs described below:
%
%  'NetworkName'    - Name of ONNX network to store in the saved file, specified as a character vector or string.
%                     Default: 'Network'
%
%  'OpsetVersion'   - Version of ONNX operator set to use, specified as an integer. Supported versions are 6, 7, 8, 9.
%                     Default: 8
%
%  'BatchSize'      - An integer batch size to export, or [] indicating variable batch size.
%                     Default: []


% Copyright 2018-2023 The Mathworks, Inc.


%% Check if support package is installed
breadcrumbFile = 'nnet.internal.cnn.supportpackages.isOnnxInstalled';
fullpath = which(breadcrumbFile);

%if isdeployed
   % Function is being called from a compiled app; throw an error    
%   error(message("nnet_cnn:supportpackages:CannotDeployImporterOrExporter", mfilename));
%   msgbox('I am in the deployed part!');
% elseif isempty(fullpath)
if isempty(fullpath)   
   % Not installed; throw an error
   name = 'Deep Learning Toolbox Converter for ONNX Model Format';
   basecode = 'ONNXCONVERTER';
   error(message('nnet_cnn:supportpackages:InstallRequired', ...
       mfilename, name, basecode));
end

% if isempty(fullpath)
%     % Not installed; throw an error
%     name = 'Deep Learning Toolbox Converter for ONNX Model Format';
%     basecode = 'ONNXCONVERTER';
%     error(message('nnet_cnn:supportpackages:InstallRequired', ...
%         mfilename, name, basecode));
% end

% Call the main function
nnet.internal.cnn.onnx.exportONNXNetwork(Network, filename, varargin{:});
end
