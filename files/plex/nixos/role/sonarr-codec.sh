#!/usr/bin/env bash

set -euo pipefail

if [ "${sonarr_eventtype}" == "Download" ]; then
    PLEX_UNSUPPORTED_CODECS="av1"
    MEDIA_CODEC=$(
        ffprobe \
            -v error \
            -select_streams v:0 \
            -show_entries stream=codec_name \
            -of default=nokey=1:noprint_wrappers=1 \
            "${sonarr_episodefile_path}"
    )

    for CODEC in ${PLEX_UNSUPPORTED_CODECS}; do
        if [ "${CODEC}" == "${MEDIA_CODEC}" ]; then
            UNSUPPORTED_CODEC=1
            break
        fi
    done

    if [ "${UNSUPPORTED_CODEC}" == "1" ]; then
        FILENAME=$(basename "${sonarr_episodefile_path}")
        FILEDIR=$(dirname "${sonarr_episodefile_path}")
        TMPFILE="${FILEDIR}/tmp-${FILENAME}"
        echo "ffmpeg \
            -threads 1 \
            -i '${sonarr_episodefile_path}' \
            -c:v libx264 \
            -crf 18 '${TMPFILE}' && \
            mv -f '${TMPFILE}' '${sonarr_episodefile_path}'" | \
            batch
    fi
fi
if [ "${sonarr_eventtype}" == "Test" ]; then
    exit 0
fi
