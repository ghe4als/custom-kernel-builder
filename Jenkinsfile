pipeline {
    agent any
    
    stages {
        stage('Build Kernel') {
            steps {
                sh '''
                # Get current user ID
                HOST_UID=$(id -u)
                HOST_GID=$(id -g)
                
                docker run --rm --privileged \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  -v ${WORKSPACE}:/kernel \
                  -w /kernel \
                  --user $HOST_UID:$HOST_GID \
                  custom-kernel-builder:latest \
                  bash -c "./build_kernel.sh"
                '''
            }
        }
        
        stage('Archive Output') {
            steps {
                archiveArtifacts artifacts: 'build_output.txt', onlyIfSuccessful: true
            }
        }
    }
}
