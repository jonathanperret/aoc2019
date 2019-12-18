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
  printf "" >> "/dev/stderr";
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

function create_head(head_pos, head_walked_distance, head_last_object,    new_head_i) {
  new_head_i = length(g_head_pos);
  g_head_pos[new_head_i] = head_pos;
  g_head_last_object[new_head_i] = head_last_object;
  g_head_walked_distance[new_head_i] = head_walked_distance;
  return new_head_i;
}

function advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, visited, again, x, y      , last_object) {
  # printf "Head %d trying to go to %d, %d\n", head_i, x, y;
  if(x < g_xmin || x >= g_xmax || y < g_ymin || y >= g_xmax) {
    # printf "(%d, %d) is out of range\n", x, y;
    return 0;
  }
  if((x, y) in visited) {
    # printf "(%d, %d) is already visited\n", x, y;
    return 0;
  }
  tile = g_space[x, y];
  if(iswall(tile)) {
    # printf "(%d, %d) is wall\n", x, y;
    visited[x, y] = -1;
    return 0;
  }
  if(again) {
    printf "Advancing head %d (%d, %d) in multiple directions!\n", head_i, x, y;
    head_i = create_head(head_pos, head_walked_distance, head_last_object);
    printf "Created new head %d\n", head_i;
  }
  if(tile == ".") {
    printf "Head %d entering free space (%d, %d)\n", head_i, x, y;
    g_head_walked_distance[head_i] = head_walked_distance + 1;
  } else {
    printf "Head %d found object '%s' at (%d, %d) after %d steps\n", head_i, tile, x, y, head_walked_distance + 1;
    g_object_parent[tile] = head_last_object;
    g_object_parent_distance[tile] = head_walked_distance + 1;

    g_head_last_object[head_i] = tile;
    g_head_walked_distance[head_i] = 0;
  }
  g_head_pos[head_i] = x SUBSEP y;
  visited[x, y] = 1;
  return 1;
}

function advance_head(head_i, visited,          xya, xy, x, y, again, head_pos, head_walked_distance, head_last_object) {
  xya = g_head_pos[head_i];
  split(xya, xy, SUBSEP);
  x = xy[1]; y = xy[2];

  # printf "Trying to advance head %d from %d, %d\n", head_i, x, y;

  head_pos = g_head_pos[head_i];
  head_walked_distance = g_head_walked_distance[head_i];
  head_last_object = g_head_last_object[head_i];

  again = 0;
  again += advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, visited, again, x+1, y);
  again += advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, visited, again, x-1, y);
  again += advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, visited, again, x, y+1);
  again += advance_head_to(head_i, head_pos, head_walked_distance, head_last_object, visited, again, x, y-1);

  printf "Did head %d advance ? %d\n", head_i, again;

  return again;
}

function build_graph(     x, y, xya, xy, visited, prev_visited, distance, current_heads, head_i, again, obj) {
  printf "Starting at %d, %d\n", g_startx, g_starty;
  delete visited;
  delete g_head_pos;
  delete g_head_last_object;
  delete g_head_walked_distance;

  visited[g_startx, g_starty] = 1;

  g_head_pos[0] = g_startx SUBSEP g_starty;
  g_head_last_object[0] = "@";
  g_head_walked_distance[0] = 0;
  visited[g_head_pos[0]] = 1;

  distance = 0;
  again = 1;
  while(again) {
    again = 0;
    copyarray(g_head_pos, current_heads);
    for(head_i in current_heads) {
      again += advance_head(head_i, visited);
    }

    printf "Visited %d tiles at distance %d\n", length(visited), distance;
    distance++;
  };
  printf "Found %d objects\n", length(g_object_parent);
}

function print_graph() {
  printf "graph {\n";
  printf "rankdir=\"LR\";\n";
  for(obj in g_object_parent) {
    printf "\"%s\" -- \"%s\" [ label = \"%d\" ];\n", g_object_parent[obj], obj, g_object_parent_distance[obj];
  }
  printf "}\n";
}

function remove_useless_doors(    useless, obj) {
  again = 1;
  while(again) {
    again = 0;
    delete parents;
    delete edges;
    for(obj in g_object_parent) {
      parents[g_object_parent[obj]] = 1;
    }
    for(obj in g_object_parent) {
      if(!(obj in parents)) {
        edges[obj] = 1;
      }
    }
    printf "Found %d edges\n", length(edges);
    for(obj in edges) {
      if(isdoor(obj)) {
        printf "Removing useless door %s\n", obj;
        delete g_object_parent[obj];
        again++;
      }
    }
  }
}

END {
  g_ymax = NR - 1;
  build_graph();
  remove_useless_doors();
  print_graph();
  print "Done.";
  close("/dev/stderr");
}
