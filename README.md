# Steps to hack on the kernel!

# Get a ubuntu machine, recommneding ubuntu:20.04

# 0. Setup build env & Download this repo
`./setup.sh`
`git clone https://github.com/thefallentree/hack-bpf.git"`


# 1. Download linxu source code
`./checkout.sh`

# 2. Build linux image
`./build.sh`

# 3. Run the kernel through QEMU
`run.sh`
