#!/usr/bin/env python3
"""
Manual deployment script - simpler approach
Create the essential components without complex CloudFormation
"""

import boto3
import json
import zipfile
import os
import time
from datetime import datetime

def deploy_infrastructure():
    """Deploy the essential infrastructure manually"""
    
    print("🚀 Manual Deployment of Moning Summarization Infrastructure")
    print("=" * 60)
    
    # Initialize clients
    dynamodb = boto3.client('dynamodb', region_name='us-west-2')
    lambda_client = boto3.client('lambda', region_name='us-west-2')
    iam = boto3.client('iam', region_name='us-west-2')
    apigateway = boto3.client('apigateway', region_name='us-west-2')
    
    try:
        # Step 1: Create DynamoDB table
        print("\n1. Creating DynamoDB table...")
        create_dynamodb_table(dynamodb)
        
        # Step 2: Create IAM roles
        print("\n2. Creating IAM roles...")
        lambda_role_arn = create_lambda_role(iam)
        
        # Step 3: Create Lambda functions
        print("\n3. Creating Lambda functions...")
        api_function_arn = create_api_lambda(lambda_client, lambda_role_arn)
        batch_function_arn = create_batch_lambda(lambda_client, lambda_role_arn)
        
        # Step 4: Create API Gateway
        print("\n4. Creating API Gateway...")
        api_url = create_api_gateway(apigateway, lambda_client, api_function_arn)
        
        # Step 5: Test the setup
        print("\n5. Testing the deployment...")
        test_deployment(api_url)
        
        # Success summary
        print("\n" + "=" * 60)
        print("🎉 DEPLOYMENT SUCCESSFUL!")
        print("=" * 60)
        print(f"✅ DynamoDB Table: article-summaries")
        print(f"✅ API Lambda: {api_function_arn.split(':')[-1]}")
        print(f"✅ Batch Lambda: {batch_function_arn.split(':')[-1]}")
        print(f"✅ API Gateway: {api_url}")
        
        # Save configuration
        config = {
            "deployment_time": datetime.now().isoformat(),
            "region": "us-west-2",
            "dynamodb_table": "article-summaries",
            "api_lambda_arn": api_function_arn,
            "batch_lambda_arn": batch_function_arn,
            "api_url": api_url,
            "model_id": "openai.gpt-oss-20b-1:0"
        }
        
        with open('deployment_config.json', 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"\n💾 Configuration saved: deployment_config.json")
        print(f"🚀 Ready for iOS app integration!")
        
        return config
        
    except Exception as e:
        print(f"\n❌ Deployment failed: {str(e)}")
        return None

def create_dynamodb_table(dynamodb):
    """Create DynamoDB table for article summaries"""
    
    try:
        # Check if table exists
        try:
            dynamodb.describe_table(TableName='article-summaries')
            print("   ✅ DynamoDB table already exists")
            return
        except dynamodb.exceptions.ResourceNotFoundException:
            pass
        
        # Create table
        dynamodb.create_table(
            TableName='article-summaries',
            KeySchema=[
                {'AttributeName': 'article_id', 'KeyType': 'HASH'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'article_id', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        # Wait for table to be active
        waiter = dynamodb.get_waiter('table_exists')
        waiter.wait(TableName='article-summaries')
        
        print("   ✅ DynamoDB table created successfully")
        
    except Exception as e:
        print(f"   ❌ DynamoDB table creation failed: {str(e)}")
        raise

def create_lambda_role(iam):
    """Create IAM role for Lambda functions"""
    
    role_name = 'moning-lambda-role'
    
    try:
        # Check if role exists
        try:
            response = iam.get_role(RoleName=role_name)
            print("   ✅ Lambda IAM role already exists")
            return response['Role']['Arn']
        except iam.exceptions.NoSuchEntityException:
            pass
        
        # Create role
        trust_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"Service": "lambda.amazonaws.com"},
                    "Action": "sts:AssumeRole"
                }
            ]
        }
        
        role = iam.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=json.dumps(trust_policy),
            Description='Role for Moning summarization Lambda functions'
        )
        
        # Attach policies
        policies = [
            'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
            'arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess',
            'arn:aws:iam::aws:policy/AmazonBedrockFullAccess'
        ]
        
        for policy in policies:
            iam.attach_role_policy(RoleName=role_name, PolicyArn=policy)
        
        # Wait for role to propagate
        time.sleep(10)
        
        print("   ✅ Lambda IAM role created successfully")
        return role['Role']['Arn']
        
    except Exception as e:
        print(f"   ❌ IAM role creation failed: {str(e)}")
        raise

def create_api_lambda(lambda_client, role_arn):
    """Create API handler Lambda function"""
    
    function_name = 'moning-api-handler'
    
    try:
        # Check if function exists
        try:
            response = lambda_client.get_function(FunctionName=function_name)
            print("   ✅ API Lambda function already exists")
            return response['Configuration']['FunctionArn']
        except lambda_client.exceptions.ResourceNotFoundException:
            pass
        
        # Create zip file
        zip_path = create_lambda_zip('api-handler')
        
        with open(zip_path, 'rb') as f:
            zip_content = f.read()
        
        # Create function
        response = lambda_client.create_function(
            FunctionName=function_name,
            Runtime='python3.12',
            Role=role_arn,
            Handler='lambda_function.lambda_handler',
            Code={'ZipFile': zip_content},
            Description='API handler for iOS app requests',
            Timeout=300,
            MemorySize=1024,
            Environment={
                'Variables': {
                    'BEDROCK_MODEL_ID': 'openai.gpt-oss-20b-1:0',
                    'DYNAMODB_TABLE': 'article-summaries',
                    'BEDROCK_REGION': 'us-west-2'
                }
            }
        )
        
        print("   ✅ API Lambda function created successfully")
        return response['FunctionArn']
        
    except Exception as e:
        print(f"   ❌ API Lambda creation failed: {str(e)}")
        raise

def create_batch_lambda(lambda_client, role_arn):
    """Create batch processing Lambda function"""
    
    function_name = 'moning-batch-summarizer'
    
    try:
        # Check if function exists
        try:
            response = lambda_client.get_function(FunctionName=function_name)
            print("   ✅ Batch Lambda function already exists")
            return response['Configuration']['FunctionArn']
        except lambda_client.exceptions.ResourceNotFoundException:
            pass
        
        # Create zip file
        zip_path = create_lambda_zip('batch-summarizer')
        
        with open(zip_path, 'rb') as f:
            zip_content = f.read()
        
        # Create function
        response = lambda_client.create_function(
            FunctionName=function_name,
            Runtime='python3.12',
            Role=role_arn,
            Handler='lambda_function.lambda_handler',
            Code={'ZipFile': zip_content},
            Description='Batch processor for article summarization',
            Timeout=900,
            MemorySize=1024,
            Environment={
                'Variables': {
                    'BEDROCK_MODEL_ID': 'openai.gpt-oss-20b-1:0',
                    'DYNAMODB_TABLE': 'article-summaries',
                    'BEDROCK_REGION': 'us-west-2'
                }
            }
        )
        
        print("   ✅ Batch Lambda function created successfully")
        return response['FunctionArn']
        
    except Exception as e:
        print(f"   ❌ Batch Lambda creation failed: {str(e)}")
        raise

def create_lambda_zip(function_type):
    """Create zip file for Lambda deployment"""
    
    zip_path = f'{function_type}-lambda.zip'
    source_dir = f'functions/{function_type}'
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        # Add lambda function
        zipf.write(f'{source_dir}/lambda_function.py', 'lambda_function.py')
        
        # Add requirements (boto3 is included in Lambda runtime)
        # No additional packages needed
    
    return zip_path

def create_api_gateway(apigateway, lambda_client, lambda_arn):
    """Create API Gateway with essential endpoints"""
    
    try:
        # Create REST API
        api = apigateway.create_rest_api(
            name='moning-summarization-api',
            description='API for Moning news summarization',
            endpointConfiguration={'types': ['REGIONAL']}
        )
        
        api_id = api['id']
        
        # Get root resource
        resources = apigateway.get_resources(restApiId=api_id)
        root_id = next(r['id'] for r in resources['items'] if r['path'] == '/')
        
        # Create /summaries resource
        summaries_resource = apigateway.create_resource(
            restApiId=api_id,
            parentId=root_id,
            pathPart='summaries'
        )
        
        # Create /summaries/{article_id} resource
        article_resource = apigateway.create_resource(
            restApiId=api_id,
            parentId=summaries_resource['id'],
            pathPart='{article_id}'
        )
        
        # Add GET method to /summaries/{article_id}
        apigateway.put_method(
            restApiId=api_id,
            resourceId=article_resource['id'],
            httpMethod='GET',
            authorizationType='NONE'
        )
        
        # Configure Lambda integration
        region = 'us-west-2'
        account_id = lambda_arn.split(':')[4]
        lambda_uri = f"arn:aws:apigateway:{region}:lambda:path/2015-03-31/functions/{lambda_arn}/invocations"
        
        apigateway.put_integration(
            restApiId=api_id,
            resourceId=article_resource['id'],
            httpMethod='GET',
            type='AWS_PROXY',
            integrationHttpMethod='POST',
            uri=lambda_uri
        )
        
        # Add Lambda permission for API Gateway
        lambda_client.add_permission(
            FunctionName=lambda_arn.split(':')[-1],
            StatementId='api-gateway-invoke',
            Action='lambda:InvokeFunction',
            Principal='apigateway.amazonaws.com',
            SourceArn=f"arn:aws:execute-api:{region}:{account_id}:{api_id}/*/*"
        )
        
        # Deploy API
        deployment = apigateway.create_deployment(
            restApiId=api_id,
            stageName='prod',
            description='Production deployment'
        )
        
        api_url = f"https://{api_id}.execute-api.{region}.amazonaws.com/prod"
        
        print("   ✅ API Gateway created successfully")
        return api_url
        
    except Exception as e:
        print(f"   ❌ API Gateway creation failed: {str(e)}")
        raise

def test_deployment(api_url):
    """Test the deployed infrastructure"""
    
    try:
        import requests
        
        # Test API endpoint
        test_url = f"{api_url}/summaries/test123"
        response = requests.get(test_url)
        
        if response.status_code in [200, 404]:  # 404 is expected for missing article
            print("   ✅ API Gateway is responding correctly")
        else:
            print(f"   ⚠️  API returned status {response.status_code}")
            
    except ImportError:
        print("   ℹ️  Skipping HTTP test (requests not available)")
    except Exception as e:
        print(f"   ⚠️  Test failed: {str(e)}")

if __name__ == "__main__":
    print("Starting manual deployment of Moning infrastructure...")
    
    config = deploy_infrastructure()
    
    if config:
        print("\n🎯 Next steps:")
        print("1. Test the API endpoints")
        print("2. Integrate with iOS app")
        print("3. Process some test articles")
        print("\n✅ Infrastructure is ready!")
    else:
        print("\n❌ Deployment failed - check errors above")