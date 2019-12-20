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
        if(!(labelname in g_portalStarts)) { g_portalStarts[labelname] = labelpos; labelname = labelname "1"; } else { labelname = labelname "2"; }
        if((i-2,NR) in g_space && g_space[i-2,NR] == ".") { g_space[i-2,NR] = labelname; } else { g_space[i+1,NR] = labelname; }
      }
      if((i, NR-1) in g_letters) {
        labelpos = i SUBSEP (NR-1);
        labelname = g_letters[i, NR-1] $i;
        if(!(labelname in g_portalStarts)) { g_portalStarts[labelname] = labelpos; labelname = labelname "1"; } else { labelname = labelname "2"; }
        if((i,NR-2) in g_space && g_space[i,NR-2] == ".") { g_space[i,NR-2] = labelname; } else { g_space[i,NR+1] = labelname; }
      }
      g_space[i, NR] = " ";
    } else {
      if(!((i,NR) in g_space)) g_space[i, NR] = $i;
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

        nx = x+1; ny = y  ; if(iswalkable(nx, ny)) add_close_neighbor(g_graph, obj, make_obj(nx, ny));
        nx = x  ; ny = y+1; if(iswalkable(nx, ny)) add_close_neighbor(g_graph, obj, make_obj(nx, ny));
      }
    }
  }
}

function add_portals(     label) {
  for(label in g_portalStarts) {
    if(label != "AA" && label != "ZZ") {
      add_close_neighbor(g_graph, label "1", label "2");
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
    remove_graph_node_inplace(graph, obj);
  }
}

END {
  g_xmax = NF;
  g_ymax = NR;
  print_space();
  scan_maze();
  printf "found %d edges\n", length(g_graph) >> "/dev/stderr";
  remove_useless_nodes(g_graph);
  printf "found %d edges\n", length(g_graph) >> "/dev/stderr";
  add_portals();
  remove_corridors(g_graph);
  print_graph(g_graph);
  savearray(g_graph, "day20graph.txt");
  close("/dev/stderr");
  if(0) {
  }
}
