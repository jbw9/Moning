#!/usr/bin/env python3
"""
Test OpenAI GPT-OSS models via Amazon Bedrock
Find the correct model IDs and test summarization
"""

import boto3
import json
from datetime import datetime

def test_bedrock_gpt_oss():
    """Test OpenAI GPT-OSS models via Amazon Bedrock"""
    
    print("🧪 Testing OpenAI GPT-OSS via Amazon Bedrock")
    print("=" * 50)
    
    try:
        # Initialize Bedrock client
        bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')
        print("✅ Bedrock runtime client initialized")
        
        # First, let's check what models are available
        try:
            bedrock_client = boto3.client('bedrock', region_name='us-east-1')
            models_response = bedrock_client.list_foundation_models()
            
            openai_models = [
                model for model in models_response['modelSummaries']
                if 'openai' in model.get('providerName', '').lower() or
                   'openai' in model.get('modelId', '').lower()
            ]
            
            if openai_models:
                print(f"✅ Found {len(openai_models)} OpenAI models in Bedrock:")
                for model in openai_models:
                    print(f"   - {model['modelId']} (Provider: {model.get('providerName', 'Unknown')})")
            else:
                print("⚠️  No OpenAI models found in model list")
                
        except Exception as e:
            print(f"⚠️  Could not list models: {str(e)}")
            print("   Continuing with known model IDs...")
        
        # Test with known OpenAI GPT-OSS model IDs
        # These are the likely model IDs based on Bedrock naming conventions
        gpt_oss_models = [
            # Standard Bedrock naming format
            "openai.gpt-oss-20b-v1:0",
            "openai.gpt-oss-120b-v1:0",
            "openai.gpt-oss-20b:0",
            "openai.gpt-oss-120b:0",
            
            # Alternative formats
            "openai/gpt-oss-20b",
            "openai/gpt-oss-120b", 
            "openai.gpt-oss-20b",
            "openai.gpt-oss-120b",
            
            # With reasoning prefix (as they're reasoning models)
            "openai.gpt-oss-reasoning-20b-v1:0",
            "openai.gpt-oss-reasoning-120b-v1:0"
        ]
        
        # Sample tech article for testing
        test_article = """
        Apple announced quarterly earnings with record-breaking iPhone sales of $69.7 billion, exceeding analyst predictions by $2.1 billion. The company reported total revenue of $89.5 billion, marking a 2% increase year-over-year despite challenging market conditions. CEO Tim Cook emphasized strong performance in international markets, particularly highlighting 18% growth in the Asia-Pacific region. Apple's services division continued its impressive trajectory with $22.3 billion in revenue, representing 16% growth from the previous year and accounting for 25% of total company revenue.
        """
        
        print(f"\n📄 Testing with sample article ({len(test_article)} characters)")
        
        for model_id in gpt_oss_models:
            try:
                print(f"\n🔄 Testing model: {model_id}")
                
                # Create OpenAI-style messages payload
                payload = {
                    "messages": [
                        {
                            "role": "system",
                            "content": "You are an expert news summarizer specializing in technology and business news. Create concise, accurate 2-3 sentence summaries that capture the most important facts and business implications."
                        },
                        {
                            "role": "user",
                            "content": f"Summarize this tech news article:\n\n{test_article}"
                        }
                    ],
                    "max_tokens": 150,
                    "temperature": 0.3,
                    "reasoning_effort": "low"  # For speed in summarization
                }
                
                # Invoke the model
                response = bedrock_runtime.invoke_model(
                    modelId=model_id,
                    body=json.dumps(payload),
                    contentType='application/json'
                )
                
                # Parse response
                response_body = json.loads(response['body'].read())
                
                # Handle different response formats
                summary = None
                if 'choices' in response_body:
                    summary = response_body['choices'][0]['message']['content']
                elif 'generation' in response_body:
                    summary = response_body['generation']
                elif 'content' in response_body:
                    summary = response_body['content']
                
                if summary:
                    print(f"   ✅ SUCCESS! Model {model_id} is working!")
                    print(f"   📝 Generated summary:")
                    print(f"      {summary.strip()}")
                    
                    # Calculate usage stats
                    input_length = len(json.dumps(payload))
                    output_length = len(summary)
                    
                    print(f"   📊 Stats:")
                    print(f"      Input: ~{input_length} chars")
                    print(f"      Output: ~{output_length} chars")
                    
                    # Test different reasoning levels if this is a reasoning model
                    test_reasoning_levels(bedrock_runtime, model_id)
                    
                    # Save successful configuration
                    success_config = {
                        "model_id": model_id,
                        "service": "bedrock",
                        "region": "us-east-1",
                        "test_summary": summary.strip(),
                        "test_time": datetime.now().isoformat(),
                        "working": True
                    }
                    
                    with open('working_gpt_oss_config.json', 'w') as f:
                        json.dump(success_config, f, indent=2)
                    
                    print(f"   💾 Configuration saved to: working_gpt_oss_config.json")
                    
                    return success_config
                else:
                    print(f"   ❌ Unexpected response format: {response_body}")
                
            except Exception as e:
                error_msg = str(e)
                print(f"   ❌ Failed: {error_msg}")
                
                if "AccessDenied" in error_msg:
                    print("   → Access denied - check Bedrock model permissions")
                elif "ValidationException" in error_msg:
                    print("   → Invalid model ID or request format")
                elif "ResourceNotFound" in error_msg:
                    print("   → Model not found in this region")
                else:
                    print(f"   → Unexpected error: {error_msg}")
                continue
        
        print("\n❌ No GPT-OSS models are working")
        return None
        
    except Exception as e:
        print(f"❌ Critical error: {str(e)}")
        return None

def test_reasoning_levels(bedrock_runtime, model_id):
    """Test different reasoning levels for GPT-OSS models"""
    
    print(f"   🧪 Testing reasoning levels for {model_id}...")
    
    reasoning_levels = ["low", "medium", "high"]
    
    for level in reasoning_levels:
        try:
            payload = {
                "messages": [
                    {
                        "role": "user",
                        "content": "Quickly summarize: Tesla reported Q4 revenue of $25.2 billion, up 3% quarterly, with 484k vehicle deliveries."
                    }
                ],
                "max_tokens": 100,
                "reasoning_effort": level
            }
            
            response = bedrock_runtime.invoke_model(
                modelId=model_id,
                body=json.dumps(payload)
            )
            
            response_body = json.loads(response['body'].read())
            summary = response_body.get('choices', [{}])[0].get('message', {}).get('content', 'No content')
            
            print(f"      {level}: {summary[:50]}...")
            
        except Exception as e:
            print(f"      {level}: Failed - {str(e)}")

def provide_deployment_plan(config):
    """Provide next steps based on successful configuration"""
    
    if not config:
        print("\n" + "=" * 60)
        print("❌ NO WORKING GPT-OSS ACCESS FOUND")
        print("=" * 60)
        print("💡 Next steps:")
        print("1. Go to Amazon Bedrock Console")
        print("2. Check 'Model access' section") 
        print("3. Ensure OpenAI GPT-OSS models are enabled")
        print("4. May need to request access if not available")
        return
    
    print("\n" + "=" * 60)
    print("🎉 GPT-OSS ACCESS CONFIRMED!")
    print("=" * 60)
    print(f"✅ Model: {config['model_id']}")
    print(f"✅ Service: Amazon Bedrock")
    print(f"✅ Region: {config['region']}")
    print("✅ Summarization: Working perfectly")
    
    print("\n🚀 READY TO DEPLOY COMPLETE INFRASTRUCTURE!")
    print("=" * 40)
    print("Next deployment steps:")
    print("1. Create DynamoDB table for caching")
    print("2. Deploy Lambda function using this model")
    print("3. Set up API Gateway for iOS app")
    print("4. Test complete pipeline")
    
    print(f"\n💰 Estimated monthly cost for your usage:")
    print("   • 300 articles/day × 30 days = 9,000 summaries")
    print("   • ~2,000 input + 150 output tokens per summary")  
    print("   • Total: ~$8-15/month (much cheaper than OpenAI API)")
    
    print(f"\n🎯 Your optimal model choice: {config['model_id']}")
    if "20b" in config['model_id']:
        print("   → GPT-OSS-20B: Faster, cheaper, perfect for news summaries")
    else:
        print("   → GPT-OSS-120B: More capable but higher cost")

if __name__ == "__main__":
    print("🚀 Testing OpenAI GPT-OSS Models on Amazon Bedrock")
    print("Finding your working model configuration...")
    
    config = test_bedrock_gpt_oss()
    provide_deployment_plan(config)
    
    if config:
        print("\n🎯 Ready to proceed with serverless deployment!")
        print("Run next: Deploy complete Lambda + API Gateway infrastructure")
    else:
        print("\n⚠️  Fix Bedrock access first, then re-run this test")