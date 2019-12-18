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
  delete g_start_pos;
  g_last_head = 0;
  printf "" >> "/dev/stderr";
  delete g_head_pos;
}

function parse(      x, y) {
  g_xmax = NF - 1;
  y = NR - 1;
  for(x=0; x<NF; x++) {
    ch = $(x + 1);
    if(ch == "@") {
      g_start_pos[length(g_start_pos)] = x SUBSEP y;
    }
    g_space[x, y] = ch;
  }
}

function add_intersections(    x, y, n) {
  n = 0;
  for(y=0; y<=g_ymax; y++) {
    for(x=0; x<=g_xmax; x++) {
      if(g_space[x,y] == "." && cango(x+1,y) + cango(x-1,y) + cango(x,y+1) + cango(x,y-1) >= 3) {
        if(debug>2) printf "Adding intersection at (%d,%d)\n", x, y;
        g_space[x,y] = "(" n++ ")";
      }
    }
  }
}

function cango(x, y) {
  return ((x,y) in g_space) && !iswall(g_space[x,y]) && !isdoor(g_space[x,y]);
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

function isblank(s) {
  return s == "." || s ~ /^[(0-9]/;
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
        printf "%s has multiple parents! %s != %s\n", tile, head_last_object, g_object_parent[tile];
        exit 1;
      }
      if(g_object_parent_distance[tile] != head_walked_distance + 1) {
        printf "%s has multiple distances! %s != %s\n", tile, head_walked_distance + 1, g_object_parent_distance[tile];
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
        printf "%d", heads[x,y] % 10;
      else
        printf "%s", substr(g_space[x,y], 1, 1);
    }
    printf "\n";
  }
}

function scan_maze(     x, y, xya, xy, visited, prev_visited, distance, current_heads, head_i, again, obj, i) {
  delete visited;
  delete g_head_pos;
  delete g_head_last_object;
  delete g_head_walked_distance;
  delete g_head_visited;

  for(i in g_start_pos) {
    g_head_pos[i] = g_start_pos[i];
    g_head_last_object[i] = "@"i;
    g_head_walked_distance[i] = 0;
    g_head_visited[i][g_head_pos[i]] = 1;
    g_space[g_head_pos[i]] = ".";
  }
  g_last_head = length(g_start_pos) - 1;

  distance = 0;
  again = 1;
  while(again) {
    if(debug>3) print_space();
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

function set_graph_distance(graph, obj1, obj2, distance) {
  if(obj1 > obj2) return set_graph_distance(graph, obj2, obj1, distance);
  graph[obj1, obj2] = distance;
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

    set_graph_distance(g_graph, obj, parent, distance);
  }
}

function add_center_shortcuts(graph) {
  set_graph_distance(graph, 1, 4, 2);
  set_graph_distance(graph, 2, 3, 2);
}

function print_graph(graph,      obj, pair, pair_a) {
  printf "graph {\n";
  printf "  rankdir=\"LR\";\n";
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);
    printf "  \"%s\" -- \"%s\" [ label = \"%d\" ];\n", pair_a[1], pair_a[2], graph[pair];
  }
  printf "}\n";
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

function move_to_object(depth, graph, to_object, path, steps, keyset,        prefix, door_opened_graph) {
  prefix = "["depth"]" substr("                                                                                                                                                                                          ", 1, 1 + depth);
  if(debug>2) printf "%sentering node '%s'\n", prefix, to_object;
  if(debug>2) printf "%sinput graph has %d edges\n", prefix, length(graph);

  if (steps >= g_best_steps) {
    if(debug>2) printf "%saborting, %d steps >= best %d\n", prefix, steps, g_best_steps;
    return;
  }

  path = path to_object;

  if(iskey(to_object)) {
    sub(toupper(to_object), to_object, keyset);
  }

  sub(/\/.*/, "", keyset);
  keyset = keyset "/" to_object;

  if(debug>0) printf "PATH: %-30s KEYSET: %-30s STEPS:%d\n", path, keyset, steps;

  if(keyset in g_known_keysets) {
    if(steps < g_known_keysets[keyset]) {
      if(debug>2) printf "%snew record for keyset %s: %d steps\n", prefix, keyset, steps;
      g_known_keysets[keyset] = steps;
      g_known_keysets_path[keyset] = path;
    } else {
      if(debug>2) printf "%salready better known for keyset %s: %d <= %d steps (%s)\n", prefix, keyset, g_known_keysets[keyset], steps, g_known_keysets_path[keyset];
      return;
    }
  } else {
    if(debug>2) printf "%snew keyset %s: %d steps\n", prefix, keyset, steps;
    g_known_keysets[keyset] = steps;
    g_known_keysets_path[keyset] = path;
  }

  if(keyset ~ /^[a-z]+\//) {
    printf "GOT ALL KEYS in %d steps\n", steps;
    if (steps < g_best_steps) {
      printf "NEW RECORD %d steps\n", steps;
      g_best_path = path;
      g_best_steps = steps;
    }
    return;
  }

  delete door_opened_graph;

  if(iskey(to_object)) {
    if(debug>2) printf "%sremoving door for key '%s'\n", prefix, to_object;
    remove_graph_node(graph, toupper(to_object), door_opened_graph);
    if(debug>2) printf "%sdoor opened graph has %d edges\n", prefix, length(door_opened_graph);
  } else {
    copyarray(graph, door_opened_graph);
  }

  if (debug>3) print_graph(door_opened_graph);

  move_from_object(depth, door_opened_graph, to_object, path, steps, keyset);
}

function move_from_object(depth, graph, from_object, path, steps, keyset,          prefix, n_i, n_obj, n_dist, new_graph, neighbors, neighbor_count, sorted_neighbors, n_a) {
  prefix = "["depth"]" substr("                                                                                                                                                                                          ", 1, 1 + depth);

  delete neighbors;
  find_neighbors(graph, from_object, neighbors);

  neighbor_count = asort(neighbors, sorted_neighbors, "neighbors_by_distance");

  if(debug>2) {
    printf "%s neighbors of %s:", prefix, from_object;
    for(n_i=1; n_i<=neighbor_count; n_i++) {
      split(sorted_neighbors[n_i], n_a, SUBSEP);
      n_obj = n_a[1];
      n_dist = n_a[2];
      printf " '%s'(%d)", n_obj, n_dist;
    }
    printf "\n";
  }

  if(debug>2) printf "%s removing node '%s' from graph\n", prefix, from_object;
  remove_graph_node(graph, from_object, new_graph);

  for(n_i=1; n_i<=neighbor_count; n_i++) {
    split(sorted_neighbors[n_i], n_a, SUBSEP);
    n_obj = n_a[1];
    n_dist = n_a[2];
    if(debug>2) printf "%s - '%s' at %d steps\n", prefix, n_obj, n_dist;

    if(isdoor(n_obj)) {
      if(debug>2) printf "%scannot go through door '%s'\n", prefix, n_obj;
      continue;
    }

    if(depth > 60) {
      printf "Stack overflow!\n";
      exit 1;
    }

    move_to_object(depth + 1, new_graph, n_obj, path, steps + n_dist, keyset);
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

function remove_useless_nodes(graph,    edgecounts, again, pair, pair_a, obj, tmp_graph) {
  again = 1;
  while(again) {
    again = 0;
    delete edgecounts;
    for(pair in graph) {
      split(pair, pair_a, SUBSEP);

      if(isblank(pair_a[1])) { if (pair_a[1] in edgecounts) edgecounts[pair_a[1]]++; else edgecounts[pair_a[1]] = 1; }
      if(isblank(pair_a[2])) { if (pair_a[2] in edgecounts) edgecounts[pair_a[2]]++; else edgecounts[pair_a[2]] = 1; }
    }
    for(obj in edgecounts) {
      if(edgecounts[obj] == 2) {
        if(debug>1) printf "Need to remove %s\n", obj;
        again = 1;
        remove_graph_node(graph, obj, tmp_graph);
        copyarray(tmp_graph, graph);
      }
    }
  }
}

function remove_intersections(graph,     pair, pair_a, obj, objects, tmp_graph) {
  delete objects;
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);

    if(isblank(pair_a[1])) { objects[pair_a[1]] = 1; }
    if(isblank(pair_a[2])) { objects[pair_a[2]] = 1; }
  }
  for(obj in objects) {
    if(debug>1) printf "Removing %s\n", obj;
    remove_graph_node(graph, obj, tmp_graph);
    copyarray(tmp_graph, graph);
  }
}

function connect_extra_bots(graph) {
  set_graph_distance(graph, "@0", "@1", 0);
  set_graph_distance(graph, "@0", "@2", 0);
  set_graph_distance(graph, "@0", "@3", 0);
  set_graph_distance(graph, "@1", "@2", 0);
  set_graph_distance(graph, "@1", "@3", 0);
  set_graph_distance(graph, "@2", "@3", 0);
}

END {
  g_ymax = NR - 1;
  add_intersections();
  print_space();
  scan_maze();
  remove_useless_doors();
  build_graph();
  print_graph(g_graph);
  # remove_useless_nodes(g_graph);
  add_center_shortcuts(g_graph);
  remove_intersections(g_graph);
  print_graph(g_graph);
  # connect_extra_bots(g_graph);
  print_graph(g_graph);
  g_best_steps = 992780;
  g_best_path = "";
  delete g_known_keysets;
  delete g_known_keysets_path;
  move_from_object(0, g_graph, "@0", "", 0, init_keyset());
  printf "BEST PATH IS %s IN %d STEPS\n", g_best_path, g_best_steps;
  print "Done.";
  close("/dev/stderr");
  if(0) {
    print_space();
    neighbors_by_distance();
    remove_useless_nodes();
    connect_extra_bots();
  }
}
