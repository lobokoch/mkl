#!/bin/bash
if [ -z $1 ]; then
	echo "Version must be informed, example: bash buil.sh 10.1.0"
	exit 1
fi

echo "Starting build generation..."

echo "Changing version to $1..."
mvn org.eclipse.tycho:tycho-versions-plugin:set-version -DnewVersion=$1

echo "Packing..."
mvn clean package

echo "DONE!"