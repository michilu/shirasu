REPO		?= shirasu
SHIRASU_TAG	 = $(shell git describe --tags)
REVISION	?= $(shell echo $(SHIRASU_TAG) | sed -e 's/^$(REPO)-//')
PKG_VERSION	?= $(shell echo $(REVISION) | tr - .)

PREFIX:=../
DEST:=$(PREFIX)$(PROJECT)

REBAR=./rebar

.PHONY: rel deps

all: deps compile
	@cd rel/files/sample ; $(MAKE)

compile:
	@$(REBAR) compile

deps:
	@$(REBAR) get-deps

clean:
	@$(REBAR) clean

distclean: clean relclean ballclean
	@$(REBAR) delete-deps

test:
	@rm -rf .eunit
	@mkdir -p .eunit
	@$(REBAR) skip_deps=true eunit

##
## Release targets
##
rel: deps
	./rebar compile generate

rel4fedora:
	@mkdir -p deps
	./rebar -C package/rpm/rebar.config compile generate

relclean:
	rm -rf rel/shirasu

build_plt:
	@$(REBAR) build-plt

dialyzer:
	@$(REBAR) dialyze

app:
	@$(REBAR) create template=mochiwebapp dest=$(DEST) appid=$(PROJECT)

xref:
	@$(REBAR) xref

eunit:
	@$(REBAR) eunit

info:
	@$(REBAR) list-deps

edoc:
	@$(REBAR) doc

serve:
	(cd priv; ./start.sh)

debug:
	($(MAKE))
	(erl -pa $$PWD/ebin deps/*/ebin -boot start_sasl -config debug +W w -s shirasu -shirasu setting \"debug_setting.yaml\")

# Release tarball creation
# Generates a tarball that includes all the deps sources so no checkouts are necessary
archivegit = git archive --format=tar --prefix=$(1)/ HEAD | (cd $(2) && tar xf -)
archivehg = hg archive $(2)/$(1)
archive = if [ -d ".git" ]; then \
		$(call archivegit,$(1),$(2)); \
	    else \
		$(call archivehg,$(1),$(2)); \
	    fi

buildtar = mkdir distdir && \
		 git clone . distdir/shirasu-clone && \
		 cd distdir/shirasu-clone && \
		 git checkout $(SHIRASU_TAG) && \
		 $(call archive,$(SHIRASU_TAG),..) && \
		 mkdir ../$(SHIRASU_TAG)/deps && \
		 make deps; \
		 for dep in deps/*; do \
                     cd $${dep} && \
                     $(call archive,$${dep},../../../$(SHIRASU_TAG)) && \
                     mkdir -p ../../../$(SHIRASU_TAG)/$${dep}/priv && \
                     git rev-list --max-count=1 HEAD > ../../../$(SHIRASU_TAG)/$${dep}/priv/git.vsn && \
                     cd ../..; done

distdir:
	$(if $(SHIRASU_TAG), $(call buildtar), $(error "You can't generate a release tarball from a non-tagged revision. Run 'git checkout <tag>', then 'make dist'"))

dist $(SHIRASU_TAG).tar.gz: distdir
	cd distdir; \
	tar czf ../$(SHIRASU_TAG).tar.gz $(SHIRASU_TAG)

buildtar4f = mkdir distdir && \
		 git clone . distdir/shirasu-clone && \
		 cd distdir/shirasu-clone && \
		 git checkout $(SHIRASU_TAG) && \
		 $(call archive,$(SHIRASU_TAG),..)

distdir4f:
	$(if $(SHIRASU_TAG), $(call buildtar4f), $(error "You can't generate a release tarball from a non-tagged revision. Run 'git checkout <tag>', then 'make dist'"))

dist4fedora $(SHIRASU_TAG).tar.gz: distdir4f
	cd distdir; \
	tar czf ../$(SHIRASU_TAG).tar.gz $(SHIRASU_TAG)

ballclean:
	rm -rf $(SHIRASU_TAG).tar.gz distdir

package: dist
	$(MAKE) -C package package

pkgclean:
	$(MAKE) -C package pkgclean

.PHONY: package
export PKG_VERSION REPO REVISION SHIRASU_TAG
