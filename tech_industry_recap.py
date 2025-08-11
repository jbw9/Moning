#!/usr/bin/env python3
"""
Tech Industry Weekly Recap Generator
Similar to Morning Brew - synthesizes the week's tech news into a cohesive narrative
"""

import requests
import feedparser
import json
import boto3
import os
from datetime import datetime, timedelta
from collections import defaultdict
import re
from typing import List, Dict, Optional

class TechIndustryRecap:
    def __init__(self):
        self.sources = [
            {"name": "TechCrunch", "url": "https://techcrunch.com/feed/", "weight": 1.0},
            {"name": "The Verge", "url": "https://www.theverge.com/rss/index.xml", "weight": 0.9},
            {"name": "Ars Technica", "url": "https://feeds.arstechnica.com/arstechnica/index", "weight": 0.95},
            {"name": "MIT Technology Review", "url": "https://www.technologyreview.com/feed/", "weight": 0.95},
            {"name": "Wired", "url": "https://www.wired.com/feed/rss", "weight": 0.9},
            {"name": "Engadget", "url": "https://www.engadget.com/rss.xml", "weight": 0.8},
            {"name": "VentureBeat", "url": "https://venturebeat.com/feed/", "weight": 0.85},
        ]
        
        # Keywords for categorizing and prioritizing articles
        self.ai_keywords = ['ai', 'artificial intelligence', 'openai', 'gpt', 'claude', 'llm', 'machine learning', 'neural', 'chatbot', 'generative']
        self.crypto_keywords = ['crypto', 'bitcoin', 'ethereum', 'blockchain', 'defi', 'nft', 'web3']
        self.startup_keywords = ['funding', 'startup', 'venture', 'series a', 'series b', 'ipo', 'acquisition', 'merger']
        self.big_tech_keywords = ['apple', 'google', 'microsoft', 'amazon', 'meta', 'tesla', 'nvidia']
        self.security_keywords = ['security', 'hack', 'breach', 'vulnerability', 'cyber', 'privacy']
        
        # High-impact keywords that indicate major stories
        self.major_story_keywords = ['released', 'launches', 'announces', 'breakthrough', 'revolutionary', 'first', 'major']
        
    def fetch_past_week_articles(self) -> List[Dict]:
        """Fetch articles from the past week across all sources"""
        
        one_week_ago = datetime.now() - timedelta(days=7)
        all_articles = []
        
        print(f"📅 Fetching articles from the past 7 days (since {one_week_ago.strftime('%Y-%m-%d')})")
        print("=" * 80)
        
        for source in self.sources:
            try:
                print(f"📡 Fetching from {source['name']}...")
                feed = feedparser.parse(source['url'])
                
                source_articles = 0
                for entry in feed.entries:
                    # Parse publication date
                    pub_date = None
                    if hasattr(entry, 'published_parsed') and entry.published_parsed:
                        pub_date = datetime(*entry.published_parsed[:6])
                    elif hasattr(entry, 'updated_parsed') and entry.updated_parsed:
                        pub_date = datetime(*entry.updated_parsed[:6])
                    
                    # Only include articles from the past week
                    if pub_date and pub_date >= one_week_ago:
                        article = {
                            'title': entry.title,
                            'url': entry.link,
                            'description': entry.get('description', ''),
                            'content': self.extract_content(entry),
                            'source': source['name'],
                            'source_weight': source['weight'],
                            'published': pub_date,
                            'author': entry.get('author', 'Unknown')
                        }
                        
                        # Add categorization and importance scoring
                        article['category'] = self.categorize_article(article)
                        article['importance_score'] = self.calculate_importance_score(article)
                        
                        all_articles.append(article)
                        source_articles += 1
                
                print(f"✅ Found {source_articles} articles from {source['name']}")
                
            except Exception as e:
                print(f"❌ Error fetching from {source['name']}: {str(e)}")
                continue
        
        # Sort by importance score and publication date
        all_articles.sort(key=lambda x: (x['importance_score'], x['published']), reverse=True)
        
        print(f"\n📊 Total articles collected: {len(all_articles)}")
        print(f"📈 Top categories: {self.get_category_distribution(all_articles)}")
        
        return all_articles
    
    def extract_content(self, entry) -> str:
        """Extract the best available content from RSS entry"""
        content = ""
        
        # Try different content fields
        if hasattr(entry, 'content') and entry.content:
            content = entry.content[0].get('value', '')
        elif hasattr(entry, 'summary_detail'):
            content = entry.summary_detail.get('value', '')
        elif hasattr(entry, 'description'):
            content = entry.description
        elif hasattr(entry, 'summary'):
            content = entry.summary
        
        # Clean HTML tags
        content = re.sub(r'<[^>]+>', '', content)
        return content.strip()[:1000]  # Limit length
    
    def categorize_article(self, article) -> str:
        """Categorize article by topic"""
        text = (article['title'] + ' ' + article['description']).lower()
        
        if any(keyword in text for keyword in self.ai_keywords):
            return 'AI & Machine Learning'
        elif any(keyword in text for keyword in self.crypto_keywords):
            return 'Crypto & Web3'
        elif any(keyword in text for keyword in self.startup_keywords):
            return 'Startups & Funding'
        elif any(keyword in text for keyword in self.big_tech_keywords):
            return 'Big Tech'
        elif any(keyword in text for keyword in self.security_keywords):
            return 'Cybersecurity'
        else:
            return 'General Tech'
    
    def calculate_importance_score(self, article) -> float:
        """Calculate importance score based on various factors"""
        score = article['source_weight']  # Base score from source reliability
        
        text = (article['title'] + ' ' + article['description']).lower()
        
        # Boost for major story keywords
        for keyword in self.major_story_keywords:
            if keyword in text:
                score += 0.3
        
        # Boost for AI-related content (hot topic)
        if any(keyword in text for keyword in self.ai_keywords):
            score += 0.5
        
        # Boost for big tech companies
        if any(keyword in text for keyword in self.big_tech_keywords):
            score += 0.2
        
        # Boost for funding/acquisition news
        if any(keyword in text for keyword in self.startup_keywords):
            score += 0.3
        
        # Boost for recent articles
        hours_old = (datetime.now() - article['published']).total_seconds() / 3600
        if hours_old < 24:
            score += 0.2
        elif hours_old < 72:
            score += 0.1
        
        return score
    
    def get_category_distribution(self, articles) -> Dict[str, int]:
        """Get distribution of articles by category"""
        categories = defaultdict(int)
        for article in articles:
            categories[article['category']] += 1
        return dict(categories)
    
    def create_industry_recap_prompt(self, articles: List[Dict]) -> str:
        """Create sophisticated prompt for industry-level analysis"""
        
        # Group articles by category for better context
        categories = defaultdict(list)
        for article in articles:
            categories[article['category']].append(article)
        
        # Build context for each category
        context_sections = []
        for category, cat_articles in categories.items():
            if len(cat_articles) >= 2:  # Only include categories with multiple articles
                section = f"\n## {category} ({len(cat_articles)} articles):\n"
                for article in cat_articles[:5]:  # Top 5 per category
                    section += f"- **{article['title']}** ({article['source']}, {article['published'].strftime('%m/%d')})\n"
                    section += f"  {article['description'][:200]}...\n"
                context_sections.append(section)
        
        articles_context = '\n'.join(context_sections)
        
        prompt = f"""You are the lead tech industry analyst for a premium newsletter similar to Morning Brew. Your job is to synthesize the week's most important tech developments into an engaging, insightful 5-10 minute read.

CONTEXT: Here are this week's key tech stories organized by category:
{articles_context}

TASK: Create a comprehensive weekly tech industry recap that:

1. **LEADS WITH THE BIGGEST STORY** - What was the week's most significant development?

2. **IDENTIFIES KEY THEMES** - What are the 3-4 major trends/themes that emerged this week?

3. **CONNECTS THE DOTS** - How do these stories relate to each other and broader industry trends?

4. **PROVIDES INSIGHT** - Go beyond just summarizing - offer analysis on why these developments matter

5. **MAINTAINS ENGAGEMENT** - Use a conversational, Morning Brew-style tone that's informative but accessible

STRUCTURE YOUR RECAP AS:
- **🔥 WEEK'S BIGGEST STORY** (2-3 paragraphs)
- **📊 KEY INDUSTRY THEMES** (3-4 themes, 2 paragraphs each)
- **🔮 WHAT TO WATCH NEXT** (Forward-looking insights)
- **💡 BOTTOM LINE** (Key takeaway for the week)

TONE: Professional but conversational, like you're briefing a smart colleague over coffee. Include specific company names, numbers, and concrete details where relevant.

TARGET LENGTH: 800-1200 words (5-10 minute read)

Begin your industry recap now:"""

        return prompt
    
    def generate_industry_recap_aws(self, articles: List[Dict]) -> Optional[str]:
        """Generate industry recap using AWS Bedrock"""
        try:
            bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-west-2')
            
            prompt = self.create_industry_recap_prompt(articles)
            
            payload = {
                "messages": [
                    {"role": "user", "content": prompt}
                ],
                "max_completion_tokens": 2000,
                "temperature": 0.7,  # Higher creativity for narrative flow
                "reasoning_effort": "high"  # Deep analysis needed
            }
            
            print("🤖 Generating industry recap with OpenAI GPT-OSS-20B...")
            
            response = bedrock_runtime.invoke_model(
                modelId='openai.gpt-oss-20b-1:0',
                body=json.dumps(payload),
                contentType='application/json'
            )
            
            response_body = json.loads(response['Body'].read())
            return response_body['choices'][0]['message']['content'].strip()
            
        except Exception as e:
            print(f"❌ Error generating AWS recap: {str(e)}")
            return None
    
    def generate_mock_industry_recap(self, articles: List[Dict]) -> str:
        """Generate a realistic mock industry recap for demonstration"""
        
        # Analyze the articles to create realistic content
        categories = self.get_category_distribution(articles)
        top_articles = articles[:10]
        
        # Count AI-related stories
        ai_stories = [a for a in articles if a['category'] == 'AI & Machine Learning']
        big_tech_stories = [a for a in articles if a['category'] == 'Big Tech']
        
        current_week = datetime.now().strftime("Week of %B %d, %Y")
        
        recap = f"""# Tech Industry Weekly Recap
## {current_week}

### 🔥 WEEK'S BIGGEST STORY: The AI Revolution Accelerates

This week marked another pivotal moment in the AI race, with major developments reshaping how we think about artificial intelligence capabilities. {ai_stories[0]['title'] if ai_stories else 'OpenAI and other major players made significant announcements'} dominated headlines, signaling that we're entering a new phase of AI competition.

The implications extend far beyond just better chatbots. We're seeing AI models become more capable, more efficient, and more integrated into everyday business operations. What's particularly striking is how quickly the industry is moving from experimental to production-ready AI applications.

### 📊 KEY INDUSTRY THEMES

**🤖 AI Arms Race Intensifies**
The competition between AI companies reached new heights this week, with {len(ai_stories)} major AI-related announcements. Companies are racing not just to build better models, but to make them more accessible and cost-effective. The focus has shifted from pure capability to practical deployment, suggesting we're moving from the "wow factor" phase to the "value creation" phase of the AI revolution.

**💰 Funding Landscape Remains Robust** 
Despite broader economic concerns, tech startups continued to attract significant investment this week. The data suggests investors remain confident in long-term tech trends, particularly in AI, cybersecurity, and enterprise software. However, there's a clear preference for companies with clear paths to profitability rather than pure growth plays.

**🛡️ Security Takes Center Stage**
With {len([a for a in articles if a['category'] == 'Cybersecurity'])} major security-related stories this week, cybersecurity remains a critical concern across the industry. From infrastructure vulnerabilities to AI safety concerns, companies are grappling with new threat vectors while trying to innovate rapidly.

**🏢 Big Tech Continues Strategic Pivots**
The major tech companies made several strategic moves this week that signal broader shifts in their priorities. {big_tech_stories[0]['title'] if big_tech_stories else 'Major tech companies announced significant strategic initiatives'}, indicating that even established giants are rapidly adapting to new technological realities.

### 🔮 WHAT TO WATCH NEXT

The next few weeks will be crucial for understanding how these AI developments translate into real business value. Watch for earnings calls from major tech companies, which should provide insight into how AI investments are affecting bottom lines.

Additionally, regulatory responses to rapid AI advancement are becoming increasingly important. The balance between innovation and safety will likely define the next phase of AI development.

### 💡 BOTTOM LINE

This week reinforced that we're in the middle of a genuine technological inflection point. The companies that can effectively integrate AI capabilities while maintaining security and regulatory compliance are likely to emerge as the next decade's winners. For investors and business leaders, the key is distinguishing between genuine innovation and hype – a challenge that's becoming more difficult as the pace of change accelerates.

---

*Analyzed {len(articles)} articles from {len(set(a['source'] for a in articles))} leading tech publications. Key categories: {', '.join(f"{k} ({v})" for k, v in categories.items())}*

**📊 This Week's Numbers:**
- {len(ai_stories)} AI & ML developments
- {len([a for a in articles if a['category'] == 'Startups & Funding'])} funding announcements  
- {len(big_tech_stories)} big tech moves
- {len([a for a in articles if a['category'] == 'Cybersecurity'])} security incidents

*Next week: Watch for reactions to this week's AI announcements and potential regulatory responses.*
"""
        
        return recap
    
    def run_industry_recap_generation(self):
        """Run the complete industry recap generation process"""
        
        print("🚀 TECH INDUSTRY WEEKLY RECAP GENERATOR")
        print("=" * 80)
        print("Creating Morning Brew-style tech industry synthesis...")
        print()
        
        # Step 1: Fetch articles
        articles = self.fetch_past_week_articles()
        
        if len(articles) < 10:
            print("❌ Not enough articles found for meaningful recap")
            return
        
        print(f"\n✅ Successfully collected {len(articles)} articles for analysis")
        
        # Step 2: Try AWS generation first
        print("\n" + "="*80)
        print("🤖 GENERATING INDUSTRY RECAP...")
        print("="*80)
        
        aws_recap = self.generate_industry_recap_aws(articles)
        
        if aws_recap:
            print("\n🎉 SUCCESS! Generated with OpenAI GPT-OSS-20B:")
            print("="*80)
            print(aws_recap)
        else:
            print("\n📝 Generating high-quality demo recap:")
            print("="*80)
            mock_recap = self.generate_mock_industry_recap(articles)
            print(mock_recap)
        
        print("\n" + "="*80)
        print("✅ INDUSTRY RECAP COMPLETE!")
        print("💡 This is the type of content your enhanced system would generate.")

def main():
    generator = TechIndustryRecap()
    generator.run_industry_recap_generation()

if __name__ == "__main__":
    main()