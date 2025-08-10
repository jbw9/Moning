#!/usr/bin/env python3
"""
Test OpenAI GPT-OSS models access
Try both Bedrock and SageMaker approaches
"""

import boto3
import json
from datetime import datetime

def test_gpt_oss_bedrock():
    """Test GPT-OSS models via Amazon Bedrock"""
    
    print("🧪 Testing OpenAI GPT-OSS via Amazon Bedrock")
    print("=" * 50)
    
    # Possible GPT-OSS model IDs in Bedrock
    gpt_oss_models = [
        "openai.gpt-oss-20b-v1:0",
        "openai.gpt-oss-120b-v1:0", 
        "openai/gpt-oss-20b",
        "openai/gpt-oss-120b",
        "openai.gpt-oss-20b",
        "openai.gpt-oss-120b"
    ]
    
    try:
        bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')
        print("✅ Bedrock client initialized")
        
        # Test article
        test_article = """
        Apple announced quarterly earnings with record iPhone sales of $69.7 billion, beating analyst expectations. 
        The company reported total revenue of $89.5 billion, up 2% year-over-year. 
        CEO Tim Cook highlighted strong international growth, particularly in emerging markets.
        Apple's services revenue reached $22.3 billion, growing 16% from the previous year.
        """
        
        for model_id in gpt_oss_models:
            try:
                print(f"\n🔄 Testing model ID: {model_id}")
                
                # Create prompt for GPT-OSS (similar to OpenAI chat format)
                messages = [
                    {
                        "role": "system",
                        "content": "You are an expert news summarizer. Create concise 2-3 sentence summaries of tech and business news articles."
                    },
                    {
                        "role": "user", 
                        "content": f"Summarize this article:\n\n{test_article}"
                    }
                ]
                
                payload = {
                    "messages": messages,
                    "max_tokens": 150,
                    "reasoning_effort": "low",  # Fast mode for GPT-OSS
                    "temperature": 0.3
                }
                
                response = bedrock_runtime.invoke_model(
                    modelId=model_id,
                    body=json.dumps(payload),
                    contentType='application/json'
                )
                
                response_body = json.loads(response['body'].read())
                
                # Parse GPT-OSS response format
                if 'choices' in response_body:
                    summary = response_body['choices'][0]['message']['content']
                elif 'generation' in response_body:
                    summary = response_body['generation']
                else:
                    summary = str(response_body)
                
                print(f"   ✅ SUCCESS with {model_id}!")
                print(f"   📝 Summary: {summary}")
                
                return {
                    'service': 'bedrock',
                    'model_id': model_id,
                    'working': True,
                    'summary': summary
                }
                
            except Exception as e:
                error_msg = str(e)
                print(f"   ❌ Failed with {model_id}: {error_msg}")
                
                if "AccessDenied" in error_msg:
                    print(f"   → Need Bedrock permissions for {model_id}")
                elif "does not exist" in error_msg:
                    print(f"   → Model {model_id} not available in Bedrock")
                continue
        
        print("\n❌ No GPT-OSS models working via Bedrock")
        return None
        
    except Exception as e:
        print(f"❌ Bedrock client error: {str(e)}")
        return None

def test_gpt_oss_sagemaker():
    """Test GPT-OSS models via SageMaker (US West)"""
    
    print("\n🧪 Testing OpenAI GPT-OSS via SageMaker")
    print("=" * 50)
    
    # Try US West (Oregon) where GPT-OSS is available
    regions_to_try = ['us-west-2', 'us-east-1']
    
    for region in regions_to_try:
        try:
            print(f"\n🌍 Testing region: {region}")
            
            # Try SageMaker JumpStart approach
            import sagemaker
            from sagemaker.jumpstart.model import JumpStartModel
            
            # Create session for the region
            boto_session = boto3.Session(region_name=region)
            sagemaker_session = sagemaker.Session(boto_session=boto_session)
            
            # Try GPT-OSS model IDs
            gpt_oss_models = [
                "openai-reasoning-gpt-oss-20b",
                "openai-reasoning-gpt-oss-120b"
            ]
            
            for model_id in gpt_oss_models:
                try:
                    print(f"   🔄 Testing {model_id} in {region}")
                    
                    model = JumpStartModel(
                        model_id=model_id,
                        sagemaker_session=sagemaker_session
                    )
                    
                    print(f"   ✅ Model instance created for {model_id}")
                    print(f"   💡 Model available but not deployed yet")
                    
                    return {
                        'service': 'sagemaker',
                        'region': region,
                        'model_id': model_id,
                        'available': True,
                        'needs_deployment': True
                    }
                    
                except Exception as e:
                    error_msg = str(e)
                    print(f"   ❌ {model_id}: {error_msg}")
                    
                    if "Invalid model ID" in error_msg:
                        print(f"   → {model_id} not available in {region}")
                    continue
            
        except Exception as e:
            print(f"   ❌ Region {region} failed: {str(e)}")
            continue
    
    return None

def check_existing_endpoints():
    """Check if you already have GPT-OSS endpoints deployed"""
    
    print("\n🔍 Checking for existing SageMaker endpoints...")
    
    regions = ['us-west-2', 'us-east-1']
    
    for region in regions:
        try:
            sagemaker_client = boto3.client('sagemaker', region_name=region)
            
            # List endpoints
            response = sagemaker_client.list_endpoints()
            endpoints = response.get('Endpoints', [])
            
            print(f"\n📋 Endpoints in {region}: {len(endpoints)}")
            
            gpt_oss_endpoints = []
            for endpoint in endpoints:
                endpoint_name = endpoint['EndpointName']
                if 'gpt' in endpoint_name.lower() or 'openai' in endpoint_name.lower():
                    gpt_oss_endpoints.append(endpoint)
                    print(f"   🎯 Found: {endpoint_name} (Status: {endpoint['EndpointStatus']})")
            
            if gpt_oss_endpoints:
                return {
                    'region': region,
                    'endpoints': gpt_oss_endpoints
                }
                
        except Exception as e:
            print(f"❌ Could not check {region}: {str(e)}")
    
    return None

def provide_next_steps(bedrock_result, sagemaker_result, endpoints_result):
    """Provide next steps based on test results"""
    
    print("\n" + "=" * 60)
    print("📊 TEST RESULTS & NEXT STEPS")
    print("=" * 60)
    
    if bedrock_result and bedrock_result.get('working'):
        print("🎉 OPTION 1: Amazon Bedrock (READY)")
        print(f"   ✅ Model: {bedrock_result['model_id']}")
        print("   ✅ Working and tested")
        print("   🚀 Can deploy Lambda functions immediately")
        print("   💡 Recommended: Use this approach")
        
        return {
            'recommended': 'bedrock',
            'model_id': bedrock_result['model_id'],
            'ready': True
        }
    
    elif endpoints_result:
        print("🎉 OPTION 2: Existing SageMaker Endpoint (READY)")
        print(f"   ✅ Region: {endpoints_result['region']}")
        print(f"   ✅ Endpoints: {len(endpoints_result['endpoints'])}")
        print("   🚀 Can use existing endpoint")
        
        return {
            'recommended': 'sagemaker_existing', 
            'region': endpoints_result['region'],
            'endpoints': endpoints_result['endpoints'],
            'ready': True
        }
    
    elif sagemaker_result and sagemaker_result.get('available'):
        print("🔧 OPTION 3: SageMaker Deployment (NEEDS SETUP)")
        print(f"   ✅ Region: {sagemaker_result['region']}")
        print(f"   ✅ Model: {sagemaker_result['model_id']}")
        print("   ⚠️  Needs deployment first")
        print("   🚀 Can deploy endpoint then Lambda functions")
        
        return {
            'recommended': 'sagemaker_deploy',
            'region': sagemaker_result['region'],
            'model_id': sagemaker_result['model_id'],
            'needs_deployment': True
        }
    
    else:
        print("❌ NO GPT-OSS ACCESS FOUND")
        print("💡 Possible solutions:")
        print("   1. Check Bedrock console for OpenAI model access")
        print("   2. Try deploying in us-west-2 region")
        print("   3. Contact AWS support about GPT-OSS availability")
        
        return {
            'recommended': None,
            'ready': False
        }

if __name__ == "__main__":
    print("🚀 Testing OpenAI GPT-OSS Model Access")
    print("Checking all possible access methods...")
    
    # Test all approaches
    bedrock_result = test_gpt_oss_bedrock()
    sagemaker_result = test_gpt_oss_sagemaker() 
    endpoints_result = check_existing_endpoints()
    
    # Provide recommendations
    next_steps = provide_next_steps(bedrock_result, sagemaker_result, endpoints_result)
    
    if next_steps['ready']:
        print(f"\n✅ GPT-OSS ACCESS CONFIRMED!")
        print(f"📋 Method: {next_steps['recommended']}")
        print("🚀 Ready to deploy complete infrastructure!")
    else:
        print("\n❌ GPT-OSS access needs configuration")
        print("💡 Follow the suggestions above to enable access")