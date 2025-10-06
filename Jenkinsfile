pipeline {
    agent any

    environment {
        PYTHON_URL = "https://github.com/indygreg/python-build-standalone/releases/download/20240107/cpython-3.11.7+20240107-x86_64-unknown-linux-gnu-install_only.tar.gz"
        PYTHON_DIR = "${env.WORKSPACE}/python"
        VENV_DIR = "${env.WORKSPACE}/venv"
        CHECKOV_REPORT = "checkov-report.sarif"
        CHECKOV_TARGET_FILE = "${env.WORKSPACE}/minimain.tf"  
        CHECKOV_DISABLE_GUIDE = "true"
        BC_API_KEY = ""
        PRISMA_API_URL = ""
    }

    stages {
        // Step 1: Download and set up prebuilt Python binary
        stage('Download Prebuilt Python') {
            steps {
                echo ":arrow_down: Downloading prebuilt Python binary..."
                sh '''
                    mkdir -p $PYTHON_DIR
                    cd $PYTHON_DIR
                    curl -L -o python.tar.gz $PYTHON_URL
                    tar -xzf python.tar.gz --strip-components=1
                    echo ":white_check_mark: Python extracted to: $PYTHON_DIR"
                '''
            }
        }

        // Step 2: Verify Python & Pip installation
        stage('Verify Python & Pip') {
            steps {
                sh '''
                    $PYTHON_DIR/bin/python3.11 --version
                    $PYTHON_DIR/bin/pip3.11 --version
                '''
            }
        }

        // Step 3: Create Virtual Environment for Pipenv
        stage('Create Virtual Environment') {
            steps {
                echo "🐍 Creating virtual environment if missing..."
                sh '''
                    if [ ! -d "$VENV_DIR" ]; then
                        $PYTHON_DIR/bin/python3.11 -m venv "$VENV_DIR"
                    else
                        echo "✅ Virtualenv already exists."
                    fi
                '''
            }
        }

        // Step 4: Install Pipenv if missing
        stage('Install Pipenv if Missing') {
            steps {
                echo "📦 Installing Pipenv if missing..."
                sh '''
                    source "$VENV_DIR/bin/activate"
                    if ! pip show pipenv > /dev/null 2>&1; then
                        pip install pipenv
                    else
                        echo "✅ Pipenv already installed."
                    fi
                '''
            }
        }

        // Step 5: Install Checkov via Pipenv
        stage('Install Checkov via Pipenv') {
            steps {
                echo "📦 Installing Checkov using Pipenv..."
                sh '''
                    source "$VENV_DIR/bin/activate"
                    pip install certifi
                    pipenv install checkov
                    echo "✅ Checkov and certifi installed."
                '''
            }
        }

        // Step 6: Run Checkov Scan
        stage('Run Checkov Scan') {
            steps {
                echo "🚨 Running Checkov scan in SARIF mode..."
                sh '''
                    source "$VENV_DIR/bin/activate"
                    export SSL_CERT_FILE=$(python -m certifi)
                    # Run Checkov on the specific file ($CHECKOV_TARGET_FILE)
                    pipenv run checkov -f "$CHECKOV_TARGET_FILE" -o sarif || true
                '''
            }
        }

        // Step 7: Display SARIF Report
        stage('Display SARIF Report') {
            steps {
                echo "📄 Displaying SARIF report:"
                sh '''
                    echo "=== Checkov SARIF Report (First 20 lines) ==="
                    head -n 20 "results.sarif"
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: "results.sarif", fingerprint: true
        }
    }
}