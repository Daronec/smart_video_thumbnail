# 📦 Публикация smart-ffmpeg-android на JitPack

Подробная инструкция по публикации нативной библиотеки на JitPack для устранения необходимости использовать GitHub credentials.

---

## 🎯 Что такое JitPack?

JitPack - это бесплатный сервис, который автоматически собирает и публикует Android библиотеки из GitHub релизов. После публикации на JitPack пользователи смогут использовать библиотеку без GitHub токенов.

**Преимущества:**

- ✅ Бесплатно для публичных репозиториев
- ✅ Не требует регистрации
- ✅ Автоматическая сборка из GitHub
- ✅ Не нужны credentials для пользователей
- ✅ Поддержка версионирования через Git теги

---

## 📋 Предварительные требования

1. ✅ Публичный GitHub репозиторий: https://github.com/Daronec/smart-ffmpeg-android
2. ✅ Рабочий `build.gradle.kts` с правильной конфигурацией
3. ✅ Git тег с версией (например, v1.0.4)

---

## 🚀 Шаг 1: Подготовка репозитория smart-ffmpeg-android

### 1.1 Проверьте build.gradle.kts

Убедитесь, что в корне репозитория `smart-ffmpeg-android` есть файл `build.gradle.kts` с правильной конфигурацией:

```kotlin
plugins {
    id("com.android.library")
    id("kotlin-android")
    id("maven-publish")
}

group = "com.github.Daronec"
version = "1.0.4"

android {
    namespace = "com.smartmedia.ffmpeg"
    compileSdk = 34

    defaultConfig {
        minSdk = 26
        targetSdk = 34

        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
}

// Конфигурация для JitPack
afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.github.Daronec"
                artifactId = "smart-ffmpeg-android"
                version = "1.0.4"
            }
        }
    }
}
```

**Ключевые моменты:**

- `group = "com.github.Daronec"` - обязательно для JitPack
- Плагин `maven-publish` добавлен
- Секция `publishing` настроена

### 1.2 Создайте jitpack.yml (опционально)

В корне репозитория создайте файл `jitpack.yml`:

```yaml
jdk:
  - openjdk11
before_install:
  - sdk install java 11.0.10-open
  - sdk use java 11.0.10-open
```

Этот файл гарантирует, что JitPack использует правильную версию Java.

### 1.3 Проверьте структуру проекта

Убедитесь, что структура выглядит так:

```
smart-ffmpeg-android/
├── build.gradle.kts          # Главный build файл
├── settings.gradle.kts        # Settings файл
├── jitpack.yml               # Конфигурация JitPack (опционально)
├── src/
│   └── main/
│       ├── kotlin/
│       │   └── com/smartmedia/ffmpeg/
│       │       └── SmartFfmpegBridge.kt
│       └── jniLibs/
│           ├── arm64-v8a/
│           │   ├── libavcodec.so
│           │   ├── libavformat.so
│           │   ├── libavutil.so
│           │   ├── libswscale.so
│           │   ├── libswresample.so
│           │   └── libsmart_ffmpeg.so
│           └── armeabi-v7a/
│               └── ... (те же файлы)
└── README.md
```

---

## 🏷️ Шаг 2: Создание Release на GitHub

### 2.1 Создайте Git тег

В репозитории `smart-ffmpeg-android`:

```bash
cd /path/to/smart-ffmpeg-android
git tag 1.0.4
git push origin 1.0.4
```

**Важно:** JitPack использует теги без префикса `v`. Используйте `1.0.4`, а не `v1.0.4`.

### 2.2 Создайте Release на GitHub

1. Перейдите: https://github.com/Daronec/smart-ffmpeg-android/releases
2. Нажмите **"Create a new release"**
3. Заполните форму:
   - **Choose a tag:** 1.0.4
   - **Release title:** `1.0.4 - JitPack Release`
   - **Description:**

````markdown
# smart-ffmpeg-android 1.0.4

Android library with FFmpeg 4.4.2 integration for video processing.

## Features

- FFmpeg 4.4.2 with JNI bridge
- Architectures: arm64-v8a, armeabi-v7a
- Methods: extractThumbnail, getVideoDuration, getVideoMetadata, getFFmpegVersion

## Installation via JitPack

Add to your `build.gradle.kts`:

```kotlin
repositories {
    maven { url = uri("https://jitpack.io") }
}

dependencies {
    implementation("com.github.Daronec:smart-ffmpeg-android:1.0.4")
}
```
````

No GitHub credentials required!

## Links

- JitPack: https://jitpack.io/#Daronec/smart-ffmpeg-android
- Flutter Plugin: https://pub.dev/packages/smart_video_thumbnail

````

4. Нажмите **"Publish release"**

---

## 🔨 Шаг 3: Сборка на JitPack

### 3.1 Запустите сборку

1. Перейдите на https://jitpack.io/
2. В поле поиска введите: `Daronec/smart-ffmpeg-android`
3. Нажмите **"Look up"**
4. Найдите версию `1.0.4` в списке
5. Нажмите **"Get it"**

JitPack начнет сборку. Это может занять 5-15 минут.

### 3.2 Проверьте статус сборки

- 🟢 **Зеленая галочка** - сборка успешна ✅
- 🔴 **Красный крестик** - ошибка сборки ❌
- 🟡 **Желтый круг** - сборка в процессе ⏳

### 3.3 Если сборка не удалась

Нажмите на красный крестик, чтобы увидеть логи. Типичные проблемы:

**Проблема 1: "Could not find build.gradle"**
- Решение: Убедитесь, что `build.gradle.kts` находится в корне репозитория

**Проблема 2: "Task 'install' not found"**
- Решение: Добавьте плагин `maven-publish` и секцию `publishing`

**Проблема 3: "NDK not found"**
- Решение: Убедитесь, что `.so` файлы находятся в `src/main/jniLibs/`

**Проблема 4: "Java version mismatch"**
- Решение: Создайте `jitpack.yml` с правильной версией Java

---

## 🔄 Шаг 4: Обновление Flutter плагина

### 4.1 Обновите android/build.gradle.kts

В репозитории `smart_video_thumbnail`, обновите `android/build.gradle.kts`:

**Было:**
```kotlin
repositories {
    google()
    mavenCentral()
    maven {
        url = uri("https://maven.pkg.github.com/Daronec/smart-ffmpeg-android")
        credentials {
            username = project.findProperty("gpr.user") as String? ?: System.getenv("GPR_USER")
            password = project.findProperty("gpr.key") as String? ?: System.getenv("GPR_KEY")
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    implementation("com.smartmedia:smart-ffmpeg-android:1.0.4")
}
````

**Стало:**

```kotlin
repositories {
    google()
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    implementation("com.github.Daronec:smart-ffmpeg-android:1.0.4")
}
```

### 4.2 Обновите example/android/build.gradle.kts

Сделайте те же изменения в `example/android/build.gradle.kts`.

### 4.3 Удалите gradle.properties

Теперь файл `~/.gradle/gradle.properties` с credentials не нужен! Можно удалить строки:

```properties
# Больше не нужно!
# gpr.user=...
# gpr.key=...
```

---

## 📝 Шаг 5: Обновление документации

### 5.1 Обновите README.md

Замените секцию установки:

**Было:**

````markdown
### Android Setup

Add GitHub Packages credentials to `~/.gradle/gradle.properties`:

```properties
gpr.user=YOUR_GITHUB_USERNAME
gpr.key=YOUR_GITHUB_TOKEN
```
````

> **Note:** You need a GitHub Personal Access Token with `read:packages` permission.

````

**Стало:**
```markdown
### Android Setup

No additional setup required! The plugin automatically downloads the native FFmpeg library from JitPack.

> **Note:** The first build may take longer as Gradle downloads the native library (~8MB).
````

### 5.2 Обновите CHANGELOG.md

Добавьте новую версию:

```markdown
## [0.1.1] - 2026-02-13

### Changed

- **Breaking:** Switched from GitHub Packages to JitPack for native library distribution
- No longer requires GitHub credentials for installation
- Simplified setup process

### Migration Guide

If you're upgrading from v0.1.0:

1. Remove GitHub credentials from `~/.gradle/gradle.properties`
2. Run `flutter clean`
3. Run `flutter pub get`
4. Rebuild your app

The plugin will now automatically download the native library from JitPack.
```

### 5.3 Обновите pubspec.yaml

```yaml
version: 0.1.1
```

---

## ✅ Шаг 6: Тестирование

### 6.1 Очистите кеш

```bash
cd smart_video_thumbnail
flutter clean
cd example
flutter clean
rm -rf ~/.gradle/caches/
```

### 6.2 Соберите проект

```bash
cd example
flutter pub get
flutter build apk
```

### 6.3 Проверьте логи

Во время сборки вы должны увидеть:

```
> Task :smart_video_thumbnail:downloadJitpackDependencies
Downloading https://jitpack.io/com/github/Daronec/smart-ffmpeg-android/1.0.4/smart-ffmpeg-android-1.0.4.aar
```

### 6.4 Запустите приложение

```bash
flutter run
```

Убедитесь, что миниатюры генерируются корректно.

---

## 🚀 Шаг 7: Публикация обновления на pub.dev

### 7.1 Обновите версию

В `pubspec.yaml`:

```yaml
version: 0.1.1
```

### 7.2 Dry-run

```bash
dart pub publish --dry-run
```

### 7.3 Опубликуйте

```bash
dart pub publish
```

### 7.4 Создайте GitHub Release

```bash
git add .
git commit -m "Switch to JitPack for native library distribution"
git tag v0.1.1
git push origin main
git push origin v0.1.1
```

Создайте Release на GitHub с описанием изменений.

---

## 📊 Преимущества после миграции

### Для пользователей:

✅ **Простая установка:**

```yaml
dependencies:
  smart_video_thumbnail: ^0.1.1
```

✅ **Нет credentials:**

- Не нужен GitHub токен
- Не нужно настраивать `gradle.properties`
- Работает сразу после `flutter pub get`

✅ **Быстрая сборка:**

- JitPack кэширует собранные библиотеки
- Первая сборка ~30 секунд, последующие ~5 секунд

### Для вас:

✅ **Меньше поддержки:**

- Нет вопросов про GitHub credentials
- Меньше issues про проблемы с доступом

✅ **Стандартный подход:**

- JitPack - стандарт для Android библиотек
- Знаком большинству Android разработчиков

✅ **Простое обновление:**

- Создайте новый тег
- JitPack автоматически соберет новую версию

---

## 🔍 Проверка работы JitPack

### Проверьте статус библиотеки:

1. Перейдите: https://jitpack.io/#Daronec/smart-ffmpeg-android
2. Убедитесь, что версия 1.0.4 имеет зеленую галочку ✅
3. Нажмите на версию, чтобы увидеть детали сборки

### Проверьте badge:

Добавьте badge в README smart-ffmpeg-android:

```markdown
[![](https://jitpack.io/v/Daronec/smart-ffmpeg-android.svg)](https://jitpack.io/#Daronec/smart-ffmpeg-android)
```

---

## 🆘 Устранение проблем

### Проблема: JitPack не находит репозиторий

**Решение:**

- Убедитесь, что репозиторий публичный
- Проверьте правильность имени: `Daronec/smart-ffmpeg-android`

### Проблема: Сборка не запускается

**Решение:**

- Создайте Git тег: `git tag 1.0.4 && git push origin 1.0.4`
- Подождите 1-2 минуты и попробуйте снова

### Проблема: Ошибка "Could not resolve dependency"

**Решение:**

```kotlin
repositories {
    maven { url = uri("https://jitpack.io") }  // Добавьте ДО mavenCentral()
    mavenCentral()
}
```

### Проблема: Старая версия кэшируется

**Решение:**

```bash
./gradlew clean
rm -rf ~/.gradle/caches/
./gradlew build --refresh-dependencies
```

---

## 📚 Дополнительные ресурсы

- **JitPack Docs:** https://jitpack.io/docs/
- **JitPack Building:** https://jitpack.io/docs/BUILDING/
- **Android Library Guide:** https://developer.android.com/studio/projects/android-library

---

## ✨ Готово!

После выполнения всех шагов:

✅ Библиотека доступна на JitPack  
✅ Пользователям не нужны GitHub credentials  
✅ Установка максимально простая  
✅ Плагин готов к использованию

**Поздравляю! Теперь ваш плагин еще проще в использовании!** 🎉
