pipeline {
  agent any

  environment {
    JFROG_USERNAME = credentials('jfrog-cli-credentials')
    IMAGE_TAR = "${env.WORKSPACE}/image.tar"
    JFROG_SERVER = "https://cbjfrog.saas-preprod.beescloud.com"
    JFROG_CLI_PATH = "${env.WORKSPACE}/jf"
  }

  stages {
    stage('Install JFrog CLI') {
      steps {
        sh '''
          if [ ! -f "$WORKSPACE/jf" ]; then
              echo ":package: Downloading JFrog CLI to workspace..."
              curl -fL https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/latest/jfrog-cli-linux-amd64/jf -o jf
              chmod +x jf
          fi
          ./jf --version
        '''
      }
    }

    stage('Configure JFrog CLI') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'jfrog-cli-credentials',
          usernameVariable: 'JF_USER',
          passwordVariable: 'JF_PASS'
        )]) {
          sh '''
            echo ":key: Configuring JFrog CLI with provided credentials..."
            ./jf config add cbjfrog-server \
              --url=${JFROG_SERVER} \
              --user=$JF_USER \
              --password=$JF_PASS \
              --interactive=false
          '''
        }
      }
    }

    stage('Scan Image with JFrog CLI') {
      steps {
        sh '''
          echo ":mag: Scanning image.tar using JFrog CLI..."
          ./jf scan "${IMAGE_TAR}" --format=sarif > jfrog-sarif-results.sarif || true
        '''
      }
    }

    stage('Display SARIF Output') {
      steps {
        sh 'cat jfrog-sarif-results.sarif'
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'jfrog-sarif-results.sarif', fingerprint: true
    }
  }
}
