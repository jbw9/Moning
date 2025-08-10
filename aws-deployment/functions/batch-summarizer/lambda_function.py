#!/usr/bin/env python3
"""
Batch Summarizer Lambda Function
Processes multiple articles using OpenAI GPT-OSS via Bedrock
Caches results in DynamoDB for fast retrieval
"""

import json
import boto3
import logging
import os
from datetime import datetime, timedelta
from typing import List, Dict, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('BEDROCK_REGION', 'us-west-2'))
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('BEDROCK_REGION', 'us-west-2'))
table = dynamodb.Table(os.environ.get('DYNAMODB_TABLE', 'article-summaries'))

# Configuration
MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'openai.gpt-oss-20b-1:0')
MAX_ARTICLES_PER_BATCH = 50
CACHE_DURATION_HOURS = 24

def lambda_handler(event, context):
    """
    Main Lambda handler for batch article summarization
    
    Expected event format:
    {
        "articles": [
            {
                "id": "article123",
                "title": "Article Title",
                "content": "Article content...",
                "source": "TechCrunch",
                "category": "AI"
            }
        ],
        "trigger": "manual|scheduled",
        "batch_size": 50
    }
    """
    
    try:
        logger.info(f"Batch summarizer started. Event: {json.dumps(event, default=str)}")
        
        # Extract articles from event
        articles = event.get('articles', [])
        trigger_type = event.get('trigger', 'manual')
        batch_size = min(event.get('batch_size', MAX_ARTICLES_PER_BATCH), MAX_ARTICLES_PER_BATCH)
        
        if not articles:
            logger.warning("No articles provided in event")
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'No articles provided',
                    'expected_format': {
                        'articles': [{'id': 'string', 'title': 'string', 'content': 'string'}]
                    }
                })
            }
        
        # Limit batch size to prevent timeout
        if len(articles) > batch_size:
            logger.info(f"Limiting batch to {batch_size} articles (received {len(articles)})")
            articles = articles[:batch_size]
        
        # Process articles
        results = process_articles_batch(articles)
        
        # Prepare response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'trigger': trigger_type,
                'processed': len(articles),
                'summaries_generated': results['new_summaries'],
                'cached_summaries': results['cached_summaries'],
                'errors': results['errors'],
                'model_used': MODEL_ID,
                'processing_time_seconds': results['processing_time']
            })
        }
        
        logger.info(f"Batch processing completed: {results}")
        return response
        
    except Exception as e:
        logger.error(f"Batch summarizer failed: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal processing error',
                'details': str(e)
            })
        }

def process_articles_batch(articles: List[Dict]) -> Dict:
    """Process a batch of articles and return summary statistics"""
    
    start_time = datetime.now()
    results = {
        'new_summaries': 0,
        'cached_summaries': 0,
        'errors': [],
        'processing_time': 0
    }
    
    for article in articles:
        try:
            article_id = article.get('id')
            if not article_id:
                results['errors'].append("Article missing 'id' field")
                continue
            
            # Check cache first
            cached_summary = get_cached_summary(article_id)
            if cached_summary:
                logger.info(f"Using cached summary for article {article_id}")
                results['cached_summaries'] += 1
                continue
            
            # Generate new summary
            content = article.get('content', '')
            title = article.get('title', '')
            
            if not content:
                results['errors'].append(f"Article {article_id} has no content")
                continue
            
            summary = generate_summary(content, title, article.get('category', ''))
            
            if summary:
                # Cache the summary
                cache_summary(article_id, summary, {
                    'title': title,
                    'source': article.get('source', ''),
                    'category': article.get('category', ''),
                    'content_length': len(content)
                })
                
                results['new_summaries'] += 1
                logger.info(f"Generated and cached summary for article {article_id}")
            else:
                results['errors'].append(f"Failed to generate summary for article {article_id}")
            
        except Exception as e:
            error_msg = f"Error processing article {article.get('id', 'unknown')}: {str(e)}"
            logger.error(error_msg)
            results['errors'].append(error_msg)
    
    results['processing_time'] = (datetime.now() - start_time).total_seconds()
    return results

def get_cached_summary(article_id: str) -> Optional[str]:
    """Check if we have a fresh cached summary for this article"""
    
    try:
        response = table.get_item(Key={'article_id': article_id})
        
        if 'Item' in response:
            item = response['Item']
            
            # Check if summary is still fresh (within cache duration)
            created_at = datetime.fromisoformat(item['created_at'])
            if datetime.utcnow() - created_at < timedelta(hours=CACHE_DURATION_HOURS):
                return item['summary']
            else:
                logger.info(f"Cached summary for {article_id} expired, will regenerate")
        
        return None
        
    except Exception as e:
        logger.error(f"Error checking cache for {article_id}: {str(e)}")
        return None

def generate_summary(content: str, title: str = "", category: str = "") -> Optional[str]:
    """Generate article summary using OpenAI GPT-OSS via Bedrock"""
    
    try:
        # Truncate very long content to stay within token limits
        max_content_length = 4000  # Conservative limit for input
        if len(content) > max_content_length:
            content = content[:max_content_length] + "..."
            logger.info(f"Content truncated to {max_content_length} characters")
        
        # Create context-aware system prompt
        system_prompt = create_system_prompt(category)
        
        # Create user prompt with context
        user_prompt = create_user_prompt(content, title)
        
        # Prepare Bedrock payload
        payload = {
            "messages": [
                {
                    "role": "system",
                    "content": system_prompt
                },
                {
                    "role": "user",
                    "content": user_prompt
                }
            ],
            "max_completion_tokens": 150,
            "temperature": 0.3,
            "reasoning_effort": "low"  # Fast mode for news summaries
        }
        
        # Invoke Bedrock model
        response = bedrock_runtime.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(payload),
            contentType='application/json'
        )
        
        # Parse response
        response_body = json.loads(response['Body'].read())
        summary = response_body['choices'][0]['message']['content'].strip()
        
        # Validate summary quality
        if len(summary) < 20:
            logger.warning(f"Generated summary too short: {summary}")
            return None
        
        return summary
        
    except Exception as e:
        logger.error(f"Error generating summary: {str(e)}")
        return None

def create_system_prompt(category: str) -> str:
    """Create category-specific system prompt"""
    
    base_prompt = "You are an expert news summarizer specializing in technology and business news. Create concise, accurate 2-3 sentence summaries that capture the most important facts and business implications."
    
    category_prompts = {
        'AI': base_prompt + " Focus on technical capabilities, business impact, and industry implications of AI developments.",
        'Business': base_prompt + " Emphasize financial figures, market impact, and strategic business decisions.",
        'Technology': base_prompt + " Highlight technical specifications, innovation aspects, and market positioning.",
        'Startups': base_prompt + " Focus on funding rounds, business models, and market disruption potential."
    }
    
    return category_prompts.get(category, base_prompt)

def create_user_prompt(content: str, title: str) -> str:
    """Create effective user prompt for summarization"""
    
    if title:
        return f"Summarize this tech news article titled '{title}':\n\n{content}"
    else:
        return f"Summarize this tech news article:\n\n{content}"

def cache_summary(article_id: str, summary: str, metadata: Dict):
    """Cache summary in DynamoDB with metadata"""
    
    try:
        current_time = datetime.utcnow()
        ttl_time = current_time + timedelta(days=30)  # Auto-delete after 30 days
        
        item = {
            'article_id': article_id,
            'summary': summary,
            'created_at': current_time.isoformat(),
            'ttl': int(ttl_time.timestamp()),
            'model_used': MODEL_ID,
            'metadata': metadata
        }
        
        table.put_item(Item=item)
        logger.debug(f"Cached summary for article {article_id}")
        
    except Exception as e:
        logger.error(f"Error caching summary for {article_id}: {str(e)}")
        # Don't raise - caching failure shouldn't stop processing