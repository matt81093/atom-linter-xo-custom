#!/bin/sh

has_linter() {
	${NPM_SCRIPT_PATH} ls --parseable --dev --depth=0 "$1" 2> /dev/null | grep -q "$1$"
}

if has_linter "coffeelint"; then
	if [ -d ./lib ]; then
		echo "Linting package using coffeelint..."
		./node_modules/.bin/coffeelint lib
		rc=$?; if [ $rc -ne 0 ]; then exit $rc; fi
	fi
	if [ -d ./spec ]; then
		echo "Linting package specs using coffeelint..."
		./node_modules/.bin/coffeelint spec
		rc=$?; if [ $rc -ne 0 ]; then exit $rc; fi
	fi
fi

if has_linter "eslint"; then
	if [ -d ./lib ]; then
		echo "Linting package using eslint..."
		./node_modules/.bin/eslint lib
		rc=$?; if [ $rc -ne 0 ]; then exit $rc; fi
	fi
	if [ -d ./spec ]; then
		echo "Linting package specs using eslint..."
		./node_modules/.bin/eslint spec
		rc=$?; if [ $rc -ne 0 ]; then exit $rc; fi
	fi
fi

if has_linter "standard"; then
	if [ -d ./lib ]; then
		echo "Linting package using standard..."
		./node_modules/.bin/standard "lib/**/*.js"
		rc=$?; if [ $rc -ne 0 ]; then exit $rc; fi
	fi
	if [ -d ./spec ]; then
		echo "Linting package specs using standard..."
		./node_modules/.bin/standard "spec/**/*.js"
		rc=$?; if [ $rc -ne 0 ]; then exit $rc; fi
	fi
	if [ -d ./test ]; then
		echo "Linting package tests using standard..."
		./node_modules/.bin/standard "test/**/*.js"
		rc=$?; if [ $rc -ne 0 ]; then exit $rc; fi
	fi
fi

if [ -d ./spec ]; then
	echo "Running specs..."
	"${ATOM_SCRIPT_PATH}" --test spec
elif [ -d ./test ]; then
	echo "Running specs..."
	"${ATOM_SCRIPT_PATH}" --test test
else
	echo "Missing spec folder! Please consider adding a test suite in './spec' or in './test'"
	exit 0
fi
