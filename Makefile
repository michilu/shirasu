EBIN_DIR := ebin
SRC_DIR := src
INCLUDE_DIR := include
ERLC := erlc
ERLC_FLAGS := -W -I $(INCLUDE_DIR) -o $(EBIN_DIR)

all:
	(cd deps; $(MAKE))
	@mkdir -p $(EBIN_DIR)
	$(ERLC) $(ERLC_FLAGS) $(SRC_DIR)/*.erl
	@cp $(SRC_DIR)/shirasu.app $(EBIN_DIR)/.

clean:
	rm -rf ebin/*.beam
	rm -rf ebin/*.app

cleanall:
	($(MAKE) clean)
	(cd deps; $(MAKE) clean)

update:
	(cd deps; $(MAKE) update)

serve:
	(cd priv; ./start.sh)

debug:
	($(MAKE) clean; $(MAKE))
	(erl -pa $$PWD/ebin deps/*/ebin -boot start_sasl -s shirasu -shirasu setting \"priv/mysetting.yaml\")

