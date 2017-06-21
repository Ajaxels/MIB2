/* graph.h */
/*
	This software library implements the maxflow algorithm
	described in

		An Experimental Comparison of Min-Cut/Max-Flow Algorithms
		for Energy Minimization in Vision.
		Yuri Boykov and Vladimir Kolmogorov.
		In IEEE Transactions on Pattern Analysis and Machine Intelligence (PAMI), 
		September 2004

	This algorithm was developed by Yuri Boykov and Vladimir Kolmogorov
	at Siemens Corporate Research. To make it available for public use,
	it was later reimplemented by Vladimir Kolmogorov based on open publications.

	If you use this software for research purposes, you should cite
	the aforementioned paper in any resulting publication.

	----------------------------------------------------------------

	For description, license, example usage, discussion of graph representation	and memory usage see README.TXT.
*/

#ifndef __GRAPH_H__
#define __GRAPH_H__

#include "block.h"

/*
	arcs and pointers to nodes are
	added in blocks for memory and time efficiency.
	Below are numbers of items in blocks
*/
#define ARC_BLOCK_SIZE 1024
#define NODEPTR_BLOCK_SIZE 128

// captype: type of edge capacities (excluding t-links)
// tcaptype: type of t-links (edges between nodes and terminals)
// flowtype: type of total flow
//
// Current instantiations are in instances.inc
template <typename captype, typename tcaptype, typename flowtype> class Graph
{
public:
	typedef enum
	{
		SOURCE	= 0,
		SINK	= 1
	} termtype; /* terminals */

	typedef int node_id;

	/* interface functions */

	/* Constructor. Optional argument is the pointer to the
	   function which will be called if an error occurs;
	   an error message is passed to this function. If this
	   argument is omitted, exit(1) will be called.

	   Note: edge_num_max in the current implementation is ignored (it's present for consistency with version 3.03) */
	Graph(int node_num_max, int edge_num_max, void (*err_function)(const char *) = NULL);

	/* Destructor */
	~Graph();

	/* Adds node(s) to the graph. By default, one node is added (num=1); then first call returns 0, second call returns 1, and so on. 
	   If num>1, then several nodes are added, and node_id of the first one is returned. */
	node_id add_node(int num = 1);

	/* Adds a bidirectional edge between 'from' and 'to'
	   with the weights 'cap' and 'rev_cap' */
	void add_edge(node_id from, node_id to, captype cap, captype rev_cap);

	/* Sets the weights of the edges 'SOURCE->i' and 'i->SINK'
	   Can be called at most once for each node before any call to 'add_tweights'.
	   Weights can be negative */
	void set_tweights(node_id i, tcaptype cap_source, tcaptype cap_sink);

	/* Adds new edges 'SOURCE->i' and 'i->SINK' with corresponding weights
	   Can be called multiple times for each node.
	   Weights can be negative */
	void add_tweights(node_id i, captype cap_source, captype cap_sink);

	/* After the maxflow is computed, this function returns to which
	   segment the node 'i' belongs (Graph::SOURCE or Graph::SINK) */
	termtype what_segment(node_id i);

	/* Computes the maxflow. Can be called only once. */
	flowtype maxflow();

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
	
private:
	/* internal variables and functions */

	struct arc_st;

	/* node structure */
	typedef struct node_st
	{
		arc_st			*first;		/* first outcoming arc */

		arc_st			*parent;	/* node's parent */
		node_st			*next;		/* pointer to the next active node
									   (or to itself if it is the last node in the list) */
		int				TS;			/* timestamp showing when DIST was computed */
		int				DIST;		/* distance to the terminal */
		short			is_sink;	/* flag showing whether the node is in the source or in the sink tree */

		captype			tr_cap;		/* if tr_cap > 0 then tr_cap is residual capacity of the arc SOURCE->node
									   otherwise         -tr_cap is residual capacity of the arc node->SINK */
	} node;

	/* arc structure */
	typedef struct arc_st
	{
		node_st			*head;		/* node the arc points to */
		arc_st			*next;		/* next arc with the same originating node */
		arc_st			*sister;	/* reverse arc */

		captype			r_cap;		/* residual capacity */
	} arc;

	/* 'pointer to node' structure */
	typedef struct nodeptr_st
	{
		node_st			*ptr;
		nodeptr_st		*next;
	} nodeptr;

	node_st*			nodes;
	int				node_num, node_num_max;
	Block<arc>			*arc_block;
	DBlock<nodeptr>		*nodeptr_block;

	void	(*error_function)(const char *);	/* this function is called if a error occurs,
										   with a corresponding error message
										   (or exit(1) is called if it's NULL) */

	flowtype			flow;		/* total flow */

/***********************************************************************/

	node				*queue_first[2], *queue_last[2];	/* list of active nodes */
	nodeptr				*orphan_first, *orphan_last;		/* list of pointers to orphans */
	int					TIME;								/* monotonically increasing global counter */

/***********************************************************************/

	/* functions for processing active list */
	void set_active(node *i);
	node *next_active();

	void maxflow_init();
	void augment(arc *middle_arc);
	void process_source_orphan(node *i);
	void process_sink_orphan(node *i);
};

#endif
