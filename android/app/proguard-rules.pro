# Regras do ProGuard/R8 do ZOOM.
#
# O Flutter Gradle Plugin ativa `isMinifyEnabled = true` automaticamente nos builds
# release e adiciona este arquivo quando ele existe em android/app/.
#
# IMPORTANTE: o plugin flutter_local_notifications usa o Gson para guardar e
# recuperar os alarmes agendados. Sem estas regras o R8 remove a assinatura
# genérica da classe anônima `new TypeToken<ArrayList<NotificationDetails>>(){}`
# e o Gson estoura com "Missing type parameter." — o que derrubava o aplicativo
# no boot receiver (ScheduledNotificationBootReceiver) a cada reinício do
# aparelho ou atualização do app.

## Gson
# O Gson usa a informação de tipo genérico guardada no class file.
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Classes específicas do Gson
-keep class com.google.gson.stream.** { *; }

# Preserva as interfaces de TypeAdapter, TypeAdapterFactory, JsonSerializer e
# JsonDeserializer (necessário para @JsonAdapter).
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Evita que o R8 apague membros anotados com @SerializedName.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Mantém as assinaturas genéricas do TypeToken e das suas subclasses
# (essencial para o R8 3.0+).
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

## Plugin de notificações locais
# As classes do plugin são referenciadas pelo manifest e pelo receivers do
# sistema — precisam continuar existindo e com os mesmos nomes.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

## App
# Mantém os nomes dos componentes declarados no manifest.
-keep class br.com.zmove.zoom.** { *; }
