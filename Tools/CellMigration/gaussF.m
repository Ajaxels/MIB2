function [gauss]=gaussF(rowDim,colDim,levDim,rowSigma,colSigma,levSigma,rowMiu,colMiu,levMiu,rho)
%function [gauss]=gaussF(rowDim,colDim,levDim,rowSigma,colSigma,levSigma,rowMiu,colMiu,levMiu,rho)
% GAUSS produces an N-dimensional gaussian function (N=1,2,3)
%-----------------------------------------------------------------
% ******         N Dimensional Gauss Function        *******
%-----------------------------------------------------------------
%------  Author :       Constantino Carlos Reyes-Aldasoro
%------                 PHD Student at the University of Warwick
%------  Supervisor :   Abhir Bhalerao
%------  18 October 2001
%-----------------------------------------------------------------
%------ input   dimensions x,y,z
%------         sigma values x,y,z >0
%------         -inf < miu values,x,y,z   < inf
%------         -1 < rho < 1  oblique distributions angle control
%------ output  n-dimensional gaussian function
%-----------------------------------------------------------------
%----------------------------------------------------
%------ For a description and explanation please refer to:
%------ http://www.dcs.warwick.ac.uk/~creyes/m-vts --
%----------------------------------------------------

%------ no input data is received, error -------------------------
if nargin<1 help gaussF;  gauss=[]; return; end;

%-----------------------------------------------------------------
%------ cases of input:                  -------------------------
%-----------------------------------------------------------------
% 1 only R,C,L, dimensions are specified,
%        then, set sigma so that borders are 1% of central value
%        sigma is set after miu is calculated
% 2 R,C,L dimensions are specified AND
%        sigmas are provided, then
%        set values of miu
% 3 all input arguments are provided
% 4 Rho is provided, in all the previous cases rho=0

if nargin<10 rho=0; end;


%-----------------------------------------------------------------
%------ Determine the dimensios of the gaussian function ---------
%------ dimensions can be input vectors as in (size(a)) ----------
%-----------------------------------------------------------------
if nargin==1
    [wRow,wCol,wLev]=size(rowDim);
    if wCol==3       %------ 3 D
        levDim=rowDim(3);      colDim=rowDim(2);      rowDim=rowDim(1);
    elseif wCol==2   %------ 2 D  set levels =1
        colDim=rowDim(2);      rowDim=rowDim(1);      levDim=1;
    elseif wCol==1   %------ 1 D is required, set others =1
        colDim=1;      levDim=1;
    end;
elseif nargin==2
    levDim=1;
end
%-----------------------------------------------------------------
%----- x, y, z dimensions of the filter --------------------------
%-----------------------------------------------------------------
filter.x=1:ceil(rowDim);
filter.y=1:ceil(colDim);
filter.z=1:ceil(levDim);
filter.data=zeros(ceil(rowDim),ceil(colDim),ceil(levDim));
[rr,cc,dd]=meshgrid(filter.x, filter.y ,filter.z);
%-----------------------------------------------------------------
%----- Determine mius and sigmas in case not provided ------------
%-----------------------------------------------------------------
if nargin<=6  %------ mean values are not provided
    rowMiu=sum(filter.x)/length(filter.x);
    colMiu=sum(filter.y)/length(filter.y);
    levMiu=sum(filter.z)/length(filter.z);
end
%sigmVal=3.7169;
%sigmVal=3.0349;
%sigmVal=2.1469;
sigmVal=1.1774;

if nargin<=3    %------ sigma values are not provided
    rowSigma=(rowMiu-1)/sigmVal;
    colSigma=(colMiu-1)/sigmVal;
    levSigma=(levMiu-1)/sigmVal;
end;
%-----------------------------------------------------------------
%------ set value for 0.1% --> sqrt(2*log(0.001)) = 3.7169  ------
%------ set value for 1% --> sqrt(2*log(0.01)) = 3.0349     ------
%------ set value for 10% --> sqrt(2*log(0.1)) = 2.1460     ------
%------ set value for 50% --> sqrt(2*log(0.5)) = 1.1774     ------

%-----------------------------------------------------------------
%------ sigma must be greater than zero --------------------------
rowSigma=max(rowSigma,0.000001);
colSigma=max(colSigma,0.000001);
levSigma=max(levSigma,0.000001);

if prod(size(rho))~=1
    %rho is the covariance matrix
    if size(rho,1)==2
        invSigma=inv(rho);
        Srr=invSigma(1,1);Scc=invSigma(2,2);Src=2*invSigma(2,1);
        Srd=0;Scd=0;Sdd =0;
    else
        invSigma=inv(rho);
        Srr=invSigma(1,1);Scc=invSigma(2,2);Src=2*invSigma(2,1);
        Srd=2*invSigma(1,3);Scd=2*invSigma(2,3);Sdd=invSigma(3,3);
    end
    exp_r= (1/rowSigma/rowSigma)*(rr-rowMiu).^2 ;
    exp_c=(1/colSigma/colSigma)*(cc-colMiu).^2 ;
    exp_d=(1/levSigma/levSigma)*(dd-levMiu).^2;
    exp_rc=(1/rowSigma/colSigma)*(rr-rowMiu).*(cc-colMiu);
    exp_rd=(1/rowSigma/levSigma)*(rr-rowMiu).*(dd-levMiu);
    exp_cd=(1/levSigma/colSigma)*(dd-levMiu).*(cc-colMiu);
    gauss=exp(-(Srr * exp_r + Scc * exp_c  + Sdd * exp_d + Src * exp_rc + Srd * exp_rd + Scd * exp_cd ));
else 




    rho=min(rho,0.999999);
    rho=max(rho,-0.999999);

    %-----------------------------------------------------------------
    %------ Calculate exponential functions in each dimension --------
    filter.x2=(1/(sqrt(2*pi)*rowSigma))*exp(-((filter.x-rowMiu).^2)/2/rowSigma/rowSigma);
    filter.y2=(1/(sqrt(2*pi)*colSigma))*exp(-((filter.y-colMiu).^2)/2/colSigma/colSigma);
    filter.z2=(1/(sqrt(2*pi)*levSigma))*exp(-((filter.z-levMiu).^2)/2/levSigma/levSigma);

    %------ ? ? ? ? The individual functions should add to 1 ? ? ? ---
    filter.x2=filter.x2/sum(filter.x2);
    filter.y2=filter.y2/sum(filter.y2);
    filter.z2=filter.z2/sum(filter.z2);
    %-----------------------------------------------------------------
    rhoExponent=(-(rho*(filter.x-rowMiu)'*(filter.y-colMiu))/rowSigma/colSigma);
    %rhoExponent=20*rhoExponent/max(max(rhoExponent));
    filter.rho=(1/sqrt(1-rho^2))*exp(rhoExponent);
    %-----------------------------------------------------------------
    %------ Get the 2D function  (if needed)--------------------------
    if (colDim>1&rowDim>1)
        twoDFilter=(filter.x2'*filter.y2).*filter.rho;
        %------ Get the 3D function  (if needed)----------------------
        if ceil(levDim)>1
            for ii=1:ceil(levDim);
                threeDFilter(:,:,ii)=twoDFilter.*filter.z2(ii);
            end;
            gauss=threeDFilter;
        else
            gauss=twoDFilter;
        end;
    else    %------This covers the 1D cases both row and column ------
        if length(filter.x2)>length(filter.y2)
            gauss=filter.x2;
        else
            gauss=filter.y2;
        end
    end;

    %------ normalising the output ------------------

    %gauss=gauss/max(max(max(gauss)));

    %------ remove NaN in case there are any
    %gauss(any(isnan(gauss)'),:) =0;
    gauss(isnan(gauss))=0;
end
