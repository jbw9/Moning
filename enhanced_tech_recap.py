#!/usr/bin/env python3
"""
Enhanced Tech Industry Weekly Recap Generator
Creates realistic Morning Brew-style recaps using actual article data
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

class EnhancedTechRecap:
    def __init__(self):
        self.sources = [
            {"name": "TechCrunch", "url": "https://techcrunch.com/feed/", "weight": 1.0},
            {"name": "The Verge", "url": "https://www.theverge.com/rss/index.xml", "weight": 0.9},
            {"name": "Ars Technica", "url": "https://feeds.arstechnica.com/arstechnica/index", "weight": 0.95},
            {"name": "MIT Technology Review", "url": "https://www.technologyreview.com/feed/", "weight": 0.95},
            {"name": "Wired", "url": "https://www.wired.com/feed/rss", "weight": 0.9},
        ]
    
    def fetch_and_analyze_articles(self) -> Dict:
        """Fetch and analyze articles with better categorization"""
        
        one_week_ago = datetime.now() - timedelta(days=7)
        articles = []
        
        print("🔍 ANALYZING THIS WEEK'S TECH LANDSCAPE")
        print("=" * 60)
        
        for source in self.sources:
            try:
                print(f"📡 Scanning {source['name']}...")
                feed = feedparser.parse(source['url'])
                
                for entry in feed.entries[:15]:  # Limit per source for quality
                    pub_date = None
                    if hasattr(entry, 'published_parsed') and entry.published_parsed:
                        pub_date = datetime(*entry.published_parsed[:6])
                    
                    if pub_date and pub_date >= one_week_ago:
                        article = {
                            'title': entry.title,
                            'url': entry.link,
                            'description': entry.get('description', '')[:500],
                            'source': source['name'],
                            'published': pub_date,
                            'raw_entry': entry
                        }
                        articles.append(article)
                        
            except Exception as e:
                print(f"❌ {source['name']}: {str(e)}")
                continue
        
        # Enhanced analysis
        analysis = self.analyze_article_trends(articles)
        print(f"✅ Analyzed {len(articles)} articles")
        return analysis
    
    def analyze_article_trends(self, articles: List[Dict]) -> Dict:
        """Advanced trend analysis of articles"""
        
        # Key company/topic tracking
        ai_companies = ['openai', 'anthropic', 'google', 'microsoft', 'nvidia', 'meta']
        ai_terms = ['gpt', 'claude', 'gemini', 'llm', 'artificial intelligence', 'machine learning', 'ai model']
        
        trends = {
            'ai_stories': [],
            'security_stories': [],
            'startup_funding': [],
            'big_tech_moves': [],
            'breakthrough_tech': [],
            'regulatory_news': [],
        }
        
        major_stories = []
        
        for article in articles:
            text = (article['title'] + ' ' + article['description']).lower()
            
            # Categorize and score importance
            importance = 0
            categories = []
            
            # AI/ML detection
            if any(term in text for term in ai_terms + ai_companies):
                trends['ai_stories'].append(article)
                categories.append('AI')
                importance += 2
            
            # Security issues
            if any(term in text for term in ['hack', 'security', 'breach', 'vulnerability', 'cyber']):
                trends['security_stories'].append(article)
                categories.append('Security')
                importance += 1.5
            
            # Startup/funding
            if any(term in text for term in ['funding', 'raises', 'series', 'investment', 'venture']):
                trends['startup_funding'].append(article)
                categories.append('Funding')
                importance += 1
            
            # Big tech moves
            if any(term in text for term in ['apple', 'google', 'microsoft', 'amazon', 'meta', 'tesla']):
                trends['big_tech_moves'].append(article)
                categories.append('Big Tech')
                importance += 1.5
            
            # Breakthrough/major announcements
            if any(term in text for term in ['launches', 'announces', 'reveals', 'breakthrough', 'first']):
                trends['breakthrough_tech'].append(article)
                importance += 1
            
            # Regulatory/policy
            if any(term in text for term in ['regulation', 'policy', 'government', 'congress', 'eu']):
                trends['regulatory_news'].append(article)
                categories.append('Regulatory')
                importance += 1
            
            article['categories'] = categories
            article['importance'] = importance
            
            if importance >= 2:
                major_stories.append(article)
        
        # Sort major stories by importance and recency
        major_stories.sort(key=lambda x: (x['importance'], x['published']), reverse=True)
        
        return {
            'articles': articles,
            'trends': trends,
            'major_stories': major_stories[:10],
            'stats': {
                'total_articles': len(articles),
                'ai_focus': len(trends['ai_stories']),
                'security_focus': len(trends['security_stories']),
                'funding_stories': len(trends['startup_funding']),
                'big_tech_stories': len(trends['big_tech_moves']),
            }
        }
    
    def create_realistic_industry_recap(self, analysis: Dict) -> str:
        """Create realistic industry recap using actual article data"""
        
        major_stories = analysis['major_stories']
        trends = analysis['trends']
        stats = analysis['stats']
        
        current_date = datetime.now().strftime("%B %d, %Y")
        
        # Find the week's biggest story
        biggest_story = major_stories[0] if major_stories else None
        
        # Identify key themes based on actual data
        themes = []
        if stats['ai_focus'] >= 3:
            themes.append(('AI Innovation Surge', trends['ai_stories'][:3]))
        if stats['security_focus'] >= 2:
            themes.append(('Cybersecurity Spotlight', trends['security_stories'][:2]))
        if stats['big_tech_stories'] >= 3:
            themes.append(('Big Tech Strategic Moves', trends['big_tech_moves'][:3]))
        if stats['funding_stories'] >= 2:
            themes.append(('Startup Funding Landscape', trends['startup_funding'][:3]))
        
        recap = f"""# 📰 Tech Weekly: The Industry Pulse
*Week of {current_date}*

---

## 🔥 **THIS WEEK'S HEADLINE**

"""
        
        if biggest_story:
            recap += f"""**{biggest_story['title']}**
            
The tech world's attention turned to this major development from {biggest_story['source']}. {biggest_story['description'][:300]}...
            
This story matters because it signals broader shifts in how the industry approaches innovation, competition, and market positioning. The ripple effects will likely influence strategic decisions across multiple companies in the coming weeks.

[Read the full story]({biggest_story['url']})

---

"""
        
        recap += "## 📊 **KEY INDUSTRY THEMES**\n\n"
        
        for theme_name, theme_articles in themes:
            recap += f"### {theme_name}\n\n"
            
            if theme_articles:
                for article in theme_articles:
                    recap += f"- **{article['title']}** ({article['source']})\n"
                    recap += f"  {article['description'][:150]}...\n\n"
                
                # Add analysis based on theme
                if 'AI' in theme_name:
                    recap += "The AI landscape continues its rapid evolution, with companies racing to deploy more capable and efficient systems. What's particularly notable is the shift from research breakthroughs to production deployments.\n\n"
                elif 'Security' in theme_name:
                    recap += "Security remains a top priority as digital infrastructure becomes more complex and attack vectors multiply. These incidents highlight the ongoing cat-and-mouse game between security teams and threat actors.\n\n"
                elif 'Big Tech' in theme_name:
                    recap += "Major technology companies are making strategic pivots that reflect changing market conditions and competitive pressures. These moves often signal broader industry trends worth watching.\n\n"
                elif 'Funding' in theme_name:
                    recap += "Despite economic uncertainties, investor appetite for innovative technology companies remains strong, particularly in areas like AI, cybersecurity, and enterprise software.\n\n"
        
        recap += """---

## 🔮 **LOOKING AHEAD**

**Next Week's Watch List:**
- Earnings reports from major tech companies will reveal how AI investments are translating to revenue
- Regulatory responses to this week's developments, particularly around AI and data privacy
- Market reactions to the strategic moves announced this week

**Industry Implications:**
The pace of technological change continues to accelerate, with particular intensity in AI and cybersecurity. Companies that can effectively balance innovation with security and regulatory compliance are positioning themselves for long-term success.

---

## 💡 **THE BOTTOM LINE**

This week reinforced that we're witnessing a fundamental reshaping of the technology landscape. The convergence of AI capabilities, security challenges, and competitive pressures is creating both unprecedented opportunities and risks.

For business leaders: Focus on building adaptable technology strategies that can evolve with the rapidly changing landscape.

For investors: Pay attention to companies that demonstrate not just innovation, but the ability to execute and scale their solutions effectively.

For everyone else: The decisions being made in boardrooms this week will shape the technology you use for years to come.

---

📊 **This Week by the Numbers:**
- {stats['total_articles']} articles analyzed across {len(analysis['trends'])} categories
- {stats['ai_focus']} AI & ML developments tracked
- {stats['security_focus']} cybersecurity incidents reported  
- {stats['funding_stories']} funding announcements
- {stats['big_tech_stories']} big tech strategic moves

*Sources: TechCrunch, The Verge, Ars Technica, MIT Technology Review, Wired*

---

*Ready for next week's recap? The tech industry never sleeps, and neither do we.* 🚀
"""
        
        return recap
    
    def generate_with_aws_bedrock(self, analysis: Dict) -> Optional[str]:
        """Generate recap using AWS Bedrock with better error handling"""
        try:
            bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-west-2')
            
            # Create focused prompt with actual article data
            major_stories = analysis['major_stories'][:5]
            article_context = "\n".join([
                f"• {article['title']} ({article['source']}) - {article['description'][:200]}..."
                for article in major_stories
            ])
            
            prompt = f"""You are an expert tech industry analyst writing a Morning Brew-style weekly recap. 

This week's top tech stories:
{article_context}

Industry stats: {analysis['stats']['ai_focus']} AI stories, {analysis['stats']['security_focus']} security stories, {analysis['stats']['big_tech_stories']} big tech moves.

Write an engaging 800-word industry recap covering:
1. Week's biggest story with analysis
2. 3-4 key industry themes with insights
3. What to watch next week
4. Bottom line takeaway

Use a conversational, insightful tone like Morning Brew. Include specific company names and numbers where relevant."""

            payload = {
                "messages": [{"role": "user", "content": prompt}],
                "max_completion_tokens": 2000,
                "temperature": 0.7
            }
            
            print("🤖 Generating with OpenAI GPT-OSS-20B...")
            
            response = bedrock_runtime.invoke_model(
                modelId='openai.gpt-oss-20b-1:0',
                body=json.dumps(payload),
                contentType='application/json'
            )
            
            # Better response parsing
            response_body = response['Body'].read().decode('utf-8')
            response_json = json.loads(response_body)
            
            if 'choices' in response_json:
                return response_json['choices'][0]['message']['content'].strip()
            else:
                print(f"❌ Unexpected response format: {response_json}")
                return None
                
        except Exception as e:
            print(f"❌ AWS generation error: {str(e)}")
            return None
    
    def run_enhanced_recap(self):
        """Run the enhanced industry recap generation"""
        
        print("🚀 ENHANCED TECH INDUSTRY WEEKLY RECAP")
        print("=" * 80)
        
        # Analyze articles
        analysis = self.fetch_and_analyze_articles()
        
        if analysis['stats']['total_articles'] < 5:
            print("❌ Insufficient articles for meaningful recap")
            return
        
        print(f"\n📈 Analysis complete: {analysis['stats']}")
        
        # Try AWS generation first
        print("\n" + "="*80)
        print("🤖 GENERATING PROFESSIONAL INDUSTRY RECAP")
        print("="*80)
        
        aws_recap = self.generate_with_aws_bedrock(analysis)
        
        if aws_recap:
            print("\n🎉 GENERATED WITH OPENAI GPT-OSS-20B:")
            print("="*80)
            print(aws_recap)
        else:
            print("\n📝 CREATING REALISTIC DEMO RECAP:")
            print("="*80)
            realistic_recap = self.create_realistic_industry_recap(analysis)
            print(realistic_recap)

def main():
    generator = EnhancedTechRecap()
    generator.run_enhanced_recap()

if __name__ == "__main__":
    main()