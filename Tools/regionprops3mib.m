function output = regionprops3mib( input, varargin )
% regionprops3mib measures the geometric properties of image objects in 
%  3D space. Objects are defined as connected pixels in 3D. This function 
%  uses regionprops to get pixellist from the binary image. If you'd like
%  to define objects connectivity on our own, use bwlabeln first. 
% 
%  output = regionprops3mib(img,properties) takes 3-D binary image or output 
%  from bwlabeln and returns measurement as specified by properties. If no
%  property is specified, the function will return all measurements by 
%  default.
%
%  output = regionprops3mib(img,'IsPixList', properties) takes an M x 3 matrix of
%  pixell list as input and returns measurements. 
%  
%  Properties can be a comma-separated list of strings such as: 
% 
%  'MajorAxis' : returns a unit vector that points in the
%  direction of the major axis
%  
%  'MajorAxisLength' : returns the length of the major axis
%  'FirstAxisLength' : returns the length of the first axis
%  'SecondAxisLength' : returns the length of the second axis
%
%  'Centroid' : returns the centroid of the object
%
%  'AllAxes' : returns measurements of all three principal axes of image
%   objects, including axis directions, eigenvalues and axis lengths, all
%   organized in descending axis length. 
%  
%  'Eccentricity' : returns Meriodional Eccentricity, defineds as the 
%   eccentricity of the section through the longest and the shortest axes
%   and Equatorial Eccentricity, defined as the eccentricity of the 
%   section through the second longest and the shortest axes. 
%  
%  Version 1.1.1
%  Copyright 2014 Chaoyuan Yeh

% 09.12.2014 modified by Ilya Belevich ilya.belevich @ helsinki.fi to fix
% situations when object has only a single pixel
% 14.11.2016, modified by Ilya Belevich, ilya.belevich @ helsinki.fi to add
% 'FirstAxisLength', 'SecondAxisLength' parameters
% 08.11.2017, renamed to regionprops3mib to do not overlap with
% regionprops3 released with Matlab R2017b

if sum(strcmpi(varargin,'IsPixList'))
    if isstruct(input)
        pixList = input;
    elseif length(size(input))== 2 && size(input,2) == 3
        pixList.pixList = input;
    else
        error('Pixel list should be either an Mx3 matrix or a structured array of Mx3 matrix');
    end
else
    pixList = regionprops(input, 'PixelList');
end

flag = false;
if numel(varargin)-sum(strcmpi(varargin,'IsPixList')) == 0, flag = true; end
if ~isstruct(pixList), pixList.PixelList = pixList; end

for ii = 1:length(pixList)
    pixs = struct2array(pixList(ii));
    covmat = cov(pixs);
    % fix situation when object consists of a single pixel
    if size(covmat,1) == 1 
        covmat = [covmat 0 0; 0 covmat 0; 0 0 0]; %#ok<AGROW>
    end
    [eVectors, eValues] = eig(covmat);
    eValues = diag(eValues);

    [eValues, idx] = sort(eValues,'descend');
    
    if flag || sum(strcmpi(varargin,'MajorAxis'))
        output(ii).MajorAxis = eVectors(:,idx(1))';
    end
    
    if flag || sum(strcmpi(varargin,'MajorAxisLength'))
        distMat = sum(pixs.*repmat(eVectors(:,idx(1))',size(pixs,1),1),2);
        output(ii).MajorAxisLength = range(distMat);
    end
    
    if flag || sum(strcmpi(varargin,'FirstAxisLength'))
            if size(pixs,1) > 1
                distMat = sum(pixs.*repmat(eVectors(:,idx(1))', size(pixs,1),1),2);
                output(ii).FirstAxisLength = range(distMat);
            else
                output(ii).FirstAxisLength = 1;
            end
    end
    
    if flag || sum(strcmpi(varargin,'SecondAxisLength'))
        if size(pixs,1) > 1
            distMat = sum(pixs.*repmat(eVectors(:,idx(2))',size(pixs,1),1),2);
            output(ii).SecondAxisLength = range(distMat);
        else
            output(ii).SecondAxisLength = 1;
        end
    end
    
    if flag || sum(strcmpi(varargin,'AllAxes')) 
        output(ii).FirstAxis = eVectors(:,idx(1))';
        output(ii).SecondAxis = eVectors(:,idx(2))';
        output(ii).ThirdAxis = eVectors(:,idx(3))';
        output(ii).EigenValues = eValues'; 
        distMat = sum(pixs.*repmat(eVectors(:,idx(1))',size(pixs,1),1),2);
        output(ii).FirstAxisLength = range(distMat);
        distMat = sum(pixs.*repmat(eVectors(:,idx(2))',size(pixs,1),1),2);
        output(ii).SecondAxisLength = range(distMat);
        distMat = sum(pixs.*repmat(eVectors(:,idx(3))',size(pixs,1),1),2);
        output(ii).ThirdAxisLength = range(distMat);
    end
    
    if flag || sum(strcmpi(varargin,'Centroid')) 
        output(ii).Centroid = mean(pixs,1);
    end
    
    if flag || sum(strcmpi(varargin,'Eccentricity'))
        output(ii).MeridionalEccentricity = sqrt(1-(eValues(3)/eValues(1))^2);
        output(ii).EquatorialEccentricity = sqrt(1-(eValues(3)/eValues(2))^2);
    end
end

