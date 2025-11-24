pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('1. Checkout Code') {
            steps {
                echo "Pulling code from GitHub..."
                checkout scm
            }
        }

        stage('2. Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "Running terraform init..."
                        terraform init

                        echo "Validating configuration..."
                        terraform validate

                        echo "Applying infrastructure..."
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('3. EC2 -> S3 File Upload') {
            steps {
                sshagent (credentials: ['ec2-ssh']) {
                    sh '''
                        set -e
                        cd terraform

                        # Read Terraform outputs
                        EC2_IP=$(terraform output -raw ec2_public_ip)
                        BUCKET_NAME=$(terraform output -raw bucket_name)

                        echo "Using EC2_IP=$EC2_IP"
                        echo "Using BUCKET_NAME=$BUCKET_NAME"

                        # 1) Make sure AWS CLI is installed on the app EC2
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP '
                            if ! command -v aws >/dev/null 2>&1; then
                                echo "AWS CLI not found – installing via snap..."
                                sudo snap install aws-cli --classic
                            else
                                echo "AWS CLI already installed."
                            fi
                        '

                        # 2) Create the demo file on EC2
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP \
                            "echo 'Hello from Jenkins via EC2!' > /home/ubuntu/demo.txt"

                        # 3) Upload the file from EC2 to S3
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP \
                            "aws s3 cp /home/ubuntu/demo.txt s3://$BUCKET_NAME/demo.txt"
                    '''
                }
            }
        }

        stage('4. Show Outputs') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "Terraform Outputs:"
                        terraform output
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline completed – infra up & file uploaded to S3!"
        }
        failure {
            echo "❌ Pipeline failed – check the stage logs above."
        }
    }
}
