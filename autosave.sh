#!/bin/sh

while true
do
    sleep ${TMOD_AUTOSAVE_INTERVAL}m
    echo "[SYSTEM] Saving world..."
    inject "save"
done