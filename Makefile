PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share/bash-centre

install:
	mkdir -p $(DESTDIR)$(BINDIR)
	mkdir -p $(DESTDIR)$(DATADIR)/lib
	mkdir -p $(DESTDIR)$(DATADIR)/examples
	mkdir -p $(DESTDIR)$(DATADIR)/uploads
	cp bash-centre.sh $(DESTDIR)$(DATADIR)/bash-centre.sh
	cp lib/*.sh $(DESTDIR)$(DATADIR)/lib/
	cp examples/*.sh $(DESTDIR)$(DATADIR)/examples/
	cp uploads/.gitkeep $(DESTDIR)$(DATADIR)/uploads/
	printf '#!/usr/bin/env bash\n# bash-centre launcher (installed by Makefile)\nexport BC_DIR="%s"\nexec "%s/bash-centre.sh" "$@"\n' "$(DESTDIR)$(DATADIR)" "$(DESTDIR)$(DATADIR)" > $(DESTDIR)$(BINDIR)/bash-centre
	chmod 755 $(DESTDIR)$(BINDIR)/bash-centre
	chmod 755 $(DESTDIR)$(DATADIR)/bash-centre.sh
	@echo "Installed. Run 'bash-centre' to start."

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/bash-centre
	rm -rf $(DESTDIR)$(DATADIR)
	@echo "Uninstalled."

lint:
	shellcheck bash-centre.sh lib/*.sh examples/*.sh

test:
	@for t in tests/test_*.sh; do \
		echo "Running $$t"; \
		bash "$$t" || exit 1; \
	done

.PHONY: install uninstall lint test
