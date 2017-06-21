function vector2 = windv(vector1, w_size)
% windv(vector,window size)
% vectorized version of windv()
% smooths a vector using a window of +/- window size
% window size is reduced at the edges
%
vl = length(vector1);

vector2 = vector1;
for index = 1:w_size
    vector2(1:vl-index)=vector2(1:vl-index)+vector1(index+1:vl);
    vector2(index+1:vl)=vector2(index+1:vl)+vector1(1:vl-index);
end;

vector2=vector2./(2*w_size+1);

for index = 1:w_size
    vector2(index)=mean(vector1(1:w_size+index));
    vector2(vl+1-index)=mean(vector1(vl+1-index-w_size:vl));
end;

