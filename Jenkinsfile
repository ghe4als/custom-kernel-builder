pipeline {
    agent any  // Use any available agent (in your case, your local machine)
    
    stages {
        stage('Build Kernel') {
            steps {
                // Run your Docker container directly with shell commands
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
                // Archives the kernel build output if the build is successful
                archiveArtifacts artifacts: 'build_output.txt', onlyIfSuccessful: true
            }
        }
    }
}
