#!/usr/bin/env python3
"""
Find available SageMaker JumpStart models across regions
The OpenAI models may only be available in specific regions
"""

import boto3
import json
from sagemaker.jumpstart import utils

def check_regions_for_models():
    """Check different AWS regions for model availability"""
    
    # Regions where new ML models are typically available first
    regions_to_check = [
        'us-west-2',  # Oregon - Often has newest models first
        'us-east-1',  # Virginia - Your current region
        'eu-west-1',  # Ireland - Good for EU
        'ap-southeast-1',  # Singapore - Good for Asia
    ]
    
    print("🌍 Checking model availability across AWS regions...")
    print("=" * 60)
    
    for region in regions_to_check:
        print(f"\n🔍 Checking region: {region}")
        
        try:
            # Create SageMaker client for this region
            sagemaker_client = boto3.client('sagemaker', region_name=region)
            
            # Test if we can access SageMaker in this region
            response = sagemaker_client.describe_domain_details()
            print(f"   ✅ SageMaker accessible in {region}")
            
        except Exception as e:
            error_str = str(e)
            if "does not exist" in error_str:
                print(f"   ℹ️  No SageMaker domain in {region}")
            else:
                print(f"   ❌ Error accessing {region}: {error_str}")
            continue
        
        # Try to deploy OpenAI model in this region
        try:
            print(f"   🧪 Testing OpenAI model deployment in {region}...")
            
            # Import SageMaker SDK with region override
            import sagemaker
            
            # Create session for this region
            boto_session = boto3.Session(region_name=region)
            sagemaker_session = sagemaker.Session(boto_session=boto_session)
            
            from sagemaker.jumpstart.model import JumpStartModel
            
            # Try OpenAI GPT-OSS-20B
            model = JumpStartModel(
                model_id="openai-reasoning-gpt-oss-20b",
                sagemaker_session=sagemaker_session
            )
            
            print(f"   ✅ OpenAI GPT-OSS-20B model found in {region}!")
            
            # Get supported instance types
            supported_instances = utils.list_jumpstart_models(
                filter="task == llm",
                region=region
            )
            
            print(f"   📋 Attempting deployment in {region}...")
            
            return deploy_in_region(region, model)
            
        except Exception as e:
            error_msg = str(e)
            if "Invalid model ID" in error_msg:
                print(f"   ❌ OpenAI models not available in {region}")
            elif "No inference ECR configuration" in error_msg:
                print(f"   ❌ ECR containers not available in {region}")
            else:
                print(f"   ❌ Error in {region}: {error_msg}")
    
    print("\n❌ OpenAI models not found in any region")
    return try_bedrock_approach()

def deploy_in_region(region, model):
    """Deploy model in the specified region"""
    
    print(f"🚀 Deploying OpenAI GPT-OSS-20B in {region}...")
    
    # Try different instance types known to work
    instance_types_to_try = [
        "ml.g5.xlarge",    # GPU instance
        "ml.m5.2xlarge",   # CPU instance 
        "ml.c5.2xlarge",   # Compute optimized
    ]
    
    for instance_type in instance_types_to_try:
        try:
            print(f"   🔄 Trying instance type: {instance_type}")
            
            predictor = model.deploy(
                initial_instance_count=1,
                instance_type=instance_type
            )
            
            endpoint_name = predictor.endpoint_name
            print(f"   🎉 SUCCESS! Deployed in {region}")
            print(f"   📋 Endpoint: {endpoint_name}")
            
            # Test the model
            test_payload = {
                "messages": [
                    {"role": "system", "content": "You are a news summarizer."},
                    {"role": "user", "content": "Summarize: Apple announced new iPhone with better camera."}
                ],
                "max_tokens": 100,
                "reasoning_effort": "low"
            }
            
            response = predictor.predict(test_payload)
            summary = response['choices'][0]['message']['content']
            
            print(f"   ✅ Test successful!")
            print(f"   📝 Sample: {summary}")
            
            # Save deployment info
            deployment_info = {
                "endpoint_name": endpoint_name,
                "region": region,
                "model_id": "openai-reasoning-gpt-oss-20b",
                "instance_type": instance_type,
                "deployment_successful": True
            }
            
            with open(f'sagemaker_endpoint_{region}.json', 'w') as f:
                json.dump(deployment_info, f, indent=2)
            
            print(f"   💾 Saved to: sagemaker_endpoint_{region}.json")
            
            return deployment_info
            
        except Exception as e:
            print(f"   ❌ Failed with {instance_type}: {str(e)}")
            continue
    
    return None

def try_bedrock_approach():
    """Try Amazon Bedrock as alternative"""
    
    print("\n🔄 Trying Amazon Bedrock approach...")
    print("OpenAI models are also available through Bedrock")
    
    try:
        # Try to access Bedrock
        bedrock_client = boto3.client('bedrock', region_name='us-west-2')  # Bedrock is available in us-west-2
        
        models = bedrock_client.list_foundation_models()
        
        openai_models = [
            model for model in models['modelSummaries']
            if 'openai' in model.get('providerName', '').lower()
        ]
        
        if openai_models:
            print("✅ Found OpenAI models in Bedrock:")
            for model in openai_models:
                print(f"   - {model['modelId']} by {model['providerName']}")
            
            print("\n💡 Recommendation: Use Bedrock instead of SageMaker")
            print("   Bedrock is often easier and more cost-effective")
            
            return {
                "deployment_type": "bedrock",
                "available_models": openai_models,
                "region": "us-west-2"
            }
        else:
            print("❌ No OpenAI models found in Bedrock either")
            return None
            
    except Exception as e:
        print(f"❌ Could not access Bedrock: {str(e)}")
        return None

def create_simple_huggingface_deployment():
    """Deploy a simple Hugging Face model that definitely works"""
    
    print("\n🔄 Deploying proven alternative: Hugging Face BART for summarization...")
    
    try:
        from sagemaker.huggingface import HuggingFaceModel
        import sagemaker
        
        # Use a model that definitely works for summarization
        huggingface_model = HuggingFaceModel(
            model_data="s3://huggingface-models/bart-large-cnn",  # Pre-trained summarization model
            role=sagemaker.get_execution_role(),
            transformers_version="4.21",
            pytorch_version="1.12",
            py_version="py38"
        )
        
        predictor = huggingface_model.deploy(
            initial_instance_count=1,
            instance_type="ml.m5.xlarge"
        )
        
        print(f"✅ Hugging Face BART deployed: {predictor.endpoint_name}")
        
        # Test with summarization
        test_input = {
            "inputs": "Apple announced new iPhone features including improved camera and longer battery life."
        }
        
        result = predictor.predict(test_input)
        print(f"📝 Test summary: {result[0]['summary_text']}")
        
        return {
            "endpoint_name": predictor.endpoint_name,
            "model_type": "huggingface-bart",
            "deployment_successful": True
        }
        
    except Exception as e:
        print(f"❌ Even Hugging Face deployment failed: {str(e)}")
        return None

if __name__ == "__main__":
    print("🔍 Finding available models for deployment...")
    
    # First try to find OpenAI models in different regions
    result = check_regions_for_models()
    
    if not result:
        # If no OpenAI models found, try simple Hugging Face alternative
        print("\n🔄 Trying simple Hugging Face alternative...")
        result = create_simple_huggingface_deployment()
    
    if result:
        print("\n" + "=" * 60)
        print("🎉 DEPLOYMENT FOUND!")
        print("=" * 60)
        print(json.dumps(result, indent=2))
    else:
        print("\n" + "=" * 60)
        print("❌ NO DEPLOYMENT SUCCESSFUL")
        print("=" * 60)
        print("💡 You may need to:")
        print("   1. Enable SageMaker JumpStart in your account")
        print("   2. Try different AWS region")
        print("   3. Contact AWS support")