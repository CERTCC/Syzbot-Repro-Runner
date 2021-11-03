#!/bin/bash

tmux new-session -d -s syzkaller 'boot_syzkaller'
tmux split-window -h 'ssh_syzkaller'
tmux attach-session -t syzkaller