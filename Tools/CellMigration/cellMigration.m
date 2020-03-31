function [Res_stats,Res_colour,Res_gray,Res_Cells]=cellMigration(dataIn)
%function [Res_stats,Res_colour,Res_gray,Res_Cells]=cellMigration(dataIn,toPlot);
%
%-------- this function plots a 3D group of tracks that have been generated with trackRBC.m
%-------------------------------------------------------------------------------------
%------  Author :   Constantino Carlos Reyes-Aldasoro                       ----------
%------             Postdoc  Sheffield University                           ----------
%------             http://tumour-microcirculation.group.shef.ac.uk         ----------
%------  27 November 2007   ---------------------------
%----------------------------------------------------
% input data:       dataIn: an image with cells or the name of an image to be read
% output data:      areaCovered     [total;relative] between boundaries of the cells
%                   Res_colour      an image equal to dataIn but with the area highlighted
%                   errT            [A;B;A+B] error of approximation of straight lines

%------ no input data is received, error -------------------------
%------ at least 2 parameters are required
if nargin <1;     help cellMigration; Res_stats=[];Res_colour=[];Res_gray=[];Res_Cells=[]; return;  end
%tic;
%if ~exist('toPlot','var'); toPlot=0; end
%------ arguments received revision   ----------------------------
if isa(dataIn,'char')
    b=imread(dataIn);    
    %fname=dataIn;
else
    b=dataIn;
    %fname='Image';
end
%%
% if ~exist('fname','var')
%     fname='Image';
% end
if min(b(:))<0
    b=b-min(b(:));
end
%------ usual dimension check
[rows,cols,levs]    = size(b);

%------ three filters to be used  f1=HPF, f2,f3=LPF
f1                  = gaussF(rows,cols,1,floor(rows/50),floor(cols/50),1,floor(rows/2),floor(cols/2),1);
f1                  = f1/max(f1(:));
f2                  = gaussF(15,15,1);
f3                  = gaussF(3,3,1);

%------ transform into Fourier to High Pass Filter
bf                  = fftshift(fft2(double(b)));

if levs>1
    %----- inverse transform filtered signals
    bHP1a               = abs(ifft2(((1-f1).*bf(:,:,1))));
    bHP2a               = abs(ifft2(((1-f1).*bf(:,:,2))));
    bHP3a               = abs(ifft2(((1-f1).*bf(:,:,3))));

    %----- LPF the filtered signals as a Local Energy Function to consolidate the variation
    bHP1                = conv2(bHP1a,f2,'same');
    bHP2                = conv2(bHP2a,f2,'same');
    bHP3                = conv2(bHP3a,f2,'same');

    %----- remove minimum and combine 3 colour layers
    bHP1                = (bHP1-min(bHP1(:)))+(bHP2-min(bHP2(:)))+(bHP3-min(bHP3(:)));
else
    %----- inverse transform filtered signals
    bHP1a               = abs(ifft2(((1-f1).*bf(:,:,1))));

    %----- LPF the filtered signals as a Local Energy Function to consolidate the variation
    bHP1                = conv2(bHP1a,f2,'same');

    %----- remove minimum and combine 3 colour layers
    bHP1                = (bHP1-min(bHP1(:)));
end

%----- Crop edges to avoid boundary conditions
bHP1                = bHP1(20:end-19,20:end-19);
%%
%----- To determine a threshold level for the segmentation Otsu is obtained for several levels of a QT

%when the QT is constructed, it is necessary to use a 2^n dimension to avoid averaging with edge artifacts
%therefore, generated a linspace between first and last point of bHP1 (it is different from input!) of  2^n dims
[rowsbHP1,colsbHP1]         = size(bHP1);
rowVector                   = linspace(1,rowsbHP1,2.^floor(log2(rowsbHP1)));
colVector                   = linspace(1,colsbHP1,2.^floor(log2(colsbHP1)));
reduced_bHP1                = interp2(bHP1,colVector,rowVector');
min_bHP1                    = min(reduced_bHP1(:));
reduced_bHP1                = reduced_bHP1-min_bHP1;
max_bHP1                    = max(reduced_bHP1(:));
reduced_bHP1                = reduced_bHP1/max_bHP1;

%better to use the average of Otsu's method for   several levels of QT.
for k=3:6
    thres2(k-2)             = graythresh(reduceu(reduced_bHP1,k)); %#ok<AGROW>
    %thres3(k-2)=255*graythresh(reduceu(bHP1(1:2.^floor(log2(rows)),1:2.^floor(log2(cols))),k)/255);
end
thres2                      = thres2*max_bHP1+min_bHP1;
thres                       = min(0.95*thres2);


%----- Binary image that captures cells due to high frequency variation
bCELLS(:,:,1)               = (bHP1>(thres));

%----- Find the main orientation of the 'gap' in the cells,
%----- this will be used to create oriented morphological operators
angleRange                  = (0:10:179);
[TraceCells]                = traceTransform_old(bCELLS(1:4:end,1:4:end),angleRange,[-1 1]);

%----- the main orientation will be given by the angle with MAXIMUM variation
tracesStd(18)               = 0;
for k=1:18
    ttt                     = squeeze(TraceCells(:,k,9));       % this trace contains the average value of the trace
    ttt(squeeze(TraceCells(:,k,11))==0) = [];                   % this discards those positions outside the image
    tracesStd(k)            = std(ttt);                         % get Std as an indication of variation
end
[maxVar,indVar]             = max(tracesStd);
angOrientation              = angleRange(indVar);

sizeOperator                = max(10,round(min(rows,cols)/40));
SE01                        = strel('line',sizeOperator,angOrientation);
SE02                        = strel('line',sizeOperator,90+angOrientation);

%----- expand the structural element
nhood1                      = getnhood(SE01);
nhood1                      = (conv2(double(nhood1),gaussF(3,3,1))>0);
nhood2                      = getnhood(SE02);
nhood2                      = (conv2(double(nhood2),gaussF(3,3,1))>0);

SE2                         = strel(nhood2);      %----- this is parallel to the cut of the cells
SE1                         = strel(nhood1);      %-----     this is perpendicular


%----- the image is morphologically 'closed' to fill in holes and gaps

bCELLS2                     = (imclose(bCELLS,SE2));
bCELLS2                     = (imclose(bCELLS2,SE1));
bCELLS2a                    = imfill(bCELLS2,'holes');
%----- The eroding element must be oriented with respect to main orientation of bCELLS2
%----- Then it is eroded considerably to generate 2 main regions, and leave open space between
%----- it may be the case that imfill fills the whole image or nearly all, do not use in that case
bCELLS2a                    = imdilate(bCELLS2a,ones(3));
if sum(bCELLS2a(:))>(0.95*rows*cols)
    bCELLS3                 = (imopen(bCELLS2,SE2));
else
    bCELLS3                 = (imopen(bCELLS2a,SE2));
end

%check to see if there is a SINGLE area of interest, or TWO (normal case)
%%
bAreas1                     = bwlabel(bCELLS3);
bAreas2                     = regionprops(bAreas1,'area');
bAreas3                     = ismember(bAreas1,find(([bAreas2.Area]/rows/cols)>0.01));
[bAreas4,numAreas]          = bwlabel(bAreas3);

%%
%----- The edges of the region are obtained
bCELLS4             = zerocross(bCELLS3-0.5);
%----- a small blur is used to get a better estimation later on
bCELLS5             = conv2(double(bCELLS4),f3,'same');
%----- all edges are labeled to find the longest two which should be the boundaries of the regions
bCELLS6             = bwlabel(bCELLS5>0);
%%
rp6                 = regionprops(bCELLS6,'majoraxislength','perimeter');
[in1,in2]           = sort([rp6.MajorAxisLength]);
%%
if numAreas==1
    %%
    %----- keep only the SINGLE largest lines and thin  with a Skeleton
    bCELLS7a            = bwmorph(bCELLS6==in2(end),'skel',Inf);

    %----- pad the results to compensate for the earlier crop
    bCELLS8a            = padData(bCELLS7a,19,[2 2],1);
    %----- this process will obtain the sets that describe the coordinates of the boundaries previously obtained
    %----- find determines the non-zero elements (sequential) and these are rearranged into rows and columns
    %xyCELLSa            = find(bCELLS8a);
    %rowsA               = 1+floor(xyCELLSa/rows);
    %colsA               = rem(xyCELLSa-1,rows)+1;
    %----- when just one area is detected, no distances are calculated, just the relative area of the
    %----- scratch
    %%
    complementArea      = bwlabel(1-bAreas4);
    complementSizes     = regionprops (complementArea,'Area');
    [temp1,temp2]       =max([complementSizes.Area]);
    complementArea2     = (complementArea==temp2);

    %bAreas3=ismember(bAreas1,find(([bAreas2.Area]/rows/cols)>0.001));

    %------ calculate area covered between lines
    totArea             = sum(complementArea2(:));
    relArea             = totArea/rows/cols;
    areaCovered         = [totArea;relArea];
    Res_stats.area      = areaCovered;
    commonArea  = padData(complementArea2,19,[2 2],1);
    %%
else
    %----- keep only the TWO largest lines and thin them with a Skeleton
    bCELLS7a            = bwmorph(bCELLS6==in2(end),'skel',Inf);
    bCELLS7b            = bwmorph(bCELLS6==in2(end-1),'skel',Inf);
    %----- pad the results to compensate for the earlier crop
    bCELLS8a            = padData(bCELLS7a,19,[2 2],1);
    bCELLS8b            = padData(bCELLS7b,19,[2 2],1);
    %t3=toc;tic;
    %----- this process will obtain the sets that describe the coordinates of the boundaries previously obtained
    %----- find determines the non-zero elements (sequential) and these are rearranged into rows and columns
    xyCELLSa            = find(bCELLS8a);
    rowsA               = 1+floor(xyCELLSa/rows);
    colsA               = rem(xyCELLSa-1,rows)+1;
    xyCELLSb            = find(bCELLS8b);
    rowsB               = 1+floor(xyCELLSb/rows);
    colsB               = rem(xyCELLSb-1,rows)+1;

    %----- in order to find the distance between each pair of points points are repeated into two matrices:
    %-----  [[n,1] [n,1] [n,1] ...   ]  for A  and [[1,m] [1,m] [1,m] ...   ] for B
    matRA               = repmat(rowsA,[1,size(rowsB,1)]);
    matCA               = repmat(colsA,[1,size(rowsB,1)]);
    matRB               = repmat(rowsB',[size(rowsA,1),1]);
    matCB               = repmat(colsB',[size(rowsA,1),1]);

    %----- distance matrix is calculated
    distBetPoints       = sqrt(((matRA-matRB).^2)+((matCA-matCB).^2  ) );
    %----- minimum distance between lines is calculated
    [minimumDist1,q1]       = min(distBetPoints); %#ok<NASGU>
    [minimumDist2,q3]       = min(distBetPoints,[],2); %#ok<NASGU>

    %[minimumDist,q2]        = min(minimumDist1);
    %----- maximum distance (of the minimum set is calculated (if needed)
    %maxDist                 = max([max(min(distBetPoints)) max(min(distBetPoints,[],2))   ]);
    Res_stats.minimumDist   = min(minimumDist1);
    Res_stats.maxDist       = max([max(min(distBetPoints)) max(min(distBetPoints,[],2))   ]);
    Res_stats.avDist        = mean([minimumDist1 minimumDist2']);
    %t4=toc;tic;



    %----- calculate the area between lines. The Lines should not intersect (they come from a bwlabel)
    %----- but they can have small holes inside so blurr to thicken, then label the complement to obtain areas
    Area2A          = bwlabel(1-(conv2(double(bCELLS7a),f3,'same')>0));
    Area2B          = bwlabel(1-(conv2(double(bCELLS7b),f3,'same')>0));
    %------ there are 4 combinations, one should be an empty set, the common area is the complement to that
    A1_B1           = sum(sum((Area2A==1)&(Area2B==1)));
    A1_B2           = sum(sum((Area2A==1)&(Area2B==2)));
    A2_B1           = sum(sum((Area2A==2)&(Area2B==1)));
    A2_B2           = sum(sum((Area2A==2)&(Area2B==2)));
    %------ determine which combination is the empty one and pad with SAME to get final area
    if A1_B1==0
        commonArea  = padData((Area2A==2)&(Area2B==2),19,[2 2],1);
    elseif A1_B2==0
        commonArea  = padData((Area2A==2)&(Area2B==1),19,[2 2],1);
    elseif A2_B1==0
        commonArea  = padData((Area2A==1)&(Area2B==2),19,[2 2],1);
    elseif A2_B2==0
        commonArea  = padData((Area2A==1)&(Area2B==1),19,[2 2],1);
    end

    %------ calculate area covered between lines
    totArea         = sum(commonArea(:));
    relArea         = totArea/rows/cols;
    areaCovered     = [totArea;relArea];
    Res_stats.area  = areaCovered;
end
kernelDilation=ones(max(5,ceil(rows/200)));
%------ merge commonArea with original image to plot

if levs>1
    %Res_colour      = b;   
    if exist('bCELLS8b','var')
        finalBoundaries=uint8(imdilate(bCELLS8a|bCELLS8b,kernelDilation));
    else
        finalBoundaries=uint8(imdilate(bCELLS8a,kernelDilation));
    end
    finalBoundaries = repmat(finalBoundaries,[1 1 3]);
    Res_colour      = 255*finalBoundaries+(1-finalBoundaries).*b;
    Res_colour(:,:,3)=Res_colour(:,:,3).*(1+0.5*uint8(commonArea));
else
%%    %Res_colour(find(imdilate(bCELLS8a,kernelDilation)))=255;
    if exist('bCELLS8b','var')
        finalBoundaries=uint8(imdilate(bCELLS8a|bCELLS8b,kernelDilation));
    else
        finalBoundaries=uint8(imdilate(bCELLS8a,kernelDilation));
    end
    Res_colour      = 255*finalBoundaries+(1-finalBoundaries).*b;
    Res_colour(:,:,2)=Res_colour(:,:,1);
    Res_colour(:,:,3)=0.9*Res_colour(:,:,1).*(1+0.5*uint8(commonArea));
%%
end
Res_gray        = double(sum(Res_colour(:,:,:),3)).*(1-0.5*(commonArea));

if nargout==4
    Res_Cells(:,:,1)=bHP1;
    Res_Cells(:,:,2)=bCELLS;
    Res_Cells(:,:,3)=bCELLS2;
    Res_Cells(:,:,4)=bCELLS2a;
    Res_Cells(:,:,5)=bCELLS3;
    Res_Cells(:,:,6)=bCELLS4;
    Res_Cells(:,:,7)=bCELLS5;
    Res_Cells(:,:,8)=bCELLS6;
    Res_Cells(:,:,9)=bCELLS7a;
    if exist('rowsB','var')
        Res_Cells(:,:,10)=bCELLS7b;
    end
end
clear a* A* x* t* r* q* n* e* f* i* k* l* m* c* S* T* b* d* P* R1 R2 R3 s*

