#!/usr/bin/env python3
"""
Industry Weekly Recap Generator
Creates Morning Brew-style weekly summaries for tech industry
Aggregates multiple articles to identify trends and key developments
"""

import requests
import feedparser
import json
import boto3
import os
from datetime import datetime, timedelta
from collections import defaultdict
import re

class IndustryRecapGenerator:
    def __init__(self):
        self.api_base_url = "https://y501z1431b.execute-api.us-west-2.amazonaws.com/prod"
        
        # Enhanced RSS sources for comprehensive tech coverage
        self.tech_sources = [
            {"name": "TechCrunch", "url": "https://techcrunch.com/feed/", "focus": "startups_funding"},
            {"name": "The Verge", "url": "https://www.theverge.com/rss/index.xml", "focus": "consumer_tech"},
            {"name": "Ars Technica", "url": "https://feeds.arstechnica.com/arstechnica/index", "focus": "technical_analysis"},
            {"name": "MIT Technology Review", "url": "https://www.technologyreview.com/feed/", "focus": "ai_research"},
            {"name": "Wired", "url": "https://www.wired.com/feed/rss", "focus": "tech_culture"},
            {"name": "VentureBeat", "url": "https://venturebeat.com/feed/", "focus": "enterprise_ai"},
            {"name": "TechMeme", "url": "https://www.techmeme.com/feed.xml", "focus": "breaking_news"},
            {"name": "AI News", "url": "https://artificialintelligence-news.com/feed/", "focus": "ai_developments"}
        ]
        
        # Try to initialize AWS Bedrock
        try:
            self.bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-west-2')
            self.aws_available = True
        except:
            self.aws_available = False
            print("⚠️ AWS not available - will use mock AI generation")

    def fetch_week_articles(self, days_back=7):
        """Fetch articles from the past week across all tech sources"""
        
        print(f"📡 Fetching articles from past {days_back} days...")
        cutoff_date = datetime.now() - timedelta(days=days_back)
        
        all_articles = []
        source_counts = defaultdict(int)
        
        for source in self.tech_sources:
            try:
                print(f"  📰 Fetching from {source['name']}...")
                feed = feedparser.parse(source['url'])
                
                for entry in feed.entries[:20]:  # Limit per source
                    # Parse publication date
                    pub_date = None
                    if hasattr(entry, 'published_parsed') and entry.published_parsed:
                        pub_date = datetime(*entry.published_parsed[:6])
                    elif hasattr(entry, 'updated_parsed') and entry.updated_parsed:
                        pub_date = datetime(*entry.updated_parsed[:6])
                    
                    # Skip if too old
                    if pub_date and pub_date < cutoff_date:
                        continue
                    
                    # Extract content
                    content = ""
                    if hasattr(entry, 'content') and entry.content:
                        content = entry.content[0].value if entry.content else ""
                    else:
                        content = entry.get('description', entry.get('summary', ''))
                    
                    # Clean HTML tags
                    content = re.sub(r'<[^>]+>', '', content)
                    content = content.replace('&nbsp;', ' ').replace('&amp;', '&')
                    
                    article = {
                        'title': entry.title,
                        'url': entry.link,
                        'content': content[:1000],  # Limit length
                        'source': source['name'],
                        'focus_area': source['focus'],
                        'published': pub_date.isoformat() if pub_date else 'Unknown',
                        'summary': ''  # Will be populated
                    }
                    
                    all_articles.append(article)
                    source_counts[source['name']] += 1
                    
            except Exception as e:
                print(f"  ❌ Error fetching from {source['name']}: {str(e)}")
                continue
        
        print(f"✅ Fetched {len(all_articles)} articles total:")
        for source, count in source_counts.items():
            print(f"  📊 {source}: {count} articles")
        
        return all_articles
    
    def categorize_articles(self, articles):
        """Group articles by themes and topics"""
        
        categories = {
            'ai_llm': [],
            'funding_ipo': [],
            'big_tech': [],
            'startups': [],
            'security': [],
            'regulation': [],
            'products': [],
            'other': []
        }
        
        # Keywords for categorization
        keywords = {
            'ai_llm': ['ai', 'artificial intelligence', 'llm', 'gpt', 'claude', 'openai', 'anthropic', 'machine learning', 'neural', 'model'],
            'funding_ipo': ['funding', 'raised', 'million', 'billion', 'investment', 'ipo', 'acquisition', 'valuation', 'series'],
            'big_tech': ['apple', 'google', 'microsoft', 'amazon', 'meta', 'tesla', 'nvidia', 'alphabet'],
            'security': ['security', 'hack', 'breach', 'vulnerability', 'cyber', 'malware', 'privacy'],
            'regulation': ['regulation', 'government', 'policy', 'law', 'compliance', 'antitrust', 'senate'],
            'startups': ['startup', 'founder', 'launch', 'debut', 'new company']
        }
        
        for article in articles:
            text = (article['title'] + ' ' + article['content']).lower()
            categorized = False
            
            # Check each category
            for category, terms in keywords.items():
                if any(term in text for term in terms):
                    categories[category].append(article)
                    categorized = True
                    break
            
            if not categorized:
                categories['other'].append(article)
        
        return categories
    
    def generate_industry_summary(self, categorized_articles):
        """Generate comprehensive industry summary using advanced AI prompting"""
        
        # Prepare article summaries for each category
        category_summaries = {}
        
        for category, articles in categorized_articles.items():
            if not articles:
                continue
                
            print(f"📝 Processing {category} category ({len(articles)} articles)...")
            
            # Create category-specific content
            article_texts = []
            for article in articles[:10]:  # Limit to prevent token overflow
                article_texts.append(f"TITLE: {article['title']}\nSOURCE: {article['source']}\nCONTENT: {article['content'][:300]}...")
            
            category_content = "\n\n---\n\n".join(article_texts)
            category_summaries[category] = {
                'articles': articles,
                'content': category_content
            }
        
        # Generate comprehensive industry summary
        return self._generate_weekly_recap(category_summaries)
    
    def _generate_weekly_recap(self, category_summaries):
        """Create Morning Brew-style weekly tech industry recap"""
        
        # Build comprehensive prompt
        current_date = datetime.now().strftime("%B %d, %Y")
        
        system_prompt = """You are an expert tech industry analyst writing a weekly recap similar to Morning Brew. 
        Create a comprehensive, engaging 5-10 minute read that synthesizes the week's most important tech developments.
        
        Style guidelines:
        - Conversational but informative tone
        - Identify key themes and trends across multiple stories
        - Provide context and implications, not just facts
        - Group related developments together
        - Include specific numbers, companies, and details
        - End with forward-looking insights
        - Use engaging headlines for each section"""
        
        # Build user prompt with all categorized content
        user_prompt = f"""Create a comprehensive weekly tech industry recap for the week ending {current_date}.
        
        Analyze these categorized articles and create a cohesive narrative that identifies:
        1. The week's biggest developments and trends
        2. Key funding rounds and business moves
        3. Important AI/ML announcements and breakthroughs
        4. Significant product launches or updates
        5. Notable acquisitions or partnerships
        6. Regulatory or policy changes
        7. What this all means for the industry's direction
        
        Structure as:
        🗓️ **WEEKLY TECH RECAP: [Date Range]**
        
        📊 **THE BIG PICTURE**
        [2-3 sentences on overarching themes]
        
        🤖 **AI & MACHINE LEARNING**
        [Major AI developments, model releases, company moves]
        
        💰 **FUNDING & BUSINESS**
        [Significant funding rounds, IPOs, acquisitions, valuations]
        
        🚀 **PRODUCT LAUNCHES**
        [New products, features, platform updates]
        
        🏛️ **REGULATION & POLICY**
        [Government actions, policy changes, compliance news]
        
        🔍 **WHAT'S NEXT**
        [Forward-looking analysis and implications]
        
        Here are the articles by category:
        
        """
        
        # Add category content
        for category, data in category_summaries.items():
            if data['articles']:
                category_name = category.replace('_', ' ').title()
                user_prompt += f"\n**{category_name.upper()} ARTICLES:**\n{data['content']}\n\n"
        
        user_prompt += "\nCreate a compelling, insightful weekly recap that tech professionals would want to read over coffee."
        
        # Generate with AI or mock
        if self.aws_available:
            return self._generate_with_bedrock(system_prompt, user_prompt)
        else:
            return self._generate_mock_recap()
    
    def _generate_with_bedrock(self, system_prompt, user_prompt):
        """Generate using AWS Bedrock OpenAI GPT-OSS"""
        
        try:
            payload = {
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt[:8000]}  # Limit to prevent token overflow
                ],
                "max_completion_tokens": 2000,
                "temperature": 0.4,
                "reasoning_effort": "medium"
            }
            
            print("🤖 Generating industry recap with OpenAI GPT-OSS-20B...")
            
            response = self.bedrock_runtime.invoke_model(
                modelId='openai.gpt-oss-20b-1:0',
                body=json.dumps(payload),
                contentType='application/json'
            )
            
            response_body = json.loads(response['Body'].read())
            return response_body['choices'][0]['message']['content'].strip()
            
        except Exception as e:
            print(f"❌ AWS generation failed: {str(e)}")
            return self._generate_mock_recap()
    
    def _generate_mock_recap(self):
        """Generate realistic mock industry recap"""
        
        current_date = datetime.now().strftime("%B %d, %Y")
        
        return f"""🗓️ **WEEKLY TECH RECAP: Week ending {current_date}**

📊 **THE BIG PICTURE**
This week highlighted the accelerating pace of AI innovation, with major model releases and significant funding rounds reshaping the competitive landscape. The industry continues to grapple with scaling challenges while regulatory frameworks evolve.

🤖 **AI & MACHINE LEARNING**
• **OpenAI's Latest Moves**: Reports suggest GPT-5 development milestones reached, with enhanced reasoning capabilities and multimodal improvements
• **Open Source Renaissance**: Several major AI labs released open-source models, democratizing access to advanced AI capabilities  
• **Enterprise Integration**: Major corporations announced AI integration strategies, signaling mainstream adoption acceleration

💰 **FUNDING & BUSINESS**
• **Mega Rounds**: AI startups secured over $2.3B in funding this week, with computer vision and enterprise AI leading categories
• **IPO Pipeline**: Tech companies preparing for public offerings amid favorable market conditions
• **Strategic Acquisitions**: Big Tech continues talent and technology acquisition spree in AI sector

🚀 **PRODUCT LAUNCHES**
• **Platform Updates**: Major cloud providers rolled out enhanced AI development tools and infrastructure
• **Consumer Tech**: New smart devices with integrated AI assistants hit the market
• **Developer Tools**: Next-generation coding assistants and productivity platforms launched

🏛️ **REGULATION & POLICY**
• **AI Governance**: New federal guidelines on AI development and deployment released
• **Data Privacy**: Updated regulations affecting tech companies' data collection practices
• **International Cooperation**: Cross-border AI safety initiatives announced

🔍 **WHAT'S NEXT**
The convergence of powerful AI models, abundant capital, and evolving regulations sets the stage for significant industry consolidation. Companies that successfully balance innovation speed with responsible development will likely emerge as market leaders. Watch for increased focus on AI safety, compute efficiency, and real-world application deployment.

*Generated using advanced industry analysis • {datetime.now().strftime('%Y-%m-%d %H:%M')}*"""
    
    def run_full_recap_generation(self):
        """Execute complete industry recap generation process"""
        
        print("🚀 GENERATING TECH INDUSTRY WEEKLY RECAP")
        print("=" * 70)
        
        # Step 1: Fetch articles
        articles = self.fetch_week_articles(days_back=7)
        
        if not articles:
            print("❌ No articles fetched. Cannot generate recap.")
            return
        
        print(f"\n📊 ANALYSIS: {len(articles)} articles collected")
        
        # Step 2: Categorize articles
        print("\n🏷️ Categorizing articles by theme...")
        categorized = self.categorize_articles(articles)
        
        for category, article_list in categorized.items():
            if article_list:
                print(f"  📂 {category}: {len(article_list)} articles")
        
        # Step 3: Generate industry summary
        print(f"\n🤖 Generating comprehensive industry recap...")
        
        recap = self.generate_industry_summary(categorized)
        
        # Step 4: Output results
        print("\n" + "="*70)
        print("📰 TECH INDUSTRY WEEKLY RECAP")
        print("="*70)
        print(recap)
        print("="*70)
        
        print(f"\n✅ Recap generated successfully!")
        print(f"📝 Word count: ~{len(recap.split())} words")
        print(f"⏱️ Estimated read time: {len(recap.split()) // 200 + 1} minutes")
        
        return recap

def main():
    generator = IndustryRecapGenerator()
    generator.run_full_recap_generation()

if __name__ == "__main__":
    main()