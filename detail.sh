# check the aws region and account id
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Your AWS Account ID is $ACCOUNT_ID and you are working in the $AWS_REGION region"

# apply the cluster configuration
eksctl create cluster -f ~/environment/cluster.yaml

# move the config file to the home directory
mv /home/ec2-user/environment/scripts/config ~/.kube/config

# check the eks cluster
eksctl get cluster --region $AWS_REGION

# check the nodegroup
eksctl get nodegroup --cluster=dev-cluster --region $AWS_REGION

# reduce the nodegroup
eksctl scale nodegroup --cluster=dev-cluster --nodes=2 --name=dev-nodes --region $AWS_REGION


## Task 3: Deploy a sample containerized application

# create a dynamodb table
aws dynamodb create-table \
--table-name Employees \
--attribute-definitions AttributeName=id,AttributeType=S \
--key-schema AttributeName=id,KeyType=HASH \
--provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

# check the dynamodb table
aws dynamodb list-tables --region $AWS_REGION

# Task 3.2: Deploy the application frontend

# check the deployment, service, and pod    
kubectl get deployment,service,pod --all-namespaces

# define the frontend s3 bucket
FRONTEND_S3=FRONT_END_SOURCE_CODE_URL

# deploy the frontend
kubectl apply -f ~/environment/deployment-frontend.yaml

# deploy the frontend service
kubectl apply -f ~/environment/service-frontend.yaml

# check the deployment, service, and pod
kubectl get deployment,service,pod

# define the backend s3 bucket
BACKEND_S3=BACK_END_SOURCE_CODE_URL

# deploy the backend
kubectl apply -f ~/environment/service-backend.yaml,~/environment/deployment-backend.yaml

# check the deployment, service, and pod
kubectl get deployment,service,pod

# check the frontend service
kubectl get service frontend --output wide

# set the service account
kubectl set serviceaccount deployment backend dynamo-sa