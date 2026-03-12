// LC: Logic and Controller system: __________________

// App-level controllers: __
// (Global session/state if choose to centralize.)

class SessionController {}

// Data Sources / Services (External world): ____________________
// (Firestore, REST APIs, device APIs, cache, etc.)

class FirestoreApi {} // All Firestore reads/writes only

class RestApi {} // Future: HTTP integrations (WalaaOne/Moyasar/TOMRA)

class DeviceApi {} // Future: location, notifications, sensors, etc.

class LocalCache {} // Future: SharedPreferences/Hive/SQLite caching

// Rules / Helpers (Internal pure logic): ____________
// (No Firebase calls here. Only calculations, mapping, validation.)

class LeaderboardRules {} // timeframeId, ranking, sorting, merge members+groups

class RelationPagesRules {} // de-dup, filtering, building dropdown options

class ValidationRules {} // input checks, guard clauses, role checks, etc.

// Use Cases (Orchestrators): ________________________
// (UI calls these. They call DataSources + Rules and return final results.)

class RelationPagesUseCase {} // loadRelationPages()

class LeaderboardUseCase {} // loadLeaderboardEntries()
