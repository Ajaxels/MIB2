function ShortestLine=shortestpath(DistanceMap,StartPoint,SourcePoint,Stepsize,Method)
% This function SHORTESTPATH traces the shortest path from start point to
% source point using Runge Kutta 4 in a 2D or 3D distance map.
%
% ShortestLine=shortestpath(DistanceMap,StartPoint,SourcePoint,Stepsize,Method)
% 
% inputs,
%   DistanceMap : A 2D or 3D distance map (from the functions msfm2d or msfm3d)
%   StartPoint : Start point of the shortest path
%   SourcePoint : (Optional), End point of the shortest path
%   Stepsize: (Optional), Line trace step size 
%   Method: (Optional), 'rk4' (default), 'euler' ,'simple'
% output,
%   ShortestLine: M x 2 or M x 3 array with the Shortest Path
%
% Note, first compile the rk4 c-code with compile_c_files
%   
% Example,
%   % Load a maze image
%   I1=im2double(imread('images/maze.gif'));
%   % Convert the image to a speed map
%   SpeedImage=I1*1000+0.001;
%   % Set the source to end of the maze
%   SourcePoint=[800;803];
%   % Calculate the distance map (distance to source)
%   DistanceMap= msfm(SpeedImage, SourcePoint); 
%   % Show the distance map
%   figure, imshow(DistanceMap,[0 3400])
%   % Trace shortestline from StartPoint to SourcePoint
%   StartPoint=[9;14];
%   ShortestLine=shortestpath(DistanceMap,StartPoint,SourcePoint);
%   % Plot the shortest route
%   hold on, plot(ShortestLine(:,2),ShortestLine(:,1),'r')
%
% Function is written by D.Kroon University of Twente (June 2009)

% Process inputs
if(~exist('Stepsize','var')), Stepsize=0.5; end
if(~exist('SourcePoint','var')), SourcePoint=[]; end
if(~exist('Method','var')), Method='rk4'; end

% Calculate gradient of DistanceMap
if(ndims(DistanceMap)==2) % Select 2D or 3D
    [Fy,Fx] = pointmin(DistanceMap);
    GradientVolume(:,:,1)=-Fx;
    GradientVolume(:,:,2)=-Fy;
else
    [Fy,Fx,Fz] = pointmin(DistanceMap);
    GradientVolume(:,:,:,1)=-Fx;
    GradientVolume(:,:,:,2)=-Fy;
    GradientVolume(:,:,:,3)=-Fz;
end
i=0;
% Reserve a block of memory for the shortest line array
ifree=10000;
ShortestLine=zeros(ifree,ndims(DistanceMap));

% Iteratively trace the shortest line
while(true)
    % Calculate the next point using runge kutta
    switch(lower(Method))
        case 'rk4'
            EndPoint=rk4(StartPoint, GradientVolume, Stepsize);
            if isnan(EndPoint(1))
                EndPoint = SourcePoint;
            end
        case 'euler'
            EndPoint=e1(StartPoint, GradientVolume, Stepsize);
        case 'simple'
            EndPoint=s1(StartPoint,DistanceMap);
        otherwise
            error('shortestpath:input','unknown method');
    end

    % Calculate the distance to the end point
    if(~isempty(SourcePoint))
        [DistancetoEnd, ind]=min(sqrt(sum((SourcePoint-repmat(EndPoint,1,size(SourcePoint,2))).^2,1)));
    else
        
        DistancetoEnd=inf;
    end
    % Calculate the movement between current point and point 10 itterations back
    if(i>10), Movement=sqrt(sum((EndPoint(:)-ShortestLine(i-10,:)').^2));  else Movement=Stepsize+1;  end
    
    % Stop if out of boundary, distance to end smaller then a pixel or
    % if we have not moved for 10 itterations
    if((EndPoint(1)==0)||(Movement<Stepsize)), break;  end

    % Count the number of itterations
    i=i+1; 
    
    % Add a new block of memory if full
    if(i>ifree), ifree=ifree+10000; ShortestLine(ifree,:)=0; 
        disp(num2str(ifree)) 
    end
  
    % Add current point to the shortest line array
    ShortestLine(i,:) = EndPoint;
    
    if(DistancetoEnd < Stepsize), 
        i=i+1;  if(i>ifree), ifree=ifree+10000; ShortestLine(ifree,:)=0; end
        % Add (Last) Source point to the shortest line array
        ShortestLine(i,:)=SourcePoint(:,ind);
        break, 
    end
    
    % Current point is next Starting Point
    StartPoint=EndPoint;
end

if((DistancetoEnd>1)&&(~isempty(SourcePoint)))
    disp('The shortest path trace did not finish at the source point');
end

% Remove unused memory from array
ShortestLine=ShortestLine(1:i,:);

