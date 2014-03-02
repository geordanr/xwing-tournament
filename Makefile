.PHONY: test testunit testserver wat

NOW=$(shell date +%s)
CASPERJS_TEST_FLAGS=#--verbose --log-level=debug

test: testunit testserver

testunit:
	mocha --compilers coffee:coffee-script/register --require test/mocha/setup --reporter spec test/mocha

testserver:
	casperjs test $(CASPERJS_TEST_FLAGS) test/casperjs/*.coffee
