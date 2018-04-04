PYTHON=python2.7

OCAMLBUILD = ocamlbuild -tag safe_string -I ocaml -cflag -g

NTARJAN = ocaml/ntarjan.ml ocaml/ntarjan.mli

default: graph.native

graph.native: $(NTARJAN) ocaml/graph.ml
	$(OCAMLBUILD) graph.native

$(NTARJAN):
	+$(MAKE) -C ../.. extraction/tarjan/$@

clean:
	$(OCAMLBUILD) -clean

.PHONY: default clean

.NOTPARALLEL: $(NTARJAN)
