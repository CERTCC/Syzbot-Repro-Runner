#!/bin/bash

input="./bug_id_list.txt"

tmux new-session -d -s repros

while IFS= read -r line
do
    tmux new-window -d -t repros -n "$line" "./launch_docker.sh $line"
done < "$input"
