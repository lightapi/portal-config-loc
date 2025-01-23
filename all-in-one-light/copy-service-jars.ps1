# Static Variables
$SERVICE_ARTIFACT_ID_PREFIX = "attribute client group oauth position role rule service user"
$SUFFIX_TYPES = "-command -query"
$GROUP_ID = "net/lightapi"
$REPO_URL = "https://s01.oss.sonatype.org/service/local/repositories/snapshots/content"

foreach ($hybrid_type in $SUFFIX_TYPES.Split(" ")) {

    $SUFFIX=$hybrid_type

    # Loop over the service artifact ids
    foreach ($artifact in $SERVICE_ARTIFACT_ID_PREFIX.Split(" ")) {

        # Loop Specific Variables
        $ARTIFACT_ID = "$artifact$SUFFIX"
        $METADATA_URL = "$REPO_URL/$($GROUP_ID -replace '/', '%2F')/$ARTIFACT_ID/maven-metadata.xml"
        $VERSION = "NotFound"
        $FULL_SNAPSHOT_URL = "NotFound"

        Write-Output "Downloading metadata.xml from $METADATA_URL"
        Invoke-WebRequest -Uri $METADATA_URL -OutFile "metadata.xml"

        if ($?) {

            # Grab the version number from the metadata.xml file
            $metadata = Get-Content "metadata.xml"
            $versionLine = $metadata | Select-String -Pattern "<version>" | Select-Object -First 1

            if ($versionLine) {
                $VERSION = $versionLine -replace '.*<version>(.*)</version>.*', '$1'
            }

            $SNAPSHOT_METADATA_URL = "$REPO_URL/$($GROUP_ID -replace '/', '%2F')/$ARTIFACT_ID/$VERSION/"
            Write-Output "Downloading snapshot_data.xml from $SNAPSHOT_METADATA_URL"
            Invoke-WebRequest -Uri $SNAPSHOT_METADATA_URL -OutFile "snapshot_data.xml"

            if ($?) {

                # Grab the snapshot URL from the snapshot_data.xml file
                $snapshotData = Get-Content "snapshot_data.xml"
                $snapshotLine = $snapshotData | Select-String -Pattern ".jar</resourceURI>" | Select-String -NotMatch "sources.jar|javadoc.jar" | Select-Object -First 1

                if ($snapshotLine) {
                    $FULL_SNAPSHOT_URL = $snapshotLine -replace '.*<resourceURI>(.*\.jar)</resourceURI>.*', '$1'
                }

                Write-Output "Downloading $ARTIFACT_ID-$VERSION.jar from $FULL_SNAPSHOT_URL"
                Invoke-WebRequest -Uri $FULL_SNAPSHOT_URL -OutFile "$ARTIFACT_ID-$VERSION.jar"

                if (-Not $?) {
                    Write-Output "Failed to download the JAR file."
                    exit 1
                }

            } else {
                Write-Output "Failed to download snapshot_data.xml"
                exit 1
            }

        } else {
            Write-Output "Failed to download metadata.xml"
            exit 1
        }

        Remove-Item "metadata.xml"
        Remove-Item "snapshot_data.xml"
    }

    # Move the downloaded JAR files to the correct directory.
    $files = Get-ChildItem -Path . -Filter "*.jar"
    if ($SUFFIX -eq "-command") {
        $files | ForEach-Object {
            Move-Item $_.FullName -Destination "./hybrid-command/service"
        }
    } else {
        $files | ForEach-Object {
            Move-Item $_.FullName -Destination "./hybrid-query/service"
        }
    }
}
