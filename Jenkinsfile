pipeline {
    agent any

    stages {
        stage('Trivy Scan') {
            steps {
                sh '''
                if ! command -v trivy > /dev/null; then
                  echo "Installing Trivy..."
                  curl -sL https://github.com/aquasecurity/trivy/releases/download/v0.65.0/trivy_0.65.0_Linux-64bit.tar.gz | tar zxvf - -C /tmp
                  mv /tmp/trivy ./trivy
                  chmod +x ./trivy
                fi

                # Run Trivy scan and save SARIF report
                ./trivy fs . --format sarif --output trivy-results.sarif || true
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-results.sarif', fingerprint: true
        }
    }
}
