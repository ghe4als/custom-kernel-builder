#!/bin/bash
set -e  # Exit on error

# Print commands as they are executed
set -x

# Variables
KERNEL_VERSION="5.15.112"  # Choose your kernel version
OUTPUT_LOG="build_output.txt"
JOBS=$(nproc || echo "2")  # Number of parallel jobs

# Create log file
echo "Starting kernel build at $(date)" > $OUTPUT_LOG

# Update package lists and install dependencies
apt-get update >> $OUTPUT_LOG 2>&1
apt-get install -y build-essential libncurses-dev gawk flex bison openssl libssl-dev dkms \
                  libelf-dev libudev-dev libpci-dev libiberty-dev autoconf wget >> $OUTPUT_LOG 2>&1

# Download kernel to a temporary directory
echo "Downloading Linux kernel source..." | tee -a $OUTPUT_LOG
mkdir -p /tmp/kernel-build
cd /tmp/kernel-build
wget -q https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz || \
  { echo "Failed to download kernel source"; exit 1; }

# Extract kernel source with no-same-owner option
echo "Extracting kernel source..." | tee -a $OUTPUT_LOG
tar --no-same-owner -xf linux-${KERNEL_VERSION}.tar.xz
cd linux-${KERNEL_VERSION}

# Create a base configuration
echo "Creating base kernel configuration..." | tee -a $OUTPUT_LOG
make defconfig >> $OUTPUT_LOG 2>&1

# Build kernel with cleaner progress updates
echo "Building kernel (this will take a while)..." | tee -a $OUTPUT_LOG

# Run make in the background and capture its PID
make -j${JOBS} >> $OUTPUT_LOG 2>&1 &
MAKE_PID=$!

# Monitor progress in the foreground
echo "Starting progress monitor..."
while kill -0 $MAKE_PID 2>/dev/null; do
    # Count object files every 5 minutes
    FILES_COUNT=$(find . -name "*.o" | wc -l)
    echo "$(date): Build in progress - ${FILES_COUNT} files compiled so far" | tee -a /kernel/build_progress.log
    sleep 300
done

# Check if make completed successfully
wait $MAKE_PID
MAKE_EXIT=$?
if [ $MAKE_EXIT -ne 0 ]; then
    echo "Kernel build failed with exit code $MAKE_EXIT" | tee -a $OUTPUT_LOG
    exit $MAKE_EXIT
fi

# Build modules
echo "Building kernel modules..." | tee -a $OUTPUT_LOG
make modules -j${JOBS} >> $OUTPUT_LOG 2>&1

echo "Kernel build completed at $(date)" | tee -a $OUTPUT_LOG

# List key output files
echo "Build artifacts:" | tee -a $OUTPUT_LOG
find arch/x86/boot -name "bzImage" | tee -a $OUTPUT_LOG

# Copy build log to the mounted volume
cp $OUTPUT_LOG /kernel/

# Copy the kernel if successfully built
cp arch/x86/boot/bzImage /kernel/bzImage
if [ $? -ne 0 ]; then
    echo "Failed to copy kernel image" | tee -a $OUTPUT_LOG
    exit 1
fi
echo "Kernel image copied to /kernel/bzImage" | tee -a $OUTPUT_LOG

# End of script
echo "Kernel build script completed successfully" | tee -a $OUTPUT_LOG
echo "Build log saved to $OUTPUT_LOG"
exit 0
