function  EndPoint = e1(StartPoint, GradientVolume, StepSize)
%  E1 is a function which performs one step of the Euler ray tracing
%  
%   EndPoint = E1(StartPoint, GradientVolume, StepSize);
%  
%    inputs :
%        StartPoint: 2D or 3D location in vectorfield
%        GradientVolume: Vectorfield
%        Stepsize : The stepsize
%  
%   outputs :
%        EndPoint : The new location (zero if outside image)
%
% Function is written by D.Kroon University of Twente (Oct 2010)

if(numel(StartPoint)==2)
    %Linear interpolation of current location  
    xBas=[0 0 1 1]+floor(StartPoint(1));
    yBas=[0 1 0 1]+floor(StartPoint(2));
    xCom=StartPoint(1)-floor(StartPoint(1)); 
    yCom=StartPoint(2)-floor(StartPoint(2)); 
  
    % Linear interpolation percentages.
    perc=[(1-xCom) * (1-yCom); 
          (1-xCom) * yCom    ;
          xCom     * (1-yCom);
          xCom     * yCom    ];

    % Split in Gradient Volumes
    Gx=GradientVolume(:,:,1);
    Gy=GradientVolume(:,:,2);

    xBas=min(max(xBas,1),size(Gx,1));
    yBas=min(max(yBas,1),size(Gx,2));
    
    ind=sub2ind(size(Gx),xBas(:),yBas(:));
    gradient=[sum(Gx(ind).*perc) sum(Gy(ind).*perc)];
    gradient=gradient./(sqrt(sum(gradient.^2))+eps);

    % Set a step in the direction of the gradient.
    EndPoint=StartPoint(:)-StepSize*gradient(:);
    check=(EndPoint(1)<1)||(EndPoint(2)<1)||(EndPoint(1)>size(Gx,1))||(EndPoint(2)>size(Gx,2));
    if(check), EndPoint=[0;0]; end
else
    %Linear interpolation of current location  
    xBas=[0 0 0 0 1 1 1 1]+floor(StartPoint(1));
    yBas=[0 0 1 1 0 0 1 1]+floor(StartPoint(2));
    zBas=[0 1 0 1 0 1 0 1]+floor(StartPoint(3));
    xCom=StartPoint(1)-floor(StartPoint(1)); 
    yCom=StartPoint(2)-floor(StartPoint(2)); 
    zCom=StartPoint(3)-floor(StartPoint(3)); 

    % Linear interpolation percentages.
    perc=[(1-xCom) * (1-yCom) * (1-zCom); 
          (1-xCom) * (1-yCom) * zCom; 
          (1-xCom) * yCom     * (1-zCom); 
          (1-xCom) * yCom     * zCom; 
          xCom     * (1-yCom) * (1-zCom); 
          xCom     * (1-yCom) * zCom; 
          xCom     * yCom     * (1-zCom); 
          xCom     * yCom     * zCom;];

    % Split in Gradient Volumes
    Gx=GradientVolume(:,:,:,1);
    Gy=GradientVolume(:,:,:,2);
    Gz=GradientVolume(:,:,:,3);
    
    xBas=min(max(xBas,1),size(Gx,1));
    yBas=min(max(yBas,1),size(Gx,2));
    zBas=min(max(zBas,1),size(Gx,3));
    
    ind=sub2ind(size(Gx),xBas(:),yBas(:),zBas(:));
    gradient=[sum(Gx(ind).*perc) sum(Gy(ind).*perc) sum(Gz(ind).*perc)];
    gradient=gradient./(sqrt(sum(gradient.^2))+eps);

    % Set a step in the direction of the gradient.
    EndPoint=StartPoint-StepSize*gradient(:);
    check=(EndPoint(1)<1)||(EndPoint(2)<1)||(EndPoint(3)<1)||(EndPoint(1)>size(Gx,1))||(EndPoint(2)>size(Gx,2))||(EndPoint(3)>size(Gx,3));
    if(check), EndPoint=[0;0;0]; end
end
