# Pylib Revision: fe4e4d72cd2d / Date: 2012/11/22 04:53:20

class Graph (object):
    def __init__ (self, edges=[], undirected=False):
        self.nodes = set()
        self.edges = {}
        self.distances = {}
        self.undirected = undirected
        for from_node, to_node, distance in edges:
            self.add_edge (from_node, to_node, distance)

    def add_edge (self, from_node, to_node, distance):
        self.nodes.add (from_node)
        self.nodes.add (to_node)
        self._add_edge (from_node, to_node, distance)
        if self.undirected:
            self._add_edge (to_node, from_node, distance)

    def _add_edge (self, from_node, to_node, distance):
        self.edges.setdefault (from_node, [])
        self.edges[from_node].append (to_node)
        if distance < 0: raise ValueError ('distance', distance)
        self.distances[(from_node, to_node)] = distance

# From (2012-11-20): http://forrst.com/posts/Dijkstras_algorithm_in_Python-B4U
# Fixed to allow use in directed graphs (vs only undirected previously)
# and a few other minor tweaks.
def find_paths (graph, initial_node):
        visited = {initial_node: 0}
        current_node = initial_node
        path = {}
        nodes = set (graph.nodes)
        while nodes:
            min_node = None
            for node in nodes:
                if node in visited:
                    if min_node is None:
                        min_node = node
                    elif visited[node] < visited[min_node]:
                        min_node = node
            if min_node is None: break
            nodes.remove (min_node)
            cur_wt = visited[min_node]
            if min_node not in graph.edges: continue
            for edge in graph.edges[min_node]:
                wt = cur_wt + graph.distances[(min_node, edge)]
                if edge not in visited or wt < visited[edge]:
                    visited[edge] = wt
                    path[edge] = min_node
        return visited, path

def shortest (graph, initial_node, goal_node):
        if initial_node not in graph.nodes:
            raise ValueError ('initial_node', initial_node)
        if goal_node not in graph.nodes:
            raise ValueError ('goal_node', goal_node)

        distances, paths = find_paths (graph, initial_node)

        if goal_node not in paths and goal_node != initial_node: return []
        route = [goal_node]; next = goal_node
        while next != initial_node:
            next = paths[next]
            route.append (next)
        route.reverse()
        return route

