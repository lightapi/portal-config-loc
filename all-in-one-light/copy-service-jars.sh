#!/bin/bash

# Static Variables
SERVICE_ARTIFACT_ID_PREFIX="attribute client group oauth position role rule service user"
SUFFIX_TYPES="-command -query"
GROUP_ID="net/lightapi"
REPO_URL="https://s01.oss.sonatype.org/service/local/repositories/snapshots/content"

for hybrid_type in $SUFFIX_TYPES; do

    SUFFIX=$hybrid_type

    # Loop over the service artifact ids
    for artifact in $SERVICE_ARTIFACT_ID_PREFIX; do

        # Loop Specific Variables
        ARTIFACT_ID="$artifact$SUFFIX"
        METADATA_URL="$REPO_URL/$GROUP_ID/$ARTIFACT_ID/maven-metadata.xml"
        VERSION="NotFound"
        FULL_SNAPSHOT_URL="NotFound"

        echo "Downloading metadata.xml from $METADATA_URL"
        curl -k -s -o metadata.xml $METADATA_URL

        if [ $? -eq 0 ]; then

            # Grab the version number from the metadata.xml file
            versionLine=$(grep -m 1 "<version>" metadata.xml)

            if [ -n "$versionLine" ]; then
                VERSION=$(echo $versionLine | sed -n 's|.*<version>\(.*\)</version>.*|\1|p')
            fi

            SNAPSHOT_METADATA_URL="$REPO_URL/$GROUP_ID/$ARTIFACT_ID/$VERSION/"
            echo "Downloading snapshot_data.xml from $SNAPSHOT_METADATA_URL"
            curl -s -k -o snapshot_data.xml $SNAPSHOT_METADATA_URL

            if [ $? -eq 0 ]; then

                # Grab the snapshot URL from the snapshot_data.xml file
                snapshotLine=$(grep ".jar</resourceURI>" snapshot_data.xml | grep -v "sources.jar\|javadoc.jar")

                if [ -n "$snapshotLine" ]; then
                    FULL_SNAPSHOT_URL=$(echo $snapshotLine | sed -n 's|.*<resourceURI>\(.*\.jar\)</resourceURI>.*|\1|p')
                fi

                echo "Downloading $ARTIFACT_ID-$VERSION.jar from $FULL_SNAPSHOT_URL"
                curl -s -k -o "$ARTIFACT_ID-$VERSION.jar" $FULL_SNAPSHOT_URL

                if [ $? -ne 0 ]; then
                    echo "Failed to download the JAR file."
                    exit 1
                fi

            else
                echo "Failed to download snapshot_data.xml"
                exit 1
            fi

        else
            echo "Failed to download metadata.xml"
            exit 1
        fi

        rm metadata.xml
        rm snapshot_data.xml
    done

    # Move the downloaded JAR files to the correct directory.
    files=$(ls *.jar)
    if [ "$SUFFIX" == "-command" ]; then
        for file in $files; do
            mv $file ./hybrid-command/service
        done
    else
        for file in $files; do
            mv $file ./hybrid-query/service
        done
    fi
done