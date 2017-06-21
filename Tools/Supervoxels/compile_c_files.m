% compile all c files
mex -v -largeArrayDims maxflowmex_v222.cpp maxflow-v2.22/adjacency_list_new_interface/graph.cpp maxflow-v2.22/adjacency_list_new_interface/maxflow.cpp
mex -v slicmex.c 
mex -v slicsupervoxelmex.c  
