import Foundation
import CoreData

// Lightweight models for widget use
struct WidgetArticle: Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let sourceName: String
    let category: String
    let publishedAt: Date
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}

struct WidgetNewsSource {
    let name: String
    let domain: String
}

// Simplified data service for widget
class WidgetDataService {
    private static let appGroupIdentifier = "group.com.jonathan.moning"
    
    static let shared = WidgetDataService()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        // Create the same data model as the main app
        let model = createDataModel()
        let container = NSPersistentContainer(name: "DataModel", managedObjectModel: model)
        
        // Use the shared App Group container
        if let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetDataService.appGroupIdentifier) {
            let storeURL = appGroupContainer.appendingPathComponent("DataModel.sqlite")
            container.persistentStoreDescriptions.first?.url = storeURL
            print("🔗 Widget using App Group container: \(storeURL)")
        } else {
            print("⚠️ Widget: App Group container not found")
        }
        
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Widget Core Data error: \(error)")
            } else {
                print("✅ Widget Core Data loaded successfully")
            }
        }
        
        return container
    }()
    
    private init() {}
    
    func fetchLatestArticles(limit: Int = 5) async -> [WidgetArticle] {
        return await withCheckedContinuation { continuation in
            let context = persistentContainer.viewContext
            
            context.perform {
                let request = NSFetchRequest<NSManagedObject>(entityName: "ArticleEntity")
                request.sortDescriptors = [NSSortDescriptor(key: "publishedAt", ascending: false)]
                request.fetchLimit = limit
                
                do {
                    let entities = try context.fetch(request)
                    let articles = entities.compactMap { entity -> WidgetArticle? in
                        guard let id = entity.value(forKey: "id") as? UUID,
                              let title = entity.value(forKey: "title") as? String,
                              let summary = entity.value(forKey: "summary") as? String,
                              let publishedAt = entity.value(forKey: "publishedAt") as? Date,
                              let category = entity.value(forKey: "category") as? String else {
                            return nil
                        }
                        
                        // Get source name (handle relationship)
                        let sourceName: String
                        if let sourceEntity = entity.value(forKey: "source") as? NSManagedObject,
                           let name = sourceEntity.value(forKey: "name") as? String {
                            sourceName = name
                        } else {
                            sourceName = "Unknown Source"
                        }
                        
                        return WidgetArticle(
                            id: id,
                            title: title,
                            summary: summary,
                            sourceName: sourceName,
                            category: category,
                            publishedAt: publishedAt
                        )
                    }
                    
                    print("📱 Widget fetched \(articles.count) articles from Core Data")
                    continuation.resume(returning: articles)
                } catch {
                    print("❌ Widget error fetching articles: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    // Recreate the same data model structure as SimplePersistenceController
    private func createDataModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create Article Entity
        let articleEntity = NSEntityDescription()
        articleEntity.name = "ArticleEntity"
        
        // Add Article attributes (simplified for widget needs)
        let articleAttributes = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("title", type: .stringAttributeType, optional: false),
            createAttribute("summary", type: .stringAttributeType, optional: false),
            createAttribute("content", type: .stringAttributeType, optional: false),
            createAttribute("category", type: .stringAttributeType, optional: false),
            createAttribute("publishedAt", type: .dateAttributeType, optional: false),
            createAttribute("audioURL", type: .stringAttributeType, optional: true),
            createAttribute("audioDuration", type: .doubleAttributeType, optional: true, defaultValue: 0.0),
            createAttribute("audioPlaybackPosition", type: .doubleAttributeType, optional: true, defaultValue: 0.0),
            createAttribute("imageURL", type: .stringAttributeType, optional: true),
            createAttribute("sourceURL", type: .stringAttributeType, optional: true),
            createAttribute("tags", type: .transformableAttributeType, optional: true),
            createAttribute("priority", type: .stringAttributeType, optional: false, defaultValue: "normal"),
            createAttribute("readingTimeMinutes", type: .integer16AttributeType, optional: false, defaultValue: 3),
            createAttribute("sentiment", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            createAttribute("status", type: .stringAttributeType, optional: false, defaultValue: "unread"),
            createAttribute("isBookmarked", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("readAt", type: .dateAttributeType, optional: true),
            createAttribute("userRating", type: .integer16AttributeType, optional: true, defaultValue: 0)
        ]
        
        articleEntity.properties = articleAttributes
        
        // Create NewsSource Entity
        let sourceEntity = NSEntityDescription()
        sourceEntity.name = "NewsSourceEntity"
        
        let sourceAttributes = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("name", type: .stringAttributeType, optional: false),
            createAttribute("domain", type: .stringAttributeType, optional: false),
            createAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            createAttribute("reliability", type: .doubleAttributeType, optional: false, defaultValue: 1.0),
            createAttribute("logoURL", type: .stringAttributeType, optional: true),
            createAttribute("rssURL", type: .stringAttributeType, optional: true),
            createAttribute("categories", type: .transformableAttributeType, optional: true)
        ]
        
        sourceEntity.properties = sourceAttributes
        
        // Create relationships
        let sourceToArticles = NSRelationshipDescription()
        sourceToArticles.name = "articles"
        sourceToArticles.destinationEntity = articleEntity
        sourceToArticles.minCount = 0
        sourceToArticles.maxCount = 0 // to-many
        sourceToArticles.deleteRule = .cascadeDeleteRule
        
        let articleToSource = NSRelationshipDescription()
        articleToSource.name = "source"
        articleToSource.destinationEntity = sourceEntity
        articleToSource.minCount = 1
        articleToSource.maxCount = 1 // to-one
        articleToSource.deleteRule = .nullifyDeleteRule
        
        sourceToArticles.inverseRelationship = articleToSource
        articleToSource.inverseRelationship = sourceToArticles
        
        sourceEntity.properties.append(sourceToArticles)
        articleEntity.properties.append(articleToSource)
        
        model.entities = [articleEntity, sourceEntity]
        
        return model
    }
    
    private func createAttribute(_ name: String, type: NSAttributeType, optional: Bool, defaultValue: Any? = nil) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        if let defaultValue = defaultValue {
            attribute.defaultValue = defaultValue
        }
        return attribute
    }
}