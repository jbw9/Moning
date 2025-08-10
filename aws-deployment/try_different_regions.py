#!/usr/bin/env python3
"""
Simple script to try OpenAI GPT-OSS deployment in different regions
The models may only be available in specific regions with specific instance types
"""

import boto3
import json
from datetime import datetime

def try_openai_deployment():
    """Try OpenAI GPT-OSS deployment in different regions"""
    
    print("🌍 Trying OpenAI GPT-OSS deployment across regions...")
    print("=" * 60)
    
    # Try regions where newer models are typically available first
    regions = ['us-west-2', 'us-east-1', 'eu-west-1']
    
    # Try different instance types that are known to work for LLMs
    instance_types = [
        'ml.g5.xlarge',      # GPU instance - best for LLMs
        'ml.g4dn.xlarge',    # Older GPU instance
        'ml.m5.2xlarge',     # CPU instance - backup option
        'ml.c5.4xlarge',     # High CPU instance
    ]
    
    for region in regions:
        print(f"\n🔍 Testing region: {region}")
        
        try:
            # Test basic SageMaker access in this region
            sagemaker_client = boto3.client('sagemaker', region_name=region)
            
            # Simple test - list endpoints (should work with basic permissions)
            try:
                sagemaker_client.list_endpoints()
                print(f"   ✅ SageMaker accessible in {region}")
            except Exception as e:
                print(f"   ❌ Cannot access SageMaker in {region}: {str(e)}")
                continue
            
            # Try deploying in this region
            success = try_deploy_in_region(region, instance_types)
            
            if success:
                return success
                
        except Exception as e:
            print(f"   ❌ Region {region} failed: {str(e)}")
            continue
    
    print("\n❌ Could not deploy in any region")
    return None

def try_deploy_in_region(region, instance_types):
    """Try deployment in specific region with different instance types"""
    
    try:
        import sagemaker
        from sagemaker.jumpstart.model import JumpStartModel
        
        # Create SageMaker session for this region
        boto_session = boto3.Session(region_name=region)
        sagemaker_session = sagemaker.Session(boto_session=boto_session)
        
        print(f"   🧪 Trying OpenAI GPT-OSS-20B deployment...")
        
        # Try to create model instance
        try:
            model = JumpStartModel(
                model_id="openai-reasoning-gpt-oss-20b",
                sagemaker_session=sagemaker_session
            )
            print(f"   ✅ Model instance created successfully")
        except Exception as e:
            if "Invalid model ID" in str(e):
                print(f"   ❌ OpenAI models not available in {region}")
                return None
            else:
                print(f"   ❌ Error creating model: {str(e)}")
                return None
        
        # Try different instance types
        for instance_type in instance_types:
            try:
                print(f"   🔄 Trying instance type: {instance_type}")
                
                predictor = model.deploy(
                    initial_instance_count=1,
                    instance_type=instance_type
                )
                
                endpoint_name = predictor.endpoint_name
                print(f"   🎉 SUCCESS! Deployed in {region} with {instance_type}")
                print(f"   📋 Endpoint: {endpoint_name}")
                
                # Quick test
                try:
                    test_payload = {
                        "messages": [
                            {"role": "user", "content": "Hello, can you summarize news?"}
                        ],
                        "max_tokens": 50
                    }
                    
                    response = predictor.predict(test_payload)
                    print(f"   ✅ Model responding correctly!")
                    
                except Exception as test_error:
                    print(f"   ⚠️ Model deployed but test failed: {str(test_error)}")
                
                # Save successful deployment info
                deployment_info = {
                    "endpoint_name": endpoint_name,
                    "region": region,
                    "instance_type": instance_type,
                    "model_id": "openai-reasoning-gpt-oss-20b",
                    "deployment_time": datetime.now().isoformat(),
                    "status": "success"
                }
                
                with open('successful_deployment.json', 'w') as f:
                    json.dump(deployment_info, f, indent=2)
                
                print(f"   💾 Deployment info saved to: successful_deployment.json")
                
                return deployment_info
                
            except Exception as e:
                error_msg = str(e)
                if "No inference ECR configuration" in error_msg:
                    print(f"   ❌ {instance_type}: ECR container not available")
                elif "ResourceLimitExceeded" in error_msg:
                    print(f"   ❌ {instance_type}: Instance limit reached")
                elif "InsufficientInstanceCapacity" in error_msg:
                    print(f"   ❌ {instance_type}: No capacity available")
                else:
                    print(f"   ❌ {instance_type}: {error_msg}")
                continue
        
        print(f"   ❌ No working instance type found in {region}")
        return None
        
    except Exception as e:
        print(f"   ❌ Failed to set up SageMaker session in {region}: {str(e)}")
        return None

def suggest_alternatives():
    """Suggest alternative approaches"""
    
    print("\n💡 Alternative Approaches:")
    print("=" * 40)
    
    print("\n1. 🎯 Try Amazon Bedrock (Recommended)")
    print("   - OpenAI models available through Bedrock")
    print("   - More cost-effective than SageMaker")
    print("   - No instance management required")
    print("   - Command: aws bedrock list-foundation-models")
    
    print("\n2. 🔄 Use different model")
    print("   - Facebook/Meta BART (bart-large-cnn)")
    print("   - Google T5 models")
    print("   - Anthropic Claude (via Bedrock)")
    
    print("\n3. 🌍 Try different AWS account region")
    print("   - Some models are region-specific")
    print("   - Consider us-west-2 as primary region")
    
    print("\n4. 📞 Contact AWS Support")
    print("   - Ask about SageMaker JumpStart model availability")
    print("   - Request access to OpenAI models")

if __name__ == "__main__":
    print("🚀 Starting Multi-Region OpenAI GPT-OSS Deployment")
    
    result = try_openai_deployment()
    
    if result:
        print("\n" + "=" * 60)
        print("🎉 DEPLOYMENT SUCCESSFUL!")
        print("=" * 60)
        print(f"✅ Region: {result['region']}")
        print(f"✅ Endpoint: {result['endpoint_name']}")
        print(f"✅ Instance: {result['instance_type']}")
        print("\n🚀 Ready to create Lambda functions!")
        
    else:
        print("\n" + "=" * 60)
        print("❌ DEPLOYMENT FAILED IN ALL REGIONS")
        print("=" * 60)
        suggest_alternatives()