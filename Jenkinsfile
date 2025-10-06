pipeline {
  agent any

  environment {
    JFROG_SERVER = "https://cbjfrog.saas-preprod.beescloud.com"
    JFROG_CLI_PATH = "${env.WORKSPACE}/jf"
    SCA_PROJECT_DIR = "${env.WORKSPACE}/test-workflow-ninja"
  }

  stages {
    stage('Install JFrog CLI') {
      steps {
        retry(3) {
          sh '''
            if [ ! -f "$WORKSPACE/jf" ]; then
              echo ":package: Downloading JFrog CLI from install-cli.jfrog.io..."
              curl -fL https://install-cli.jfrog.io | sh
              chmod +x jfrog
              mv jfrog jf  # Rename to 'jf' for consistency in pipeline
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

    stage('Debug Directory Contents') {
      steps {
        sh '''
          echo "🔍 Listing contents of SCA project dir:"
          ls -la "${SCA_PROJECT_DIR}"
          echo "🔍 Counting files:"
          find "${SCA_PROJECT_DIR}" | wc -l
        '''
      }
    }

    stage('Run SCA Scan on test-workflow-ninja') {
      steps {
        dir("${env.SCA_PROJECT_DIR}") {
          sh '''
            echo ":wrench: Using portable Go and Node.js..."
            export PATH=$PWD/tools/go/bin:$PWD/tools/node/bin:$PATH

            echo ":mag: Running SCA scan..."
            ../jf audit . --sca --format sarif > ../jfrog-sarif-sca-results.sarif || true
          '''
        }
      }
    }

    stage('Display SARIF Output') {
      steps {
        sh 'cat jfrog-sarif-sca-results.sarif || echo "No SARIF output found."'
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'jfrog-sarif-sca-results.sarif', fingerprint: true
    }
  }
}
