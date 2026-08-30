# ── flutter_local_notifications / Gson ───────────────────────────────────
#
# Without these rules, release builds throw at runtime:
#
#   java.lang.RuntimeException: Missing type parameter.
#     at ...FlutterLocalNotificationsPlugin.loadScheduledNotifications
#     at ...FlutterLocalNotificationsPlugin.pendingNotificationRequests
#
# The plugin persists scheduled notifications as JSON via Gson, using
#   new TypeToken<ArrayList<NotificationDetails>>() {}.getType()
# which depends on the generic signature surviving into the bytecode. R8
# strips `Signature` attributes by default, so getType() finds no type
# parameter and throws.
#
# loadScheduledNotifications() runs when scheduling a notification, when one
# fires, and on boot/app-update — so this breaks notifications entirely in
# release builds while debug builds (no R8) work fine. That mismatch is why
# this only ever reproduced on real devices installed from Play, never on a
# debug emulator.
#
# The plugin ships no consumer ProGuard rules, so apps must supply their own.
# Copied from the plugin's own example app.

## Gson rules
# Gson uses generic type information stored in a class file when working with
# fields. Proguard removes such information by default, so configure it to
# keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# Gson specific classes
-dontwarn sun.misc.**

# Prevent proguard from stripping interface information from TypeAdapter,
# TypeAdapterFactory, JsonSerializer, JsonDeserializer instances (so they can
# be used in @JsonAdapter)
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses with R8 version
# 3.0 and higher.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# The model classes Gson (de)serializes for scheduled notifications — keep
# their members so field names survive obfuscation and round-trip correctly.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
