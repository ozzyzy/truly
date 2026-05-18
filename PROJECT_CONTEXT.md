# Truly — Project Context for Claude Code

## Что такое приложение

**Truly** — iOS-приложение (SwiftUI) для осознанного использования маленьких окон времени (5–20 минут). Помогает пользователю «вернуть» себе время, которое обычно тратится бездумно на телефон.

Ключевой месседж: **"You reclaimed X minutes"** — не «дала себе», а именно **вернула**.

---

## MVP — три сценария

1. **Push-уведомление** → пользователь открывает приложение → видит случайное действие → запускает таймер
2. **Открыл приложение сам** → видит случайное действие → запускает таймер
3. **Не нравится** → тапает shuffle → карточка меняется на новое случайное действие

Всё остальное (утренний выбор, заранее спланированный список, детект Instagram) — **не MVP**.

---

## Продуктовый хук

**Накопленное время как identity metric.**

Лучший хук для Truly — не streak (создаёт тревогу, противоречит ДНК приложения), а накопленное число «возвращённого» времени:

- Число никогда не уменьшается → нет наказания за пропуск
- Первый milestone (1 час всего) = «aha moment» → нужен тихий celebrate-момент на Done экране
- Через несколько недель пользователь идентифицирует себя как «человек, который заботится о своём времени»

На **Done экране** три колонки: сегодня / за неделю / **всего** (всего — самое важное).

---

## Дизайн-система

### Цветовая палитра (mint)
```
background:    #F6FAF8   светлый мятный фон
surface:       #FFFFFF   белые карточки
surface2:      #F0F4F2   вторичные фоны, chips
textPrimary:   #181D1C   почти чёрный
textSecondary: #3D4A43   тёмно-серый
accent:        #3DB88A   мятный (кнопки, toggle, чипы)
accentDeep:    #006C4C   тёмный мятный (заголовки, иконки)
border:        #EBEFED   тонкие разделители
```

Старая тёплая/персиковая палитра удалена. `accent2` переименован в `accentDeep`.

### Логотип "truly"
Шрифт: **bold, dark, без градиента**
```swift
Text("truly")
    .font(.system(size: 28, weight: .bold))
    .foregroundStyle(theme.textPrimary)  // #181D1C
```

### Фон (TrulyBackground)
Три анимированных ellipse-блоба с медленным дрейфом (9–14 сек), без жёсткого LinearGradient. Цвета: `#83F8C6` opacity 0.28 (top-left), `#3DB88A` opacity 0.13 (bottom-right), `#83F8C6` opacity 0.09 (центр).

### Карточка действия
Glassmorphism: `.regularMaterial` + белая граница opacity 0.55 + border-radius 36. Внутри: category chip (uppercase, tracking), иконка в скруглённом квадрате, title bold 26pt, duration pill.

### Основная кнопка (primary)
Mint gradient + белый текст + Capsule shape:
```swift
LinearGradient(colors: [#3DB88A, #2A9070], startPoint: .topLeading, endPoint: .bottomTrailing)
```

---

## Архитектура (финальная)

### Навигация
Убран **TabView**. Единственный root — `HomeView` в `NavigationStack`.
- Settings → sheet
- Library → sheet
- History/Stats → sheet
- Timer → push в NavigationStack
- Done → push в NavigationStack, автовозврат через 3.2 сек

### HomeRoute
```swift
enum HomeRoute: Hashable {
    case timer(ActionItem)
    case done(Int)
}
// .actionCard удалён — карточка теперь прямо на главном экране
```

### Поток данных
```
TrulyApp
  └── RootView (.environment(.trulyTheme, .mint))
        └── HomeView (NavigationStack)
              ├── → TimerFlowView → DoneView
              ├── sheet: LibraryView
              ├── sheet: SettingsView
              └── sheet: StatsView
```

---

## Файлы проекта (актуальный список)

### Активные файлы
```
TrulyApp.swift                          — entry point, без ThemeManager
Views/
  RootView.swift                        — просто HomeView + mint тема + onboarding
  HomeView.swift                        — карточка действия на главном экране
  TimerFlowView.swift                   — таймер с круговым прогресс-рингом
  DoneView.swift                        — "You reclaimed X minutes" + 3 колонки статистики
  SettingsView.swift                    — уведомления (3 времени) + Library section
  LibraryView.swift                     — sheet с liked/hidden действиями
  StatsView.swift                       — история (sheet через кнопку chart.bar в HomeView)
  OnboardingView.swift                  — онбординг (3 шага: welcome, время, включить уведомления)
  Components/DesignSystem.swift         — TrulyBackground, TrulyCard, TrulyButton
Services/
  TrulyTheme.swift                      — единая mint тема + Color(hex:) extension
  HomeRoute.swift                       — .timer(ActionItem), .done(Int)
  PreferenceStore.swift                 — liked/hidden + resetHidden()
  LogStore.swift                        — хранилище ActionLog
  SuggestionEngine.swift                — алгоритм случайного предложения
  CatalogService.swift                  — загрузка каталога действий
  NotificationService.swift             — scheduling push notifications
  NotificationDelegate.swift            — обработка тапа на уведомление
Models/
  ActionItem.swift                      — id, title, detail, category, minutes
  ActionLog.swift                       — id, actionId, titleSnapshot, category, plannedMinutes, completedMinutes, completedAt
ActionCategory+UI.swift                 — iconName, displayName, accent(in:)
```

### Удалённые файлы (были лишними)
- `TimerView.swift` — дублировал TimerFlowView
- `ActionCardView.swift` — карточка теперь инлайн в HomeView
- `ActionCardFlowView.swift` — не использовался
- `IntentPickerView.swift` — не входит в MVP
- `ThemeManager.swift` — только всегда возвращал .evening, лишняя абстракция
- `ContentView.swift` — Xcode-шаблон, не использовался

---

## Копирайт / Tone of Voice

- Приложение общается в духе: тихо, без давления, без streak-тревоги
- Ключевые фразы:
  - "random pick for you" (на главном экране)
  - "You **reclaimed** X minutes." (на Done)
  - "ты вернул себе" (подпись к статистике)
  - "choose something else" (ссылка под карточкой)
- Без: мотивационных цитат, аватаров, фото-декораций, вкладки About/Share

---

## Уведомления

Три времени: **9:00 утро / 13:00 день / 21:00 вечер** (хранятся как `morningHour`, `afternoonHour`, `eveningHour` в AppStorage). Deep link через `NotificationCenter.default.publisher(for: .trulyOpenSuggestion)` → HomeView обновляет `current` карточку.

---

## Что ещё не сделано (V2 / backlog)

- **Milestone-момент** при первом достижении 1 часа всего (тихий celebrate на Done)
- **iOS Shortcuts интеграция** — автоматически открывать Truly при входе в Instagram (невозможно нативно, только через Shortcuts как V2)
- **Onboarding** — обновить под новый мятный дизайн (сейчас использует старые стили)
- **StatsView** — переписать под новый дизайн (сейчас старый List-стиль)
- **Локализация** — strings файл проверить на актуальность после рефакторинга
- **Анимация swap карточки** — добавить haptic feedback при shuffle
- **Первый запуск** — если нет suggestions (пустой каталог или всё скрыто), улучшить empty state
