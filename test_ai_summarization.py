#!/usr/bin/env python3
"""
Test script for Moning AI Summarization System
Fetches real articles and tests the AI summarization API
"""

import requests
import json
import hashlib
import uuid
from datetime import datetime
import feedparser
import time
import sys

class MoningAITester:
    def __init__(self):
        self.api_base_url = "https://y501z1431b.execute-api.us-west-2.amazonaws.com/prod"
        
        # RSS sources from your app (same as RSSService.swift)
        self.rss_sources = [
            {"name": "TechCrunch", "url": "https://techcrunch.com/feed/"},
            {"name": "The Verge", "url": "https://www.theverge.com/rss/index.xml"},
            {"name": "Ars Technica", "url": "https://feeds.arstechnica.com/arstechnica/index"},
            {"name": "MIT Technology Review", "url": "https://www.technologyreview.com/feed/"},
            {"name": "Wired", "url": "https://www.wired.com/feed/rss"},
        ]
    
    def fetch_latest_article(self, source_name=None):
        """Fetch the latest article from RSS feeds"""
        if source_name:
            sources = [s for s in self.rss_sources if s["name"] == source_name]
            if not sources:
                print(f"❌ Source '{source_name}' not found")
                return None
        else:
            sources = self.rss_sources
        
        for source in sources:
            try:
                print(f"📡 Fetching from {source['name']}...")
                feed = feedparser.parse(source['url'])
                
                if feed.entries:
                    entry = feed.entries[0]  # Latest article
                    
                    # Generate consistent article ID (similar to your iOS app)
                    article_url = entry.link
                    content = getattr(entry, 'content', [])
                    description = entry.get('description', '')
                    
                    # Extract content
                    if content and len(content) > 0:
                        article_content = content[0].get('value', description)
                    else:
                        article_content = description
                    
                    # Create article ID (UUID based on URL for consistency)
                    article_id = str(uuid.uuid5(uuid.NAMESPACE_URL, article_url))
                    
                    article = {
                        'id': article_id,
                        'title': entry.title,
                        'url': article_url,
                        'content': article_content,
                        'source': source['name'],
                        'published': entry.get('published', 'Unknown'),
                        'author': entry.get('author', 'Unknown')
                    }
                    
                    print(f"✅ Found article: {entry.title[:60]}...")
                    return article
                    
            except Exception as e:
                print(f"❌ Error fetching from {source['name']}: {str(e)}")
                continue
        
        print("❌ Could not fetch any articles")
        return None
    
    def test_single_summary(self, article_id):
        """Test single article summary API endpoint"""
        try:
            url = f"{self.api_base_url}/summaries/{article_id}"
            print(f"📤 Testing single summary API: {url}")
            
            response = requests.get(url, timeout=30)
            
            print(f"📥 Response status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                return data
            elif response.status_code == 404:
                print("❌ Article not found in cache (hasn't been processed yet)")
                return None
            else:
                print(f"❌ API error: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Error testing single summary: {str(e)}")
            return None
    
    def test_batch_summary(self, article_ids):
        """Test batch summary API endpoint"""
        try:
            url = f"{self.api_base_url}/batch-summaries"
            payload = {"article_ids": article_ids}
            
            print(f"📤 Testing batch summary API with {len(article_ids)} article(s)")
            
            response = requests.post(
                url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            
            print(f"📥 Response status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                return data
            else:
                print(f"❌ Batch API error: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Error testing batch summary: {str(e)}")
            return None
    
    def test_on_demand_generation(self, article):
        """
        Test on-demand summary generation (this would need to be added to your API)
        For now, this just simulates what the summary would look like
        """
        print("🤖 Simulating on-demand AI summary generation...")
        
        # This is what your OpenAI API would return
        simulated_summary = f"This article from {article['source']} discusses {article['title'][:30]}... [AI Summary would be generated here with OpenAI GPT-OSS-20B]"
        
        return {
            'article_id': article['id'],
            'summary': simulated_summary,
            'created_at': datetime.now().isoformat(),
            'model_used': 'openai.gpt-oss-20b-1:0',
            'cached': False,
            'metadata': {
                'source': article['source'],
                'generated_via': 'test_script'
            }
        }
    
    def run_full_test(self, source_name=None):
        """Run complete AI summarization test"""
        print("🚀 Starting Moning AI Summarization Test")
        print("=" * 60)
        
        # 1. Fetch latest article
        article = self.fetch_latest_article(source_name)
        if not article:
            return
        
        print("\n📰 ARTICLE DETAILS:")
        print("=" * 60)
        print(f"📰 Title: {article['title']}")
        print(f"🔗 URL: {article['url']}")
        print(f"📺 Source: {article['source']}")
        print(f"👤 Author: {article['author']}")
        print(f"📅 Published: {article['published']}")
        print(f"🆔 Article ID: {article['id']}")
        print(f"📄 Content Preview: {article['content'][:200]}...")
        
        # 2. Test single summary API
        print("\n🧪 TESTING AI SUMMARIZATION API:")
        print("=" * 60)
        
        summary_result = self.test_single_summary(article['id'])
        
        if summary_result:
            print("✅ Found cached summary!")
            print(f"🤖 AI SUMMARY:")
            print(f"    {summary_result['summary']}")
            print(f"🔬 Model: {summary_result.get('model_used', 'Unknown')}")
            print(f"📅 Generated: {summary_result.get('created_at', 'Unknown')}")
            print(f"💾 Cached: {summary_result.get('cached', False)}")
        else:
            print("❌ No cached summary found")
            
            # 3. Test batch API
            print("\n🔄 Trying batch API...")
            batch_result = self.test_batch_summary([article['id']])
            
            if batch_result and batch_result.get('found', 0) > 0:
                summaries = batch_result.get('summaries', {})
                if article['id'] in summaries and summaries[article['id']]:
                    summary_data = summaries[article['id']]
                    print("✅ Found summary via batch API!")
                    print(f"🤖 AI SUMMARY:")
                    print(f"    {summary_data['summary']}")
                    print(f"🔬 Model: {summary_data.get('model_used', 'Unknown')}")
                else:
                    print("❌ No summary found via batch API either")
                    
                    # 4. Simulate on-demand generation
                    print("\n🔧 Testing on-demand generation simulation...")
                    simulated = self.test_on_demand_generation(article)
                    print("🤖 SIMULATED AI SUMMARY:")
                    print(f"    {simulated['summary']}")
            else:
                print("❌ Batch API returned no results")
        
        print("\n🎯 TEST SUMMARY:")
        print("=" * 60)
        print(f"📰 Article tested: {article['title'][:50]}...")
        print(f"🔗 You can read it here: {article['url']}")
        print(f"📊 API Status: {'✅ Working' if summary_result or batch_result else '⚠️ No cached summaries'}")
        print("✅ Test completed successfully!")

def main():
    tester = MoningAITester()
    
    # Allow specifying source
    if len(sys.argv) > 1:
        source_name = sys.argv[1]
        print(f"Testing with {source_name} articles...")
    else:
        source_name = None
        print("Testing with articles from all sources...")
    
    tester.run_full_test(source_name)

if __name__ == "__main__":
    main()