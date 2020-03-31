function [F,f1,f2,f3,f4,f5,f6,f7,f8]=traceTransform(data,angleRange,distanceRange)

%------ Usual dimension check
[rows,cols,dm]=size(data);
delta=1e-10;                % avoid dicision by zero
rCent=1+floor(rows/2);        % rows from centre to edge
cCent=1+floor(cols/2);        % columns from centre to edge
diagDistance=ceil(sqrt(rCent^2 + cCent^2));

%------- angleRange =[initAngle:stepAngle:finalAngle] in the range [0:179], [0:359]
if ~exist('angleRange')
    %------ The step for the angle to scan the image and other parameters
    stepFi=5;
    angleRange=0:stepFi:359;
end
angleIndex=1:length(angleRange);

%------- distanceRange =[initDistance finDistance] in the range [-1:1]*sqrt((rows/2)^2+(cols/2)^2)
%-------                 to cover up to the end of the image
if ~exist('distanceRange')
    %------ The step for the angle to scan the image and other parameters
    distanceRange=[-1 1];
end


%%%%inCosSin=(abs(tan(pi*angleRange/180)))>(tan(rows/cols));



%----- Generate  rotating lines centred at (rCent,cCent)
%----- initial points (0-179)
c1=[cCent+diagDistance*cos(pi*angleRange/180)];%c1(c1<1)=1;c1(c1>cols)=cols;
r1=[rCent+diagDistance*sin(pi*angleRange/180)];%r1(r1<1)=1;r1(r1>rows)=rows;
%----- end points (180:359)
c2=[cCent-diagDistance*cos(pi*angleRange/180)];%c2(c2<1)=1;c2(c2>cols)=cols;
r2=[rCent-diagDistance*sin(pi*angleRange/180)];%r2(r2<1)=1;r2(r2>rows)=rows;

%----- Generate PERPENDICULAR rotating lines centred at (rCent,cCent) Centred at zero!
%----- initial points (0-179)
c1Perpend=[diagDistance*cos(pi*(90+angleRange)/180)];%c1(c1<1)=1;c1(c1>cols)=cols;
r1Perpend=[diagDistance*sin(pi*(90+angleRange)/180)];%r1(r1<1)=1;r1(r1>rows)=rows;
%----- end points (180:359)
c2Perpend=[-diagDistance*cos(pi*(90+angleRange)/180)];%c2(c2<1)=1;c2(c2>cols)=cols;
r2Perpend=[-diagDistance*sin(pi*(90+angleRange)/180)];%r2(r2<1)=1;r2(r2>rows)=rows;


%distRange_R=diagDistance*distanceRange/rCent;
%distRange_C=diagDistance*distanceRange/cCent;
%if size(distanceRange,2)==1
%    rUnRotated=rCent*distRange_R;
%    cUnRotated=cCent*distRange_C;
%else
%    %------ r and cUnRotated are going to store parallel TRACES  with elements ti
%    %------ they should be longer than the columns or rows, if the image is a square
%    %------ then a sqrt(2) = 1.4142 could be used or 1.5 to round but for rectangles this does not apply
%    rExtremes=[floor(distRange_R(1)*rCent) ceil(rCent*distRange_R(2))];
%    cExtremes=[floor(distRange_C(1)*cCent) ceil(cCent*distRange_C(2))];
%    rUnRotated=rExtremes(1):rExtremes(2);
%    cUnRotated=cExtremes(1):cExtremes(2);
%end
%------ Transform data in a meshgrid
%[R,C]=meshgrid(1:rows,1:cols);

%------ Begin loop over the ANGLE first
for countAngle=angleIndex
    fiGrad=angleRange(countAngle);

    %----- this sequence calculates the points at which the traces will be generated
    %----- it NEEDS to be longer than the image itself to grab the corners
    cTraceAxis=linspace(c1(countAngle),c2(countAngle),ceil(diagDistance*2));
    rTraceAxis=linspace(r1(countAngle),r2(countAngle),ceil(diagDistance*2));

    %----- These points are the TRACE itself that will be displaced as needed
    cTrace=linspace(c1Perpend(countAngle),c2Perpend(countAngle),ceil(diagDistance*2));
    rTrace=linspace(r1Perpend(countAngle),r2Perpend(countAngle),ceil(diagDistance*2));

    %----- Second loop over the length of the Axis of the trace
    for countPosition=1:length(cTraceAxis)
        rr=rTrace+rTraceAxis(countPosition);
        cc=cTrace+cTraceAxis(countPosition);
        rr(cc>cols)=[];cc(cc>cols)=[];
        cc(rr>rows)=[];rr(rr>rows)=[];
        rr(cc<1)=[];cc(cc<1)=[];
        cc(rr<1)=[];rr(rr<1)=[];
        if ~isempty(rr)
            %---- this index locates the coordinates of the points of the trace
            indRowsCols=round((cc-1)*rows +rr);
            %---- here we extract the values of the trace
            traceValues=data(indRowsCols);
            %------ here the different functionals for the Trace Transform are applied
            %------ 1) sum(ti)
            f1=(sum(traceValues));
            %------ 2) sum(i*ti)
            f2=(sum(traceValues.*[1:length(traceValues)]));
            %------ 3) sum(sqrt(ti^2))
            f3=(sum(sqrt(traceValues.^2)));
            %------ 4) max(ti)
            f4=(max(traceValues));
            %------ 5) sum(|ti+1 -ti|)
            f5=(sum(abs(diff(traceValues))));
            %------ 7) sum(ti+1 -ti)
            f6=(sum(diff(traceValues)));
            %------ 6) sum(|ti+1 -ti|^2)
            f7=(sum((diff(traceValues)).^2));
            %------ 8) min(ti)
            f8=(min(traceValues));
            %------ 9) mean(ti)
            f9=(mean(traceValues));
            %------ 10) sum(ti==0)
            f10=sum(traceValues==0);
            F(countPosition,countAngle,1)=f1;
            F(countPosition,countAngle,2)=f2;
            F(countPosition,countAngle,3)=f3;
            F(countPosition,countAngle,4)=f4;
            F(countPosition,countAngle,5)=f5;
            F(countPosition,countAngle,6)=f6;
            F(countPosition,countAngle,7)=f7;
            F(countPosition,countAngle,8)=f8;
            F(countPosition,countAngle,9)=f9;
            F(countPosition,countAngle,10)=f10;
            %----- Reference for valid points in the transform
            F(countPosition,countAngle,11)=1;
            clear f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 traceValues rr cc

        end
    end
end

%     %--- this is the axis of rotation
%     rProjected=ceil(rows/2)+sin(fi)*rUnRotated;
%     cProjected=ceil(cols/2)+cos(fi)*cUnRotated ;
%     %------ Begin loop over the Distance from the centre
%     %    for n=-floor(1.5*rCent):ceil(rCent*1.5)
%     for n=rUnRotated
%         x(cExtremes(2)+n+1,:)=cProjected-n*sin(fi);    %---- these are the parallel lines "t"
%         y(rExtremes(2)+n+1,:)=rProjected+n*cos(fi);
%         y(x<1)=[];x(x<1)=[];
%         y(x>rows)=[];x(x>rows)=[];
%         x(y<1)=[];y(y<1)=[];
%         x(y>rows)=[];y(y>rows)=[];
%         if ~isempty(x)
%             lenX=length(x);
%             %[ 1+n+floor(1.5*rCent) fiGrad]
%             %for k=1:lenX
%             %[k 1+n+floor(1.5*rCent) fiGrad]
%             %if (ceil(y(k)+delta)<=rows)&(ceil(x(k)+delta)<=cols)
%             indRowsCols=round((x-1)*rows +y);
%             try
%                 F(1:lenX,1+n+rExtremes(2),countAngle)=data(indRowsCols);
%             catch
%                 ffff=1;
%             end
%             %F(1:lenX,1+n+floor(1.5*rCent),fiGrad)=floor(interp2(R,C,data,x,y));
%             F2(1,1+n+rExtremes(2),countAngle)=lenX;
%             %F2(1,1+n+floor(1.5*rCent),fiGrad)=lenX;
%             %end
%             %end
%         end
%         clear x y;
%     end
%     clear rProjected cProjected;
% end

%F=F(:,:,angleRange);


[x,y,z]=meshgrid(1:size(F,2),1:size(F,1),1);

qqqqq=3;

