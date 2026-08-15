#!/bin/bash
if ! systemctl --user is-active hermes-gateway.service >/dev/null 2>&1; then
    echo "$(date) Gateway not active, attempting reset-failed + start"
    systemctl --user reset-failed hermes-gateway.service
    systemctl --user start hermes-gateway.service
    sleep 10
    systemctl --user status hermes-gateway.service --no-pager
fi
