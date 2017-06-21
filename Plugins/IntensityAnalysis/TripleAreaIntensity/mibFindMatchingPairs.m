function idx = mibFindMatchingPairs(X1, X2)
% find matching pairs for X1 from X2
% X1[:, (x,y)]
% X2[:, (x,y)]

% % following code is equal to pdist2 function in the statistics toolbox
% % such as: dist = pdist2(X1,X2);
dist = zeros([size(X1,1) size(X2,1)]);
for i=1:size(X1,1)
    for j=1:size(X2,1)
        dist(i,j) = sqrt((X1(i,1)-X2(j,1))^2 + (X1(i,2)-X2(j,2))^2);
    end
end

% alternative fast method
% DD = sqrt( bsxfun(@plus,sum(X1.^2,2),sum(X2.^2,2)') - 2*(X1*X2') );

% following is an adaptation of a code by Gunther Struyf
% http://stackoverflow.com/questions/12083467/find-the-nearest-point-pairs-between-two-sets-of-of-matrix
N = size(X1,1);
matchAtoB=NaN(N,1);
X1b = X1;
X2b = X2;
for ii=1:N
    %dist(:,matchAtoB(1:ii-1))=Inf; % make sure that already picked points of B are not eligible to be new closest point
    %[~, matchAtoB(ii)]=min(dist(ii,:));
    dist(matchAtoB(1:ii-1),:)=Inf; % make sure that already picked points of B are not eligible to be new closest point
    %         for jj=1:N
    %             [~, minVec(jj)] = min(dist(:,jj));
    %         end
    [~, matchAtoB(ii)]=min(dist(:,ii));
    
    %         X2b(matchAtoB(1:ii-1),:)=Inf;
    %         goal = X1b(ii,:);
    %         r = bsxfun(@minus,X2b,goal);
    %         [~, matchAtoB(ii)] = min(hypot(r(:,1),r(:,2)));
end
matchBtoA = NaN(size(X2,1),1);
matchBtoA(matchAtoB)=1:N;
idx =  matchBtoA;   % indeces of the matching objects, i.e. STATS1(objId) =match= STATS2(idx(objId))

end