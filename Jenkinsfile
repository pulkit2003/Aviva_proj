pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('1️⃣ Checkout Code') {
            steps {
                echo "📦 Fetching source code from GitHub..."
                checkout scm
            }
        }

        stage('2️⃣ Deploy Infra (Terraform)') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "🚀 Initializing Terraform..."
                        terraform init -input=false

                        echo "🔍 Validating Terraform..."
                        terraform validate

                        echo "🏗️  Applying Terraform..."
                        terraform apply -auto-approve -input=false -compact-warnings
                    '''
                }
            }
        }

        stage('3️⃣ Upload File to S3 via EC2') {
            steps {
                sshagent (credentials: ['ec2-ssh']) {   // your SSH credential ID
                    sh '''
                        set -e
                        cd terraform

                        # Read Terraform outputs
                        EC2_IP=$(terraform output -raw ec2_public_ip)
                        BUCKET=$(terraform output -raw bucket_name)

                        echo "📌 EC2: $EC2_IP | S3 Bucket: $BUCKET"

                        echo "⏳ Waiting 60 seconds for EC2 SSH to be ready..."
                        sleep 60

                        echo "🔐 Installing AWS CLI on EC2 (if missing)..."
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP '
                            if ! command -v aws >/dev/null 2>&1; then
                                sudo snap install aws-cli --classic > /dev/null
                                echo "✔ AWS CLI installed"
                            else
                                echo "✔ AWS CLI already present"
                            fi
                        '

                        echo "📝 Creating demo file on EC2..."
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP \
                            "echo 'Hello from Jenkins 🚀' > ~/demo.txt"

                        echo "☁ Uploading file from EC2 to S3..."
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP \
                            "aws s3 cp ~/demo.txt s3://$BUCKET/demo.txt > /dev/null"

                        echo "🎉 Upload successful! File: s3://$BUCKET/demo.txt"
                    '''
                }
            }
        }

        stage('4️⃣ Output Summary') {
            steps {
                dir('terraform') {
                    sh '''
                        echo ""
                        echo "📢 Final Terraform Outputs:"
                        terraform output
                        echo ""
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully – infra created and file uploaded to S3."
        }
        failure {
            echo "❌ Pipeline failed – check the logs for the failing stage."
        }
    }
}
