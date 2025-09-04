-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
# Optional: Gson/reflection rules
#-keep class com.google.gson.** { *; }
#-dontwarn com.google.gson.**
