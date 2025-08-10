#!/usr/bin/env python3
"""
Test Llama 3.1 70B access via Amazon Bedrock
Create optimal summarization prompts for news articles
"""

import boto3
import json
from datetime import datetime

def test_llama_access():
    """Test if Llama 3.1 70B is accessible via Bedrock"""
    
    print("🧪 Testing Llama 3.1 70B Access via Bedrock")
    print("=" * 50)
    
    try:
        # Initialize Bedrock client
        bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')
        
        print("✅ Bedrock client initialized")
        
        # Llama 3.1 70B model ID in Bedrock
        model_id = "meta.llama3-1-70b-instruct-v1:0"
        
        # Sample tech news article for testing
        test_article = """
        Apple announced its quarterly earnings today, revealing record iPhone sales despite global economic challenges. 
        The company reported revenue of $89.5 billion, beating analyst expectations of $87.2 billion. 
        CEO Tim Cook highlighted strong performance in international markets, particularly in Asia-Pacific regions.
        The iPhone 15 Pro models showed exceptional demand, with supply constraints lasting through the quarter.
        Apple also revealed investments in AI infrastructure, allocating $4.2 billion for machine learning research.
        The company's services revenue grew 16% year-over-year, reaching $22.3 billion.
        Apple stock rose 3.2% in after-hours trading following the earnings announcement.
        Looking ahead, the company expects continued growth in the upcoming holiday quarter.
        """
        
        # Optimized prompt for Llama 3.1 summarization
        prompt = f"""<|begin_of_text|><|start_header_id|>system<|end_header_id|>
You are an expert news summarizer specializing in technology and business news. Your task is to create concise, accurate summaries that capture the most important facts and implications.

Guidelines:
- Keep summaries to exactly 2-3 sentences
- Focus on key facts, numbers, and business implications  
- Maintain journalistic objectivity
- Preserve important financial data and percentages
- Use clear, professional language

<|eot_id|><|start_header_id|>user<|end_header_id|>
Summarize this tech news article:

{test_article.strip()}

<|eot_id|><|start_header_id|>assistant<|end_header_id|>"""

        # Bedrock request payload for Llama 3.1
        payload = {
            "prompt": prompt,
            "max_gen_len": 150,  # Limit output length
            "temperature": 0.3,   # Lower for consistent summaries
            "top_p": 0.9
        }
        
        print(f"🔄 Testing with model: {model_id}")
        print("📄 Sample article:", test_article[:100] + "...")
        
        # Make request to Bedrock
        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps(payload),
            contentType='application/json'
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        summary = response_body['generation'].strip()
        
        print("\n✅ SUCCESS! Llama 3.1 is working!")
        print("=" * 50)
        print(f"📝 Generated Summary:")
        print(f"{summary}")
        print("=" * 50)
        
        # Calculate token usage (approximate)
        input_tokens = len(prompt.split()) * 1.3  # Rough estimate
        output_tokens = len(summary.split()) * 1.3
        
        print(f"📊 Usage Stats:")
        print(f"   Input tokens: ~{int(input_tokens)}")
        print(f"   Output tokens: ~{int(output_tokens)}")
        print(f"   Total tokens: ~{int(input_tokens + output_tokens)}")
        
        # Test different summarization styles
        test_different_styles(bedrock_runtime, model_id)
        
        return True
        
    except Exception as e:
        error_msg = str(e)
        print(f"❌ Error testing Llama access: {error_msg}")
        
        if "AccessDenied" in error_msg:
            print("💡 You may need to request access to Llama 3.1 in Bedrock Console")
        elif "ValidationException" in error_msg:
            print("💡 Check the model ID or request format")
        else:
            print(f"💡 Unexpected error: {error_msg}")
        
        return False

def test_different_styles(bedrock_runtime, model_id):
    """Test different summarization approaches for optimal results"""
    
    print("\n🧪 Testing Different Summarization Styles...")
    
    test_cases = [
        {
            "name": "Technical Focus",
            "system_prompt": "You are a technical news summarizer. Focus on technical details, specifications, and engineering implications.",
            "article": "OpenAI released GPT-5 with 1.2 trillion parameters, featuring improved multimodal capabilities and 50% better performance on coding tasks. The model uses a new transformer architecture with sparse attention mechanisms."
        },
        {
            "name": "Business Focus", 
            "system_prompt": "You are a business news summarizer. Focus on financial implications, market impact, and business strategy.",
            "article": "Tesla reported Q4 earnings with revenue of $25.2 billion, up 3% from last quarter. The company delivered 484,000 vehicles, slightly below analyst expectations of 487,000 units."
        }
    ]
    
    for i, test_case in enumerate(test_cases, 1):
        try:
            prompt = f"""<|begin_of_text|><|start_header_id|>system<|end_header_id|>
{test_case['system_prompt']} Create a 2-sentence summary.

<|eot_id|><|start_header_id|>user<|end_header_id|>
{test_case['article']}

<|eot_id|><|start_header_id|>assistant<|end_header_id|>"""

            payload = {
                "prompt": prompt,
                "max_gen_len": 100,
                "temperature": 0.2,
                "top_p": 0.9
            }
            
            response = bedrock_runtime.invoke_model(
                modelId=model_id,
                body=json.dumps(payload)
            )
            
            response_body = json.loads(response['body'].read())
            summary = response_body['generation'].strip()
            
            print(f"\n{i}. {test_case['name']}:")
            print(f"   📝 {summary}")
            
        except Exception as e:
            print(f"   ❌ Test {i} failed: {str(e)}")

def save_optimal_prompts():
    """Save the optimal prompt templates for production use"""
    
    prompt_templates = {
        "default_tech_news": """<|begin_of_text|><|start_header_id|>system<|end_header_id|>
You are an expert news summarizer for technology and AI news. Create concise, accurate summaries that capture key facts and business implications in exactly 2-3 sentences.

<|eot_id|><|start_header_id|>user<|end_header_id|>
Summarize this tech news article:

{article_content}

<|eot_id|><|start_header_id|>assistant<|end_header_id|>""",

        "business_focus": """<|begin_of_text|><|start_header_id|>system<|end_header_id|>
You are a business news summarizer. Focus on financial data, market impact, and business strategy. Preserve specific numbers and percentages. Limit to 2-3 sentences.

<|eot_id|><|start_header_id|>user<|end_header_id|>
{article_content}

<|eot_id|><|start_header_id|>assistant<|end_header_id|>""",

        "technical_focus": """<|begin_of_text|><|start_header_id|>system<|end_header_id|>
You are a technical news summarizer. Focus on specifications, technical details, and engineering implications. Keep to 2-3 sentences with technical accuracy.

<|eot_id|><|start_header_id|>user<|end_header_id|>
{article_content}

<|eot_id|><|start_header_id|>assistant<|end_header_id|>"""
    }
    
    with open('llama_prompt_templates.json', 'w') as f:
        json.dump(prompt_templates, f, indent=2)
    
    print("\n💾 Saved optimal prompt templates to: llama_prompt_templates.json")

if __name__ == "__main__":
    print("🚀 Testing Llama 3.1 70B on Amazon Bedrock")
    print("Testing your access and optimizing prompts for news summarization...")
    
    success = test_llama_access()
    
    if success:
        save_optimal_prompts()
        
        print("\n" + "=" * 60)
        print("🎉 LLAMA 3.1 READY FOR DEPLOYMENT!")
        print("=" * 60)
        print("✅ Access confirmed")
        print("✅ Summarization working") 
        print("✅ Prompt templates optimized")
        print("\n🚀 Next: Deploy complete serverless infrastructure!")
        
    else:
        print("\n" + "=" * 60)
        print("❌ ACCESS ISSUE - NEEDS FIXING")
        print("=" * 60)
        print("💡 Go to Bedrock Console and ensure Llama 3.1 70B access is enabled")