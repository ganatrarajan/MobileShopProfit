# ==============================================================================
# ProGuard / R8 Rules for Mobile Repair Hub (com.repairehub)
# ==============================================================================

# ------------------------------------------------------------------------------
# General & Flutter Engine Rules
# ------------------------------------------------------------------------------
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Application code
-keep class com.repairehub.** { *; }

# ------------------------------------------------------------------------------
# Razorpay SDK Rules
# ------------------------------------------------------------------------------
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# ------------------------------------------------------------------------------
# Firebase & Google Play Services
# ------------------------------------------------------------------------------
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ------------------------------------------------------------------------------
# Mobile Scanner (MLKit & CameraX)
# ------------------------------------------------------------------------------
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-keep class dev.steenbakker.mobile_scanner.** { *; }

# ------------------------------------------------------------------------------
# Geolocator / Location Services
# ------------------------------------------------------------------------------
-keep class com.baseflow.geolocator.** { *; }

# ------------------------------------------------------------------------------
# PDF & Printing
# ------------------------------------------------------------------------------
-dontwarn net.sf.andpdf.**
-dontwarn com.sun.pdfview.**
-keep class net.nfet.flutter.printing.** { *; }

# ------------------------------------------------------------------------------
# Image Picker & AndroidX Support
# ------------------------------------------------------------------------------
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-dontwarn androidx.**
