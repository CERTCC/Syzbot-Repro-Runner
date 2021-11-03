# Syzbot Repro Runner

This tool is used to automate reproducing a crash reported by Syzbot.  
It consists of a containerized linux build environment and a set of scripts to automate building and running the kernel and C reproducers

## Usage

### Setup

**Generate the VM filesystem image**

The following command will create a default Debian stretch image used by the Dockerfile.
The `create-image.sh` script is based on the `create-image.sh` from the syzbot project.

```bash
cd ./bootstrap_img && ./create-image.sh
``` 

**Build the build environment docker container**

```bash
docker build -t syzbot_repro .
```

### Running a reproducer

The following command will run a container and build the kernel and reproducer for the target `<syzbot_id>`

```bash
docker run --privileged -it syzbot_repro ./run_repro.sh <syzbot_id>
```

*Example*
```bash
docker run --privileged -it syzbot_repro ./run_repro.sh 
```

---

## Components

### Dockerfile
The Dockerfile specifies a container with all the necessary tools and libraries for building a linux kernel and running a syzbot reproducer with QEMU.

### syzbot_scraper
The syzbot_scraper is a simple Python Scrapy based webscraper to pull down and parse the various reproducer files and kernel config files for building an affected kernel and reproducer

### crashers/build_crashers.sh
This script will compile the reproducer C files retrieved from the syzbot report.

### run_repro.sh
The run_repro.sh script is executed inside the docker container and 
- invokes the scraper to retrieve the syzbot data
- "shallow clones" the linux kernel at the affected commit
- builds the linux kernel
- compiles the reproducer
- boots the affected kernel with QEMU
- runs the compiled reproducer in the kernel

### local_scripts
This is a couple of scripts to automate running multiple containers for a list of syzbot bug ids.

---

## Gotchas

### Kernel forks
Currently the `run_repro.sh` script has the `linux-next` tree hardcoded as the target kernel repo.
Syzbot runs syzkaller against several other forks as well.

This information can be parsed from the syzbot report data, but has not been implemented yet.
Instead, it will take some manual verification that the target syzbot report is for the correct fork.
Or the `run_repro.sh` can be modified to target the desired fork.

### C Reproducers
The syzbot report will need to have a C reproducer included. Currently the scraper doesn't have a check for that automatically.

### "Shallow Clone"
`run_repro.sh` uses a bit of a hack to avoid cloning the entire kernel tree - since it appears the kernel.org server does not support any `uploadpack.allow{*}SHA1InWant` options.
This relies on the fact that syzbot is using commit id's with an associated reference. If this assumption is not true, then this workaround will break.