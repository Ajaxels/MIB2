function D=bwdistsc1(bw,aspect,maxval)
% D=BWDISTSC1(BW,ASPECT,MAXVAL)
% BWDISTSC1 computes Euclidean distance transform of a binary 3D image 
% BW out to a specified value MAXVAL. This allows accelerating the 
% calculations in some cases with strongly nonconvex geometries, if the 
% distance transform only needs to be calculated out to a specific value. 
% The distance transform assigns to each pixel in BW a number that is 
% the distance from that pixel to the nearest nonzero pixel in BW. BW may 
% be a 3D array or a cell array of 2D slices. BWDISTSC1 can also accept
% regular 2D images. ASPECT is a 3-component vector defining the aspect 
% ratios to use when calculating the distances in BW. If ASPECT is not set, 
% isotropic aspect ratio [1 1 1] is used. If MAXVAL is specified, the 
% distance transform will be only calculated out to the value MAXVAL.
%
% BWDISTSC1 uses the same algorithm as BWDISTSC but without forward-
% backward scan. 
%
% BWDISTSC1 tries to use MATLAB's bwdist for 2D scans if possible, which
% is faster. Otherwise BWDISTSC1 will use its own algorithm for 2D scans. 
% Also incorporates the fix for Matlab version detection bug in the 
% original BWDISTSC contributed by Tudor Dima.
%
%(c) Yuriy Mishchenko HHMI JFRC Chklovskii Lab JUL 2007
% This function written Yuriy Mishchenko JUL 2011
% This function updated Yuriy Mishchenko SEP 2013

% This code is free for use or modifications, just please give credit where
% appropriate. If you modify the code or fix bugs, please drop me a message
% at gmyuriy@hotmail.com.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scan algorithms below use the following Lema:                 %
% LEMA: let F(X,z) be lower envelope of a family of parabola:   %
% F(X,z)=min_{k} [G(X)+(z-k)^2];                                %
% and let H_k(X,z)=A(X)+(z-k)^2 be a parabola.                  %
% Then for H_k(X,z)==F(X,z) at each X there exist at most       %
% two solutions k1<k2 such that H_k12(X,z)=F(X,z), and          %
% H_k(X,z)<F(X,z) is restricted to at most k1<k2.               %
% Here X is any-dimensional coordinate.                         %
%                                                               %
% Thus, simply scan away from any z such that H_k(X,z)<F(X,z)   %
% in either direction as long as H_k(X,z)<F(X,z) and update     %
% F(X,z). Note that need to properly choose starting point;     %
% starting point is any z such that H_k(X,z)<F(X,z); z==k is    %
% usually, but not always the starting point!                   %
%                                                               %
% Citation:                                                     %
% Mishchenko Y. (2013) A function for fastcomputation of large  %
% discrete Euclidean distance transforms in three or more       %
% dimensions in Matlab. Signal, Image and Video Processing      %
% DOI: 10.1007/s11760-012-0419-9.                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse inputs
if(nargin<2 || isempty(aspect)) aspect=[1 1 1]; end
if(nargin<3 || isempty(maxval)) maxval=Inf; end

% establish (once) whether we will use the "regionprops";
% on Matlab versions earlier than 7.3 regionprops is too slow for simply 
% collecting regions, as we want, and internal algorithm will be faster
UseRegionProps = exist('regionprops', 'file') && VersionNewerThan(7.3);

% need this to remove pixels from consideration in the scan if current 
% distance becomes greater than MAXVAL
maxval2=maxval^2;

% determine geometry of the data
if(iscell(bw)) shape=[size(bw{1}),length(bw)]; else shape=size(bw); end

% correct this for 2D data
if(length(shape)==2) shape=[shape,1]; end
if(length(aspect)==2) aspect=[aspect,1]; end
    
% allocate internal memory
D=cell(1,shape(3)); for k=1:shape(3) D{k}=zeros(shape(1:2)); end
   

%%%%%%%%%%%%% scan along XY %%%%%%%%%%%%%%%%
for k=1:shape(3)    
    if(iscell(bw)) bwXY=bw{k}; else bwXY=bw(:,:,k); end
    
    DXY=zeros(shape(1:2));    

    % if can, use 2D bwdist from image processing toolbox    
    if(exist('bwdist') && aspect(1)==aspect(2))
        DXY=aspect(1)^2*bwdist(bwXY).^2;
        DXY(DXY>maxval2)=Inf;
    else    % if not, use full XY-scan        
        %%%%%%%%%%%%%%% X-SCAN %%%%%%%%%%%%%%%        
        % reference nearest bwXY "on"-pixel in x direction downward:
        
        %  scan bottow-up, copy x-reference from previous row unless 
        %  there is bwXY "on"-pixel in that point in current row
        xlower=repmat(Inf,shape(1:2)); 
        
        xlower(1,find(bwXY(1,:)))=1;    % fill in first row
        for i=2:shape(1)
            xlower(i,:)=xlower(i-1,:);  % copy previous row
            xlower(i,find(bwXY(i,:)))=i;% unless there is pixel
        end
        
        % reference nearest bwXY "on"-pixel in x direction upward:
        xupper=repmat(Inf,shape(1:2));
        
        xupper(end,find(bwXY(end,:)))=shape(1);
        for i=shape(1)-1:-1:1
            xupper(i,:)=xupper(i+1,:);
            xupper(i,find(bwXY(i,:)))=i;
        end
                
        % find pixels for which distance needs to be updated
        idx=find(~bwXY); [x,y]=ind2sub(shape(1:2),idx);
        
        % set distance as the shortest to upward or to downward
        DXY(idx)=aspect(1)^2*min((x-xlower(idx)).^2,(x-xupper(idx)).^2);
        DXY(DXY>maxval2)=Inf;
        
        %%%%%%%%%%%%%%% Y-SCAN %%%%%%%%%%%%%%%
        % this will be the envelop
        D1=repmat(Inf,shape(1:2));
        % these will be the references to parabolas defining the envelop
        DK=repmat(Inf,shape(1:2));

        for i=1:shape(2)
            % need to select starting point for each X:
            % * starting point should be below current envelop
            % * i0==i is not necessarily a starting point
            % * there is at most one starting point
            % * there may be no starting point
            
            % i0 is the starting points for each X: i0(X) is the first 
            % y-index such that parabola from line i is below the envelop
            
            % first guess is the current y-line
            i0=repmat(i,shape(1),1);
            
            % some auxiliary datasets
            d0=DXY(:,i); 
            x=(1:shape(1))'; 

            % L0 indicates for which X starting point had been fixed
            L0=isinf(d0);
            
            while(~isempty(find(~L0,1)))
                % reference starting points in DXY
                idx=sub2ind(shape(1:2),x(~L0),i0(~L0));
                
                % these are current best parabolas for starting points
                ik=DK(idx);
                
                % these are new values from parabola from line #i
                dtmp=d0(~L0)+aspect(2)^2*(i0(~L0)-i).^2;
                dtmp(dtmp>maxval2)=Inf;
                
                % these starting points are OK - below the envelop
                L=D1(idx)>dtmp; D1(idx(L))=dtmp(L);
                
                % points which are still above the envelop but ik==i0,
                % will not get any better, so fix them as well
                L=isinf(dtmp) | L | (ik==i0(~L0));
                                
                % all other points are not OK, need new starting point:
                % starting point should be at least below parabola 
                % beating us at current choice of i0
                
                % solve quadratic equation to find where this happens
                ik=(ik-i); 
                di=(D1(idx(~L))-dtmp(~L))./ik(~L)/2/aspect(2)^2;

                % should select next highest index to the equality
                di=fix(di)+sign(di);
                
                % the new starting points
                idx=find(~L0); 
                i0(idx(~L))=i0(idx(~L))+di;

                % update L0 to indicate which points we've fixed
                L0(~L0)=L; L0(idx(~L))=(di==0);
                
                % points that went out can't get better; 
                % fix them as well
                L=(i0<1) | (i0>shape(2)); i0(L)=i;
                L0(L)=1;                
            end

            % will keep track along which X should keep updating distance
            map_lower=true(shape(1),1);
            map_upper=true(shape(1),1);

            % scan from starting points for each X i0 in increments of 1
            di=0;       % distance from current y-line
            eols=2;     % end-of-line-scan flag
            while(eols)
                eols=2;
                di=di+1;
                dtmp=repmat(Inf,shape(1),1);
                
                % select X which can be updated for di<0;
                % i.e. X which had been below envelop all way till now
                x=find(map_lower);
                if(~isempty(x))
                    % prevent index dropping below 1st
                    L=i0(map_lower)-di>=1;
                    map_lower(map_lower)=L;
                    % select pixels (X,i0(X)-di)
                    idx=sub2ind(shape(1:2),x(L),i0(map_lower)-di);
                    if(~isempty(idx))
                        dtmp=d0(map_lower)+...
                            aspect(2)^2*(i0(map_lower)-di-i).^2;
                        dtmp(dtmp>maxval2)=Inf;
                    
                        % these pixels are to be updated with i0-di
                        L=D1(idx)>dtmp;
                        map_lower(map_lower)=L;
                        D1(idx(L))=dtmp(L);
                        DK(idx(L))=i;
                    end
                else    % if this is empty, get ready to quit
                    eols=eols-1;
                end

                % select X which can be updated for di>0;
                % i.e. X which had been below envelop all way till now                
                x=find(map_upper);
                if(~isempty(x))
                    % prevent index from going over array limits                    
                    L=i0(map_upper)+di<=shape(2);
                    map_upper(map_upper)=L;
                    % select pixels (X,i0(X)+di)
                    idx=sub2ind(shape(1:2),x(L),i0(map_upper)+di);
                    if(~isempty(idx))
                        dtmp=d0(map_upper)+...
                            aspect(2)^2*(i0(map_upper)+di-i).^2;
                        dtmp(dtmp>maxval2)=Inf;
                    
                        % check which pixels are to be updated with i0+di
                        L=D1(idx)>dtmp;
                        map_upper(map_upper)=L;
                        D1(idx(L))=dtmp(L);
                        DK(idx(L))=i;
                    end
                else    % if this is empty, get ready to quit
                    eols=eols-1;
                end  
            end
        end
        DXY=D1;
    end
    D{k}=DXY; 
end


%%%%%%%%%%%%% scan along Z %%%%%%%%%%%%%%%%
% this will be the envelop of the parabolas centered on different Z points
D1=cell(size(D));
for k=1:shape(3) D1{k}=repmat(Inf,shape(1:2)); end
% these will be the Z-references for the parabolas forming the envelop
DK=cell(size(D));
for k=1:shape(3) DK{k}=repmat(Inf,shape(1:2)); end


% start building the envelope 
for k=1:shape(3)
    % need to select starting point for each XY:
    % * starting point should be below already existing current envelop
    % * k0==k is not necessarily a starting point
    % * there may be no starting point
    
    % j0 is the starting points for each XY: k0(XY) is the first
    % z-index such that the parabola from slice k gets below the envelop

    % for initial starting point, guess the current slice k
    k0=repmat(k,shape(1:2));
    
    % L0 indicates which starting points had been found so far
    L0=isinf(D{k});
    
    while(~isempty(find(~L0,1)))
        % because of using cells, need to explicitly scan in Z
        % to avoid repetitious searches in k0, parse first
        ss = getregions(k0, UseRegionProps);
        
        for kk=1:shape(3)
            % these are starting points @kk which had not been set yet
            if(kk<=length(ss)) idx=ss(kk).PixelIdxList; else idx=[]; end
            idx=idx(~L0(idx));

            if(isempty(idx)) continue; end
            
            % these are currently the best parabolas for slice kk
            ik=DK{kk}(idx);
            
            % these are new distances for points in kk from parabolas in k
            dtmp=D{k}(idx)+aspect(3)^2*(kk-k)^2;
            dtmp(dtmp>maxval2)=Inf;
            
            % these points are below current envelop, OK starting points
            L=D1{kk}(idx)>dtmp; D1{kk}(idx(L))=dtmp(L);
            
            % these points are not OK, but since ik==k0
            % can't get any better, so remove them as well from search
            L=L | (ik==kk) | isinf(dtmp);
                
            % all other points are not OK, need new starting point:
            % starting point should be at least below the parabola
            % beating us at current choice of k0, thus make new guess for k
            ik=(ik-k);
            dk=(D1{kk}(idx(~L))-dtmp(~L))./ik(~L)/2/aspect(3)^2;
            dk=fix(dk)+sign(dk);
            k0(idx(~L))=k0(idx(~L))+dk;
    
            % update starting points that had been fixed in this pass
            L0(idx)=L;
            L0(idx(~L))=(dk==0);
    
            % points that went out of boundaries can't get better, fix them
            L=(k0<1) | (k0>shape(3));
            L0(L)=1;
            k0(L)=k;
        end
    end

    % map_lower/map_upper keeps track of which pixels yet can be updated
    % with new distances, i.e., all such XY that had been below envelop 
    % for all dk up to now, for dk<0/dk>0 respectively
    map_lower=true(shape(1:2));
    map_upper=true(shape(1:2));
    
    % parse different values in k0 to avoid repetitious searching below
    ss = getregions(k0, UseRegionProps);

    % scan away from starting points in increments of 1
    dk=0;       % distance from current xy-slice
    eols=2;     % end-of-scan flag
    while(eols)
        eols=2;
        dk=dk+1;
        dtmp=repmat(Inf,shape(1:2));

        if(~isempty(find(map_lower,1)))
            % prevent index from going over the boundaries
            L=k0(map_lower)-dk>=1;
            map_lower(map_lower)=L;
            % need to explicitly scan in Z because of using cell-arrays
            for kk=1:shape(3)
                % get all XY such that k0-dk==kk
                if(kk+dk<=length(ss) & kk+dk>=1) 
                    idx=ss(kk+dk).PixelIdxList; 
                else
                    idx=[]; 
                end
                idx=idx(map_lower(idx));

                if(~isempty(idx))
                    dtmp=D{k}(idx)+aspect(3)^2*(kk-k)^2;
                    dtmp(dtmp>maxval2)=Inf;
                    
                    % these pixels are to be updated with new 
                    % distances at k0-dk
                    L=D1{kk}(idx)>dtmp;
                    map_lower(idx)=L;
                    D1{kk}(idx(L))=dtmp(L);
                    DK{kk}(idx(L))=k;
                end
            end
        else
            eols=eols-1;
        end

        if(~isempty(find(map_upper,1)))
            % prevent index from going over the boundaries            
            L=k0(map_upper)+dk<=shape(3);
            map_upper(map_upper)=L;
            % need to explicitly scan in Z because of using cell-arrays
            for kk=1:shape(3)
                % get all XY such that k0+dk==kk                
                if(kk-dk<=length(ss) && kk-dk>=1) 
                    idx=ss(kk-dk).PixelIdxList; 
                else
                    idx=[]; 
                end
                idx=idx(map_upper(idx));                

                if(~isempty(idx))
                    dtmp=D{k}(idx)+aspect(3)^2*(kk-k)^2;
                    dtmp(dtmp>maxval2)=Inf;
    
                    % these pixels are to be updated with new 
                    % distances at k0+dk
                    L=D1{kk}(idx)>dtmp;
                    map_upper(idx)=L;
                    D1{kk}(idx(L))=dtmp(L);
                    DK{kk}(idx(L))=k;
                end
            end
        else
            eols=eols-1;
        end
    end
end

% prepare the answer, limit distances to MAXVAL
for k=1:shape(3)
  D1{k}(D1{k}>maxval2)=maxval2; 
end

% prepare the answer, convert to output format matching the input
if(iscell(bw))
    D=cell(size(bw));
    for k=1:shape(3) D{k}=sqrt(D1{k}); end
else
    D=zeros(shape);
    for k=1:shape(3) D(:,:,k)=sqrt(D1{k}); end
end

end

function s=getregions(map, UseRegionProps)
% this function is replacer for regionprops(map,'PixelIdxList);
% it produces the list of different values along with the list of 
% indexes of the pixels in the map with these values; s is struct-array 
% such that s(i).PixelIdxList contains list of pixels in map 
% with value i.

% enable using regionprops if available on Matlab versions 7.3 and later,
% regionprops is faster than this code at these versions

% version control for using regionprops is now outside (Turod Dima)
 
if UseRegionProps
    s=regionprops(map,'PixelIdxList');
    return
end

idx=(1:prod(size(map)))';
dtmp=double(map(:));

[dtmp,ind]=sort(dtmp); 
idx=idx(ind);
ind=[0;find([diff(dtmp(:));1])];

s=[];
for i=2:length(ind)
    if(dtmp(ind(i)))==0 continue; end
    s(dtmp(ind(i))).PixelIdxList=idx(ind(i-1)+1:ind(i));
end

end

% --- VersionNewerThan and str2numarray added lower ---
function vn = VersionNewerThan(v_ref, AllowEqual)
% V_isNewer = VersionNewerThan(V_REF, AllowEqual)
% 
% compare current Matlab version V_CURR with V_REF
% returns TRUE when current version is newer than V_REF (or as new when AllowEqual)
%
% V_REF     - string or number
% AllowEqual- boolean (dafault TRUE)
% 
% V_CURR vs. V_REF  | AllowEqual | V_isNewer
%    newer          |  any       |  true
%    same           |  true      |  true
%    same           |  false     |  false 
%    older          |  any       |  false    
% 
% 26.12.2011 - new, Tudor for Yuriy > bwdistsc1

if nargin < 2, AllowEqual = true; end
if nargin < 1, v_ref = 7.3; end
if isnumeric(v_ref)
    v_ref = num2str(v_ref);
end

v = version;

% compare version numbers group-by-group
% i.e. 7.11.0.584 later than 7.3.1, etc
% this works when v and v_ref are strings of unequal lengths
% containing any number of dots

% split version strings into numerical arrays
VerSeparator = '.';
vd = str2numarray(v, VerSeparator);       % installed
vrd = str2numarray(v_ref, VerSeparator);  % reference
nG = min(numel(vd),numel(vrd));

% start comparison at most significant group
iG = 1;
while (iG <= nG) 
    vn = sign(vd(iG) - vrd(iG)); % -1 0 1
    iG = iG+1;
    if vn ~= 0
        break
    end
end
if vn == 0 % set the longer of {vd, vrd} as 'the latest
    vn = numel(vd) -numel(vrd);
end
vn = vn > 0 || (AllowEqual && vn == 0); % was hard '>='
end

function vd = str2numarray(vs, VerSeparator)
% > split version string into array of double
% > also strip chars trailing 1st ' '  or '('
% i.e. both '7.11.0.584' and '7.11.0.584 (R2010b)'
%  will be converted to [7 11 0 584]

iC = 0;
iPrev = 0;
iS = 0;
sL = numel(vs);
vd = zeros(1,sL);
while iS < sL
    iS = iS+1;
    if vs(iS) == VerSeparator
        iC = iC + 1;
        vd(iC) = str2double(vs(iPrev+1:iS-1));
        iPrev = iS;
    elseif (vs(iS) == ' ') || (vs(iS) == '(')
        sL = iS-1;
        break        
    end
end
% also store the last section, '.' to end
% (or the only section when no VerSeparator is present)
iC = iC + 1;
vd(iC) = str2double(vs(iPrev+1:sL));
vd = vd(1:iC);
end

