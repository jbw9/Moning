import Foundation

struct MockData {
    static let sources = [
        NewsSource(name: "TechCrunch", domain: "techcrunch.com"),
        NewsSource(name: "VentureBeat", domain: "venturebeat.com"),
        NewsSource(name: "The Verge", domain: "theverge.com"),
        NewsSource(name: "Wired", domain: "wired.com")
    ]
    
    static let articles = [
        Article(
            title: "AI Breakthrough: GPT-5 Shows Human-Level Reasoning",
            summary: "OpenAI's latest model demonstrates unprecedented problem-solving abilities across multiple domains, marking a significant milestone in artificial intelligence development.",
            content: "OpenAI's latest model demonstrates unprecedented problem-solving abilities across multiple domains, marking a significant milestone in artificial intelligence development. The new GPT-5 model shows remarkable improvements in logical reasoning, mathematical problem-solving, and creative tasks that were previously challenging for AI systems.",
            source: sources[0],
            category: .artificialIntelligence,
            publishedAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date(),
            audioURL: "audio_1",
            audioDuration: 180,
            imageURL: nil
        ),
        Article(
            title: "Microsoft Copilot Integration Reaches 1 Billion Users",
            summary: "Microsoft's AI assistant now spans across all major Office applications, transforming workplace productivity for enterprise customers worldwide.",
            content: "Microsoft's AI assistant now spans across all major Office applications, transforming workplace productivity for enterprise customers worldwide. The integration includes advanced features for document creation, data analysis, and automated workflows.",
            source: sources[0],
            category: .artificialIntelligence,
            publishedAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
            audioURL: "audio_2",
            audioDuration: 150,
            imageURL: nil
        ),
        Article(
            title: "Startup Raises $100M for Quantum Computing Platform",
            summary: "IonQ secures massive funding round to accelerate commercial quantum computing applications for enterprise customers.",
            content: "IonQ secures massive funding round to accelerate commercial quantum computing applications for enterprise customers. The funding will be used to expand their quantum cloud platform and develop new algorithms for various industries.",
            source: sources[1],
            category: .startups,
            publishedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            audioURL: "audio_3",
            audioDuration: 210,
            imageURL: nil
        ),
        Article(
            title: "YC Demo Day: 15 AI Startups Raise $50M Combined",
            summary: "Y Combinator's latest batch showcases impressive AI-focused companies attracting significant investor interest in machine learning applications.",
            content: "Y Combinator's latest batch showcases impressive AI-focused companies attracting significant investor interest in machine learning applications. The startups cover various sectors including healthcare, finance, and developer tools.",
            source: sources[1],
            category: .startups,
            publishedAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
            audioURL: "audio_4",
            audioDuration: 195,
            imageURL: nil
        ),
        Article(
            title: "Apple Vision Pro Gets Major Update",
            summary: "Hardware innovations, software updates, and cutting-edge developments in augmented reality technology continue to evolve rapidly.",
            content: "Hardware innovations, software updates, and cutting-edge developments in augmented reality technology continue to evolve rapidly. The update includes improved hand tracking, new apps, and better battery optimization.",
            source: sources[2],
            category: .technology,
            publishedAt: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date(),
            audioURL: "audio_5",
            audioDuration: 165,
            imageURL: nil
        ),
        Article(
            title: "Tesla Announces New Chip Architecture",
            summary: "Revolutionary semiconductor design promises 10x performance improvement for autonomous driving and AI workloads in vehicles.",
            content: "Revolutionary semiconductor design promises 10x performance improvement for autonomous driving and AI workloads in vehicles. The new architecture uses advanced 3nm process technology.",
            source: sources[2],
            category: .technology,
            publishedAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
            audioURL: "audio_6",
            audioDuration: 175,
            imageURL: nil
        )
    ]
    
    static let categoryOverviews = [
        CategoryOverview(
            category: .artificialIntelligence,
            articleCount: 2,
            topHeadlines: [
                "AI Breakthrough: GPT-5 Shows Human-Leve...",
                "Microsoft Copilot Integration Reaches 1 Billi..."
            ],
            articles: Array(articles.filter { $0.category == .artificialIntelligence }.prefix(2))
        ),
        CategoryOverview(
            category: .startups,
            articleCount: 2,
            topHeadlines: [
                "Startup Raises $100M for Quantum...",
                "YC Demo Day: 15 AI Startups Raise $50M..."
            ],
            articles: Array(articles.filter { $0.category == .startups }.prefix(2))
        ),
        CategoryOverview(
            category: .technology,
            articleCount: 2,
            topHeadlines: [
                "Apple Vision Pro Gets Major Update...",
                "Tesla Announces New Chip Architecture..."
            ],
            articles: Array(articles.filter { $0.category == .technology }.prefix(2))
        )
    ]
}