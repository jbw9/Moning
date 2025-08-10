#!/usr/bin/env python3
"""
API Handler Lambda Function
Serves iOS app requests for article summaries
Handles both single and batch summary requests
"""

import json
import boto3
import logging
import os
from datetime import datetime
from typing import Dict, List, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('BEDROCK_REGION', 'us-west-2'))
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('BEDROCK_REGION', 'us-west-2'))
table = dynamodb.Table(os.environ.get('DYNAMODB_TABLE', 'article-summaries'))

# Configuration
MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'openai.gpt-oss-20b-1:0')

def lambda_handler(event, context):
    """
    Main Lambda handler for API requests from iOS app
    
    Supported endpoints:
    GET /summaries/{article_id} - Get single summary
    POST /batch-summaries - Get multiple summaries
    OPTIONS /* - CORS preflight
    """
    
    try:
        method = event['httpMethod']
        path = event['path']
        
        logger.info(f"API request: {method} {path}")
        
        # CORS headers for all responses
        cors_headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            'Access-Control-Max-Age': '86400'
        }
        
        # Handle CORS preflight
        if method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': cors_headers,
                'body': ''
            }
        
        # Route to appropriate handler
        if method == 'GET' and path.startswith('/summaries/'):
            return handle_single_summary(event, cors_headers)
        elif method == 'POST' and path == '/batch-summaries':
            return handle_batch_summaries(event, cors_headers)
        else:
            return {
                'statusCode': 404,
                'headers': cors_headers,
                'body': json.dumps({
                    'error': 'Endpoint not found',
                    'available_endpoints': {
                        'GET /summaries/{article_id}': 'Get single summary',
                        'POST /batch-summaries': 'Get multiple summaries'
                    }
                })
            }
    
    except Exception as e:
        logger.error(f"API handler error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Internal server error',
                'details': str(e)
            })
        }

def handle_single_summary(event, headers) -> Dict:
    """Handle GET /summaries/{article_id}"""
    
    try:
        # Extract article_id from path
        article_id = event['pathParameters']['article_id']
        
        if not article_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'Missing article_id parameter'})
            }
        
        logger.info(f"Fetching summary for article: {article_id}")
        
        # Try to get from cache first
        response = table.get_item(Key={'article_id': article_id})
        
        if 'Item' in response:
            item = response['Item']
            
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'article_id': article_id,
                    'summary': item['summary'],
                    'created_at': item.get('created_at'),
                    'model_used': item.get('model_used', MODEL_ID),
                    'cached': True,
                    'metadata': item.get('metadata', {})
                })
            }
        else:
            # Summary not found in cache
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Summary not found',
                    'article_id': article_id,
                    'message': 'Article has not been processed yet. Try batch processing first.'
                })
            }
    
    except Exception as e:
        logger.error(f"Error handling single summary request: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }

def handle_batch_summaries(event, headers) -> Dict:
    """Handle POST /batch-summaries"""
    
    try:
        # Parse request body
        if not event.get('body'):
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Missing request body',
                    'expected_format': {
                        'article_ids': ['id1', 'id2', 'id3']
                    }
                })
            }
        
        body = json.loads(event['body'])
        article_ids = body.get('article_ids', [])
        
        if not article_ids or not isinstance(article_ids, list):
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Invalid article_ids format',
                    'expected': 'Array of article ID strings'
                })
            }
        
        # Limit batch size to prevent timeout
        max_batch_size = 50
        if len(article_ids) > max_batch_size:
            article_ids = article_ids[:max_batch_size]
            logger.info(f"Limited batch to {max_batch_size} articles")
        
        logger.info(f"Fetching batch summaries for {len(article_ids)} articles")
        
        # Fetch summaries from cache
        summaries = {}
        found_count = 0
        
        for article_id in article_ids:
            try:
                response = table.get_item(Key={'article_id': article_id})
                
                if 'Item' in response:
                    item = response['Item']
                    summaries[article_id] = {
                        'summary': item['summary'],
                        'created_at': item.get('created_at'),
                        'model_used': item.get('model_used', MODEL_ID),
                        'metadata': item.get('metadata', {})
                    }
                    found_count += 1
                else:
                    summaries[article_id] = None
                    
            except Exception as e:
                logger.error(f"Error fetching summary for {article_id}: {str(e)}")
                summaries[article_id] = {'error': str(e)}
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'summaries': summaries,
                'found': found_count,
                'not_found': len(article_ids) - found_count,
                'total_requested': len(article_ids),
                'model_used': MODEL_ID
            })
        }
    
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'error': 'Invalid JSON in request body'})
        }
    except Exception as e:
        logger.error(f"Error handling batch summaries request: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }

def generate_summary_on_demand(content: str, title: str = "") -> Optional[str]:
    """
    Generate summary on-demand for missing articles
    (Optional: for future enhancement)
    """
    
    try:
        # Truncate content if too long
        max_length = 4000
        if len(content) > max_length:
            content = content[:max_length] + "..."
        
        # Create prompt
        system_prompt = "You are an expert news summarizer. Create concise 2-3 sentence summaries of tech news articles."
        user_prompt = f"Summarize this article{f' titled \"{title}\"' if title else ''}:\n\n{content}"
        
        payload = {
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "max_completion_tokens": 150,
            "temperature": 0.3,
            "reasoning_effort": "low"
        }
        
        response = bedrock_runtime.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(payload),
            contentType='application/json'
        )
        
        response_body = json.loads(response['Body'].read())
        return response_body['choices'][0]['message']['content'].strip()
        
    except Exception as e:
        logger.error(f"Error generating on-demand summary: {str(e)}")
        return None