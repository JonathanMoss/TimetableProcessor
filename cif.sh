#!/bin/bash

set -u

./find_sched.sh -h $1 -d -t CREWE > TMP && ./sched_summary.sh