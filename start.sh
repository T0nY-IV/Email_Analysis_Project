#!/bin/bash

# Start email_refresher.py in the background
python email_refresher.py &

# Start api.py in the foreground
exec python api.py
