pipeline {
    agent any
    
    stages {
        stage('Build Kernel') {
            steps {
                sh '''
                docker run --rm --privileged \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  -v ${WORKSPACE}:/kernel \
                  -w /kernel \
                  custom-kernel-builder:latest \
                  bash -c "./build_kernel.sh"
                
                # Monitor the build
                echo "Build started, monitoring progress..."
                while docker ps | grep kernel-builder > /dev/null; do
                    echo "$(date): Build still running..."
                    docker exec kernel-builder bash -c "cd /tmp/kernel-build/linux-* && echo 'Current files:' && find . -name '*.o' | wc -l"
                    sleep 300
                done
                '''
            }
        }
        
        stage('Archive Output') {
            steps {
                archiveArtifacts artifacts: 'build_output.txt, bzImage', onlyIfSuccessful: true
            }
        }

        stage('Boot Kernel with QEMU') {
            steps {
                timeout(time: 30, unit: 'SECONDS') {
                    sh '''
                    echo "Booting custom kernel with QEMU..."

                    qemu-system-x86_64 \
                    -kernel bzImage \
                    -nographic \
                    -append "console=ttyS0" \
                    -no-reboot \
                    -m 512M > qemu_output.log 2>&1 &

                    BOOT_PID=$!

                    echo "Waiting for kernel to boot..."

                    sleep 10

                    # Check for successful kernel boot
                    if grep -q "Linux version" qemu_output.log; then
                        echo "Kernel boot successful:"
                        grep "Linux version" qemu_output.log
                    else
                        echo "Kernel boot failed or didn't start correctly:"
                        cat qemu_output.log
                        kill $BOOT_PID || true
                        exit 1
                    fi

                    kill $BOOT_PID || true
                    '''
                }
            }
        }
    }
}
