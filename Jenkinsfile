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
