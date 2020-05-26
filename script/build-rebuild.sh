#!/bin/sh
#"${APM_SCRIPT_PATH}" ci

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
