img = imread('coins.png');
bin = imfill(img>100, 'holes');
dist = bwdist(bin);
wat1 = watershed(dist, 4);
% compute overlay image for display
tmp = uint8(double(img).*(wat1>0));
ovr = uint8(cat(3, max(img, uint8(255*(wat1==0))), tmp, tmp));

% show the resulting graph
[edgeList1, meanInt1] = imRichRAG(wat1,1,img);
wat2 =  imdilate(wat1, ones([3 3 3]));   % fill the gaps
[edgeList2, meanInt2] = imRichRAG(wat2,1,img);


figure(1)
subplot(2,2,1)
imshowpair(img, wat1);
title('Default clusters from watershed');
subplot(2,2,2)
imshowpair(img, wat2);
title('Clusters with filled gaps');
subplot(2,2,3)
title('Edge intensity comparison')
plot(1:numel(meanInt1), meanInt1, 'o-', 1:numel(meanInt1), meanInt2, 'o-');
ylabel('Mean edge intensity, counts');
xlabel('Edge index');
legend('with gaps', 'without gaps');
grid;