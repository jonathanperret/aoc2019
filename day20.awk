#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"
@include "graph"

BEGIN {
  ENVIRON["LANG"] = "C";
  printf "" >> "/dev/stderr";
  FPAT = ".";
  g_letterCount = 0;
  delete g_letters;
  delete g_space;
  delete g_graph;
  delete g_portalStarts;
  delete g_objpos;

  g_xmin = 1;
  g_ymin = 1;
}

function parse(     i, labelname, labelpos) {
  for (i=1; i<=NF; i++) {
    if ($i ~ /[A-Z]/) {
      g_letterCount++;
      g_letters[i, NR] = $i;

      if((i-1, NR) in g_letters) {
        labelpos = (i-1) SUBSEP NR;
        labelname = g_letters[i-1, NR] $i;
        if(!(labelname ~ /AA|ZZ/)) { if(!(labelname in g_portalStarts)) { g_portalStarts[labelname] = labelpos; } }
        if((i-2,NR) in g_space && g_space[i-2,NR] == ".") { g_space[i-2,NR] = labelname; } else { g_space[i+1,NR] = labelname; }
      }
      if((i, NR-1) in g_letters) {
        labelpos = i SUBSEP (NR-1);
        labelname = g_letters[i, NR-1] $i;
        if(!(labelname ~ /AA|ZZ/)) { if(!(labelname in g_portalStarts)) { g_portalStarts[labelname] = labelpos; } }
        if((i,NR-2) in g_space && g_space[i,NR-2] == ".") { g_space[i,NR-2] = labelname; } else { g_space[i,NR+1] = labelname; }
      }
      g_space[i, NR] = " ";
    } else {
      if(!((i,NR) in g_space)) g_space[i, NR] = $i;
    }
  }
}

function adjust_portals(     x, y) {
  for(y=g_ymin; y<=g_ymax; y++) {
    for(x=g_xmin; x<=g_xmax; x++) {
      if(g_space[x,y] ~ /[A-Z]/ && !( g_space[x,y] ~ /AA|ZZ/ )) {
        if((x-g_xmin) < 5 || (y-g_ymin) < 5 || (g_xmax-x) < 5 || (g_ymax-y) < 5) {
          g_space[x,y] = g_space[x,y] "o";
        } else {
          g_space[x,y] = g_space[x,y] "i";
        }
      }
    }
  }
}

{
  parse();
}

function print_space(     x, y, h) {
  print "SPACE:" >> "/dev/stderr";
  for(y=g_ymin; y<=g_ymax; y++) {
    for(x=g_xmin; x<=g_xmax; x++) {
      printf "%-3s", substr(g_space[x, y]g_space[x,y]g_space[x,y], 1, 3) >> "/dev/stderr";
    }
    printf "\n" >> "/dev/stderr";
  }
}

function iswalkable(x, y) {
  if(!((x,y) in g_space)) return 0;
  return g_space[x,y] == "." || g_space[x,y] ~ /[A-Z]/;
}

function make_obj(x, y) {
  return g_space[x, y] == "." ? "." x "_" y : g_space[x, y];
}

function add_close_neighbor(graph, from_object, to_object) {
  set_graph_distance(graph, from_object, to_object, 1);
}

function scan_maze(     x, y, nx, ny, obj) {
  for(y=0; y<=g_ymax; y++) {
    for(x=0; x<=g_xmax; x++) {
      if(iswalkable(x, y)) {
        # printf "Creating edges from (%d,%d)\n", x, y >> "/dev/stderr";
        obj = make_obj(x, y);
        g_objpos[obj] = x/10 "," (g_ymax-y)/10;

        nx = x+1; ny = y  ; if(iswalkable(nx, ny)) add_close_neighbor(g_graph, obj, make_obj(nx, ny));
        nx = x  ; ny = y+1; if(iswalkable(nx, ny)) add_close_neighbor(g_graph, obj, make_obj(nx, ny));
      }
    }
  }
}

function print_graph_with_pos(graph,      obj, pair, pair_a, objects) {
  printf "graph {\n" >> "/dev/stderr";
  printf "  rankdir=\"LR\";\n" >> "/dev/stderr";
  list_graph_objects(graph, objects);
  for(obj in objects) {
    printf "  \"%s\" [ pos = \"%s!\" ];\n", obj, g_objpos[obj] >> "/dev/stderr";
  }
  for(pair in graph) {
    split(pair, pair_a, SUBSEP);
    printf "  \"%s\" -- \"%s\" [ label = \"%d\" ];\n", pair_a[1], pair_a[2], graph[pair] >> "/dev/stderr";
  }
  printf "}\n" >> "/dev/stderr";
  fflush();
}

END {
  g_xmax = NF;
  g_ymax = NR;
  adjust_portals();
  print_space();
  scan_maze();
  printf "found %d portals\n", length(g_portalStarts) >> "/dev/stderr";
  printf "found %d edges\n", length(g_graph) >> "/dev/stderr";
  remove_useless_nodes(g_graph);
  printf "found %d edges\n", length(g_graph) >> "/dev/stderr";
  savearray(g_graph, "day20graph.txt");
  print_graph_with_pos(g_graph);
  close("/dev/stderr");
  if(0) {
  }
}
