#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"
@include "graph"

BEGIN {
  ENVIRON["LANG"] = "C";
  printf "" >> "/dev/stderr";
  delete g_graph;
  delete g_shortcuts;
}

function parse() {
  g_graph[$1] = $2;
}

{
  parse();
}

function expand(in_graph, out_graph,      objects, obj, pair, pair_a, src_obj, dest_obj, component_count) {
  list_graph_objects(in_graph, objects);
  delete out_graph;
  for(level = 0; level < 40; level++) {
    for(pair in in_graph) {
      if(pair ~ /AA|ZZ/ && level>0) continue;
      split(pair, pair_a, SUBSEP);
      out_graph[pair_a[1] "_" level, pair_a[2] "_" level] = in_graph[pair];
    }
    for(obj in objects) {
      if(obj ~ /i/) {
        src_obj = obj "_" level;
        dest_obj = substr(obj,1,2) "o_" (level + 1);
        set_graph_distance(out_graph, src_obj, dest_obj, 1);
        remove_graph_node_inplace_tracing(out_graph, src_obj);

        component_count = count_graph_components(out_graph);
        printf "Graph now has %d components\n", component_count >> "/dev/stderr";
        if(component_count == 1) {
          printf "Stopping expansion at level %d\n", level >> "/dev/stderr";
          return;
        }
      }
    }
  }
}

function get_shortcut(obj1, obj2) {
  if(obj2 < obj2) return get_shortcut(obj2, obj1);
  if((obj1,obj2) in g_shortcuts) return g_shortcuts[obj1,obj2]; else return "";
}

function remove_graph_node_inplace_tracing(graph, obj,         pair, pair_a, neighbor_dist, distance, n1, n2, old_distance, edgestoremove) {
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
          if ((n1,n2) in graph) {
            if(distance < graph[n1,n2]) {
              g_shortcuts[n1,n2] = get_shortcut(n1,obj) "," obj "," get_shortcut(obj,n2);
            } else {
              # printf "An edge exists between %s and %s with distance %d <= %d\n", n1, n2, graph[n1,n2], distance >> "/dev/stderr";
            }
          } else {
            g_shortcuts[n1,n2] = get_shortcut(n1,obj) "(" neighbor_dist[n1] ")" obj "(" neighbor_dist[n2] ")"  get_shortcut(obj,n2);
          }
          set_graph_distance(graph, n1, n2, distance);
        }
      }
    }
  }
}


function remove_corridors(graph,     obj, objects, objects_to_remove) {
  list_graph_objects(graph, objects);
  delete objects_to_remove;
  for(obj in objects) {
    if(!(obj ~ /AA|ZZ/)) { objects_to_remove[obj] = 1; }
  }
  for(obj in objects_to_remove) {
    if(debug>1) { printf "Removing %s\n", obj >> "/dev/stderr"; }
    remove_graph_node_inplace_tracing(graph, obj);
    if(debug>1) { printf "Graph now has %d edges\n", length(graph) >> "/dev/stderr"; }
  }
}

function count_graph_components(graph,    pair, pair_a, components, old, new, component_name, component_count) {
  delete components;
  component_name = 0;
  component_count = 0;
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);
    if(pair_a[1] in components && pair_a[2] in components && components[pair_a[1]] != components[pair_a[2]]) {
      old = components[pair_a[2]];
      new = components[pair_a[1]];
      # printf "Merging %d into %d\n", old, new >> "/dev/stderr";
      for (c in components) {
        if(components[c] == old) {
          components[c] = new;
        }
      }
      component_count--;
    } if(pair_a[1] in components) {
      components[pair_a[2]] = components[pair_a[1]];
    } else if(pair_a[2] in components) {
      components[pair_a[1]] = components[pair_a[2]];
    } else {
      components[pair_a[1]] = component_name;
      components[pair_a[2]] = component_name;
      component_name++;
      component_count++;
    }
  }
  return component_count;
}

END {
  # printf "found %d edges\n", length(g_graph);
  # print_graph(g_graph);
  expand(g_graph, g_multigraph);
  print_graph(g_multigraph);
  remove_corridors(g_multigraph);
  printf "path: %s\n", "AA_0" get_shortcut("AA_0","ZZ_0") "ZZ_0" >> "/dev/stderr";
  printf "path length: %d\n", g_multigraph["AA_0","ZZ_0"] >> "/dev/stderr";

  close("/dev/stderr");
  if(0) {
    remove_corridors();
  }
}
