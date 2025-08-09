import CoreData
import Foundation
import Combine

@MainActor
class SimpleDataService: ObservableObject {
    private let persistenceController: SimplePersistenceController
    private let newsService = NewsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var articles: [Article] = []
    @Published var sources: [NewsSource] = []
    @Published var userPreferences: UserPreferences?
    @Published var isLoadingNews = false
    @Published var lastNewsUpdate: Date?
    @Published var newsErrorMessage: String?
    
    
    init(persistenceController: SimplePersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadInitialData()
        setupNewsServiceBinding()
    }
    
    // MARK: - Articles
    
    func loadArticles() {
        let request: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ArticleEntity.publishedAt, ascending: false)]
        
        do {
            let articleEntities = try persistenceController.container.viewContext.fetch(request)
            let convertedArticles = articleEntities.compactMap { convertToArticle($0) }
            self.articles = convertedArticles
            
            // If no articles exist, fetch from NewsAPI
            if convertedArticles.isEmpty {
                print("📊 No articles found in Core Data, will fetch from NewsAPI")
                Task {
                    await fetchLatestNews()
                }
            }
        } catch {
            print("❌ Error loading articles from Core Data: \(error)")
            // Start fresh and fetch from NewsAPI
            self.articles = []
            Task {
                await fetchLatestNews()
            }
        }
    }
    
    func saveArticle(_ article: Article) {
        
        let context = persistenceController.container.viewContext
        
        // Check if article already exists
        let request: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", article.id as CVarArg)
        
        do {
            let existingArticles = try context.fetch(request)
            let articleEntity = existingArticles.first ?? ArticleEntity(context: context)
            
            // Update or create article entity
            updateArticleEntity(articleEntity, with: article)
            
            persistenceController.save()
            loadArticles() // Refresh the articles list
        } catch {
            print("Error saving article: \(error)")
        }
    }
    
    func deleteArticle(_ article: Article) {
        
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", article.id as CVarArg)
        
        do {
            let articles = try context.fetch(request)
            articles.forEach { context.delete($0) }
            persistenceController.save()
            loadArticles()
        } catch {
            print("Error deleting article: \(error)")
        }
    }
    
    func getArticlesByCategory(_ category: CategoryType) -> [Article] {
        return articles.filter { $0.category == category }
    }
    
    func getUnreadArticles() -> [Article] {
        return articles.filter { $0.status == .unread }
    }
    
    func markArticleAsRead(_ article: Article) {
        var updatedArticle = article
        updatedArticle.status = .read
        updatedArticle.readAt = Date()
        saveArticle(updatedArticle)
    }
    
    func toggleBookmark(for article: Article) {
        var updatedArticle = article
        updatedArticle.isBookmarked.toggle()
        updatedArticle.status = updatedArticle.isBookmarked ? .bookmarked : .read
        saveArticle(updatedArticle)
    }
    
    // MARK: - News Sources
    
    func loadSources() {
        let request: NSFetchRequest<NewsSourceEntity> = NewsSourceEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NewsSourceEntity.name, ascending: true)]
        
        do {
            let sourceEntities = try persistenceController.container.viewContext.fetch(request)
            let convertedSources = sourceEntities.compactMap { convertToNewsSource($0) }
            self.sources = convertedSources
        } catch {
            print("Error loading sources: \(error)")
            self.sources = []
        }
    }
    
    // MARK: - User Preferences
    
    func loadUserPreferences() {
        
        let request: NSFetchRequest<UserPreferencesEntity> = UserPreferencesEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let preferencesEntities = try persistenceController.container.viewContext.fetch(request)
            if let entity = preferencesEntities.first {
                self.userPreferences = convertToUserPreferences(entity)
            } else {
                // Create default preferences
                self.userPreferences = UserPreferences.default
                saveUserPreferences(UserPreferences.default)
            }
        } catch {
            print("Error loading user preferences: \(error)")
            self.userPreferences = UserPreferences.default
        }
    }
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        
        let context = persistenceController.container.viewContext
        
        let request: NSFetchRequest<UserPreferencesEntity> = UserPreferencesEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let existingPreferences = try context.fetch(request)
            let preferencesEntity = existingPreferences.first ?? UserPreferencesEntity(context: context)
            
            updatePreferencesEntity(preferencesEntity, with: preferences)
            
            persistenceController.save()
            self.userPreferences = preferences
        } catch {
            print("Error saving user preferences: \(error)")
        }
    }
    
    // MARK: - Initial Data Setup
    
    private func loadInitialData() {
        loadArticles()
        loadSources()
        loadUserPreferences()
        
        // If we have no articles, fetch from news API
        if articles.isEmpty {
            Task {
                await fetchLatestNews()
            }
        }
    }
    
    // MARK: - News Service Integration
    
    private func setupNewsServiceBinding() {
        // Bind NewsService published properties to our published properties
        newsService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoadingNews, on: self)
            .store(in: &cancellables)
        
        newsService.$lastUpdateTime
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastNewsUpdate, on: self)
            .store(in: &cancellables)
        
        newsService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.newsErrorMessage, on: self)
            .store(in: &cancellables)
        
        newsService.$articles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newArticles in
                self?.handleFetchedArticles(newArticles)
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func fetchLatestNews() async {
        guard let preferences = userPreferences else {
            // Use default categories if preferences not loaded
            await newsService.fetchLatestArticles(categories: [.artificialIntelligence, .technology, .startups])
            return
        }
        
        let categories = preferences.preferredCategories.isEmpty ? 
            CategoryType.allCases : preferences.preferredCategories
        
        await newsService.fetchLatestArticles(categories: categories)
    }
    
    @MainActor
    func refreshNews() async {
        await fetchLatestNews()
    }
    
    @MainActor
    func fetchArticlesForCategory(_ category: CategoryType) async {
        do {
            let categoryArticles = try await newsService.fetchArticlesForCategory(category)
            handleFetchedArticles(categoryArticles)
        } catch {
            newsErrorMessage = error.localizedDescription
        }
    }
    
    private func handleFetchedArticles(_ fetchedArticles: [Article]) {
        // Merge fetched articles with existing ones, avoiding duplicates
        var updatedArticles = articles
        
        for article in fetchedArticles {
            // Check if article already exists (by URL or title similarity)
            let exists = updatedArticles.contains { existingArticle in
                existingArticle.sourceURL == article.sourceURL ||
                (existingArticle.title.lowercased() == article.title.lowercased() && 
                 existingArticle.source.name == article.source.name)
            }
            
            if !exists {
                updatedArticles.append(article)
                // Save new article to Core Data
                saveArticle(article)
            }
        }
        
        // Sort by publication date
        self.articles = updatedArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        // Articles successfully fetched and stored
        if !fetchedArticles.isEmpty {
            print("✅ Successfully fetched \(fetchedArticles.count) articles from NewsAPI")
        }
    }
    
    func shouldRefreshNews() -> Bool {
        guard let lastUpdate = lastNewsUpdate else { return true }
        
        // Refresh if it's been more than 30 minutes
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        return lastUpdate < thirtyMinutesAgo
    }
    
    // MARK: - Conversion Helpers
    
    private func convertToArticle(_ entity: ArticleEntity) -> Article? {
        guard let id = entity.id,
              let title = entity.title,
              let summary = entity.summary,
              let content = entity.content,
              let publishedAt = entity.publishedAt,
              let sourceEntity = entity.source,
              let source = convertToNewsSource(sourceEntity),
              let categoryString = entity.category,
              let category = CategoryType(rawValue: categoryString),
              let priorityString = entity.priority,
              let priority = ArticlePriority(rawValue: priorityString),
              let statusString = entity.status,
              let status = ArticleStatus(rawValue: statusString) else {
            return nil
        }
        
        return Article(
            id: id,
            title: title,
            summary: summary,
            content: content,
            source: source,
            category: category,
            publishedAt: publishedAt,
            audioURL: entity.audioURL,
            audioDuration: entity.audioDuration,
            imageURL: entity.imageURL,
            sourceURL: entity.sourceURL,
            tags: entity.tags ?? [],
            priority: priority,
            readingTimeMinutes: Int(entity.readingTimeMinutes),
            sentiment: entity.sentiment,
            status: status,
            isBookmarked: entity.isBookmarked,
            readAt: entity.readAt,
            audioPlaybackPosition: entity.audioPlaybackPosition,
            userRating: entity.userRating > 0 ? Int(entity.userRating) : nil
        )
    }
    
    private func convertToNewsSource(_ entity: NewsSourceEntity) -> NewsSource? {
        guard let id = entity.id,
              let name = entity.name,
              let domain = entity.domain else {
            return nil
        }
        
        let categories = (entity.categories ?? []).compactMap { CategoryType(rawValue: $0) }
        
        return NewsSource(
            id: id,
            name: name,
            domain: domain,
            isActive: entity.isActive,
            reliability: entity.reliability,
            categories: categories,
            rssURL: entity.rssURL,
            logoURL: entity.logoURL
        )
    }
    
    private func convertToUserPreferences(_ entity: UserPreferencesEntity) -> UserPreferences? {
        guard let dailyDigestTime = entity.dailyDigestTime else {
            return nil
        }
        
        let preferredCategories = (entity.preferredCategories ?? []).compactMap { CategoryType(rawValue: $0) }
        
        return UserPreferences(
            preferredCategories: preferredCategories,
            readingSpeed: Int(entity.readingSpeed),
            audioPlaybackSpeed: entity.audioPlaybackSpeed,
            notificationsEnabled: entity.notificationsEnabled,
            dailyDigestTime: dailyDigestTime,
            autoPlayAudio: entity.autoPlayAudio,
            offlineModeEnabled: entity.offlineModeEnabled,
            dataSaverMode: entity.dataSaverMode,
            preferredAudioVoice: entity.preferredAudioVoice ?? "system"
        )
    }
    
    private func updateArticleEntity(_ entity: ArticleEntity, with article: Article) {
        entity.id = article.id
        entity.title = article.title
        entity.summary = article.summary
        entity.content = article.content
        entity.category = article.category.rawValue
        entity.publishedAt = article.publishedAt
        entity.audioURL = article.audioURL
        entity.audioDuration = article.audioDuration
        entity.imageURL = article.imageURL
        entity.sourceURL = article.sourceURL
        entity.tags = article.tags
        entity.priority = article.priority.rawValue
        entity.readingTimeMinutes = Int16(article.readingTimeMinutes)
        entity.sentiment = article.sentiment
        entity.status = article.status.rawValue
        entity.isBookmarked = article.isBookmarked
        entity.readAt = article.readAt
        entity.audioPlaybackPosition = article.audioPlaybackPosition
        entity.userRating = article.userRating.map { Int16($0) } ?? 0
        
        // Handle source relationship
        if entity.source?.id != article.source.id {
            let context = persistenceController.container.viewContext
            let sourceRequest: NSFetchRequest<NewsSourceEntity> = NewsSourceEntity.fetchRequest()
            sourceRequest.predicate = NSPredicate(format: "id == %@", article.source.id as CVarArg)
            
            do {
                let sources = try context.fetch(sourceRequest)
                if let sourceEntity = sources.first {
                    entity.source = sourceEntity
                } else {
                    // Create new source if it doesn't exist
                    let newSourceEntity = NewsSourceEntity(context: context)
                    updateSourceEntity(newSourceEntity, with: article.source)
                    entity.source = newSourceEntity
                }
            } catch {
                print("Error setting article source: \(error)")
            }
        }
    }
    
    private func updateSourceEntity(_ entity: NewsSourceEntity, with source: NewsSource) {
        entity.id = source.id
        entity.name = source.name
        entity.domain = source.domain
        entity.isActive = source.isActive
        entity.reliability = source.reliability
        entity.categories = source.categories.map { $0.rawValue }
        entity.rssURL = source.rssURL
        entity.logoURL = source.logoURL
    }
    
    private func updatePreferencesEntity(_ entity: UserPreferencesEntity, with preferences: UserPreferences) {
        entity.id = entity.id ?? UUID()
        entity.preferredCategories = preferences.preferredCategories.map { $0.rawValue }
        entity.readingSpeed = Int16(preferences.readingSpeed)
        entity.audioPlaybackSpeed = preferences.audioPlaybackSpeed
        entity.notificationsEnabled = preferences.notificationsEnabled
        entity.dailyDigestTime = preferences.dailyDigestTime
        entity.autoPlayAudio = preferences.autoPlayAudio
        entity.offlineModeEnabled = preferences.offlineModeEnabled
        entity.dataSaverMode = preferences.dataSaverMode
        entity.preferredAudioVoice = preferences.preferredAudioVoice
    }
}