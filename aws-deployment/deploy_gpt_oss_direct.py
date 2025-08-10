#!/usr/bin/env python3
"""
Direct deployment of OpenAI GPT-OSS-20B model to SageMaker
Bypasses model listing by using known model IDs directly
"""

import boto3
import json
import time
from datetime import datetime

def deploy_gpt_oss_direct():
    """Deploy GPT-OSS-20B model directly using known model ID"""
    
    print("🚀 Starting Direct OpenAI GPT-OSS-20B Deployment")
    print("=" * 60)
    
    try:
        # Import SageMaker SDK
        try:
            from sagemaker.jumpstart.model import JumpStartModel
            import sagemaker
            print("✅ SageMaker SDK imported successfully")
        except ImportError:
            print("❌ SageMaker SDK not found. Installing...")
            import subprocess
            subprocess.check_call(['pip3', 'install', 'sagemaker>=2.190.0'])
            from sagemaker.jumpstart.model import JumpStartModel
            import sagemaker
        
        # Initialize SageMaker session
        sagemaker_session = sagemaker.Session()
        region = boto3.Session().region_name
        print(f"✅ SageMaker session initialized in region: {region}")
        
        # Known model IDs for OpenAI GPT-OSS models
        models_to_try = [
            "openai-reasoning-gpt-oss-20b",  # Smaller model, better for serverless
            "openai-reasoning-gpt-oss-120b", # Larger model
            "openai-gpt-oss-20b",            # Alternative naming
            "openai-gpt-oss-120b"            # Alternative naming
        ]
        
        for model_id in models_to_try:
            print(f"\n🔄 Attempting to deploy model: {model_id}")
            
            try:
                # Create JumpStart model instance
                model = JumpStartModel(
                    model_id=model_id,
                    model_version="*",  # Use latest version
                    instance_type="ml.inf2.xlarge"  # Cost-effective inference instance
                )
                
                print(f"✅ Model instance created for {model_id}")
                
                # Deploy with serverless configuration for cost efficiency
                print("🚀 Deploying to serverless endpoint...")
                
                predictor = model.deploy(
                    initial_instance_count=1,
                    serverless_inference_config={
                        "MemorySizeInMB": 16384,  # 16GB memory
                        "MaxConcurrency": 5       # Max concurrent requests
                    }
                )
                
                endpoint_name = predictor.endpoint_name
                print(f"🎉 SUCCESS! Model deployed!")
                print(f"📋 Endpoint name: {endpoint_name}")
                
                # Test the endpoint
                print("\n🧪 Testing the deployed model...")
                test_payload = {
                    "messages": [
                        {
                            "role": "system",
                            "content": "You are a helpful assistant that summarizes news articles concisely."
                        },
                        {
                            "role": "user", 
                            "content": "Summarize: Apple announced new iPhone features including improved camera and longer battery life in their latest product launch event."
                        }
                    ],
                    "max_tokens": 150,
                    "reasoning_effort": "low"
                }
                
                response = predictor.predict(test_payload)
                summary = response['choices'][0]['message']['content']
                
                print(f"✅ Test successful!")
                print(f"📝 Sample summary: {summary}")
                
                # Save endpoint info for Lambda functions
                endpoint_info = {
                    "endpoint_name": endpoint_name,
                    "model_id": model_id,
                    "deployment_time": datetime.now().isoformat(),
                    "region": region,
                    "instance_type": "serverless",
                    "memory_mb": 16384,
                    "max_concurrency": 5
                }
                
                with open('sagemaker_endpoint_info.json', 'w') as f:
                    json.dump(endpoint_info, f, indent=2)
                
                print(f"\n📁 Endpoint info saved to: sagemaker_endpoint_info.json")
                print(f"🎯 Use this endpoint name in your Lambda functions: {endpoint_name}")
                
                return endpoint_info
                
            except Exception as e:
                error_msg = str(e)
                print(f"❌ Failed to deploy {model_id}: {error_msg}")
                
                # Check for specific error types
                if "does not exist" in error_msg.lower():
                    print("   → Model ID not found, trying next...")
                    continue
                elif "not authorized" in error_msg.lower():
                    print("   → Permission issue, you may need additional SageMaker permissions")
                    break
                elif "region" in error_msg.lower():
                    print("   → Model may not be available in us-east-1, trying next...")
                    continue
                else:
                    print(f"   → Unexpected error: {error_msg}")
                    continue
        
        print("\n❌ Could not deploy any GPT-OSS model variant")
        print("🔍 Let's try alternative deployment methods...")
        
        return try_alternative_deployment()
        
    except Exception as e:
        print(f"❌ Critical error: {str(e)}")
        return None

def try_alternative_deployment():
    """Try deploying using alternative models available in SageMaker"""
    
    print("\n🔄 Trying alternative open source models for summarization...")
    
    # Alternative models that are definitely available in SageMaker JumpStart
    alternative_models = [
        {
            "id": "huggingface-text2text-flan-t5-xl", 
            "name": "FLAN-T5-XL",
            "description": "Excellent for summarization tasks"
        },
        {
            "id": "meta-textgeneration-llama-2-7b-f",
            "name": "Llama 2 7B", 
            "description": "Good general-purpose model"
        },
        {
            "id": "huggingface-text2text-flan-t5-large",
            "name": "FLAN-T5-Large",
            "description": "Smaller but still good for summarization"
        }
    ]
    
    for model_info in alternative_models:
        try:
            print(f"\n🔄 Trying {model_info['name']}: {model_info['description']}")
            
            from sagemaker.jumpstart.model import JumpStartModel
            
            model = JumpStartModel(
                model_id=model_info["id"],
                instance_type="ml.m5.xlarge"  # More standard instance type
            )
            
            print(f"✅ Model instance created for {model_info['name']}")
            
            # Deploy with standard configuration
            predictor = model.deploy(
                initial_instance_count=1
            )
            
            endpoint_name = predictor.endpoint_name
            print(f"🎉 SUCCESS! {model_info['name']} deployed!")
            print(f"📋 Endpoint name: {endpoint_name}")
            
            # Test the model
            if "flan-t5" in model_info["id"]:
                # FLAN-T5 uses different input format
                test_input = "summarize: Apple announced new iPhone features including improved camera and longer battery life."
                response = predictor.predict(test_input)
                summary = response[0]['generated_text']
            else:
                # Other models use chat format
                test_payload = {
                    "inputs": "Summarize this: Apple announced new iPhone features including improved camera and longer battery life.",
                    "parameters": {
                        "max_new_tokens": 150,
                        "temperature": 0.3
                    }
                }
                response = predictor.predict(test_payload)
                summary = response[0]['generated_text']
            
            print(f"✅ Test successful!")
            print(f"📝 Sample summary: {summary}")
            
            # Save endpoint info
            endpoint_info = {
                "endpoint_name": endpoint_name,
                "model_id": model_info["id"],
                "model_name": model_info["name"],
                "deployment_time": datetime.now().isoformat(),
                "region": boto3.Session().region_name,
                "instance_type": "ml.m5.xlarge",
                "model_type": "alternative"
            }
            
            with open('sagemaker_endpoint_info.json', 'w') as f:
                json.dump(endpoint_info, f, indent=2)
            
            print(f"\n🎯 Use this endpoint: {endpoint_name}")
            return endpoint_info
            
        except Exception as e:
            print(f"❌ Failed to deploy {model_info['name']}: {str(e)}")
            continue
    
    print("\n❌ Could not deploy any model")
    print("💡 You may need additional SageMaker permissions or try a different region")
    return None

if __name__ == "__main__":
    print("Starting OpenAI GPT-OSS deployment...")
    
    result = deploy_gpt_oss_direct()
    
    if result:
        print("\n" + "=" * 60)
        print("🎉 DEPLOYMENT SUCCESSFUL!")
        print("=" * 60)
        print(f"📋 Endpoint: {result['endpoint_name']}")
        print(f"🤖 Model: {result.get('model_name', result['model_id'])}")
        print("🚀 Ready for Lambda integration!")
    else:
        print("\n" + "=" * 60) 
        print("❌ DEPLOYMENT FAILED")
        print("=" * 60)
        print("💡 Next steps:")
        print("   1. Check IAM permissions for SageMaker")
        print("   2. Try different AWS region")
        print("   3. Contact AWS support about model availability")