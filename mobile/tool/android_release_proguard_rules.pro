# School PDF Android Release R8 rules (app-level; copied into generated Android).
#
# Exact GitHub Actions physical-APK replay run 45598982538 confirmed FATAL at
# androidx.startup.InitializationProvider -> WorkManagerInitializer ->
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
# Room uses reflection to instantiate WorkDatabase_Impl's no-arg constructor.
# R8 full mode may retain the class name but strip the unused constructor.
# Keep only reflection entrypoints; do not disable the global optimizer.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
# WorkManager creates input mergers by reflection as well.
-keep class * extends androidx.work.InputMerger { <init>(); }
