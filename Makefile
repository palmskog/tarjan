TARJANML = extraction/tarjan/ocaml/ntarjan.ml extraction/tarjan/ocaml/ntarjan.mli

all: default

default: Makefile.coq
	$(MAKE) -f Makefile.coq

quick: Makefile.coq
	$(MAKE) -f Makefile.coq quick

install: Makefile.coq
	$(MAKE) -f Makefile.coq install

clean: Makefile.coq
	$(MAKE) -f Makefile.coq cleanall
	rm -f Makefile.coq Makefile.coq.conf

Makefile.coq: _CoqProject
	coq_makefile -f _CoqProject -o Makefile.coq \
	  -extra '$(TARJANML)' \
	    'extraction/tarjan/coq/extract_tarjan.v core/tarjan.vo' \
	    '$$(COQC) $$(COQDEBUG) $$(COQFLAGS) extraction/tarjan/coq/extract_tarjan.v'

$(TARJANML): Makefile.coq
	$(MAKE) -f Makefile.coq $@

.PHONY: all default quick clean
