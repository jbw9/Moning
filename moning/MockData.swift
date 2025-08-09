import Foundation

struct MockData {
    static let sources = [
        NewsSource(name: "TechCrunch", domain: "techcrunch.com", categories: [.artificialIntelligence, .startups, .technology]),
        NewsSource(name: "VentureBeat", domain: "venturebeat.com", categories: [.artificialIntelligence, .startups]),
        NewsSource(name: "The Verge", domain: "theverge.com", categories: [.technology, .mobile]),
        NewsSource(name: "Wired", domain: "wired.com", categories: [.technology, .cybersecurity])
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
            sourceURL: "https://techcrunch.com/ai-breakthrough-gpt5",
            tags: ["AI", "OpenAI", "GPT-5", "Machine Learning"],
            priority: .breaking,
            readingTimeMinutes: 5
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
            sourceURL: "https://techcrunch.com/microsoft-copilot-users",
            tags: ["Microsoft", "Copilot", "AI", "Productivity"],
            priority: .high,
            readingTimeMinutes: 4
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
            sourceURL: "https://venturebeat.com/ionq-funding-round",
            tags: ["IonQ", "Quantum Computing", "Funding", "Series B"],
            priority: .high,
            readingTimeMinutes: 6
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
            sourceURL: "https://venturebeat.com/yc-demo-day-ai",
            tags: ["Y Combinator", "Demo Day", "AI Startups", "Fundraising"],
            priority: .normal,
            readingTimeMinutes: 5
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
            sourceURL: "https://theverge.com/apple-vision-pro-update",
            tags: ["Apple", "Vision Pro", "AR", "Update"],
            priority: .normal,
            readingTimeMinutes: 4
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
            sourceURL: "https://theverge.com/tesla-chip-architecture",
            tags: ["Tesla", "Semiconductors", "Autonomous Driving", "Hardware"],
            priority: .normal,
            readingTimeMinutes: 4
        )
    ]
    
    static let categoryOverviews = [
        CategoryOverview(
            category: .artificialIntelligence,
            articleCount: 2,
            unreadCount: 1,
            topHeadlines: [
                "AI Breakthrough: GPT-5 Shows Human-Level Reasoning",
                "Microsoft Copilot Integration Reaches 1 Billion Users"
            ],
            articles: Array(articles.filter { $0.category == .artificialIntelligence }.prefix(2))
        ),
        CategoryOverview(
            category: .startups,
            articleCount: 2,
            unreadCount: 2,
            topHeadlines: [
                "Startup Raises $100M for Quantum Computing Platform",
                "YC Demo Day: 15 AI Startups Raise $50M Combined"
            ],
            articles: Array(articles.filter { $0.category == .startups }.prefix(2))
        ),
        CategoryOverview(
            category: .technology,
            articleCount: 2,
            unreadCount: 1,
            topHeadlines: [
                "Apple Vision Pro Gets Major Update",
                "Tesla Announces New Chip Architecture"
            ],
            articles: Array(articles.filter { $0.category == .technology }.prefix(2))
        )
    ]
    
    // Sample user preferences
    static let sampleUserPreferences = UserPreferences.default
    
    // Sample reading sessions
    static let sampleReadingSessions = [
        ReadingSession(
            articleId: articles[0].id,
            startTime: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date(),
            endTime: Calendar.current.date(byAdding: .minute, value: -10, to: Date()) ?? Date(),
            durationSeconds: 300,
            completionPercentage: 1.0,
            readingMode: .audio
        ),
        ReadingSession(
            articleId: articles[1].id,
            startTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
            durationSeconds: 120,
            completionPercentage: 0.6,
            readingMode: .text
        )
    ]
}