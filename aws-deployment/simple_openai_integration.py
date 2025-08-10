#!/usr/bin/env python3
"""
Simple OpenAI API integration for article summarization
Much simpler and more cost-effective for your use case
"""

import os
from openai import OpenAI
import json

def setup_openai_summarization():
    """
    Cost analysis for your use case:
    - 300 articles/day × 30 days = 9,000 articles/month
    - Average article: ~2,000 tokens, summary: ~100 tokens
    - Total tokens: ~18,900,000 input + 900,000 output = ~19.8M tokens/month
    - Cost with GPT-4o-mini: ~$3-5/month
    - Cost with GPT-3.5-turbo: ~$1-2/month
    
    Compare to AWS SageMaker: $50-100/month + complexity
    """
    
    print("🚀 OpenAI API Integration Setup")
    print("=" * 50)
    
    # Check if OpenAI API key is set
    api_key = os.getenv('OPENAI_API_KEY')
    
    if not api_key:
        print("❌ OpenAI API key not found!")
        print("\n📋 To set up:")
        print("1. Go to: https://platform.openai.com/api-keys")
        print("2. Create a new API key")
        print("3. Add to your environment:")
        print("   export OPENAI_API_KEY='your-key-here'")
        return False
    
    try:
        # Initialize OpenAI client
        client = OpenAI(api_key=api_key)
        
        # Test with a sample article
        test_article = """
        Apple announced today that its new iPhone 16 Pro will feature an advanced camera system 
        with improved low-light performance and AI-enhanced photography capabilities. The device 
        will also include a more powerful A18 Bionic chip that enables faster processing speeds 
        and better energy efficiency. Pre-orders begin next Friday with general availability 
        expected in late October. The starting price will be $1,199 for the base 256GB model.
        """
        
        print("✅ OpenAI client initialized")
        print("🧪 Testing summarization...")
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",  # Most cost-effective for summarization
            messages=[
                {
                    "role": "system",
                    "content": "You are an expert news summarizer. Create concise, accurate summaries of tech news articles in 2-3 sentences. Focus on key facts and implications."
                },
                {
                    "role": "user", 
                    "content": f"Summarize this article:\n\n{test_article}"
                }
            ],
            max_tokens=150,
            temperature=0.3  # Lower temperature for more consistent summaries
        )
        
        summary = response.choices[0].message.content
        
        print(f"📄 Original: {len(test_article)} characters")
        print(f"📝 Summary: {summary}")
        print(f"💰 Tokens used: {response.usage.total_tokens}")
        print(f"💵 Estimated cost: ${response.usage.total_tokens * 0.00015 / 1000:.6f}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error testing OpenAI API: {str(e)}")
        return False

def create_lambda_with_openai():
    """Create AWS Lambda function that uses OpenAI API"""
    
    lambda_code = '''
import json
import os
from openai import OpenAI
import boto3
from datetime import datetime, timedelta

# Initialize clients
openai_client = OpenAI(api_key=os.environ['OPENAI_API_KEY'])
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('article-summaries')

def lambda_handler(event, context):
    """
    Process articles using OpenAI API and cache in DynamoDB
    Much simpler than managing SageMaker endpoints
    """
    try:
        articles = event.get('articles', [])
        summaries_generated = 0
        
        for article in articles:
            # Check cache first
            cached = get_cached_summary(article['id'])
            if cached:
                continue
            
            # Generate summary using OpenAI
            summary = generate_summary_openai(article['content'])
            
            # Cache result
            cache_summary(article['id'], summary, article.get('title', ''))
            summaries_generated += 1
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'summaries_generated': summaries_generated,
                'total_articles': len(articles)
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def generate_summary_openai(content):
    """Generate summary using OpenAI API"""
    response = openai_client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "You are an expert news summarizer. Create concise, accurate summaries of tech news articles in 2-3 sentences."
            },
            {
                "role": "user",
                "content": f"Summarize this article:\\n\\n{content[:2000]}"  # Truncate long articles
            }
        ],
        max_tokens=150,
        temperature=0.3
    )
    
    return response.choices[0].message.content

def get_cached_summary(article_id):
    """Check DynamoDB cache"""
    try:
        response = table.get_item(Key={'article_id': article_id})
        if 'Item' in response:
            item = response['Item']
            created_at = datetime.fromisoformat(item['created_at'])
            if datetime.utcnow() - created_at < timedelta(hours=24):
                return item['summary']
        return None
    except Exception:
        return None

def cache_summary(article_id, summary, title=""):
    """Cache in DynamoDB"""
    table.put_item(
        Item={
            'article_id': article_id,
            'summary': summary,
            'title': title,
            'created_at': datetime.utcnow().isoformat(),
            'ttl': int((datetime.utcnow() + timedelta(days=30)).timestamp())
        }
    )
'''
    
    print("📝 Lambda function code generated")
    print("💡 This approach is much simpler than SageMaker!")
    
    return lambda_code

if __name__ == "__main__":
    
    print("🔍 Checking OpenAI API setup...")
    
    if setup_openai_summarization():
        print("\n✅ OpenAI integration working!")
        print("\n💡 Recommendation: Use this instead of complex AWS ML services")
        print("   - 10x simpler to implement")
        print("   - More cost-effective for your volume")  
        print("   - Better summarization quality")
        print("   - No infrastructure management")
        
        # Generate Lambda code
        lambda_code = create_lambda_with_openai()
        
        with open('lambda_openai_summarizer.py', 'w') as f:
            f.write(lambda_code)
        
        print("\n📁 Created: lambda_openai_summarizer.py")
        print("🚀 Ready to deploy simplified solution!")
        
    else:
        print("\n❌ Set up OpenAI API key first")
        print("💡 This is still the recommended approach for your use case")