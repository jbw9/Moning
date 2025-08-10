#!/usr/bin/env python3
"""
Fix API Gateway configuration
Add missing routes and CORS headers
"""

import boto3
import json

def fix_api_gateway():
    """Fix API Gateway configuration issues"""
    
    print("🔧 Fixing API Gateway Configuration")
    print("=" * 40)
    
    # Load config
    with open('deployment_config.json', 'r') as f:
        config = json.load(f)
    
    api_url = config['api_url']
    api_id = api_url.split('.')[0].split('//')[1]  # Extract API ID from URL
    
    apigateway = boto3.client('apigateway', region_name='us-west-2')
    lambda_client = boto3.client('lambda', region_name='us-west-2')
    
    try:
        # Get resources
        resources = apigateway.get_resources(restApiId=api_id)
        
        print(f"   📋 API ID: {api_id}")
        print(f"   📋 Current resources: {len(resources['items'])}")
        
        # Find root and summaries resources
        root_id = None
        summaries_id = None
        
        for resource in resources['items']:
            if resource['path'] == '/':
                root_id = resource['id'] 
            elif resource['path'] == '/summaries':
                summaries_id = resource['id']
        
        # Create /batch-summaries resource if missing
        batch_resource = None
        for resource in resources['items']:
            if resource['path'] == '/batch-summaries':
                batch_resource = resource
                break
        
        if not batch_resource:
            print("   🔄 Creating /batch-summaries resource...")
            batch_resource = apigateway.create_resource(
                restApiId=api_id,
                parentId=root_id,
                pathPart='batch-summaries'
            )
        
        # Add POST method to /batch-summaries
        try:
            apigateway.put_method(
                restApiId=api_id,
                resourceId=batch_resource['id'],
                httpMethod='POST',
                authorizationType='NONE'
            )
            print("   ✅ Added POST method to /batch-summaries")
        except Exception as e:
            if "ConflictException" in str(e):
                print("   ℹ️  POST method already exists")
            else:
                raise
        
        # Configure Lambda integration for POST
        lambda_arn = config['api_lambda_arn']
        region = 'us-west-2'
        account_id = lambda_arn.split(':')[4]
        lambda_uri = f"arn:aws:apigateway:{region}:lambda:path/2015-03-31/functions/{lambda_arn}/invocations"
        
        try:
            apigateway.put_integration(
                restApiId=api_id,
                resourceId=batch_resource['id'],
                httpMethod='POST',
                type='AWS_PROXY',
                integrationHttpMethod='POST',
                uri=lambda_uri
            )
            print("   ✅ Configured Lambda integration for POST")
        except Exception as e:
            if "ConflictException" in str(e):
                print("   ℹ️  Integration already exists")
            else:
                raise
        
        # Add OPTIONS method for CORS
        for resource in resources['items']:
            if resource['path'] in ['/summaries/{article_id}', '/batch-summaries']:
                try:
                    apigateway.put_method(
                        restApiId=api_id,
                        resourceId=resource['id'],
                        httpMethod='OPTIONS',
                        authorizationType='NONE'
                    )
                    
                    # Mock integration for OPTIONS
                    apigateway.put_integration(
                        restApiId=api_id,
                        resourceId=resource['id'],
                        httpMethod='OPTIONS',
                        type='MOCK',
                        requestTemplates={'application/json': '{"statusCode": 200}'}
                    )
                    
                    # Method response for OPTIONS
                    apigateway.put_method_response(
                        restApiId=api_id,
                        resourceId=resource['id'],
                        httpMethod='OPTIONS',
                        statusCode='200',
                        responseParameters={
                            'method.response.header.Access-Control-Allow-Headers': False,
                            'method.response.header.Access-Control-Allow-Methods': False,
                            'method.response.header.Access-Control-Allow-Origin': False
                        }
                    )
                    
                    # Integration response for OPTIONS
                    apigateway.put_integration_response(
                        restApiId=api_id,
                        resourceId=resource['id'],
                        httpMethod='OPTIONS',
                        statusCode='200',
                        responseParameters={
                            'method.response.header.Access-Control-Allow-Headers': "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
                            'method.response.header.Access-Control-Allow-Methods': "'GET,POST,OPTIONS'",
                            'method.response.header.Access-Control-Allow-Origin': "'*'"
                        }
                    )
                    
                    print(f"   ✅ Added CORS OPTIONS to {resource['path']}")
                    
                except Exception as e:
                    if "ConflictException" in str(e):
                        print(f"   ℹ️  CORS already configured for {resource['path']}")
                    else:
                        print(f"   ⚠️  CORS config failed for {resource['path']}: {str(e)}")
        
        # Add Lambda permission for API Gateway invoke
        try:
            lambda_client.add_permission(
                FunctionName=lambda_arn.split(':')[-1],
                StatementId='api-gateway-batch-invoke',
                Action='lambda:InvokeFunction',
                Principal='apigateway.amazonaws.com',
                SourceArn=f"arn:aws:execute-api:{region}:{account_id}:{api_id}/*/*"
            )
            print("   ✅ Added Lambda permission for API Gateway")
        except Exception as e:
            if "ResourceConflictException" in str(e):
                print("   ℹ️  Lambda permission already exists")
            else:
                print(f"   ⚠️  Lambda permission failed: {str(e)}")
        
        # Redeploy API
        print("   🔄 Redeploying API...")
        apigateway.create_deployment(
            restApiId=api_id,
            stageName='prod',
            description='Fixed configuration deployment'
        )
        
        print("   ✅ API Gateway configuration fixed!")
        print(f"   🔗 Updated API: {api_url}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ API Gateway fix failed: {str(e)}")
        return False

if __name__ == "__main__":
    print("Fixing API Gateway configuration...")
    
    success = fix_api_gateway()
    
    if success:
        print("\n✅ API Gateway fixed successfully!")
        print("🧪 Run test_complete_system.py again to verify")
    else:
        print("\n❌ API Gateway fix failed")