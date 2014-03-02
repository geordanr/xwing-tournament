.PHONY: test testunit testserver wat

NOW=$(shell date +%s)
#CASPER_LOG_LEVEL=--log-level=debug
#CASPER_VERBOSE=--verbose
CASPERJS_TEST_FLAGS=$(CASPER_VERBOSE) $(CASPER_LOG_LEVEL)

test: testunit testserver

testunit:
	mocha --compilers coffee:coffee-script/register --require test/mocha/setup --reporter spec test/mocha

testserver:
	casperjs test $(CASPERJS_TEST_FLAGS) test/casperjs
