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
  printf "" >> "/dev/stderr";
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

function iswalkable(x, y) {
  return ((x,y) in g_space) && !iswall(g_space[x,y]);
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
  return s == "." || s ~ /^[(0-9*]/;
}

function print_space(     x, y, h) {
  print "SPACE:";
  for(y=0; y<=g_ymax; y++) {
    for(x=0; x<=g_xmax; x++) {
      printf "%s", substr(g_space[x,y], 1, 1);
    }
    printf "\n";
  }
}

function make_obj(x, y) {
  return g_space[x, y] == "." ? "*" x "_" y : g_space[x, y];
}

function mark_starts(    i) {
  for(i in g_start_pos) {
    g_space[g_start_pos[i]] = "@"i;
  }
}

function scan_maze(     x, y, nx, ny, obj) {
  for(y=0; y<=g_ymax; y++) {
    for(x=0; x<=g_xmax; x++) {
      if(iswalkable(x, y)) {
        printf "Creating edges from (%d,%d)\n", x, y;
        obj = make_obj(x, y);
        nx = x+1; ny = y  ; if(iswalkable(nx, ny)) set_graph_distance(g_graph, obj, make_obj(nx, ny), 1);
        nx = x-1; ny = y  ; if(iswalkable(nx, ny)) set_graph_distance(g_graph, obj, make_obj(nx, ny), 1);
        nx = x  ; ny = y+1; if(iswalkable(nx, ny)) set_graph_distance(g_graph, obj, make_obj(nx, ny), 1);
        nx = x  ; ny = y-1; if(iswalkable(nx, ny)) set_graph_distance(g_graph, obj, make_obj(nx, ny), 1);
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

function remove_graph_node_inplace(graph, obj,         pair, pair_a, neighbor_dist, distance, n1, n2, old_distance, edgestoremove) {
  delete neighbor_dist;
  delete edgestoremove;
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);
    distance = graph[pair];
    if (pair_a[1] == obj) {
      # if(debug>2) printf "removing edge to %s\n", pair_a[2];
      neighbor_dist[pair_a[2]] = distance;
    } else if (pair_a[2] == obj) {
      # if(debug>2) printf "removing edge to %s\n", pair_a[1];
      neighbor_dist[pair_a[1]] = distance;
    } else {
      # if(debug>2) printf "keeping edge %s\n", pair;
      continue;
    }
    edgestoremove[pair] = 1;
  }
  for(pair in edgestoremove) {
    delete graph[pair];
  }
  for(n1 in neighbor_dist) {
    for(n2 in neighbor_dist) {
      if(n1 < n2) {
        distance = neighbor_dist[n1] + neighbor_dist[n2];
        if ((n1, n2) in graph) {
          old_distance = graph[n1, n2];
          if(distance < old_distance) {
            # if(debug>2) printf "replacing edge %s = %d < %d\n", n1 SUBSEP n2, distance, old_distance;
            graph[n1, n2] = distance;
          } else {
            # if(debug>2) printf "edge %s already exists with distance %d <= %d\n", n1 SUBSEP n2, old_distance, distance;
          }
        } else {
          # if(debug>2) printf "adding edge %s = %d\n", n1 SUBSEP n2, distance;
          graph[n1, n2] = distance;
        }
      }
    }
  }
}

function print_graph(graph,      obj, pair, pair_a) {
  printf "graph {\n";
  printf "  rankdir=\"LR\";\n";
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);
    printf "  \"%s\" -- \"%s\" [ label = \"%d\" ];\n", pair_a[1], pair_a[2], graph[pair];
  }
  printf "}\n";
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

function move_bot_to_object(depth, graph, bot_pos, bot_i, to_object, path, steps, keyset,        prefix, door_opened_graph, i, new_bot_pos) {
  prefix = "["depth"]" substr("                                                                                                                                                                                          ", 1, 1 + depth);
  if(debug>2) printf "%sbot %d entering node '%s'\n", prefix, bot_i, to_object;

  if (steps >= g_best_steps) {
    if(debug>2) printf "%saborting, %d steps >= best %d\n", prefix, steps, g_best_steps;
    return;
  }

  path = path to_object;
  g_tested_path_count++;

  copyarray(bot_pos, new_bot_pos);
  new_bot_pos[bot_i] = to_object;

  if(iskey(to_object)) {
    sub(toupper(to_object), to_object, keyset);
  }

  sub(/\/.*/, "", keyset);
  for(i = 0; i < length(new_bot_pos); i++) {
    keyset = keyset "/" new_bot_pos[i];
  }

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
    if (steps < g_best_steps) {
      printf "NEW RECORD %d steps\n", steps;
      g_best_path = path;
      g_best_steps = steps;
    }
    return;
  }

  if(iskey(to_object)) {
    if(debug>2) printf "%sremoving door for key '%s'\n", prefix, to_object;
    remove_graph_node(graph, toupper(to_object), door_opened_graph);
    if(debug>2) printf "%sdoor opened graph has %d edges\n", prefix, length(door_opened_graph);
  } else {
    copyarray(graph, door_opened_graph);
  }

  if (debug>3) print_graph(door_opened_graph);

  move_bots(depth, door_opened_graph, new_bot_pos, path, steps, keyset);
}

function move_bot_from_object(depth, graph, bot_pos, bot_i, path, steps, keyset,          prefix, from_object, n_i, n_obj, n_dist, new_graph, neighbors, neighbor_count, sorted_neighbors, n_a) {
  prefix = "["depth"]" substr("                                                                                                                                                                                          ", 1, 1 + depth);

  from_object = bot_pos[bot_i];

  if(debug>2) printf "%sbot %d moving from %s\n", prefix, bot_i, from_object;

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

    move_bot_to_object(depth + 1, new_graph, bot_pos, bot_i, n_obj, path, steps + n_dist, keyset);
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

function remove_useless_nodes(graph,     pair, pair_a, obj, objects) {
  delete objects;
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);

    if(isblank(pair_a[1])) { objects[pair_a[1]] = 1; }
    if(isblank(pair_a[2])) { objects[pair_a[2]] = 1; }
  }
  for(obj in objects) {
    if(debug>1) printf "Removing %s\n", obj;
    remove_graph_node_inplace(graph, obj);
  }
}

function remove_useless_doors(graph,      pair, pair_a, edgecounts, again, obj, tmp_graph) {
  again = 1;
  while(again) {
    again = 0;
    delete edgecounts;
    for(pair in graph) {
      split(pair, pair_a, SUBSEP);

      if(isdoor(pair_a[1])) { if (pair_a[1] in edgecounts) edgecounts[pair_a[1]]++; else edgecounts[pair_a[1]] = 1; }
      if(isdoor(pair_a[2])) { if (pair_a[2] in edgecounts) edgecounts[pair_a[2]]++; else edgecounts[pair_a[2]] = 1; }
    }
    for(obj in edgecounts) {
      if(edgecounts[obj] == 1) {
        if(debug>1) printf "Removing door %s\n", obj;
        again = 1;
        remove_graph_node(graph, obj, tmp_graph);
        copyarray(tmp_graph, graph);
      }
    }
  }
}

function move_bots(depth, graph, bot_pos, path, steps, keyset,      i) {
  for(i = 0; i < length(bot_pos); i++) {
    move_bot_from_object(depth, graph, bot_pos, i, path, steps, keyset);
  }
}

function solve(    bot_pos, i) {
  g_tested_path_count = 0;
  g_best_steps = 999999;
  g_best_path = "";
  delete g_known_keysets;
  delete g_known_keysets_path;
  delete bot_pos;

  for(i in g_start_pos) {
    bot_pos[i] = "@"i;
  }
  move_bots(0, g_graph, bot_pos, "", 0, init_keyset());
  printf "BEST PATH IS %s IN %d STEPS (tested %d paths)\n", g_best_path, g_best_steps, g_tested_path_count;
}

END {
  g_ymax = NR - 1;
  if (debug>1) print_space();
  mark_starts();
  scan_maze();
  if (debug>1) print_graph(g_graph);
  remove_useless_nodes(g_graph);
  if (debug>1) print_graph(g_graph);
  remove_useless_doors(g_graph);
  if (debug>1) print_graph(g_graph);
  solve();
  print "Done.";
  close("/dev/stderr");
  if(0) {
    print_space();
    neighbors_by_distance();
  }
}
