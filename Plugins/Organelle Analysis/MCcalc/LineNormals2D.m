function N=LineNormals2D(Vertices, Lines)
% This function calculates the normals, of the line points
% using the neighbouring points of each contour point, and 
% forward an backward differences on the end points
%
% N=LineNormals2D(V,L)
%
% inputs,
%   V : List of points/vertices 2 x M
% (optional)
%   Lines : A N x 2 list of line pieces, by indices of the vertices
%         (if not set assume Lines=[1 2; 2 3 ; ... ; M-1 M])
%
% outputs,
%   N : The normals of the Vertices 2 x M
%
% Example, Hand
%  load('testdata');
%  N=LineNormals2D(Vertices,Lines);
%  figure,
%  plot([Vertices(:,1) Vertices(:,1)+10*N(:,1)]',[Vertices(:,2) Vertices(:,2)+10*N(:,2)]');
%
% Function is written by D.Kroon University of Twente (August 2011)

% If no line-indices, assume a x(1) connected with x(2), x(3) with x(4) ...
if(nargin<2)
    Lines=[(1:(size(Vertices,1)-1))' (2:size(Vertices,1))'];
end

% Calculate tangent vectors
DT=Vertices(Lines(:,1),:)-Vertices(Lines(:,2),:);

% Make influence of tangent vector 1/Distance
% (Weighted Central Differences. Points which are closer give a 
% more accurate estimate of the normal)
LL=sqrt(DT(:,1).^2+DT(:,2).^2);
DT(:,1)=DT(:,1)./max(LL.^2, eps);
DT(:,2)=DT(:,2)./max(LL.^2, eps);

D1=zeros(size(Vertices)); D1(Lines(:,1),:)=DT;
D2=zeros(size(Vertices)); D2(Lines(:,2),:)=DT;
D=D1+D2;

% Normalize the normal
LL=sqrt(D(:,1).^2+D(:,2).^2);

% normals facing out of the shape
N(:,1)= D(:,2)./LL;
N(:,2)= -D(:,1)./LL;

% normals facing into the shape
%N(:,1)= -D(:,2)./LL;
%N(:,2)= D(:,1)./LL;