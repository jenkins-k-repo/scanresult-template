pipeline {
    agent any

    environment {
        SONAR_HOST = "https://sonarqube.saas-preprod.beescloud.com"
        PROJECT_KEY = "sarif__bash_test_${env.BUILD_NUMBER}"
        SCANNER_VERSION = "5.0.1.3006"
        SCANNER_HOME = "${WORKSPACE}/sonar-scanner-5.0.1.3006"
        JAVA_HOME = "${WORKSPACE}/jdk17"
        PATH = "${WORKSPACE}/jdk17/bin:${PATH}"
        jq = "${WORKSPACE}/bin/jq"
    }

    stages {
        stage('Install JDK') {
            steps {
                sh '''
                  echo "Downloading JDK..."
                  curl -sLo openjdk.tar.gz https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.14%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.14_7.tar.gz
                  tar -xzf openjdk.tar.gz
                  rm -rf jdk17 && mv jdk-17* jdk17
                  mkdir -p ${WORKSPACE}/bin
                  if [ ! -f ${WORKSPACE}/bin/jq ]; then
                      echo "Downloading jq..."
                      curl -sLo ${WORKSPACE}/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
                      chmod +x ${WORKSPACE}/bin/jq
                  fi
                '''
            }
        }

        stage('Install SonarScanner CLI') {
            steps {
                sh """
                  if [ ! -d "sonar-scanner-${SCANNER_VERSION}-linux" ]; then
                    echo "Downloading Sonar Scanner CLI..."
                    curl -sLo scanner-sq.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SCANNER_VERSION}.zip
                    jar -xf scanner-sq.zip
                    rm scanner-sq.zip
                  else
                    echo "SonarScanner already installed."
                  fi
                """
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonarqube-preprod-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        chmod +x ${SCANNER_HOME}/bin/sonar-scanner
                        ${SCANNER_HOME}/bin/sonar-scanner \
                          -Dsonar.projectKey=$PROJECT_KEY \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=$SONAR_HOST \
                          -Dsonar.login=$SONAR_TOKEN
                    """
                }
            }
        }

        stage('Wait for Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonarqube-preprod-token', variable: 'SONAR_TOKEN')]) {
                    script {
                        def reportTask = readFile '.scannerwork/report-task.txt'
                        def ceTaskUrl = reportTask.readLines()
                            .find { it.startsWith("ceTaskUrl=") }
                            .replace("ceTaskUrl=", "")

                        echo "Waiting for SonarQube CE task to complete: ${ceTaskUrl}"

                        timeout(time: 5, unit: 'MINUTES') {
                            waitUntil {
                                def result = sh(
                                    script: "curl -s -u ${SONAR_TOKEN}: ${ceTaskUrl} | $jq -r '.task.status'",
                                    returnStdout: true
                                ).trim()
                                echo "SonarQube CE task status: ${result}"
                                return (result == "SUCCESS")
                            }
                        }
                    }
                }
            }
        }

        stage('Generate SARIF') {
            steps {
                withCredentials([string(credentialsId: 'sonarqube-preprod-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        chmod +x ./sonar_to_sariff.sh
                        ./sonar_to_sariff.sh get_sarif_output \
                        "$SONAR_HOST" \
                        "$SONAR_TOKEN" \
                        "$PROJECT_KEY" \
                        "$WORKSPACE" \
                        "$SCANNER_VERSION" > sonar.sarif.json
                    '''
                }
            }
        }

        stage('Archive SARIF Artifact') {
            steps {
                archiveArtifacts artifacts: 'sonar.sarif.json', fingerprint: true
            }
        }
    }
}
