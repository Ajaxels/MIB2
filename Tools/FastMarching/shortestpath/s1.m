function  EndPoint = s1(StartPoint, Volume)
%  S1 is a function which looks for a lower pixel location in a local
%   neighborhood
%  
%   EndPoint = S1(StartPoint, GradientVolume, StepSize);
%  
%    inputs :
%        StartPoint: 2D or 3D location in vectorfield
%        Volume: 2D or 3D matrix with values
%  
%   outputs :
%        EndPoint : The new location (zero if outside image)
%
% Function is written by D.Kroon University of Twente (Oct 2010)

StartPoint=round(StartPoint);
S=StartPoint;
if(numel(StartPoint)==2)
    for stepsize=1:3
        sxm=max(S(1)-stepsize,1); 
        sym=max(S(2)-stepsize,1);
        sxp=min(S(1)+stepsize,size(Volume,1));
        syp=min(S(2)+stepsize,size(Volume,2));

        X=sxm:sxp;
        Y=sym:syp;
        SubVolume=Volume(sxm:sxp,sym:syp);
        
        CVolume=SubVolume<Volume(S(1),S(2));
        check=any(CVolume(:));
        if(check), break; end
    end
    if(check), 
        [temp,ind]=min(SubVolume(:));
        [i,j]=ind2sub(size(CVolume),ind);
        EndPoint=[X(i);Y(j)];
    else
        EndPoint=StartPoint;
    end
else
    for stepsize=1:3
        sxm=max(S(1)-stepsize,1); 
        sym=max(S(2)-stepsize,1);
        szm=max(S(3)-stepsize,1);
        
        sxp=min(S(1)+stepsize,size(Volume,1));
        syp=min(S(2)+stepsize,size(Volume,2));
        szp=min(S(3)+stepsize,size(Volume,3));

        X=sxm:sxp;
        Y=sym:syp;
        Z=szm:szp;
        SubVolume=Volume(sxm:sxp,sym:syp,szm:szp);

        CVolume=SubVolume<Volume(S(1),S(2),S(3));
        check=any(CVolume(:));
        if(check), break; end
    end
    if(check), 
        [temp,ind]=min(SubVolume(:));
        [i,j,k]=ind2sub(size(CVolume),ind);
        EndPoint=[X(i);Y(j);Z(k)];
    else
        EndPoint=StartPoint;
    end
end



