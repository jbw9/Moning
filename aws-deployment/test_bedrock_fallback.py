#!/usr/bin/env python3
"""
Test available Bedrock models while waiting for GPT-OSS access
Use Claude 3.5 Haiku as backup option
"""

import boto3
import json

def test_available_bedrock_models():
    """Test what models are actually available in Bedrock"""
    
    print("🔍 Testing Available Bedrock Models")
    print("=" * 40)
    
    try:
        bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')
        
        # Models that should definitely be available
        fallback_models = [
            {
                "id": "anthropic.claude-3-5-haiku-20241022-v1:0",
                "name": "Claude 3.5 Haiku",
                "format": "anthropic"
            },
            {
                "id": "anthropic.claude-3-haiku-20240307-v1:0", 
                "name": "Claude 3 Haiku",
                "format": "anthropic"
            },
            {
                "id": "amazon.nova-micro-v1:0",
                "name": "Amazon Nova Micro",
                "format": "amazon"
            },
            {
                "id": "amazon.nova-lite-v1:0",
                "name": "Amazon Nova Lite", 
                "format": "amazon"
            }
        ]
        
        test_article = """
        Apple announced quarterly earnings with record iPhone sales of $69.7 billion, beating expectations. 
        The company reported total revenue of $89.5 billion, up 2% year-over-year.
        CEO Tim Cook highlighted strong international growth and services revenue of $22.3 billion.
        """
        
        working_models = []
        
        for model in fallback_models:
            try:
                print(f"\n🔄 Testing {model['name']} ({model['id']})")
                
                if model['format'] == 'anthropic':
                    payload = {
                        "messages": [
                            {
                                "role": "user",
                                "content": f"Summarize this in 2-3 sentences:\n\n{test_article}"
                            }
                        ],
                        "max_tokens": 150,
                        "temperature": 0.3,
                        "anthropic_version": "bedrock-2023-05-31"
                    }
                    
                elif model['format'] == 'amazon':
                    payload = {
                        "messages": [
                            {
                                "role": "user", 
                                "content": f"Summarize this tech news in 2-3 sentences:\n\n{test_article}"
                            }
                        ],
                        "inferenceConfig": {
                            "maxTokens": 150,
                            "temperature": 0.3
                        }
                    }
                
                response = bedrock_runtime.invoke_model(
                    modelId=model['id'],
                    body=json.dumps(payload)
                )
                
                response_body = json.loads(response['body'].read())
                
                # Parse different response formats
                summary = None
                if 'content' in response_body:
                    if isinstance(response_body['content'], list):
                        summary = response_body['content'][0].get('text', '')
                    else:
                        summary = response_body['content']
                elif 'message' in response_body:
                    summary = response_body['message']['content'][0]['text']
                elif 'output' in response_body:
                    summary = response_body['output']['message']['content'][0]['text']
                
                if summary:
                    print(f"   ✅ SUCCESS! {model['name']} working")
                    print(f"   📝 Summary: {summary[:100]}...")
                    
                    working_models.append({
                        'id': model['id'],
                        'name': model['name'],
                        'format': model['format'],
                        'sample_summary': summary
                    })
                else:
                    print(f"   ❌ Unexpected response format: {response_body}")
                
            except Exception as e:
                error_msg = str(e)
                print(f"   ❌ Failed: {error_msg}")
                
                if "AccessDenied" in error_msg:
                    print("   → Need to enable this model in Bedrock Console")
                elif "ValidationException" in error_msg:
                    print("   → Invalid request format")
                continue
        
        return working_models
        
    except Exception as e:
        print(f"❌ Bedrock error: {str(e)}")
        return []

def recommend_next_steps(working_models):
    """Recommend approach based on available models"""
    
    print("\n" + "=" * 60)
    print("📊 BEDROCK MODEL TEST RESULTS")
    print("=" * 60)
    
    if working_models:
        print(f"✅ Found {len(working_models)} working models:")
        
        best_model = None
        for model in working_models:
            print(f"   • {model['name']} - {model['id']}")
            
            # Prioritize Claude 3.5 Haiku (excellent for summarization)
            if "claude-3-5-haiku" in model['id'] and not best_model:
                best_model = model
            elif "claude-3-haiku" in model['id'] and not best_model:
                best_model = model
            elif "nova" in model['id'] and not best_model:
                best_model = model
        
        if best_model:
            print(f"\n🎯 RECOMMENDED MODEL: {best_model['name']}")
            print(f"   Model ID: {best_model['id']}")
            print("   💡 We can deploy with this while waiting for GPT-OSS access")
            
            # Save working configuration
            config = {
                "model_id": best_model['id'],
                "model_name": best_model['name'],
                "format": best_model['format'],
                "service": "bedrock",
                "region": "us-east-1",
                "ready_to_deploy": True
            }
            
            with open('bedrock_working_config.json', 'w') as f:
                json.dump(config, f, indent=2)
            
            print("   💾 Configuration saved to: bedrock_working_config.json")
            
            return config
    else:
        print("❌ No models are working")
        print("💡 You need to enable model access in Bedrock Console")
    
    print("\n🔧 NEXT STEPS:")
    print("1. Go to Bedrock Console → Model access")
    print("2. Enable Claude 3.5 Haiku (backup option)")
    print("3. Enable OpenAI GPT-OSS models (preferred)")
    print("4. Re-run test once access is granted")
    
    return None

if __name__ == "__main__":
    print("🧪 Testing Available Bedrock Models")
    print("Finding what we can use while waiting for GPT-OSS...")
    
    working_models = test_available_bedrock_models()
    config = recommend_next_steps(working_models)
    
    if config:
        print("\n🚀 READY TO DEPLOY!")
        print(f"Using: {config['model_name']}")
        print("Can switch to GPT-OSS later when access is enabled")
    else:
        print("\n⚠️  Enable model access in Bedrock Console first")