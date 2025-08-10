
# Production Lambda function for GPT-OSS-20B
import json
import boto3
from datetime import datetime

bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-west-2')

def lambda_handler(event, context):
    """Summarize articles using GPT-OSS-20B"""
    
    try:
        articles = event.get('articles', [])
        summaries = []
        
        for article in articles:
            payload = {
                "messages": [
                    {
                        "role": "system",
                        "content": "You are an expert news summarizer. Create concise 2-3 sentence summaries of tech news articles."
                    },
                    {
                        "role": "user",
                        "content": f"Summarize: {article['content']}"
                    }
                ],
                "max_completion_tokens": 150,
                "temperature": 0.3,
                "reasoning_effort": "low"
            }
            
            response = bedrock_runtime.invoke_model(
                modelId='openai.gpt-oss-20b-1:0',
                body=json.dumps(payload),
                contentType='application/json'
            )
            
            response_body = json.loads(response['Body'].read())
            summary = response_body['choices'][0]['message']['content']
            
            summaries.append({
                'article_id': article['id'],
                'summary': summary.strip()
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'summaries': summaries,
                'model_used': 'GPT-OSS-20B',
                'processed': len(summaries)
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
