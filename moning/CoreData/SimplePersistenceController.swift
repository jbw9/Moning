import CoreData
import Foundation

class SimplePersistenceController: ObservableObject {
    static let shared = SimplePersistenceController()
    
    static var preview: SimplePersistenceController = {
        let result = SimplePersistenceController(inMemory: true)
        // Add sample data for previews if needed
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        // Create the model programmatically since .xcdatamodeld isn't working yet
        let model = Self.createDataModel()
        
        container = NSPersistentContainer(name: "DataModel", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Use App Group container for shared data access between app and widget
            if let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jonathan.moning") {
                let storeURL = appGroupContainer.appendingPathComponent("DataModel.sqlite")
                container.persistentStoreDescriptions.first?.url = storeURL
                print("✅ Using App Group container: \(storeURL)")
            } else {
                print("⚠️ App Group container not found, falling back to default location")
            }
        }
        
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                // For now, just log the error instead of crashing
                print("❌ Core Data failed to load - will fetch fresh data from NewsAPI")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    private static func createDataModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create Article Entity
        let articleEntity = NSEntityDescription()
        articleEntity.name = "ArticleEntity"
        articleEntity.managedObjectClassName = NSStringFromClass(ArticleEntity.self)
        
        // Add Article attributes
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
        sourceEntity.managedObjectClassName = NSStringFromClass(NewsSourceEntity.self)
        
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
        
        // Create ReadingSession Entity
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "ReadingSessionEntity"
        sessionEntity.managedObjectClassName = NSStringFromClass(ReadingSessionEntity.self)
        
        let sessionAttributes = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("startTime", type: .dateAttributeType, optional: false),
            createAttribute("endTime", type: .dateAttributeType, optional: true),
            createAttribute("durationSeconds", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            createAttribute("completionPercentage", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            createAttribute("readingMode", type: .stringAttributeType, optional: false, defaultValue: "text")
        ]
        
        sessionEntity.properties = sessionAttributes
        
        // Create UserPreferences Entity
        let prefsEntity = NSEntityDescription()
        prefsEntity.name = "UserPreferencesEntity"
        prefsEntity.managedObjectClassName = NSStringFromClass(UserPreferencesEntity.self)
        
        let prefsAttributes = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("preferredCategories", type: .transformableAttributeType, optional: true),
            createAttribute("readingSpeed", type: .integer16AttributeType, optional: false, defaultValue: 250),
            createAttribute("audioPlaybackSpeed", type: .doubleAttributeType, optional: false, defaultValue: 1.0),
            createAttribute("notificationsEnabled", type: .booleanAttributeType, optional: false, defaultValue: true),
            createAttribute("dailyDigestTime", type: .dateAttributeType, optional: false),
            createAttribute("autoPlayAudio", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("offlineModeEnabled", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("dataSaverMode", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("preferredAudioVoice", type: .stringAttributeType, optional: false, defaultValue: "system")
        ]
        
        prefsEntity.properties = prefsAttributes
        
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
        
        // Add relationship for reading sessions
        let articleToSessions = NSRelationshipDescription()
        articleToSessions.name = "readingSessions"
        articleToSessions.destinationEntity = sessionEntity
        articleToSessions.minCount = 0
        articleToSessions.maxCount = 0 // to-many
        articleToSessions.deleteRule = .cascadeDeleteRule
        
        let sessionToArticle = NSRelationshipDescription()
        sessionToArticle.name = "article"
        sessionToArticle.destinationEntity = articleEntity
        sessionToArticle.minCount = 1
        sessionToArticle.maxCount = 1 // to-one
        sessionToArticle.deleteRule = .nullifyDeleteRule
        
        articleToSessions.inverseRelationship = sessionToArticle
        sessionToArticle.inverseRelationship = articleToSessions
        
        articleEntity.properties.append(articleToSessions)
        sessionEntity.properties.append(sessionToArticle)
        
        model.entities = [articleEntity, sourceEntity, sessionEntity, prefsEntity]
        
        return model
    }
    
    private static func createAttribute(_ name: String, type: NSAttributeType, optional: Bool, defaultValue: Any? = nil) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        if let defaultValue = defaultValue {
            attribute.defaultValue = defaultValue
        }
        return attribute
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
    }
}