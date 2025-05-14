import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext { persistentContainer.viewContext }

    private init() {
        persistentContainer = NSPersistentContainer(name: "GetFitModel")
        
        // Configure the context for optimal performance
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Try loading with automatic migration first
        if !tryLoadStore(withOptions: [NSMigratePersistentStoresAutomaticallyOption: true,
                                        NSInferMappingModelAutomaticallyOption: true]) {
            // If that fails, try destructive migration (recreate store)
            _ = performDestructiveMigration()
        }
    }
    
    private func tryLoadStore(withOptions options: [String: Any]) -> Bool {
        do {
            try persistentContainer.persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: persistentStoreURL(),
                options: options
            )
            print("Successfully loaded persistent store")
            return true
        } catch {
            let nsError = error as NSError
            print("Failed to load persistent store: \(error)")
            
            // Check if this is a relationship mapping error
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
               let reason = underlyingError.userInfo["reason"] as? String,
               reason.contains("Can not map from a to-many to a to-one relationship") {
                print("Detected to-many/to-one relationship migration issue, will perform destructive migration")
            }
            return false
        }
    }
    
    private func persistentStoreURL() -> URL {
        // Get the application support directory
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Create the URL for the SQLite database
        return appSupportURL.appendingPathComponent("GetFitModel.sqlite")
    }
    
    private func performDestructiveMigration() -> Bool {
        print("Performing destructive CoreData migration")
        
        let storeURL = persistentStoreURL()
        let fileManager = FileManager.default
        
        // Store paths
        let sqlitePath = storeURL.path
        let shmPath = sqlitePath + "-shm"
        let walPath = sqlitePath + "-wal"
        
        // Delete all store files
        do {
            // Only try to delete if the files exist
            if fileManager.fileExists(atPath: sqlitePath) {
                try fileManager.removeItem(atPath: sqlitePath)
            }
            if fileManager.fileExists(atPath: shmPath) {
                try fileManager.removeItem(atPath: shmPath)
            }
            if fileManager.fileExists(atPath: walPath) {
                try fileManager.removeItem(atPath: walPath)
            }
            
            // Try to create a new store from scratch
            try persistentContainer.persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: nil
            )
            
            print("Successfully recreated the persistent store")
            return true
            
        } catch {
            print("Failed to perform destructive migration: \(error)")
            return false
        }
    }
}
