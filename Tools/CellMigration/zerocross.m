function bor = zerocross(imag);

% get zero crossings of a certain input can be 2D or 1D
%-------------------------------------------------------------------------------------
%------  Author :   Constantino Carlos Reyes-Aldasoro                       ----------
%------             Postdoc  Sheffield University                           ----------
%------             http://tumour-microcirculation.group.shef.ac.uk         ----------
%------  27 November 2007   ---------------------------
%----------------------------------------------------

% if  min(imag(:))>= 0;
%    msgbox('No negative values in data','Zerocross warning','warn');
%    bor = [];
%    return;
% end;

[lins,cols,levels] = size(imag);
delta = 0.00001;

if ~isa(imag,'logical')
    imag=sign(imag);
end
%------ revise the case ------
%------    1 1D use plot for either line or column data
%------    2 1D but not line or column, stored in various z
%------    3 2D use surfdat_r.m function
%------    4 3D use just the base of cube

if ((cols==1|lins==1)&levels==1)  %- 1D over main plane
    if cols>= lins
        yy = [0 imag(1:cols-1)];
    else
        yy = [0 imag(1:lins-1)']';
    end;
    bor = abs((sign(imag+delta)-sign(yy+delta)));
elseif (cols==1&lins==1&levels~= 1)%- 1D over other plane
    imag = permute(imag,[2 3 1]);
    yy = [0 imag(1:cols-1)];
    bor = (sign(imag+delta)-sign(yy+delta));
elseif (lins~= 1&cols~= 1&levels==1) %- 2D over main plane
    %------ only 1 degree neighbourhood considered---------
    %    imag = imag+delta;
    %    yy5 = [zeros(1,cols);  imag(1:lins-1,1:cols)];              %|d
    %    yy6 = [imag(2:lins,1:cols);zeros(1,cols)];                  %u|
    %    yy7 = [ zeros(lins,1) imag(1:lins,1:cols-1)];               %-r
    %    yy8 = [ imag(1:lins,2:cols) zeros(lins,1)];                 %l-
    %    bor5 = fix(delta+(sign(imag)-sign(yy5))/2);
    %    bor6 = fix(delta+(sign(imag)-sign(yy6))/2);
    %    bor7 = fix(delta+(sign(imag)-sign(yy7))/2);
    %    bor8 = fix(delta+(sign(imag)-sign(yy8))/2);
    %    bor = sign(bor5+bor6+bor7+bor8);
    diffVer         = diff(imag,1,1);zerCols = zeros(1,cols);
    diffHor         = diff(imag,1,2);zerRows = zeros(lins,1);
    qq1             = [zerCols;(diffVer)>0];
    qq2             = [(diffVer)<0;zerCols];
    qq3             = [ (diffHor)<0 zerRows ];
    qq4             = [ zerRows (diffHor)>0 ];
    bor             = qq1|qq2|qq3|qq4;
elseif(lins~= 1&cols~= 1&levels~= 1) %- 3D
    yy5             = [zeros(1,cols,levels);  imag(1:lins-1,1:cols,:)];     %|d
    yy6             = [imag(2:lins,1:cols,:);zeros(1,cols,levels)];                  %u|
    yy7             = [ zeros(lins,1,levels) imag(1:lins,1:cols-1,:)];               %-r
    yy8             = [ imag(1:lins,2:cols,:) zeros(lins,1,levels)];                 %l-
    bor5            = fix(delta+(sign(imag)-sign(yy5))/2);
    bor6            = fix(delta+(sign(imag)-sign(yy6))/2);
    bor7            = fix(delta+(sign(imag)-sign(yy7))/2);
    bor8            = fix(delta+(sign(imag)-sign(yy8))/2);
    bor             = sign(bor5+bor6+bor7+bor8);
end;

%------ 2nd degree neighbourhood ----------------------------
%   yy1 = [zeros(1,cols); zeros(lins-1,1) imag(1:lins-1,1:cols-1)]; %\d
%   yy2 = [zeros(1,cols); imag(1:lins-1,2:cols) zeros(lins-1,1)];   %/d
%   yy3 = [imag(2:lins,2:cols) zeros(lins-1,1); zeros(1,cols)];     %u\
%   yy4 = [zeros(lins-1,1) imag(2:lins,1:cols-1); zeros(1,cols)];   %u/
%   bor1 = abs(sign(imag+delta)-sign(yy1+delta));
%   bor2 = abs(sign(imag+delta)-sign(yy2+delta));
%   bor3 = abs(sign(imag+delta)-sign(yy3+delta));
%   bor4 = abs(sign(imag+delta)-sign(yy4+delta));
%   bor = sign(bor1+bor2+bor3+bor4+bor5+bor6+bor7+bor8);
