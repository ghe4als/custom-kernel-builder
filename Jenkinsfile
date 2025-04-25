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
    }
}
