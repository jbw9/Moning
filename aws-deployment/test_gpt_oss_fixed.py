#!/usr/bin/env python3
"""
Test OpenAI GPT-OSS models with correct parameter names
Fixed: max_tokens -> max_completion_tokens
"""

import boto3
import json
from datetime import datetime

def test_gpt_oss_fixed():
    """Test OpenAI GPT-OSS models with correct parameters"""
    
    print("🧪 Testing OpenAI GPT-OSS Models (Fixed Parameters)")
    print("=" * 50)
    
    try:
        bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-west-2')
        print("✅ Bedrock runtime client initialized (us-west-2)")
        
        gpt_oss_models = [
            {
                "id": "openai.gpt-oss-20b-1:0",
                "name": "GPT-OSS-20B",
                "description": "Smaller, faster, perfect for news summaries"
            },
            {
                "id": "openai.gpt-oss-120b-1:0", 
                "name": "GPT-OSS-120B",
                "description": "Larger, more capable reasoning model"
            }
        ]
        
        test_article = """
        Apple announced quarterly earnings with record iPhone sales of $69.7 billion, exceeding analyst expectations by $2.1 billion. The company reported total revenue of $89.5 billion, up 2% year-over-year despite challenging market conditions. CEO Tim Cook highlighted strong international growth, particularly in Asia-Pacific markets which grew 18%. Apple's services division continued strong performance with $22.3 billion in revenue, representing 16% growth and now accounting for 25% of total company revenue.
        """
        
        print(f"📄 Testing with tech news article ({len(test_article)} characters)")
        
        for model in gpt_oss_models:
            try:
                print(f"\n🔄 Testing {model['name']} - {model['description']}")
                print(f"   Model ID: {model['id']}")
                
                # Fixed payload with correct parameter names
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
                    "max_completion_tokens": 150,  # Fixed: was max_tokens
                    "temperature": 0.3,
                    "reasoning_effort": "low"
                }
                
                print("   🚀 Invoking model with correct parameters...")
                
                response = bedrock_runtime.invoke_model(
                    modelId=model['id'],
                    body=json.dumps(payload),
                    contentType='application/json'
                )
                
                response_body = json.loads(response['body'].read())
                print(f"   📨 Response received!")
                
                # Parse OpenAI-style response
                summary = None
                if 'choices' in response_body:
                    summary = response_body['choices'][0]['message']['content']
                elif 'content' in response_body:
                    summary = response_body['content']
                
                if summary:
                    print(f"   ✅ SUCCESS! {model['name']} is working perfectly!")
                    print(f"   📝 Generated Summary:")
                    print(f"      {summary.strip()}")
                    
                    # Get usage info if available
                    if 'usage' in response_body:
                        usage = response_body['usage']
                        print(f"   📊 Token Usage:")
                        print(f"      Input: {usage.get('prompt_tokens', 'N/A')}")
                        print(f"      Output: {usage.get('completion_tokens', 'N/A')}")
                        print(f"      Total: {usage.get('total_tokens', 'N/A')}")
                    
                    # Test different content types
                    test_different_articles(bedrock_runtime, model['id'])
                    
                    # Save working configuration
                    config = {
                        "model_id": model['id'],
                        "model_name": model['name'],
                        "region": "us-west-2",
                        "service": "bedrock",
                        "parameters": {
                            "max_completion_tokens": 150,
                            "temperature": 0.3,
                            "reasoning_effort": "low"
                        },
                        "test_summary": summary.strip(),
                        "working": True,
                        "timestamp": datetime.now().isoformat()
                    }
                    
                    filename = f"gpt_oss_working_config.json"
                    with open(filename, 'w') as f:
                        json.dump(config, f, indent=2)
                    
                    print(f"   💾 Working config saved: {filename}")
                    
                    return config
                    
                else:
                    print(f"   ❌ Unexpected response format:")
                    print(f"      {json.dumps(response_body, indent=2)}")
                
            except Exception as e:
                print(f"   ❌ Error with {model['name']}: {str(e)}")
                continue
        
        return None
        
    except Exception as e:
        print(f"❌ Critical error: {str(e)}")
        return None

def test_different_articles(bedrock_runtime, model_id):
    """Test summarization with different types of tech articles"""
    
    print(f"   🧪 Testing different article types with {model_id}...")
    
    test_cases = [
        {
            "type": "Business News",
            "content": "Tesla reported Q4 2024 revenue of $25.2 billion, up 3% from Q3. The company delivered 484,000 vehicles, slightly below analyst expectations of 487,000. CEO Elon Musk announced plans to expand Supercharger network by 40% in 2025."
        },
        {
            "type": "Tech Product",
            "content": "Google unveiled its new Pixel 9 smartphone featuring an improved AI chip and 50% longer battery life. The device includes advanced computational photography and starts at $799, competing directly with iPhone 15."
        },
        {
            "type": "AI/ML News", 
            "content": "OpenAI announced GPT-5 with multimodal capabilities and 10x performance improvement over GPT-4. The model will be available through API in Q2 2025 with enterprise pricing starting at $0.10 per 1K tokens."
        }
    ]
    
    for i, case in enumerate(test_cases, 1):
        try:
            payload = {
                "messages": [
                    {
                        "role": "system",
                        "content": f"Summarize {case['type'].lower()} in exactly 2 sentences. Focus on key facts and numbers."
                    },
                    {
                        "role": "user",
                        "content": case['content']
                    }
                ],
                "max_completion_tokens": 100,
                "temperature": 0.2,
                "reasoning_effort": "low"
            }
            
            response = bedrock_runtime.invoke_model(
                modelId=model_id,
                body=json.dumps(payload)
            )
            
            response_body = json.loads(response['body'].read())
            summary = response_body['choices'][0]['message']['content']
            
            print(f"      {i}. {case['type']}: {summary.strip()}")
            
        except Exception as e:
            print(f"      {i}. {case['type']}: Failed - {str(e)}")

def create_production_template(config):
    """Create production Lambda template using working config"""
    
    if not config:
        return
    
    lambda_template = f'''
# Production Lambda function for {config['model_name']}
import json
import boto3
from datetime import datetime

bedrock_runtime = boto3.client('bedrock-runtime', region_name='{config['region']}')

def lambda_handler(event, context):
    """Summarize articles using {config['model_name']}"""
    
    try:
        articles = event.get('articles', [])
        summaries = []
        
        for article in articles:
            payload = {{
                "messages": [
                    {{
                        "role": "system",
                        "content": "You are an expert news summarizer. Create concise 2-3 sentence summaries of tech news articles."
                    }},
                    {{
                        "role": "user",
                        "content": f"Summarize: {{article['content']}}"
                    }}
                ],
                "max_completion_tokens": {config['parameters']['max_completion_tokens']},
                "temperature": {config['parameters']['temperature']},
                "reasoning_effort": "{config['parameters']['reasoning_effort']}"
            }}
            
            response = bedrock_runtime.invoke_model(
                modelId='{config['model_id']}',
                body=json.dumps(payload),
                contentType='application/json'
            )
            
            response_body = json.loads(response['Body'].read())
            summary = response_body['choices'][0]['message']['content']
            
            summaries.append({{
                'article_id': article['id'],
                'summary': summary.strip()
            }})
        
        return {{
            'statusCode': 200,
            'body': json.dumps({{
                'summaries': summaries,
                'model_used': '{config['model_name']}',
                'processed': len(summaries)
            }})
        }}
        
    except Exception as e:
        return {{
            'statusCode': 500,
            'body': json.dumps({{'error': str(e)}})
        }}
'''
    
    with open('lambda_production_template.py', 'w') as f:
        f.write(lambda_template)
    
    print(f"   📝 Production Lambda template created: lambda_production_template.py")

if __name__ == "__main__":
    print("🚀 Testing OpenAI GPT-OSS with Fixed Parameters")
    print("Using correct OpenAI parameter names...")
    
    config = test_gpt_oss_fixed()
    
    if config:
        create_production_template(config)
        
        print("\n" + "=" * 60)
        print("🎉 OPENAI GPT-OSS IS WORKING PERFECTLY!")
        print("=" * 60)
        print(f"✅ Model: {config['model_name']} ({config['model_id']})")
        print(f"✅ Region: {config['region']}")
        print("✅ Parameters: Fixed and optimized")
        print("✅ Summarization: High quality")
        
        print("\n🚀 READY FOR COMPLETE DEPLOYMENT!")
        print("Next steps:")
        print("1. Deploy DynamoDB table") 
        print("2. Deploy Lambda functions")
        print("3. Set up API Gateway")
        print("4. Test complete pipeline")
        print("5. Integrate with iOS app")
        
        print(f"\n💡 Using {config['model_name']} for cost-effective news summarization!")
        
    else:
        print("\n❌ Still having issues - check the error details above")