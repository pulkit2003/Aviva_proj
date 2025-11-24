pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('1️⃣ Checkout Code') {
            steps {
                echo "📦 Fetching source code..."
                checkout scm
            }
        }

        stage('2️⃣ Deploy Infra (Terraform)') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "🚀 Initializing Terraform..."
                        terraform init -input=false > /dev/null

                        echo "🔍 Validating Terraform..."
                        terraform validate > /dev/null

                        echo "🏗️  Applying Terraform (quiet mode)..."
                        terraform apply -auto-approve -input=false -compact-warnings
                    '''
                }
            }
        }

        stage('3️⃣ Upload File to S3 via EC2') {
            steps {
                sshagent (credentials: ['ec2-ssh']) {
                    sh '''
                        set -e
                        cd terraform

                        EC2_IP=$(terraform output -raw ec2_public_ip)
                        BUCKET=$(terraform output -raw bucket_name)

                        echo "📌 EC2: $EC2_IP | S3 Bucket: $BUCKET"

                        echo "🔐 Installing AWS CLI (if missing)..."
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP '
                            if ! command -v aws >/dev/null 2>&1; then
                                sudo snap install aws-cli --classic > /dev/null
                                echo "✔ AWS CLI installed"
                            else
                                echo "✔ AWS CLI already present"
                            fi
                        '

                        echo "📝 Creating demo file..."
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP \
                            "echo 'Hello from Jenkins 🚀' > ~/demo.txt"

                        echo "☁ Uploading to S3..."
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
                        echo "📢 Final Outputs:"
                        terraform output
                        echo ""
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline Completed Successfully!"
        }
        failure {
            echo "❌ Pipeline Failed — Check Logs."
        }
    }
}
