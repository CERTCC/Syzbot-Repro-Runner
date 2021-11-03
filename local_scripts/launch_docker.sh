
#!/bin/bash

docker run --privileged -it --name syzbot_repro_$1 syzbot_repro ./run_repro.sh $1