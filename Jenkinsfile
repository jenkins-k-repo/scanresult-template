pipeline {
  agent any

  environment {
    IMAGE_TAR = "${env.WORKSPACE}/image.tar"
    JFROG_SERVER = "https://cbjfrog.saas-preprod.beescloud.com"
    JFROG_CLI_PATH = "${env.WORKSPACE}/jf"
  }

  stages {
    stage('Install JFrog CLI') {
      steps {
        retry(3) {
          sh '''
            if [ ! -f "$WORKSPACE/jf" ]; then
              echo ":package: Downloading JFrog CLI..."
              curl -fL https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/latest/jfrog-cli-linux-amd64/jf -o jf
              chmod +x jf
            fi
            ./jf --version
          '''
        }
      }
    }

    stage('Configure JFrog CLI') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'jfrog-cli-credentials',
          usernameVariable: 'JF_USER',
          passwordVariable: 'JF_PASS'
        )]) {
          // Use a unique server ID to avoid conflict if it already exists
          sh '''
            echo ":key: Configuring JFrog CLI with credentials..."
            ./jf config add cbjfrog-server-jenkins \
              --url=${JFROG_SERVER} \
              --user=$JF_USER \
              --password=$JF_PASS \
              --interactive=false || ./jf config use cbjfrog-server-jenkins
          '''
        }
      }
    }

    stage('Scan Image with JFrog CLI') {
      steps {
        sh '''
          echo ":mag: Scanning image using JFrog CLI..."
          ./jf scan "${IMAGE_TAR}" --format=sarif > jfrog-sarif-results.sarif || true
        '''
      }
    }

    stage('Display SARIF Output') {
      steps {
        sh 'cat jfrog-sarif-results.sarif || echo "No SARIF output found."'
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'jfrog-sarif-results.sarif', fingerprint: true
    }
  }
}
