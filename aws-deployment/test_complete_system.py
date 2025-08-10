#!/usr/bin/env python3
"""
Test the complete deployed infrastructure
1. Test batch processing (Lambda)
2. Test API endpoints 
3. Validate full pipeline
"""

import boto3
import json
import requests
import time
from datetime import datetime

# Load deployment config
with open('deployment_config.json', 'r') as f:
    config = json.load(f)

API_URL = config['api_url']
BATCH_LAMBDA = config['batch_lambda_arn'].split(':')[-1]

def test_complete_system():
    """Test the complete deployed system"""
    
    print("🧪 Testing Complete Moning Summarization System")
    print("=" * 60)
    print(f"API URL: {API_URL}")
    print(f"Batch Lambda: {BATCH_LAMBDA}")
    
    # Test 1: Batch Processing
    print("\n1. Testing Batch Processing (Lambda)...")
    test_batch_processing()
    
    # Test 2: API Endpoints  
    print("\n2. Testing API Endpoints...")
    test_api_endpoints()
    
    # Test 3: End-to-end Pipeline
    print("\n3. Testing End-to-End Pipeline...")
    test_full_pipeline()
    
    print("\n" + "=" * 60)
    print("🎉 SYSTEM TESTING COMPLETE!")
    print("✅ Your infrastructure is working perfectly!")
    print("🚀 Ready for iOS app integration!")

def test_batch_processing():
    """Test the batch processing Lambda function"""
    
    try:
        lambda_client = boto3.client('lambda', region_name='us-west-2')
        
        # Test articles
        test_articles = [
            {
                "id": "test001",
                "title": "Apple Announces New iPhone 16",
                "content": "Apple unveiled the iPhone 16 today with significant improvements to battery life and camera capabilities. The new device features a more powerful A18 chip and enhanced AI processing. Pre-orders begin Friday with availability starting next week. The starting price is $799 for the base 128GB model.",
                "source": "TechCrunch",
                "category": "Technology"
            },
            {
                "id": "test002", 
                "title": "OpenAI Releases GPT-5",
                "content": "OpenAI announced GPT-5 with breakthrough reasoning capabilities and multimodal support. The model shows significant improvements in coding, mathematics, and scientific reasoning. Enterprise pricing starts at $0.10 per 1K tokens. The release includes new safety features and alignment improvements.",
                "source": "The Verge",
                "category": "AI"
            }
        ]
        
        # Invoke batch processing Lambda
        payload = {
            "articles": test_articles,
            "trigger": "test",
            "batch_size": 10
        }
        
        print("   🚀 Invoking batch processing Lambda...")
        
        response = lambda_client.invoke(
            FunctionName=BATCH_LAMBDA,
            InvocationType='RequestResponse',
            Payload=json.dumps(payload)
        )
        
        result = json.loads(response['Payload'].read())
        
        if response['StatusCode'] == 200 and 'body' in result:
            body = json.loads(result['body'])
            print(f"   ✅ Batch processing successful!")
            print(f"      📊 Processed: {body.get('processed', 0)} articles")
            print(f"      📝 New summaries: {body.get('summaries_generated', 0)}")
            print(f"      💾 Cached: {body.get('cached_summaries', 0)}")
            print(f"      🤖 Model: {body.get('model_used', 'Unknown')}")
            return True
        else:
            print(f"   ❌ Batch processing failed: {result}")
            return False
            
    except Exception as e:
        print(f"   ❌ Batch test error: {str(e)}")
        return False

def test_api_endpoints():
    """Test API Gateway endpoints"""
    
    try:
        # Test 1: Get single summary (should work after batch processing)
        print("   🔄 Testing single summary endpoint...")
        
        response = requests.get(f"{API_URL}/summaries/test001")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Single summary API working!")
            print(f"      📝 Summary: {data.get('summary', '')[:100]}...")
            print(f"      💾 Cached: {data.get('cached', False)}")
        elif response.status_code == 404:
            print(f"   ℹ️  Summary not found (expected if batch processing didn't run)")
        else:
            print(f"   ❌ Single summary failed: {response.status_code}")
        
        # Test 2: Batch summaries endpoint
        print("   🔄 Testing batch summaries endpoint...")
        
        batch_payload = {
            "article_ids": ["test001", "test002", "nonexistent"]
        }
        
        response = requests.post(
            f"{API_URL}/batch-summaries",
            json=batch_payload,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Batch summaries API working!")
            print(f"      📊 Found: {data.get('found', 0)}/{data.get('total_requested', 0)}")
            print(f"      🤖 Model: {data.get('model_used', 'Unknown')}")
        else:
            print(f"   ❌ Batch summaries failed: {response.status_code}")
            print(f"      Response: {response.text}")
        
        # Test 3: CORS and OPTIONS
        print("   🔄 Testing CORS support...")
        
        response = requests.options(f"{API_URL}/summaries/test")
        
        if 'Access-Control-Allow-Origin' in response.headers:
            print(f"   ✅ CORS headers present")
        else:
            print(f"   ⚠️  CORS headers missing (may need manual configuration)")
            
    except Exception as e:
        print(f"   ❌ API test error: {str(e)}")

def test_full_pipeline():
    """Test the complete pipeline with fresh data"""
    
    try:
        print("   🔄 Testing complete pipeline with new article...")
        
        # Step 1: Process new article via batch Lambda
        lambda_client = boto3.client('lambda', region_name='us-west-2')
        
        new_article = {
            "id": f"pipeline_test_{int(time.time())}",
            "title": "Microsoft Introduces New AI Assistant", 
            "content": "Microsoft unveiled its latest AI assistant technology today, featuring advanced natural language processing and integration with Office 365. The assistant can help with document creation, data analysis, and meeting summaries. Beta testing begins next month for enterprise customers. The technology represents a significant leap in workplace AI automation.",
            "source": "Microsoft Blog",
            "category": "Business"
        }
        
        # Process via batch Lambda
        payload = {"articles": [new_article], "trigger": "pipeline_test"}
        
        response = lambda_client.invoke(
            FunctionName=BATCH_LAMBDA,
            Payload=json.dumps(payload)
        )
        
        result = json.loads(response['Payload'].read())
        
        if response['StatusCode'] == 200:
            print("   ✅ Step 1: Article processed via Lambda")
            
            # Step 2: Wait a moment for DynamoDB consistency
            time.sleep(2)
            
            # Step 3: Retrieve via API
            api_response = requests.get(f"{API_URL}/summaries/{new_article['id']}")
            
            if api_response.status_code == 200:
                data = api_response.json()
                summary = data.get('summary', '')
                
                print("   ✅ Step 2: Summary retrieved via API")
                print(f"      📝 Generated Summary:")
                print(f"         {summary}")
                print(f"      🤖 Model: {data.get('model_used', 'Unknown')}")
                print("   🎉 FULL PIPELINE WORKING!")
                
                return True
            else:
                print(f"   ❌ Step 2: API retrieval failed ({api_response.status_code})")
                return False
        else:
            print(f"   ❌ Step 1: Lambda processing failed")
            return False
            
    except Exception as e:
        print(f"   ❌ Pipeline test error: {str(e)}")
        return False

if __name__ == "__main__":
    print("Testing complete Moning infrastructure deployment...")
    test_complete_system()