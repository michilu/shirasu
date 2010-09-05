EBIN_DIR := ebin
SRC_DIR := src
EXAMPLES_DIR := examples
INCLUDE_DIR := include
ERLC := erlc
ERLC_FLAGS := -W -I $(INCLUDE_DIR) -o $(EBIN_DIR)


all: misultin erlang-rfc4627
	(cd misultin; $(MAKE))
	(cd erlang-rfc4627; $(MAKE))

clean:
	(cd misultin; $(MAKE) clean)
	(cd erlang-rfc4627; $(MAKE) clean)

del:
	(rm -rf misultin)
	(rm -rf erlang-rfc4627)

update: misultin erlang-rfc4627
	(cd misultin; git pull)
	(cd erlang-rfc4627; git pull)

misultin:
	(git clone http://github.com/ostinelli/misultin.git)

erlang-rfc4627:
	(git clone http://github.com/tonyg/erlang-rfc4627.git)

