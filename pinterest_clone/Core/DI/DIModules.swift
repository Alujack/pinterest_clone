//
//  DIModules.swift
//  pinterest_clone
//
//  Organize service registration into modules
//

import Foundation

/// Database module - registers all database-related services
struct DatabaseModule: DIModule {
    func registerServices(in container: Container) {
        // Database Manager (Singleton)
        container.registerSingleton(
            DatabaseManager.self,
            instance: DatabaseManager.shared
        )
        
        // Repositories (Transient - new instance per injection)
        container.register(
            PinRepositoryProtocol.self,
            lifecycle: .transient
        ) { container in
            PinRepository(database: container.resolve())
        }
        
        container.register(
            BoardRepositoryProtocol.self,
            lifecycle: .transient
        ) { container in
            BoardRepository(database: container.resolve())
        }
        
        print("✅ DatabaseModule registered")
    }
}

/// Service module - registers business logic services
struct ServiceModule: DIModule {
    func registerServices(in container: Container) {
        // Pin Service
        container.register(
            PinServiceProtocol.self,
            lifecycle: .singleton
        ) { container in
            PinService(repository: container.resolve())
        }
        
        // Board Service
        container.register(
            BoardServiceProtocol.self,
            lifecycle: .singleton
        ) { container in
            BoardService(repository: container.resolve())
        }
        
        print("✅ ServiceModule registered")
    }
}

/// View Model module - registers view models
struct ViewModelModule: DIModule {
    func registerServices(in container: Container) {
        // Note: ViewModels are typically created directly in views due to @MainActor requirements
        // They use DI through their initializers: init(service: container.resolve())
        
        print("✅ ViewModelModule registered (ViewModels created in views)")
    }
}

// MARK: - Module Registration Helper

extension Container {
    /// Register multiple modules at once
    func register(modules: [DIModule]) {
        for module in modules {
            module.registerServices(in: self)
        }
    }
    
    /// Register all app modules
    static func registerAppModules() {
        let modules: [DIModule] = [
            DatabaseModule(),
            ServiceModule(),
            ViewModelModule()
        ]
        
        shared.register(modules: modules)
        
        #if DEBUG
        shared.printDependencyTree()
        #endif
    }
}

