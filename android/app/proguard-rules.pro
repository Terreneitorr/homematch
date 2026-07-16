# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Sign In
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# HomeMatch — mantener modelos de datos
-keep class com.example.homematch.** { *; }

# Mantener anotaciones
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Stripe
-keep class com.stripe.** { *; }

# OkHttp (usado por Dio internamente)
-dontwarn okhttp3.**
-dontwarn okio.**

# Play Core (Solución para errores de R8 con componentes diferidos de Flutter)
-dontwarn com.google.android.play.core.**

