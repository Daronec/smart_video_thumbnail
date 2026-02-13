# Создание GitHub репозитория для smart_video_thumbnail

## 📋 Пошаговая инструкция

### Шаг 1: Создайте репозиторий на GitHub

1. **Откройте браузер** и перейдите на https://github.com/new

2. **Заполните форму:**
   - **Repository name:** `smart_video_thumbnail`
   - **Description:** `High-performance Flutter plugin for extracting video thumbnails using native FFmpeg engine`
   - **Visibility:** Public ✅
   - **Initialize repository:**
     - ❌ НЕ добавляйте README
     - ❌ НЕ добавляйте .gitignore
     - ❌ НЕ добавляйте license
     - (Эти файлы уже есть в проекте)

3. **Нажмите "Create repository"**

### Шаг 2: Инициализируйте локальный репозиторий

**Вариант A: Автоматически (рекомендуется)**

Запустите файл `GITHUB_SETUP.bat`:

```bash
GITHUB_SETUP.bat
```

Скрипт выполнит все необходимые команды автоматически.

**Вариант B: Вручную**

Выполните команды в терминале:

```bash
# 1. Инициализация git
git init

# 2. Добавление всех файлов
git add .

# 3. Первый коммит
git commit -m "Initial commit - v0.1.0"

# 4. Переименование ветки в main
git branch -M main

# 5. Добавление remote (замените YOUR_USERNAME на ваш GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/smart_video_thumbnail.git

# 6. Создание тега
git tag v0.1.0

# 7. Отправка на GitHub
git push -u origin main
git push origin v0.1.0
```

### Шаг 3: Настройте репозиторий на GitHub

1. **Перейдите в репозиторий:**
   https://github.com/YOUR_USERNAME/smart_video_thumbnail

2. **Добавьте описание и topics:**
   - Нажмите на шестеренку рядом с "About"
   - **Description:** `High-performance Flutter plugin for extracting video thumbnails using native FFmpeg engine`
   - **Website:** `https://pub.dev/packages/smart_video_thumbnail`
   - **Topics:** `flutter`, `dart`, `video`, `thumbnail`, `ffmpeg`, `video-processing`, `android`, `flutter-plugin`
   - Нажмите "Save changes"

3. **Проверьте файлы:**
   - ✅ README.md отображается с badges и скриншотом
   - ✅ LICENSE файл присутствует
   - ✅ Структура проекта корректна

### Шаг 4: Создайте Release

1. **Перейдите в Releases:**
   - Нажмите "Releases" в правой панели
   - Или перейдите: https://github.com/YOUR_USERNAME/smart_video_thumbnail/releases

2. **Создайте новый release:**
   - Нажмите "Create a new release"
   - **Choose a tag:** v0.1.0 (должен быть в списке)
   - **Release title:** `v0.1.0 - Initial Release`
   - **Description:** Скопируйте содержимое из CHANGELOG.md

3. **Опубликуйте:**
   - Нажмите "Publish release"

### Шаг 5: Обновите ссылки

Теперь нужно обновить ссылки в документации на правильный GitHub URL.

**Файлы для обновления:**

- README.md (если есть ссылки на GitHub)
- pubspec.yaml (repository, homepage, issue_tracker)

**Пример для pubspec.yaml:**

```yaml
homepage: https://github.com/YOUR_USERNAME/smart_video_thumbnail
repository: https://github.com/YOUR_USERNAME/smart_video_thumbnail
issue_tracker: https://github.com/YOUR_USERNAME/smart_video_thumbnail/issues
```

---

## 🔧 Устранение проблем

### Проблема: "remote origin already exists"

```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/smart_video_thumbnail.git
```

### Проблема: Ошибка аутентификации

**Используйте Personal Access Token:**

1. Перейдите: https://github.com/settings/tokens
2. Нажмите "Generate new token" → "Generate new token (classic)"
3. Выберите scopes: `repo` (полный доступ)
4. Скопируйте токен
5. При push используйте токен вместо пароля:
   ```bash
   Username: YOUR_USERNAME
   Password: YOUR_TOKEN
   ```

**Или настройте SSH:**

1. Создайте SSH ключ:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```
2. Добавьте ключ на GitHub: https://github.com/settings/keys
3. Измените remote на SSH:
   ```bash
   git remote set-url origin git@github.com:YOUR_USERNAME/smart_video_thumbnail.git
   ```

### Проблема: Большой размер репозитория

Если git жалуется на большие файлы:

```bash
# Проверьте размер файлов
git ls-files -z | xargs -0 du -h | sort -h -r | head -20

# Удалите большие файлы из истории (если нужно)
git filter-branch --tree-filter 'rm -f path/to/large/file' HEAD
```

---

## 📊 После создания репозитория

### Проверьте

- ✅ Репозиторий публичный
- ✅ README отображается корректно
- ✅ Скриншот виден
- ✅ Topics добавлены
- ✅ Release v0.1.0 создан
- ✅ Ссылка на pub.dev в описании

### Поделитесь

**Reddit:**

- r/FlutterDev
- r/dartlang

**Twitter/X:**

```
🎉 Just published smart_video_thumbnail - a Flutter plugin for video thumbnail generation!

✅ Native FFmpeg integration
✅ All video formats supported
✅ High performance (50-300ms)
✅ RGBA8888 output

pub.dev: https://pub.dev/packages/smart_video_thumbnail
GitHub: https://github.com/YOUR_USERNAME/smart_video_thumbnail

#Flutter #FlutterDev #FFmpeg
```

**Discord:**

- Flutter Community
- Flutter Dev

**LinkedIn:**
Напишите пост о создании плагина с техническими деталями.

---

## 🔄 Дальнейшая работа

### Обновление кода

```bash
# 1. Внесите изменения
# 2. Коммит
git add .
git commit -m "Description of changes"

# 3. Push
git push origin main
```

### Создание новой версии

```bash
# 1. Обновите версию в pubspec.yaml
# 2. Обновите CHANGELOG.md
# 3. Коммит
git add .
git commit -m "Bump version to 0.1.1"

# 4. Создайте тег
git tag v0.1.1

# 5. Push
git push origin main
git push origin v0.1.1

# 6. Опубликуйте на pub.dev
dart pub publish

# 7. Создайте Release на GitHub
```

---

## 📚 Полезные команды Git

```bash
# Проверить статус
git status

# Посмотреть историю
git log --oneline

# Посмотреть изменения
git diff

# Отменить изменения в файле
git checkout -- filename

# Посмотреть remote
git remote -v

# Посмотреть теги
git tag

# Удалить тег локально
git tag -d v0.1.0

# Удалить тег на GitHub
git push origin :refs/tags/v0.1.0
```

---

## ✅ Готово!

После выполнения всех шагов у вас будет:

- ✅ Репозиторий на GitHub
- ✅ Код загружен
- ✅ Release v0.1.0 создан
- ✅ Плагин опубликован на pub.dev
- ✅ Документация актуальна

**Ваш плагин теперь доступен всему Flutter сообществу!** 🎉

---

## 🆘 Нужна помощь?

- **GitHub Docs:** https://docs.github.com/
- **Git Docs:** https://git-scm.com/doc
- **Flutter Plugins:** https://docs.flutter.dev/development/packages-and-plugins

Если возникли проблемы, создайте issue или обратитесь в Flutter Community Discord.
