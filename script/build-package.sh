#!/bin/sh

# ATOM_CHANNEL="${ATOM_CHANNEL:=stable}"
if [ "${ATOM_CHANNEL}" ]; then
	ATOM_CHANNEL="${ATOM_CHANNEL}"
else
	ATOM_CHANNEL="${ATOM_CHANNEL:=stable}"
fi

if [ "${ATOM_LINT_WITH_BUNDLED_NODE}" ]; then
	ATOM_LINT_WITH_BUNDLED_NODE="true"
else
	ATOM_LINT_WITH_BUNDLED_NODE="false"
fi

if [ "${TRAVIS_OS_NAME}" = "osx" ]; then
	SYSTEMOS="osx"
elif [ "${TRAVIS_OS_NAME}" = "linux" ]; then
	SYSTEMOS="linux"
elif [ "${TRAVIS_OS_NAME}" = "windows" ]; then
	echo "Windows builds are not yet supported"
	exit 255
elif [ "${CIRCLECI}" = "true" ]; then
	if ["${CIRCLE_BUILD_IMAGE}" = "osx"]; then
		SYSTEMOS="circleosx"
	elif ["${CIRCLE_BUILD_IMAGE}" = "linux"]; then
		SYSTEMOS="circlelinux"
	else
		echo "Unknown CI environment, exiting"
		exit 255
	fi
else
	echo "Unknown CI environment, exiting"
	exit 255
fi

echo "Downloading latest Atom release on the ${ATOM_CHANNEL} channel..."
case "${SYSTEMOS}" in
	"osx")
		curl -s -L "https://atom.io/download/mac?channel=${ATOM_CHANNEL}" \
		-H 'Accept: application/octet-stream' \
		-o "atom.zip"
		mkdir atom
		unzip -q atom.zip -d atom
		if [ "${ATOM_CHANNEL}" = "stable" ]; then
			export ATOM_APP_NAME="Atom.app"
			export ATOM_SCRIPT_NAME="atom.sh"
			export ATOM_SCRIPT_PATH="./atom/${ATOM_APP_NAME}/Contents/Resources/app/atom.sh"
		else
			export ATOM_APP_NAME="Atom ${ATOM_CHANNEL}.app"
			export ATOM_SCRIPT_NAME="atom-${ATOM_CHANNEL}"
			export ATOM_SCRIPT_PATH="./atom-${ATOM_CHANNEL}"
			ln -s "./atom/${ATOM_APP_NAME}/Contents/Resources/app/atom.sh" "${ATOM_SCRIPT_PATH}"
		fi
		export ATOM_PATH="./atom"
		export APM_SCRIPT_PATH="./atom/${ATOM_APP_NAME}/Contents/Resources/app/apm/node_modules/.bin/apm"
		export NPM_SCRIPT_PATH="./atom/${ATOM_APP_NAME}/Contents/Resources/app/apm/node_modules/.bin/npm"
		export PATH="${PATH}:${TRAVIS_BUILD_DIR}/atom/${ATOM_APP_NAME}/Contents/Resources/app/apm/node_modules/.bin"
		;;
	"linux")
		curl -s -L "https://atom.io/download/deb?channel=${ATOM_CHANNEL}" \
		-H 'Accept: application/octet-stream' \
		-o "atom-amd64.deb"
		/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -ac -screen 0 1280x1024x16
		export DISPLAY=":99"
		dpkg-deb -x atom-amd64.deb "${HOME}/atom"
		if [ "${ATOM_CHANNEL}" = "stable" ]; then
			export ATOM_SCRIPT_NAME="atom"
			export APM_SCRIPT_NAME="apm"
		else
			export ATOM_SCRIPT_NAME="atom-${ATOM_CHANNEL}"
			export APM_SCRIPT_NAME="apm-${ATOM_CHANNEL}"
		fi
		export ATOM_SCRIPT_PATH="${HOME}/atom/usr/bin/${ATOM_SCRIPT_NAME}"
		export APM_SCRIPT_PATH="${HOME}/atom/usr/bin/${APM_SCRIPT_NAME}"
		export NPM_SCRIPT_PATH="${HOME}/atom/usr/share/${ATOM_SCRIPT_NAME}/resources/app/apm/node_modules/.bin/npm"
		export PATH="${PATH}:${HOME}/atom/usr/bin"
	"windows")
		echo "Windows not yet supported"
		exit 255
		;;
	"circleosx")
		curl -s -L "https://atom.io/download/mac?channel=${ATOM_CHANNEL}" \
		-H 'Accept: application/octet-stream' \
		-o "atom.zip"
		mkdir -p /tmp/atom
		unzip -q atom.zip -d /tmp/atom
		if [ "${ATOM_CHANNEL}" = "stable" ]; then
			export ATOM_APP_NAME="Atom.app"
			export ATOM_SCRIPT_NAME="atom.sh"
			export ATOM_SCRIPT_PATH="/tmp/atom/${ATOM_APP_NAME}/Contents/Resources/app/atom.sh"
		else
			export ATOM_APP_NAME="Atom ${ATOM_CHANNEL}.app"
			export ATOM_SCRIPT_NAME="atom-${ATOM_CHANNEL}"
			export ATOM_SCRIPT_PATH="/tmp/atom-${ATOM_CHANNEL}"
			ln -s "/tmp/atom/${ATOM_APP_NAME}/Contents/Resources/app/atom.sh" "${ATOM_SCRIPT_PATH}"
		fi
		export ATOM_PATH="/tmp/atom"
		export APM_SCRIPT_PATH="/tmp/atom/${ATOM_APP_NAME}/Contents/Resources/app/apm/node_modules/.bin/apm"
		export NPM_SCRIPT_PATH="/tmp/atom/${ATOM_APP_NAME}/Contents/Resources/app/apm/node_modules/.bin/npm"
		export PATH="${PATH}:${TRAVIS_BUILD_DIR}/atom/${ATOM_APP_NAME}/Contents/Resources/app/apm/node_modules/.bin"

		# Clear screen saver
		osascript -e 'tell application "System Events" to keystroke "x"'
		;;
	"circlelinux")
		# Assume the build is on a Debian based image (Circle CI provided Linux images)
		curl -s -L "https://atom.io/download/deb?channel=${ATOM_CHANNEL}" \
		-H 'Accept: application/octet-stream' \
		-o "atom-amd64.deb"
		sudo dpkg --install atom-amd64.deb || true
		sudo apt-get update
		sudo apt-get --fix-broken --assume-yes --quiet install
		if [ "${ATOM_CHANNEL}" = "stable" ] || [ "${ATOM_CHANNEL}" = "dev" ]; then
			export ATOM_SCRIPT_PATH="atom"
			export APM_SCRIPT_PATH="apm"
		else
			export ATOM_SCRIPT_PATH="atom-${ATOM_CHANNEL}"
			export APM_SCRIPT_PATH="apm-${ATOM_CHANNEL}"
		fi
		export NPM_SCRIPT_PATH="/usr/share/atom/resources/app/apm/node_modules/.bin/npm"
		;;
	*)
		echo "Unknown CI environment, exiting!"
		exit 255
		;;
esac

echo "Using Atom version:"
"${ATOM_SCRIPT_PATH}" -v
echo "Using APM version:"
"${APM_SCRIPT_PATH}" -v

echo "Downloading package dependencies..."

if [ "${ATOM_LINT_WITH_BUNDLED_NODE}" = "true" ]; then
	echo "Building for development..."
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
	echo "Building for production..."
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
	# echo "Installing xo..."
	# npm install xo
	# echo "and remaining dependencies..."
	npm install
	# echo "Upgrading packages to latest"
	# apm upgrade --confirm false
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