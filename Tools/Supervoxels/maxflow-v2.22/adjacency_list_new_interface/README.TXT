Directory 'adjacency_list_new_interface' is derived from 'adjacency_list',
but uses the same interface as maxflow-v3.03 (to help those migrating
from version 3.03). This version and version 3.03 implement exactly
the same algorithm, but have the following differences:
- version 3.03 offers some extra functionality (such as search tree reusing);
- the number node_num_max specified in the constructor can be exceeded in version 3.03 but not in this version.

