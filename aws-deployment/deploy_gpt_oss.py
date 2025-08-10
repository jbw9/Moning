#!/usr/bin/env python3
"""
Deploy OpenAI GPT-OSS-20B model to SageMaker Serverless
This script will deploy the model and return the endpoint name for use in Lambda functions
"""

import boto3
import json
import time
from datetime import datetime

def deploy_gpt_oss_model():
    """Deploy GPT-OSS-20B model to SageMaker Serverless"""
    
    print("🚀 Starting OpenAI GPT-OSS-20B deployment...")
    
    try:
        # Initialize SageMaker client
        sagemaker_client = boto3.client('sagemaker', region_name='us-east-1')
        
        # Check if we can access SageMaker
        print("✅ SageMaker client initialized successfully")
        
        # Try to deploy using SageMaker JumpStart approach
        print("\n📦 Attempting to deploy GPT-OSS-20B model...")
        
        # Model configuration
        model_name = f"openai-gpt-oss-20b-{int(time.time())}"
        endpoint_name = f"gpt-oss-20b-endpoint-{int(time.time())}"
        
        # Note: Since the direct JumpStart model might not be available,
        # we'll try the Bedrock approach first, then fall back to alternatives
        
        print(f"📋 Model name: {model_name}")
        print(f"📋 Endpoint name: {endpoint_name}")
        
        # Check available foundation models
        try:
            print("\n🔍 Checking available foundation models...")
            response = sagemaker_client.list_model_packages(
                ModelPackageType='Versioned',
                MaxResults=50
            )
            
            print(f"Found {len(response['ModelPackageSummaryList'])} model packages")
            
            # Look for OpenAI or similar models
            openai_models = [
                pkg for pkg in response['ModelPackageSummaryList'] 
                if 'openai' in pkg.get('ModelPackageDescription', '').lower() or
                   'gpt' in pkg.get('ModelPackageDescription', '').lower()
            ]
            
            if openai_models:
                print("🎯 Found OpenAI-related models:")
                for model in openai_models:
                    print(f"  - {model.get('ModelPackageDescription', 'No description')}")
            else:
                print("ℹ️  No OpenAI models found in model packages")
                
        except Exception as e:
            print(f"⚠️  Could not list model packages: {str(e)}")
        
        # Since direct deployment might not work, let's check Bedrock availability
        print("\n🔄 Checking Amazon Bedrock for OpenAI models...")
        
        try:
            bedrock_client = boto3.client('bedrock', region_name='us-east-1')
            
            # List available foundation models in Bedrock
            bedrock_models = bedrock_client.list_foundation_models()
            
            openai_bedrock = [
                model for model in bedrock_models['modelSummaries']
                if 'openai' in model.get('providerName', '').lower()
            ]
            
            if openai_bedrock:
                print("🎯 Found OpenAI models in Bedrock:")
                for model in openai_bedrock:
                    print(f"  - {model['modelId']} by {model['providerName']}")
                    
                print("\n💡 Recommendation: Use Amazon Bedrock for OpenAI models")
                print("   This is more cost-effective and easier to manage than SageMaker for your use case.")
                
                return {
                    'deployment_type': 'bedrock',
                    'available_models': openai_bedrock,
                    'recommendation': 'Use Bedrock instead of SageMaker for better cost efficiency'
                }
            
        except Exception as e:
            print(f"⚠️  Could not check Bedrock: {str(e)}")
        
        # Alternative: Use a compatible open source model
        print("\n🔄 Alternative: Deploy compatible open source model...")
        print("   Recommended alternatives:")
        print("   - meta-textgeneration-llama-2-7b-f (Available in SageMaker JumpStart)")
        print("   - huggingface-text2text-flan-t5-xl (Good for summarization)")
        
        return {
            'deployment_type': 'alternative_needed',
            'status': 'OpenAI GPT-OSS not directly available',
            'recommendations': [
                'Use Amazon Bedrock for OpenAI models (if available)',
                'Deploy Llama 2 7B or Flan-T5-XL for similar functionality',
                'Consider using OpenAI API directly for development'
            ]
        }
        
    except Exception as e:
        print(f"❌ Error during deployment: {str(e)}")
        return {
            'deployment_type': 'error',
            'error': str(e)
        }

def check_bedrock_openai_availability():
    """Check if OpenAI models are available in Bedrock"""
    try:
        bedrock_client = boto3.client('bedrock', region_name='us-east-1')
        
        # Check if we can access Bedrock
        models = bedrock_client.list_foundation_models()
        
        for model in models['modelSummaries']:
            if 'openai' in model.get('providerName', '').lower():
                print(f"✅ Found OpenAI model: {model['modelId']}")
                return model['modelId']
                
        return None
        
    except Exception as e:
        print(f"Could not check Bedrock: {str(e)}")
        return None

if __name__ == "__main__":
    print("=" * 60)
    print("🤖 OpenAI GPT-OSS Model Deployment Script")
    print("=" * 60)
    
    # First check Bedrock availability
    bedrock_model = check_bedrock_openai_availability()
    
    if bedrock_model:
        print(f"\n🎉 OpenAI model available in Bedrock: {bedrock_model}")
        print("💡 Recommendation: Use Bedrock instead of SageMaker")
        print("   - Much more cost effective")
        print("   - No infrastructure management")
        print("   - Better for your use case")
    else:
        # Try SageMaker deployment
        result = deploy_gpt_oss_model()
        print(f"\n📊 Deployment result: {json.dumps(result, indent=2)}")
    
    print("\n" + "=" * 60)
    print("Next steps will depend on the results above...")