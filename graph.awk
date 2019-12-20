function isblank(s) {
  return s ~ /^\./;
}

function set_graph_distance(graph, obj1, obj2, distance,    old_distance) {
  if(obj1 > obj2) return set_graph_distance(graph, obj2, obj1, distance);
  if ((obj1, obj2) in graph) {
    old_distance = graph[obj1, obj2];
    if(distance < old_distance) {
      # if(debug>2) printf "replacing edge %s = %d < %d\obj", obj1 SUBSEP obj2, distance, old_distance >> "/dev/stderr";
      graph[obj1, obj2] = distance;
    } else {
      # if(debug>2) printf "edge %s already exists with distance %d <= %d\obj", obj1 SUBSEP obj2, old_distance, distance >> "/dev/stderr";
    }
  } else {
    # if(debug>2) printf "adding edge %s = %d\obj", obj1 SUBSEP obj2, distance >> "/dev/stderr";
    graph[obj1, obj2] = distance;
  }
}

function delete_graph_edge(graph, obj1, obj2) {
  if(obj1 > obj2) return delete_graph_edge(graph, obj2, obj1);
  delete graph[obj1, obj2];
}

function remove_graph_node(in_graph, obj, out_graph,       pair, pair_a, neighbor_dist, distance, n1, n2, old_distance) {
  delete neighbor_dist;
  delete out_graph;
  for(pair in in_graph) {
    split(pair, pair_a, SUBSEP);
    distance = in_graph[pair];
    if (pair_a[1] == obj) {
      # if(debug>2) printf "removing edge to %s\n", pair_a[2] >> "/dev/stderr";
      neighbor_dist[pair_a[2]] = distance;
    } else if (pair_a[2] == obj) {
      # if(debug>2) printf "removing edge to %s\n", pair_a[1] >> "/dev/stderr";
      neighbor_dist[pair_a[1]] = distance;
    } else {
      # if(debug>2) printf "copying edge %s\n", pair >> "/dev/stderr";
      out_graph[pair] = distance;
    }
  }
  for(n1 in neighbor_dist) {
    for(n2 in neighbor_dist) {
      if(n1 < n2) {
        distance = neighbor_dist[n1] + neighbor_dist[n2];
        set_graph_distance(out_graph, n1, n2, distance);
      }
    }
  }
}

function remove_graph_node_inplace(graph, obj,         pair, pair_a, neighbor_dist, distance, n1, n2, old_distance, edgestoremove) {
  delete neighbor_dist;
  delete edgestoremove;
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);
    distance = graph[pair];
    if (pair_a[1] == obj) {
      # if(debug>2) printf "removing edge to %s\n", pair_a[2] >> "/dev/stderr";
      neighbor_dist[pair_a[2]] = distance;
    } else if (pair_a[2] == obj) {
      # if(debug>2) printf "removing edge to %s\n", pair_a[1] >> "/dev/stderr";
      neighbor_dist[pair_a[1]] = distance;
    } else {
      # if(debug>2) printf "keeping edge %s\n", pair >> "/dev/stderr";
      continue;
    }
    edgestoremove[pair] = 1;
  }
  for(pair in edgestoremove) {
    delete graph[pair];
  }
  if(length(neighbor_dist) == 1) {
  } else {
    for(n1 in neighbor_dist) {
      for(n2 in neighbor_dist) {
        if(n1 < n2) {
          distance = neighbor_dist[n1] + neighbor_dist[n2];
          set_graph_distance(graph, n1, n2, distance);
        }
      }
    }
  }
}

function print_graph(graph,      obj, pair, pair_a) {
  printf "graph {\n" >> "/dev/stderr";
  printf "  rankdir=\"LR\";\n" >> "/dev/stderr";
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);
    printf "  \"%s\" -- \"%s\" [ label = \"%d\" ];\n", pair_a[1], pair_a[2], graph[pair] >> "/dev/stderr";
  }
  printf "}\n" >> "/dev/stderr";
  fflush();
}

function find_neighbors(graph, from_object, out_neighbors,    neighbor_count, pair, pair_a, n_obj) {
  delete out_neighbors;
  neighbor_count = 0;
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);

    if(pair_a[1] == from_object) {
      n_obj = pair_a[2];
    } else if(pair_a[2] == from_object) {
      n_obj = pair_a[1];
    } else {
      continue;
    }
    out_neighbors[++neighbor_count] = n_obj SUBSEP graph[pair];
  }
  return neighbor_count;
}

function neighbors_by_distance(i1, v1, i2, v2,    a1, a2, hint) {
  split(v1, a1, SUBSEP);
  split(v2, a2, SUBSEP);

#  hint = "tgrjdoayukbhcivezwqxfnpsml";
#  if(index(hint, a1[1]) < index(hint,a2[1])) {
#    return -1;
#  } else if(index(hint, a1[1]) == index(hint,a2[1])) {
#    return 0;
#  } else {
#    return 1;
#  }

  if(a1[1] < a2[1]) {
    return -1;
  } else if (a1[1] == a2[1]) {
    if(a1[2] < a2[2]) {
      return -1;
    } else if (a1[2] == a2[2]) {
      return 0;
    } else {
      return 1;
    }
  } else {
    return 1;
  }
}

function list_graph_objects(graph, objects,      pair, pair_a) {
  delete objects;
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);

    objects[pair_a[1]] = 1;
    objects[pair_a[2]] = 1;
  }
}

function remove_useless_nodes(graph,     obj, objects, objects_to_remove) {
  list_graph_objects(graph, objects);
  delete objects_to_remove;
  for(obj in objects) {
    if(isblank(obj)) { objects_to_remove[obj] = 1; }
  }
  for(obj in objects_to_remove) {
    if(debug>1) { printf "Removing %s\n", obj >> "/dev/stderr"; }
    remove_graph_node_inplace(graph, obj);
  }
}

0 {
  set_graph_distance();
  remove_graph_node();
  remove_graph_node_inplace();
  print_graph();
  find_neighbors();
  neighbors_by_distance();
  remove_useless_nodes();
}
