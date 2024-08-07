if command -v rclone &> /dev/null
then
    echo "Rclone executable found (global)"
    RCLONE_COMMAND="rclone"
else
    RCLONE_COMMAND="./rclone"
    if [ ! -f rclone ]; then
        echo "No rclone executable found, installing first (binary)"
        curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
        unzip rclone-current-linux-amd64.zip
        cp rclone-*-linux-amd64/rclone .
        rm -rf rclone-*
        chmod +x rclone
    else
        echo "Rclone executable found (binary)"
    fi
fi

if [ -z "${PORT}" ]; then
    echo "No PORT env var, using 8080 port"
    PORT=8585
else
    echo "PORT env var found, using $PORT port"
fi

if [ -n "${CONFIG_BASE64}" ] || [ -n "${CONFIG_URL}" ]; then
    echo "Rclone config found"

    if [ -n "${CONFIG_BASE64}" ]; then
        echo "${CONFIG_BASE64}" | base64 -d > rclone.conf
        echo "Base64-encoded config is used"
        CONFIG_BASE64=W215eGNsdWI3XQp0eXBlID0gZHJpdmUKY2xpZW50X2lkID0gMjY5NDc3NDcyNzk2LTRqNjdmMm9lcXQ1ajkxYjJzbmZ1MGwyYzA5ZGNrcHFqLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tCmNsaWVudF9zZWNyZXQgPSBHT0NTUFgtaFNremEzZmlyNXVvT0ZfQ1BBVGN0QWpxR3BORwpzY29wZSA9IGRyaXZlCnRva2VuID0geyJhY2Nlc3NfdG9rZW4iOiJ5YTI5LmEwQVhvb0Nnc0UyN093RjI5SGdTd3VZSkJEaHVqM2d2RVZWT3ZJdEV2OWhkUi12STBTUXhQNl9RZVlGZHMzXzRyWEpsSGJPU29qaEdaTWRWMUlrM1FKRnFuWksxYkx3aklvdFRWRUhoclo5ZmN1Zmw0WDhFX3ZIeTRLZzRmMVFWV2pDZXlJeWNtUG5VVUxxUWRqYzJ2WWpLb2NSTndzTE03Tk9NMmlhQ2dZS0FSTVNBUkVTRlFIR1gyTWliN3ZUQmlwUnFjYW5uS2pSWDJoLUxBMDE3MSIsInRva2VuX3R5cGUiOiJCZWFyZXIiLCJyZWZyZXNoX3Rva2VuIjoiMS8vMDlwcXF5RXZiSXl1OENnWUlBUkFBR0FrU053Ri1MOUlyakdLS190empEWW5Id2tFY2hPQ25ZNEZhU2tXVzV6bk9uZHpyTWt1ME9mcWhsdjY5WW1JNmRZbVk1eEhxUUktMlZHQSIsImV4cGlyeSI6IjIwMjQtMDctMDlUMjM6MTY6MDcuNjUzNTU1OSswMzozMCJ9CnRlYW1fZHJpdmUgPQ==
    elif [ -n "${CONFIG_URL}" ]; then
        curl "$CONFIG_URL" > rclone.conf
        echo "Gist link config is used"
        CONFIG_URL=https://gist.githubusercontent.com/Khanomix/38febd6b077826ffef8b24225fff1372/raw/rcconfh
    fi
    
    contents=$(cat rclone.conf)

    if ! echo "$contents" | grep -q "\[combine\]"; then
        remotes=$(echo "$contents" | grep '^\[' | sed 's/\[\(.*\)\]/\1/g')

        upstreams=""
        for remote in $remotes; do
            upstreams+="$remote=$remote: "
        done

        upstreams=${upstreams::-1}

        echo -e "\n\n[combine]\ntype = combine\nupstreams = $upstreams" >> rclone.conf
    fi

else
    echo "No Rclone config URL found, serving blank config"
    touch rclone.conf
    echo -e "[combine]\ntype = alias\nremote = dummy" > rclone.conf
fi

CMD="${RCLONE_COMMAND} serve http combine: --addr=:$PORT --read-only --config rclone.conf"
if [ -n "${USERNAME}" ] && [ -n "${PASSWORD}" ]; then
    CMD="${CMD} --user=\"$USERNAME\" --pass=\"$PASSWORD\""
    echo "Authentication is set"
fi
if [ "${DARK_MODE,,}" = "true" ]; then
    CMD="${CMD} --template=templates/dark.html"
    echo "Template is set to dark"
else
    echo "Template is set to light"
fi

echo "Running rclone index"
eval $CMD
