#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"

BEGIN {
  ENVIRON["LANG"] = "C";
  delete g_space;
  FS="";
  g_xmin = 0;
  g_xmax = 0;
  g_ymin = 0;
  g_ymax = 0;
  g_last_head = 0;
  if(debug>2) printf "" >> "/dev/stderr";
}

function parse(      x, y) {
  g_xmax = NF - 1;
  y = NR - 1;
  for(x=0; x<NF; x++) {
    ch = $(x + 1);
    if(ch == "@") {
      g_startx = x;
      g_starty = y;
    }
    g_space[x, y] = ch;
  }
}

{
  parse();
}

function iskey(s) {
  return s ~ /[a-z]/;
}

function isdoor(s) {
  return s ~ /[A-Z]/;
}

function iswall(s) {
  return s == "#";
}

function create_head(head_pos, head_walked_distance, head_last_object, head_visited,   new_head_i) {
  new_head_i = ++g_last_head;
  g_head_pos[new_head_i] = head_pos;
  g_head_last_object[new_head_i] = head_last_object;
  g_head_walked_distance[new_head_i] = head_walked_distance;
  g_head_visited[new_head_i]["dummy"] = 1;
  copyarray(head_visited, g_head_visited[new_head_i]);
  return new_head_i;
}

function advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, head_visited, again, x, y      , last_object) {
  # if(debug>2) printf "Head %d trying to go to %d, %d\n", head_i, x, y;
  if(x < g_xmin || x >= g_xmax || y < g_ymin || y >= g_ymax) {
    # if(debug>2) printf "(%d, %d) is out of range\n", x, y;
    return 0;
  }
  if((x, y) in head_visited) {
    # if(debug>2) printf "(%d, %d) is already visited\n", x, y;
    return 0;
  }
  tile = g_space[x, y];
  if(iswall(tile)) {
    # if(debug>2) printf "(%d, %d) is wall\n", x, y;
    head_visited[x, y] = -1;
    return 0;
  }
  if(again) {
    if(debug>2) printf "Advancing head %d (%d, %d) in multiple directions!\n", head_i, x, y;
    head_i = create_head(head_pos, head_walked_distance, head_last_object, head_visited);
    if(debug>2) printf "Created new head %d\n", head_i;
  }
  if(tile == ".") {
    if(debug>2) printf "Head %d entering free space (%d, %d)\n", head_i, x, y;
    g_head_walked_distance[head_i] = head_walked_distance + 1;
  } else {
    if(debug>2) printf "Head %d found object '%s' at (%d, %d) after %d steps\n", head_i, tile, x, y, head_walked_distance + 1;
    if(tile in g_object_parent) {
      if(g_object_parent[tile] != head_last_object) {
        if(debug>2) printf "%s has multiple parents! %s != %s\n", tile, head_last_object, g_object_parent[tile];
        exit 1;
      }
      if(g_object_parent_distance[tile] != head_walked_distance + 1) {
        if(debug>2) printf "%s has multiple distances! %s != %s\n", tile, head_walked_distance + 1, g_object_parent_distance[tile];
        exit 1;
      }
    } else {
      g_object_parent[tile] = head_last_object;
      g_object_parent_distance[tile] = head_walked_distance + 1;
    }

    g_head_last_object[head_i] = tile;
    g_head_walked_distance[head_i] = 0;
  }
  g_head_pos[head_i] = x SUBSEP y;
  g_head_visited[head_i][x, y] = 1;
  return 1;
}

function advance_head(head_i,      xya, xy, x, y, again, head_pos, head_walked_distance, head_last_object, head_visited) {
  xya = g_head_pos[head_i];
  split(xya, xy, SUBSEP);
  x = xy[1]; y = xy[2];

  # if(debug>2) printf "Trying to advance head %d from %d, %d\n", head_i, x, y;

  head_pos = g_head_pos[head_i];
  head_walked_distance = g_head_walked_distance[head_i];
  head_last_object = g_head_last_object[head_i];
  copyarray(g_head_visited[head_i], head_visited);

  again = 0;
  again += advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, head_visited, again, x+1, y);
  again += advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, head_visited, again, x-1, y);
  again += advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, head_visited, again, x, y+1);
  again += advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, head_visited, again, x, y-1);

  if(debug>2) printf "Did head %d advance ? %d\n", head_i, again;
  if(!again) {
    if(debug>2) printf "Killing head %d\n", head_i;
    delete g_head_pos[head_i];
  }

  return again;
}

function print_space(     x, y, h, heads) {
  print "SPACE:";
  for(h in g_head_pos) {
    heads[g_head_pos[h]] = h;
  }
  for(y=0; y<=g_ymax; y++) {
    for(x=0; x<=g_xmax; x++) {
      if((x,y) in heads)
        if(debug>2) printf "%d", heads[x,y] % 10;
      else
        if(debug>2) printf "%s", g_space[x,y];
    }
    if(debug>2) printf "\n";
  }
}

function scan_maze(     x, y, xya, xy, visited, prev_visited, distance, current_heads, head_i, again, obj) {
  if(debug>2) printf "Starting at %d, %d\n", g_startx, g_starty;
  delete visited;
  delete g_head_pos;
  delete g_head_last_object;
  delete g_head_walked_distance;
  delete g_head_visited;

  g_head_pos[0] = g_startx SUBSEP g_starty;
  g_head_last_object[0] = "@";
  g_head_walked_distance[0] = 0;
  g_head_visited[0][g_startx, g_starty] = 1;

  distance = 0;
  again = 1;
  while(again) {
    # print_space();
    again = 0;
    copyarray(g_head_pos, current_heads);
    for(head_i in current_heads) {
      again += advance_head(head_i);
    }

    if(debug>2) printf "Got %d heads at distance %d\n", length(g_head_pos), distance;
    distance++;
  };
  if(debug>2) printf "Found %d objects\n", length(g_object_parent);
}

function remove_useless_doors(    parents, leaves, obj, again) {
  again = 1;
  while(again) {
    again = 0;
    delete parents;
    delete leaves;
    for(obj in g_object_parent) {
      parents[g_object_parent[obj]] = 1;
    }
    for(obj in g_object_parent) {
      if(!(obj in parents)) {
        leaves[obj] = 1;
      }
    }
    if(debug>2) printf "Found %d leaves\n", length(leaves);
    for(obj in leaves) {
      if(isdoor(obj) || obj ~ /[0-9]/) {
        if(debug>2) printf "Removing useless door %s\n", obj;
        delete g_object_parent[obj];
        again++;
      }
    }
  }
}

function set_graph_distance(obj1, obj2, distance) {
  if(obj1 > obj2) return set_graph_distance(obj2, obj1, distance);
  g_graph[obj1, obj2] = distance;
}

function remove_graph_node(in_graph, obj, out_graph,       pair, pair_a, neighbor_dist, distance, n1, n2, old_distance) {
  delete neighbor_dist;
  delete out_graph;
  for(pair in in_graph) {
    split(pair, pair_a, SUBSEP);
    distance = in_graph[pair];
    if (pair_a[1] == obj) {
      # if(debug>2) printf "removing edge to %s\n", pair_a[2];
      neighbor_dist[pair_a[2]] = distance;
    } else if (pair_a[2] == obj) {
      # if(debug>2) printf "removing edge to %s\n", pair_a[1];
      neighbor_dist[pair_a[1]] = distance;
    } else {
      # if(debug>2) printf "copying edge %s\n", pair;
      out_graph[pair] = distance;
    }
  }
  for(n1 in neighbor_dist) {
    for(n2 in neighbor_dist) {
      if(n1 < n2) {
        distance = neighbor_dist[n1] + neighbor_dist[n2];
        if ((n1, n2) in out_graph) {
          old_distance = out_graph[n1, n2];
          if(distance < old_distance) {
            # if(debug>2) printf "replacing edge %s = %d < %d\n", n1 SUBSEP n2, distance, old_distance;
            out_graph[n1, n2] = distance;
          } else {
            # if(debug>2) printf "edge %s already exists with distance %d <= %d\n", n1 SUBSEP n2, old_distance, distance;
          }
        } else {
          # if(debug>2) printf "adding edge %s = %d\n", n1 SUBSEP n2, distance;
          out_graph[n1, n2] = distance;
        }
      }
    }
  }
}

function build_graph(      obj, parent, distance) {
  for(obj in g_object_parent) {
    parent = g_object_parent[obj];
    distance = g_object_parent_distance[obj];
    # if(parent == "@") continue;

    set_graph_distance(obj, parent, distance);
  }
#   set_graph_distance(1, 2, 4);
#   set_graph_distance(1, 3, 4);
#   #set_graph_distance(1, 4, 6);
#   #set_graph_distance(1, 5, 6);
#   set_graph_distance(1, 6, 4);
#   set_graph_distance(1, 7, 2);
#   set_graph_distance(2, 3, 2);
#   set_graph_distance(2, 4, 4);
#   set_graph_distance(2, 5, 4);
#   #set_graph_distance(2, 6, 6);
#   set_graph_distance(2, 7, 4);
#   set_graph_distance(3, 4, 4);
#   set_graph_distance(3, 5, 4);
#   #set_graph_distance(3, 6, 6);
#   set_graph_distance(3, 7, 4);
#   set_graph_distance(4, 5, 2);
#   set_graph_distance(4, 6, 4);
#   #set_graph_distance(4, 7, 6);
#   set_graph_distance(5, 6, 4);
#   #set_graph_distance(5, 7, 6);
#   set_graph_distance(6, 7, 4);
}

function print_graph(graph,      obj, pair, pair_a) {
  if(debug>2) printf "graph {\n";
  if(debug>2) printf "  rankdir=\"LR\";\n";
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);
    if(debug>2) printf "  \"%s\" -- \"%s\" [ label = \"%d\" ];\n", pair_a[1], pair_a[2], graph[pair];
  }
  if(debug>2) printf "}\n";
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
    out_neighbors[neighbor_count++] = n_obj SUBSEP graph[pair];
  }
}

function neighbors_by_distance(i1, v1, i2, v2,    a1, a2) {
  split(v1, a1, SUBSEP);
  split(v2, a2, SUBSEP);

  ideal = "afbjgnhdloepcikm";

  if(index(ideal, a1[1]) < index(ideal,a2[1])) {
    return -1;
  } else if(index(ideal, a1[1]) == index(ideal,a2[1])) {
    return 0;
  } else {
    return 1;
  }


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

function optimize(depth, graph, current_object, path, steps, keyset,        prefix, neighbors, n_i, n_obj, n_dist, new_graph, door_opened_graph, neighbor_count, sorted_neighbors, n_a, edgesum, keyset_with_pos) {
  prefix = "["depth"]" substr("                                                                                                                                                                                          ", 1, 1 + depth);
  if(debug>2) printf "%s entering node '%s'\n", prefix, current_object;
  if(debug>2) printf "%s input graph has %d edges\n", prefix, length(graph);

  if (steps >= g_best_steps) {
    if(debug>2) printf "%saborting, %d steps >= best %d\n", prefix, steps, g_best_steps;
    return;
  }

  path = path current_object;
  if(iskey(current_object)) {
    sub(toupper(current_object), current_object, keyset);
  }

  keyset_with_pos = keyset "/" current_object;

  if(debug>1) printf "PATH: %-30s KEYSET: %-30s STEPS:%d\n", path, keyset_with_pos, steps;

  if(keyset_with_pos in g_known_keysets) {
    if(steps < g_known_keysets[keyset_with_pos]) {
      if(debug>2) printf "%snew record for keyset %s: %d steps\n", prefix, keyset_with_pos, steps;
      g_known_keysets[keyset_with_pos] = steps;
      g_known_keysets_path[keyset_with_pos] = path;
    } else {
      if(debug>2) printf "%salready better known for keyset %s: %d <= %d steps (%s)\n", prefix, keyset, g_known_keysets[keyset_with_pos], steps, g_known_keysets_path[keyset_with_pos];
      return;
    }
  } else {
    if(debug>2) printf "%snew keyset %s: %d steps\n", prefix, keyset_with_pos, steps;
    g_known_keysets[keyset_with_pos] = steps;
    g_known_keysets_path[keyset_with_pos] = path;
  }

  if(length(path)>0) {
    if(path in g_known_paths) {
      if(steps < g_known_paths[path]) {
        if(debug>2) printf "%snew record for path %s: %d steps\n", prefix, path, steps;
        g_known_paths[path] = steps;
      } else {
        if(debug>2) printf "%salready better known for path %s: %d <= %d steps\n", prefix, path, g_known_paths[path], steps;
        return;
      }
    } else {
      if(debug>2) printf "%snew path %s: %d steps\n", prefix, path, steps;
      g_known_paths[path] = steps;
    }

    if(keyset ~ /^[a-z]+$/) {
      printf "GOT ALL KEYS in %d steps\n", steps;
      if (steps < g_best_steps) {
        printf "NEW RECORD %d steps\n", steps;
        g_best_steps = steps;
      }
      return;
    }
  }

  # print_graph(graph);

  delete door_opened_graph;

  if(iskey(current_object)) {
    if(debug>2) printf "%sremoving door for key '%s'\n", prefix, current_object;
    remove_graph_node(graph, toupper(current_object), door_opened_graph);
    if(debug>2) printf "%sdoor opened graph has %d edges\n", prefix, length(door_opened_graph);
  } else {
    copyarray(graph, door_opened_graph);
  }

#   edgesum = 0;
#   for(pair in graph) {
#     edgesum += graph[pair];
#   }
#   if(debug>2) printf "%sedge sum is now %d\n", prefix, edgesum;

  delete neighbors;
  find_neighbors(door_opened_graph, current_object, neighbors);

  if(debug>2) printf "%s removing node '%s' from graph\n", prefix, current_object;
  remove_graph_node(door_opened_graph, current_object, new_graph);
  if(debug>2) printf "%s new graph has %d edges\n", prefix, length(new_graph);

  neighbor_count = asort(neighbors, sorted_neighbors, "neighbors_by_distance");

  if(debug>2) {
    printf "%s neighbors of %s:", prefix, current_object;
    for(n_i=1; n_i<=neighbor_count; n_i++) {
      split(sorted_neighbors[n_i], n_a, SUBSEP);
      n_obj = n_a[1];
      n_dist = n_a[2];
      printf " '%s'(%d)", n_obj, n_dist;
    }
    printf "\n";
  }
  for(n_i=1; n_i<=neighbor_count; n_i++) {
    split(sorted_neighbors[n_i], n_a, SUBSEP);
    n_obj = n_a[1];
    n_dist = n_a[2];
    if(debug>2) printf "%s - '%s' at %d steps\n", prefix, n_obj, n_dist;

    # print_graph(new_graph);
    if(isdoor(n_obj)) {
      if(debug>2) printf "%scannot go through door '%s'\n", prefix, n_obj;
      continue;
    }

    if(depth < 60)
      optimize(depth + 1, new_graph, n_obj, path, steps + n_dist, keyset);
  }

}

function init_keyset(      keyset_a, keyset, i, n, pair) {
  for(pair in g_space) {
    if(iskey(g_space[pair])) {
      keyset_a[pair] = toupper(g_space[pair]);
    }
  }
  n = asort(keyset_a);
  keyset = "";
  for(i=1; i<=n; i++) {
    keyset = keyset keyset_a[i];
  }
  return keyset;
}

END {
  g_ymax = NR - 1;
  scan_maze();
  remove_useless_doors();
  build_graph();
  print_graph(g_graph);
  g_best_steps = 3452;
  delete g_known_paths;
  delete g_known_keysets;
  delete g_known_keysets_path;
  optimize(0, g_graph, "@", "", 0, init_keyset());
  print "Done.";
  close("/dev/stderr");
  if(0) {
    print_space();
    neighbors_by_distance();
  }
}
