# Keep Google Tink classes
-keep class com.google.crypto.tink.** { *; }
-keep class com.google.errorprone.annotations.** { *; }
-keep class javax.annotation.** { *; }
-keep class javax.annotation.concurrent.** { *; }

# Keep other necessary classes related to cryptography
-keep class com.google.crypto.tink.** { *; }
-keep class com.google.crypto.tink.Aead* { *; }
-keep class com.google.crypto.tink.KeysetManager* { *; }
-keep class com.google.crypto.tink.PrimitiveSet* { *; }

# Keep Google API Client classes
-keep class com.google.api.client.** { *; }

# Keep Joda-Time classes
-keep class org.joda.time.** { *; }