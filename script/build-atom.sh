#!/bin/sh

# ATOM_CHANNEL="${ATOM_CHANNEL:=stable}"
if [ "${ATOM_CHANNEL}" = "stable" ]; then
	export ATOM_CHANNEL="${ATOM_CHANNEL}"
else
	export ATOM_CHANNEL="${ATOM_CHANNEL:=stable}"
fi

if [ "${ATOM_LINT_WITH_BUNDLED_NODE}" = "true" ]; then
	export ATOM_LINT_WITH_BUNDLED_NODE="true"
else
	export ATOM_LINT_WITH_BUNDLED_NODE="false"
fi

if [ "${TRAVIS_OS_NAME}" = "osx" ]; then
	export SYSTEMOS="osx"
elif [ "${TRAVIS_OS_NAME}" = "linux" ]; then
	export SYSTEMOS="linux"
elif [ "${TRAVIS_OS_NAME}" = "windows" ]; then
	echo "Windows builds are not yet supported"
	exit 255
elif [ "${CIRCLECI}" = "true" ]; then
	if ["${CIRCLE_BUILD_IMAGE}" = "osx"]; then
		export SYSTEMOS="circleosx"
	elif ["${CIRCLE_BUILD_IMAGE}" = "linux"]; then
		export SYSTEMOS="circlelinux"
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
		;;
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

exit
