#!/bin/bash
# FujiRuro-OS Yazi Wrapper
# Ensures Sixel graphics work correctly in foot.

export TERM=foot
/usr/local/bin/yazi "$@"
