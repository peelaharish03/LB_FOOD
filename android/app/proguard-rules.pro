# --- Fix for Razorpay Flutter SDK ---
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepattributes *Annotation*
-keep class proguard.annotation.** { *; }
-dontwarn proguard.annotation.**

# --- Keep Flutter classes safe ---
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**
