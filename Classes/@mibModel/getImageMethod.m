function varargout = getImageMethod(obj, methodName, id, varargin)
% function varargout = getImageMethod(obj, methodName, id, varargin)
% run desired method of the mibImage class
%
% Using this function the syntax result =
% obj.mibModel.I{obj.mibModel.I}.methodName can be written as
% obj.mibModel.getImageMethod('methodName')
%
% Parameters:
% methodName: a string with name of the mibImage method to run
% id: [@b optional], id of the dataset, when NaN the currently shown dataset (obj.Id)
% varargin: list of parameters for the method to call
%
% Return values:
% varargout: output results

%|
% @b Examples:
% @code data = obj.mibModel.getImageMethod('getData', NaN, 'image', 4, 0);;     // call from mibController: get current dataset @endcode
% @code obj.mibModel.getImageMethod('updateImgInfo', NaN, 'updated!');     // call from mibController: update image info for the dataset @endcode
% @code timePoint = obj.mibModel.getImageMethod('getCurrentTimePoint', NaN);     // call from mibController: get current time point @endcode
%
% @attention this method is about 3.1 times slower than use direct access
% to methods of mibImage as obj.mibModel.I{obj.mibModel.Id}.methodName();
% It is still fast ~40 ns/call

% Copyright (C) 13.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%


if nargin < 3; id = NaN; end;
if isnan(id); id = obj.Id; end;

fh = str2func(methodName);  
switch numel(varargin)
    case 0
        switch nargout
            case 0
                fh(obj.I{id});
            case 1
                varargout{1} = fh(obj.I{id});
            case 2
                [varargout{1}, varargout{2}] = fh(obj.I{id});
            case 3
                [varargout{1}, varargout{2}, varargout{3}] = fh(obj.I{id});
            case 4
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = fh(obj.I{id});
            case 5
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}, varargout{5}] = fh(obj.I{id});
        end
        
    case 1
        switch nargout
            case 0
                fh(obj.I{id}, varargin{1});
            case 1
                varargout{1} = fh(obj.I{id}, varargin{1});
            case 2
                [varargout{1}, varargout{2}] = fh(obj.I{id}, varargin{1});
            case 3
                [varargout{1}, varargout{2}, varargout{3}] = fh(obj.I{id}, varargin{1});
            case 4
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = fh(obj.I{id}, varargin{1});
            case 5
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}, varargout{5}] = fh(obj.I{id}, varargin{1});
        end
    case 2
        switch nargout
            case 0
                fh(obj.I{id}, varargin{1}, varargin{2});
            case 1
                varargout{1} = fh(obj.I{id}, varargin{1}, varargin{2});
            case 2
                [varargout{1}, varargout{2}] = fh(obj.I{id}, varargin{1}, varargin{2});
            case 3
                [varargout{1}, varargout{2}, varargout{3}] = fh(obj.I{id}, varargin{1}, varargin{2});
            case 4
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = fh(obj.I{id}, varargin{1}, varargin{2});
            case 5
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}, varargout{5}] = fh(obj.I{id}, varargin{1}, varargin{2});
        end
    case 3
        switch nargout
            case 0
                fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3});
            case 1
                varargout{1} = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3});
            case 2
                [varargout{1}, varargout{2}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3});
            case 3
                [varargout{1}, varargout{2}, varargout{3}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3});
            case 4
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3});
            case 5
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}, varargout{5}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3});
        end
    case 4
        switch nargout
            case 0
                fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4});
            case 1
                varargout{1} = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4});
            case 2
                [varargout{1}, varargout{2}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4});
            case 3
                [varargout{1}, varargout{2}, varargout{3}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4});
            case 4
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4});
            case 5
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}, varargout{5}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4});
        end
    case 5
        switch nargout
            case 0
                fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5});
            case 1
                varargout{1} = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5});
            case 2
                [varargout{1}, varargout{2}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5});
            case 3
                [varargout{1}, varargout{2}, varargout{3}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5});
            case 4
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5});
            case 5
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}, varargout{5}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5});
        end
    case 6
        switch nargout
            case 0
                fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6});
            case 1
                varargout{1} = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6});
            case 2
                [varargout{1}, varargout{2}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6});
            case 3
                [varargout{1}, varargout{2}, varargout{3}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6});
            case 4
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6});
            case 5
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}, varargout{5}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6});
        end
    case 7
        switch nargout
            case 0
                fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7});
            case 1
                varargout{1} = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7});
            case 2
                [varargout{1}, varargout{2}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7});
            case 3
                [varargout{1}, varargout{2}, varargout{3}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7});
            case 4
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7});
            case 5
                [varargout{1}, varargout{2}, varargout{3}, varargout{4}, varargout{5}] = fh(obj.I{id}, varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7});
        end
end

switch methodName
    case 'updateImgInfo'
        notify(obj, 'updateImgInfo');   % notify about updated meta
end


