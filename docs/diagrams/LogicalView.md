# ClinicGO Logical View (MVVM Architecture)

## UML Package Diagram

```mermaid
graph TB
    subgraph "Presentation Layer"
        subgraph "Views"
            MainScreen["Main Screen<br/>(Navigation & Layout)"]
            ProfileView["Profile View<br/>(Authentication)"]
            MedicationsView["Medications View<br/>(List & Management)"]
            HomeView["Home View<br/>(Today's Schedule)"]
        end
        
        subgraph "ViewModels"
            HomeVM["HomeViewModel<br/>(State Management)"]
            DosesVM["DailyDosesViewModel<br/>(Dose Logic)"]
            ProfileVM["ProfileViewModel<br/>(Auth State)"]
        end
        
        subgraph "Widgets & Components"
            FloatingNav["FloatingBottomNavBar"]
            AppBackground["AppBackground"]
            DoseCard["DoseCard"]
            MedCard["MedicationCard"]
        end
    end
    
    subgraph "Business Logic Layer"
        subgraph "Services"
            DoseScheduling["DoseSchedulingService<br/>(Calculate Schedules)"]
            NotificationCtrl["MissedDoseNotificationController<br/>(Notification Logic)"]
            AuthService["AuthService<br/>(Session Management)"]
        end
        
        subgraph "Domain Entities"
            Medication["Medication<br/>(name, dosage, frequency)"]
            ScheduledDose["ScheduledDose<br/>(timing, status)"]
            MedicationReminder["MedicationReminder<br/>(recurring schedule)"]
            DoseLogEntry["DoseLogEntry<br/>(audit trail)"]
        end
    end
    
    subgraph "Data Access Layer"
        subgraph "Repositories"
            MedRepo["MedicationRepository<br/>(CRUD operations)"]
            DoseLogRepo["DoseLogRepository<br/>(Dose history)"]
            PendingStore["PendingNotificationStore<br/>(Local queue)"]
        end
        
        subgraph "External Data Sources"
            Supabase["Supabase<br/>(PostgreSQL)<br/>- Users<br/>- Medications<br/>- Dose Logs"]
            LocalStorage["Local Storage<br/>(Hive/SQLite)<br/>- Offline cache<br/>- Pending reminders"]
        end
    end
    
    subgraph "External Integrations"
        GoogleMaps["Google Maps API<br/>(Pharmacy locations)"]
        VisionAPI["Vision/LLM API<br/>(Prescription parsing)"]
    end
    
    %% View to ViewModel connections
    MainScreen -->|listens| HomeVM
    MainScreen -->|listens| ProfileVM
    ProfileView -->|listens| ProfileVM
    HomeView -->|listens| DosesVM
    MedicationsView -->|listens| HomeVM
    
    %% ViewModel to Service connections
    HomeVM -->|uses| DoseScheduling
    DosesVM -->|uses| DoseScheduling
    DosesVM -->|uses| NotificationCtrl
    ProfileVM -->|uses| AuthService
    
    %% ViewModel to Repository connections
    HomeVM -->|queries| MedRepo
    DosesVM -->|queries| MedRepo
    DosesVM -->|logs| DoseLogRepo
    NotificationCtrl -->|checks| DoseLogRepo
    NotificationCtrl -->|manages| PendingStore
    
    %% Repository to Data Source connections
    MedRepo -->|sync| Supabase
    MedRepo -->|cache| LocalStorage
    DoseLogRepo -->|sync| Supabase
    DoseLogRepo -->|fallback| LocalStorage
    AuthService -->|verify| Supabase
    
    %% External integrations
    MedRepo -->|queries| GoogleMaps
    MedRepo -->|queries| VisionAPI
    
    %% Component connections
    HomeVM -->|updates| DoseCard
    HomeVM -->|updates| MedCard
    HomeVM -->|navigates| FloatingNav
    
    style MainScreen fill:#e1f5ff
    style ProfileView fill:#e1f5ff
    style MedicationsView fill:#e1f5ff
    style HomeView fill:#e1f5ff
    
    style HomeVM fill:#fff3e0
    style DosesVM fill:#fff3e0
    style ProfileVM fill:#fff3e0
    
    style DoseScheduling fill:#f3e5f5
    style NotificationCtrl fill:#f3e5f5
    style AuthService fill:#f3e5f5
    
    style MedRepo fill:#e8f5e9
    style DoseLogRepo fill:#e8f5e9
    style PendingStore fill:#e8f5e9
    
    style Supabase fill:#fce4ec
    style LocalStorage fill:#fce4ec
    
    style GoogleMaps fill:#f1f8e9
    style VisionAPI fill:#f1f8e9
```

## Architecture Description

### **Presentation Layer**
- **Views**: Flutter UI components (MainScreen, ProfileView, HomeView, MedicationsView)
- **ViewModels**: Manage state using ChangeNotifier pattern
  - `HomeViewModel`: Overall navigation and home screen state
  - `DailyDosesViewModel`: Medication schedule and dose logging
  - `ProfileViewModel`: User authentication state
- **Widgets**: Reusable UI components (navigation bar, cards, backgrounds)

### **Business Logic Layer**
- **Services**:
  - `DoseSchedulingService`: Calculates upcoming doses based on medication reminders
  - `MissedDoseNotificationController`: Manages notification scheduling and delivery
  - `AuthService`: Handles user authentication and session management
- **Domain Entities**: Core business objects (Medication, ScheduledDose, DoseLogEntry, etc.)

### **Data Access Layer**
- **Repositories**: Abstract data operations
  - `MedicationRepository`: CRUD for medications and reminders
  - `DoseLogRepository`: Tracks medication administration
  - `PendingNotificationStore`: Local queue for notification attempts
- **Data Sources**:
  - **Supabase**: Cloud database for sync across devices
  - **Local Storage**: Hive/SQLite for offline-first medication reminders

### **External Integrations**
- **Google Maps API**: Locate nearby pharmacies
- **Vision/LLM API**: Parse prescription images and extract medication details

## Key Design Patterns

1. **MVVM**: Clean separation of UI (View) from business logic (ViewModel)
2. **Repository Pattern**: Abstract data access behind repositories
3. **Offline-First**: Local storage enables functionality without network
4. **Dependency Injection**: GetIt service locator for loose coupling
5. **Observer Pattern**: ChangeNotifier for reactive UI updates
