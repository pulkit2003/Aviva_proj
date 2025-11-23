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
                        set -e

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
                sshagent (credentials: ['ec2-ssh']) {   // Jenkins SSH credential ID
                    sh '''
                        set -e
                        cd terraform

                        # Read Terraform outputs
                        EC2_IP=$(terraform output -raw ec2_public_ip)
                        BUCKET_NAME=$(terraform output -raw bucket_name)

                        echo "Using EC2_IP=$EC2_IP"
                        echo "Using BUCKET_NAME=$BUCKET_NAME"

                        # SSH into EC2: create file, install awscli, upload to S3
                        ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP <<EOF
echo 'Hello from Jenkins via EC2!' > /home/ubuntu/demo.txt
sudo apt-get update -y
sudo apt-get install -y awscli
aws s3 cp /home/ubuntu/demo.txt s3://$BUCKET_NAME/demo.txt
EOF
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
