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

echo "Rebuilding packages for correct NodeJS version..."
case "${SYSTEMOS}" in
	"windows")
		npm rebuild
		"${APM_SCRIPT_PATH}"\electron-rebuild.cmd
		;;
	*)
		npm rebuild
		"${APM_SCRIPT_PATH}"/electron-rebuild
		;;
esac
