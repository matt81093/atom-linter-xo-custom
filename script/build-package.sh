#!/bin/sh

echo "Downloading package dependencies..."

if [ "${ATOM_LINT_WITH_BUNDLED_NODE}" = "true" ]; then
	if [ -f "package-lock.json" ]; then
		"${APM_SCRIPT_PATH}" ci
	else
		echo "Warning: package-lock.json not found; running apm install instead of apm ci"
		"${APM_SCRIPT_PATH}" install
		"${APM_SCRIPT_PATH}" clean
	fi

	# Override the PATH to put the Node bundled with APM first
	case "${SYSTEMOS}" in
		"osx")
			export PATH="./atom/${ATOM_APP_NAME}/Contents/Resources/app/apm/bin:${PATH}"
			;;
		"linux")
			export PATH="${HOME}/atom/usr/share/${ATOM_SCRIPT_NAME}/resources/app/apm/bin:${PATH}"
			;;
		"circleosx")
			export PATH="/tmp/atom/${ATOM_APP_NAME}/Contents/Resources/app/apm/bin:${PATH}"
			;;
		"circlelinux")
			# Since CircleCI/Linux is a fully installed environment, we use the system path to apm
			export PATH="/usr/share/atom/resources/app/apm/bin:${PATH}"
			;;
	esac
else
	export NPM_SCRIPT_PATH="npm"
	if [ -f "package-lock.json" ]; then
		"${APM_SCRIPT_PATH}" ci --production
	else
		echo "Warning: package-lock.json not found; running apm install instead of apm ci"
		"${APM_SCRIPT_PATH}" install --production
		"${APM_SCRIPT_PATH}" clean
	fi

	# Use the system NPM to install the devDependencies
	echo "Using Node version:"
	node --version
	echo "Using NPM version:"
	npm --version
	npm install
fi

if [ -n "${APM_TEST_PACKAGES}" ]; then
	echo "Installing atom package dependencies..."
	for pack in ${APM_TEST_PACKAGES}; do
		"${APM_SCRIPT_PATH}" install "${pack}"
	done
fi

# Fix npm node prefix
# nodeVersion = node --version
# npm config delete prefix
# npm config set prefix $NVM_DIR/versions/node/${nodeVersion}
# Recompile packages
# echo "Recompiling from source..."
# npm rebuild --build-from-source

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
exit
