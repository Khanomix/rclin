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

if [ -z "${CONFIG_BASE64}" ] || [ -z "${CONFIG_URL}" ]; then
    echo "Rclone config found"
    CONFIG_BASE64='W25pbWxlZWNoXQp0eXBlID0gZHJvcGJveAp0b2tlbiA9IHsiYWNjZXNzX3Rva2VuIjoic2wuQjlDQTlFVGZxMzF3VjhyMDlQQ2tuTUlmN3NET3VkUFQ4LUxoNEhuU2pjVGtUa0xqRGliODlQaWxPMWN6b0dRZmR0U3BpY2VtUkRSQ2xhLW4tTE9IVjJHUHBEc0lzdDRsa2VRdzVnb0tldHVwT3NyRGJtWng1NlFMWl9NU3VWM2FKS3Q1ZmFHbjllaXpuT3MiLCJ0b2tlbl90eXBlIjoiYmVhcmVyIiwicmVmcmVzaF90b2tlbiI6IkFaSnpzM1Z4eVdzQUFBQUFBQUFBQWJFZ3FKZEVOTU10a3BVSERfWTJMYzhMNGdXWFp1M0IwRDBsdUJJQi05bFIiLCJleHBpcnkiOiIyMDI0LTA5LTE2VDE5OjE5OjExLjQ5Nzg4NTIrMDM6MzAifQoKW25pbWxlZWNoMl0KdHlwZSA9IGRyb3Bib3gKdG9rZW4gPSB7ImFjY2Vzc190b2tlbiI6InNsLkItNHd6dFNwdkdaZ0tVNVVfeWVsNXZqVE1ySTcwWU91di10U0ViSDJQMmNtamVzZ1cyS09iM1h0SmNXUnBSdGxSYnVyS09vb3FpaHZ6aVkxNmtEOFFkR0p4OEZ2T1Z6aGFfQ0YyY0JrdXd1ZDRZU1AwbDFrTUF2RkVSaDdnN3Z4bGpyaGVsV1daQkZVN2MwIiwidG9rZW5fdHlwZSI6ImJlYXJlciIsInJlZnJlc2hfdG9rZW4iOiJQRFZFWjJsSC11RUFBQUFBQUFBQUFkdjlRc3VFdWdtZWtDa3UzSzhTbDlhR3hGUFV2dU9kS2lCdDJ6YWVkdkE5IiwiZXhwaXJ5IjoiMjAyNC0xMC0xNlQyMTowNzoyMC4yNDg1MDM2KzAzOjMwIn0KCltuaW1fZHJdCnR5cGUgPSBkcm9wYm94CnRva2VuID0geyJhY2Nlc3NfdG9rZW4iOiJzbC5CN0tjRE16U1Ribl8zWmJvNGtyOXFQbEZhOFlKaWZRSTdWVEFMOFhacXZZMmx0aW5qVTZwRlp3OEZkTzdzRWxudDBHNFJvdkdjOVZLVUc2NUtKWVZRSnVKUTdoT1pwRXlwbm1tbm0tZHI0bjV0ZmZKOUY4NzJuck5kQzNxazM1QzhrT2lKTEphc2pLNkZYZyIsInRva2VuX3R5cGUiOiJiZWFyZXIiLCJyZWZyZXNoX3Rva2VuIjoiNUFUZ2l3azJkWThBQUFBQUFBQUFBU1dBbWs1bE5KN1Breld6aGVEWmd2NFY4U0I5VFNlMHI1ejhNenpkZEFNeCIsImV4cGlyeSI6IjIwMjQtMDgtMTdUMTg6Mjg6MzkuNDU4OTQ0MSswMzozMCJ9'
    CONFIG_URL='https://gist.githubusercontent.com/Khanomix/38febd6b077826ffef8b24225fff1372/raw/rccn'
    if [ -n "${CONFIG_BASE64}" ]; then
        echo "${CONFIG_BASE64}" | base64 -d > rclone.conf
        echo "Base64-encoded config is used"
    elif [ -n "${CONFIG_URL}" ]; then
        curl "${CONFIG_URL}" > rclone.conf
        echo "Gist link config is used"
        
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
