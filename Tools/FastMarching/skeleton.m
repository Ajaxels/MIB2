function S=skeleton(I,verbose)
% This function Skeleton will calculate an accurate skeleton (centerlines) 
% of an object represented by an binary image / volume using the fastmarching 
% distance transform.
%
% S=skeleton(I,verbose)
%
% inputs,
%	I : A 2D or 3D binary image
%	verbose : Boolean, set to true (default) for debug information
%
% outputs
%   S : Cell array with the centerline coordinates of the skeleton branches
%
% Literature
%   Robert van Uitert and Ingmar Bitter : "Subvoxel precise skeletons of volumetric 
%	data base on fast marching methods", 2007.
%
% Example 2D,
%
% % Read Blood vessel image
%   I=im2double(rgb2gray(imread('images/vessels2d.png')));
%
% % Convert double image to logical
%   Ibin=I<0.5;
%
% % Use fastmarching to find the skeleton
%   S=skeleton(Ibin);
% % Display the skeleton
%   figure, imshow(Ibin); hold on;
%   for i=1:length(S)
%     L=S{i};
%     plot(L(:,2),L(:,1),'-','Color',rand(1,3));
%   end
%
%
%  Example 3D,
%
% % Read Blood vessel image
%   load('images/vessels3d');
% % Note, this data is pre-processed from Dicom ConeBeam-CT with
% % V = imfill(Vraw > 30000,'holes');
%
% % Use fastmarching to find the skeleton
%   S=skeleton(V);
%
%
% % Show the iso-surface of the vessels
% figure,
%   FV = isosurface(V,0.5)
%   patch(FV,'facecolor',[1 0 0],'facealpha',0.3,'edgecolor','none');
%   view(3)
%   camlight
% % Display the skeleton
%   hold on;
%   for i=1:length(S)
%     L=S{i};
%     plot3(L(:,2),L(:,1),L(:,3),'-','Color',rand(1,3));
%   end

if(nargin<2), verbose=true; end

if(size(I,3)>1), IS3D=true; else IS3D=false; end

% Distance to vessel boundary
BoundaryDistance=getBoundaryDistance(I,IS3D);
if(verbose),
    disp('Distance Map Constructed');
end
    
% Get maximum distance value, which is used as starting point of the
% first skeleton branch
[SourcePoint,maxD]=maxDistancePoint(BoundaryDistance,I,IS3D);

% Make a fastmarching speed image from the distance image
SpeedImage=(BoundaryDistance/maxD).^4;
SpeedImage(SpeedImage==0)=1e-10;

% Skeleton segments found by fastmarching
SkeletonSegments=cell(1,1000);

% Number of skeleton iterations
itt=0;

while(true)
    if(verbose),
        disp(['Find Branches Iterations : ' num2str(itt)]);
    end

    % Do fast marching using the maximum distance value in the image
    % and the points describing all found branches are sourcepoints.
    [T,Y] = msfm(SpeedImage, SourcePoint, false, false);
      
    % Trace a branch back to the used sourcepoints
    StartPoint=maxDistancePoint(Y,I,IS3D);
    
    ShortestLine=shortestpath(T,StartPoint,SourcePoint,1,'rk4');
    % Calculate the length of the new skeleton segment
    linelength=GetLineLength(ShortestLine,IS3D);
        
    % Stop finding branches, if the lenght of the new branch is smaller
    % then the diameter of the largest vessel
    if(linelength<maxD*2), break; end;
    
    % Store the found branch skeleton
    itt=itt+1;
    SkeletonSegments{itt}=ShortestLine;
    
    % Add found branche to the list of fastmarching SourcePoints
    SourcePoint=[SourcePoint ShortestLine'];
end
SkeletonSegments(itt+1:end)=[];
S=OrganizeSkeleton(SkeletonSegments,IS3D);
if(verbose),
    disp(['Skeleton Branches Found : ' num2str(length(S))]);
end

function ll=GetLineLength(L,IS3D)
if(IS3D)
    dist=sqrt((L(2:end,1)-L(1:end-1,1)).^2+ ...
              (L(2:end,2)-L(1:end-1,2)).^2+ ...
              (L(2:end,3)-L(1:end-1,3)).^2);
else
    dist=sqrt((L(2:end,1)-L(1:end-1,1)).^2+ ...
              (L(2:end,2)-L(1:end-1,2)).^2);
end
ll=sum(dist);

    
function S=OrganizeSkeleton(SkeletonSegments,IS3D)
n=length(SkeletonSegments);
if(IS3D)
    Endpoints=zeros(n*2,3);
else
    Endpoints=zeros(n*2,2);
end
l=1;
for w=1:n
    ss=SkeletonSegments{w};
    l=max(l,length(ss));
    Endpoints(w*2-1,:)=ss(1,:); 
    Endpoints(w*2,:)  =ss(end,:);
end
CutSkel=spalloc(size(Endpoints,1),l,10000);
ConnectDistance=2^2;

for w=1:n
    ss=SkeletonSegments{w};
    ex=repmat(Endpoints(:,1),1,size(ss,1));
    sx=repmat(ss(:,1)',size(Endpoints,1),1);
    ey=repmat(Endpoints(:,2),1,size(ss,1));
    sy=repmat(ss(:,2)',size(Endpoints,1),1);
    if(IS3D)
        ez=repmat(Endpoints(:,3),1,size(ss,1));
        sz=repmat(ss(:,3)',size(Endpoints,1),1);
    end
    if(IS3D)
        D=(ex-sx).^2+(ey-sy).^2+(ez-sz).^2;
    else
        D=(ex-sx).^2+(ey-sy).^2;
    end
    check=min(D,[],2)<ConnectDistance;
    check(w*2-1)=false; check(w*2)=false;
    if(any(check))
        j=find(check);
        for i=1:length(j)
            line=D(j(i),:);
            [foo,k]=min(line);
            if((k>2)&&(k<(length(line)-2))), CutSkel(w,k)=1; end
        end
    end
end

pp=0;
for w=1:n
    ss=SkeletonSegments{w};
    r=[1 find(CutSkel(w,:)) length(ss)];
    for i=1:length(r)-1
        pp=pp+1;
        S{pp}=ss(r(i):r(i+1),:);
    end
end

function BoundaryDistance=getBoundaryDistance(I,IS3D)
% Calculate Distance to vessel boundary

% Set all boundary pixels as fastmarching source-points (distance = 0)
if(IS3D),S=ones(3,3,3); else S=ones(3,3); end
B=xor(I,imdilate(I,S));
ind=find(B(:));
if(IS3D)
    [x,y,z]=ind2sub(size(B),ind);
    SourcePoint=[x(:) y(:) z(:)]';
else
    [x,y]=ind2sub(size(B),ind);
    SourcePoint=[x(:) y(:)]';
end

% Calculate Distance to boundarypixels for every voxel in the volume
SpeedImage=ones(size(I));
BoundaryDistance = msfm(SpeedImage, SourcePoint, false, true);

% Mask the result by the binary input image
BoundaryDistance(~I)=0;

function [posD,maxD]=maxDistancePoint(BoundaryDistance,I,IS3D)
% Mask the result by the binary input image
BoundaryDistance(~I)=0;

% Find the maximum distance voxel
[maxD,ind] = max(BoundaryDistance(:));
if(~isfinite(maxD))
    error('Skeleton:Maximum','Maximum from MSFM is infinite !');
end

if(IS3D)
    [x,y,z]=ind2sub(size(I),ind); posD=[x;y;z];
else
    [x,y]=ind2sub(size(I),ind); posD=[x;y];
end
