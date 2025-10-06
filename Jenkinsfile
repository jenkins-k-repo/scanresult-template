@Library('sonar-sarif-tool@main') _
pipeline {
    agent any

    environment {
        SONAR_HOST = "https://sonarqube.saas-preprod.beescloud.com"
        SONAR_TOKEN = credentials('sonarqube-preprod-token') 
        PROJECT_KEY = "sarif_test_${env.BUILD_NUMBER}"
        SCANNER_VERSION = "5.0.1.3006"
        SCANNER_HOME = "${WORKSPACE}/sonar-scanner-5.0.1.3006"
        JAVA_HOME = "${WORKSPACE}/jdk17"
        PATH = "${WORKSPACE}/jdk17/bin:${PATH}"
        JQ = "${WORKSPACE}/bin/jq"
        SARIF_FILE = "sonar-report.sarif"
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
                    SCANNER_VERSION=5.0.1.3006
                    SCANNER_HOME=sonar-scanner-${SCANNER_VERSION}-linux

                    if [ ! -d "${SCANNER_HOME}" ]; then
                    echo "Downloading Sonar Scanner CLI..."
                    curl -sLo scanner-sq.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006.zip
                    # Use it
                    jar -xf scanner-sq.zip
                    rm scanner-sq.zip
                    else
                    echo "SonarScanner already installed."
                    fi
                """
            }
        }

        stage('Get user token') {
            steps {
                script {
                    // Try generating a fresh token
                    def response = sh(
                        script: """curl -s -u ${SONAR_TOKEN}: \
                        -X POST "${SONAR_HOST}/api/user_tokens/generate?name=${PROJECT_KEY}" """,
                        returnStdout: true
                    ).trim()

                    echo "Raw API response: ${response}"

                    def user_token = sh(
                        script: """echo '${response}' | ${JQ} -r '.token // empty'""",
                        returnStdout: true
                    ).trim()

                    if (user_token) {
                        echo "✅ Generated user token: ${user_token}"
                        env.USER_TOKEN = user_token
                    } else {
                        echo "⚠️ Token not returned. Likely it already exists with name ${PROJECT_KEY}"
                        echo "ℹ️ SonarQube does NOT return existing tokens, only metadata."
                    }
                }
            }
        }



        // stage('Get user token') {
        //     steps {
        //         script {
        //             def user_token = sh(script: "curl -X POST -s -u ${SONAR_TOKEN}: ${SONAR_HOST}/api/user_tokens/generate?name=${PROJECT_KEY} | ${JQ} -r '.token'", returnStdout: true)
        //             echo "Generated user token: ${user_token}"
        //         }
        //     }
        // }


        stage('SonarQube Analysis') {
            steps {
                sh """
                    chmod +x ${SCANNER_HOME}/bin/sonar-scanner
                    ${SCANNER_HOME}/bin/sonar-scanner \
                      -Dsonar.projectKey=$PROJECT_KEY \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=$SONAR_HOST \
                      -Dsonar.login=$USER_TOKEN
                """
            }
        }

        stage('Wait for Analysis') {
            steps {
                script {
                    def reportTask = readFile '.scannerwork/report-task.txt'
                    def ceTaskUrl = reportTask.readLines()
                        .find { it.startsWith("ceTaskUrl=") }
                        .replace("ceTaskUrl=", "")

                    echo "Waiting for SonarQube CE task to complete: ${ceTaskUrl}"

                    timeout(time: 5, unit: 'MINUTES') {
                        waitUntil {
                            def result = sh(
                                script: "curl -s -u ${SONAR_TOKEN}: ${ceTaskUrl} | ${JQ} -r '.task.status'",
                                returnStdout: true
                            ).trim()
                            echo "SonarQube CE task status: ${result}"
                            return (result == "SUCCESS")
                        }
                    }
                }
            }
        }

        stage('Generate sarif and archive') {
          steps {
            script {
                echo "===== Library Function ====="
                def workspacePath = env.WORKSPACE

                // Get the SARIF content
                def sarifContent = helper.getSarifOutput(env.SONAR_HOST, env.SONAR_TOKEN, env.PROJECT_KEY, workspacePath, SCANNER_VERSION)

                // Write the SARIF content to a .sarif file
                writeFile file: "${workspacePath}/${env.SARIF_FILE}", text: sarifContent
                echo "File written to: ${workspacePath}/${env.SARIF_FILE}"  // Debug print

                // Archive the SARIF file
                archiveArtifacts artifacts: "${env.SARIF_FILE}", fingerprint: true
            }
        }

      }
    }
}