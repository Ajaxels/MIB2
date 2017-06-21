/* graph.cpp */

#include <stdio.h>
#include <string.h>
#include "graph.h"

template <typename captype, typename tcaptype, typename flowtype>
	Graph<captype, tcaptype, flowtype>::Graph(int _node_num_max, int edge_num_max, void (*err_function)(const char *))
	: node_num(0), node_num_max(_node_num_max)
{
	error_function = err_function;
	nodes = (node*) malloc(node_num_max*sizeof(node));
	arc_block  = new Block<arc>(ARC_BLOCK_SIZE, error_function);
	flow = 0;
}

template <typename captype, typename tcaptype, typename flowtype>
	Graph<captype, tcaptype, flowtype>::~Graph()
{
	free(nodes);
	delete arc_block;
}

template <typename captype, typename tcaptype, typename flowtype>
	typename Graph<captype, tcaptype, flowtype>::node_id Graph<captype, tcaptype, flowtype>::add_node(int num)
{
	node_id i = node_num;
	node_num += num;

	if (node_num > node_num_max)
	{
		printf("Error: the number of nodes is exceeded!\n");
		exit(1);
	}
	memset(nodes + i, 0, num*sizeof(node_st));

	return i;
}

template <typename captype, typename tcaptype, typename flowtype>
	void Graph<captype, tcaptype, flowtype>::add_edge(node_id _from, node_id _to, captype cap, captype rev_cap)
{
	arc *a, *a_rev;
	node* from = nodes + _from;
	node* to = nodes + _to;

	a = arc_block -> New(2);
	a_rev = a + 1;

	a -> sister = a_rev;
	a_rev -> sister = a;
	a -> next = from -> first;
	from -> first = a;
	a_rev -> next = ((node*)to) -> first;
	to -> first = a_rev;
	a -> head = to;
	a_rev -> head = from;
	a -> r_cap = cap;
	a_rev -> r_cap = rev_cap;
}

template <typename captype, typename tcaptype, typename flowtype>
	void Graph<captype, tcaptype, flowtype>::set_tweights(node_id _i, tcaptype cap_source, tcaptype cap_sink)
{
	flow += (cap_source < cap_sink) ? cap_source : cap_sink;
	nodes[_i] . tr_cap = cap_source - cap_sink;
}

template <typename captype, typename tcaptype, typename flowtype>
	void Graph<captype, tcaptype, flowtype>::add_tweights(node_id _i, captype cap_source, captype cap_sink)
{
	register captype delta = nodes[_i] . tr_cap;
	if (delta > 0) cap_source += delta;
	else           cap_sink   -= delta;
	flow += (cap_source < cap_sink) ? cap_source : cap_sink;
	nodes[_i] . tr_cap = cap_source - cap_sink;
}

#include "instances.inc"
