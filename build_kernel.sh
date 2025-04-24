#!/bin/bash
set -e  # Exit on error

# Print commands as they are executed
set -x

# Variables
KERNEL_VERSION="5.15.112"  # Choose your kernel version
OUTPUT_LOG="build_output.txt"
JOBS=$(nproc || echo "4")  # Number of parallel jobs (use available cores)

# Create log file
echo "Starting kernel build at $(date)" > $OUTPUT_LOG

# Update package lists and install dependencies
apt-get update >> $OUTPUT_LOG 2>&1
apt-get install -y build-essential libncurses-dev gawk flex bison openssl libssl-dev dkms \
                  libelf-dev libudev-dev libpci-dev libiberty-dev autoconf >> $OUTPUT_LOG 2>&1

# Download kernel
echo "Downloading Linux kernel source..." | tee -a $OUTPUT_LOG
wget -q https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz || \
  { echo "Failed to download kernel source"; exit 1; }

# Extract kernel source
echo "Extracting kernel source..." | tee -a $OUTPUT_LOG
tar -xf linux-${KERNEL_VERSION}.tar.xz
cd linux-${KERNEL_VERSION}

# Create a base configuration
echo "Creating base kernel configuration..." | tee -a $OUTPUT_LOG
make defconfig >> $OUTPUT_LOG 2>&1

# Optional: Customize kernel config here
# e.g., Enable/disable specific modules, features
# make menuconfig  # Uncomment if you want to manually configure

# Build kernel
echo "Building kernel (this will take a while)..." | tee -a $OUTPUT_LOG
make -j${JOBS} >> $OUTPUT_LOG 2>&1

# Optional: Build modules
echo "Building kernel modules..." | tee -a $OUTPUT_LOG
make modules -j${JOBS} >> $OUTPUT_LOG 2>&1

# Create package (optional)
# make bindeb-pkg -j${JOBS} >> $OUTPUT_LOG 2>&1

echo "Kernel build completed at $(date)" | tee -a $OUTPUT_LOG

# List key output files
echo "Build artifacts:" | tee -a $OUTPUT_LOG
find arch/x86/boot -name "bzImage" | tee -a $OUTPUT_LOG
echo "Build log saved to $OUTPUT_LOG"

# Return to original directory
cd ..

# Copy build log to workspace root to ensure it's archived
cp linux-${KERNEL_VERSION}/$OUTPUT_LOG .

exit 0
