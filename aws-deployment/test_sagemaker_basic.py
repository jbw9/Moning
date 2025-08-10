#!/usr/bin/env python3
"""
Basic SageMaker JumpStart test to see if the service is working at all
"""

import boto3

def test_sagemaker_jumpstart():
    """Test if SageMaker JumpStart is accessible in the account"""
    
    print("🧪 Testing SageMaker JumpStart Basic Access")
    print("=" * 50)
    
    try:
        # Test basic SageMaker access
        sagemaker_client = boto3.client('sagemaker', region_name='us-east-1')
        
        print("✅ SageMaker client created")
        
        # Try to list endpoints (basic permission test)
        try:
            response = sagemaker_client.list_endpoints()
            print(f"✅ Can list endpoints: {len(response.get('Endpoints', []))} found")
        except Exception as e:
            print(f"❌ Cannot list endpoints: {str(e)}")
            return False
        
        # Try to check SageMaker JumpStart capabilities
        try:
            from sagemaker import jumpstart
            print("✅ SageMaker JumpStart SDK imported")
            
            # Try to list available models (this might fail due to permissions)
            try:
                from sagemaker.jumpstart import utils
                # This is a simple call that should work if JumpStart is properly enabled
                print("✅ JumpStart utils imported")
                
            except Exception as e:
                print(f"⚠️  JumpStart utils issue: {str(e)}")
            
        except Exception as e:
            print(f"❌ SageMaker JumpStart not accessible: {str(e)}")
            return False
        
        # Test if we can create a SageMaker session
        try:
            import sagemaker
            session = sagemaker.Session()
            print(f"✅ SageMaker session created in region: {session.boto_region_name}")
            
            # Get the default bucket (this should work)
            try:
                bucket = session.default_bucket()
                print(f"✅ Default S3 bucket: {bucket}")
            except Exception as e:
                print(f"⚠️  No default S3 bucket: {str(e)}")
            
        except Exception as e:
            print(f"❌ Cannot create SageMaker session: {str(e)}")
            return False
        
        print("\n✅ SageMaker JumpStart appears to be working!")
        return True
        
    except Exception as e:
        print(f"❌ SageMaker access failed: {str(e)}")
        return False

def test_bedrock_access():
    """Test if Amazon Bedrock is accessible (simpler alternative)"""
    
    print("\n🧪 Testing Amazon Bedrock Access")
    print("=" * 40)
    
    # Bedrock is available in specific regions
    bedrock_regions = ['us-west-2', 'us-east-1', 'eu-west-1']
    
    for region in bedrock_regions:
        try:
            bedrock_client = boto3.client('bedrock', region_name=region)
            
            # Try to list foundation models
            response = bedrock_client.list_foundation_models()
            models = response.get('modelSummaries', [])
            
            print(f"✅ Bedrock working in {region}: {len(models)} models available")
            
            # Look for OpenAI models specifically
            openai_models = [
                model for model in models
                if 'openai' in model.get('providerName', '').lower()
            ]
            
            if openai_models:
                print(f"🎯 Found {len(openai_models)} OpenAI models in {region}:")
                for model in openai_models[:3]:  # Show first 3
                    print(f"   - {model.get('modelId', 'Unknown')}")
                
                return {
                    'region': region,
                    'openai_models': openai_models
                }
            else:
                print(f"   ℹ️  No OpenAI models found in {region}")
                
        except Exception as e:
            error_str = str(e)
            if "AccessDenied" in error_str:
                print(f"❌ Bedrock access denied in {region} (may need to enable Bedrock)")
            else:
                print(f"❌ Bedrock failed in {region}: {error_str}")
    
    return None

if __name__ == "__main__":
    print("🔍 Diagnosing AWS ML Services Access")
    print("=" * 60)
    
    # Test SageMaker first
    sagemaker_works = test_sagemaker_jumpstart()
    
    # Test Bedrock as alternative
    bedrock_result = test_bedrock_access()
    
    print("\n" + "=" * 60)
    print("📊 DIAGNOSIS RESULTS")
    print("=" * 60)
    
    if sagemaker_works:
        print("✅ SageMaker JumpStart: Working")
        print("💡 The ECR error might be model-specific or region-specific")
        print("   Try running: python3 try_different_regions.py")
    else:
        print("❌ SageMaker JumpStart: Issues detected")
        print("💡 May need additional permissions or account setup")
    
    if bedrock_result:
        print(f"✅ Amazon Bedrock: Working in {bedrock_result['region']}")
        print(f"🎯 OpenAI models available: {len(bedrock_result['openai_models'])}")
        print("💡 Recommended: Use Bedrock instead of SageMaker")
        print("   - Simpler deployment")
        print("   - No instance management")
        print("   - More cost-effective")
    else:
        print("❌ Amazon Bedrock: Not accessible or no OpenAI models")
    
    print("\n🎯 NEXT STEPS:")
    if bedrock_result:
        print("1. Use Amazon Bedrock for OpenAI models (Recommended)")
        print("2. Much simpler than SageMaker deployment")
    elif sagemaker_works:
        print("1. Try different regions for SageMaker deployment")
        print("2. Contact AWS support about model availability")
    else:
        print("1. Check IAM permissions for SageMaker and Bedrock")
        print("2. Ensure services are enabled in your account")
        print("3. Contact AWS support")