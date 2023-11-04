#!/bin/ash
set -e
cd app/
ls
uvicorn main:app --host 0.0.0.0 --workers 20