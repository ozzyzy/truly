# Truly — Project Context

## Что такое приложение

**Truly** — iOS-приложение (SwiftUI, ru-only) для осознанного использования маленьких окон времени (1–20 минут). Помогает вернуть себе время, которое обычно тратится бездумно на телефон.

---

## Продуктовые принципы

1. **Гендер-нейтральность.** Весь копирайт без гендерных форм прошедшего времени («вернула», «подвигалась» и т.п.). Допустимо: повелительное наклонение, настоящее/будущее время, пассив («момент создан», «страницы прочитаны»), безличные конструкции.
2. **Только русский.** `Localizable.xcstrings` удалён. Все `Text("...")` переведены на `Text(verbatim:)`.
3. **Никаких ложных обещаний.** Приложение не имеет доступа к экранному времени — любые упоминания порога скрин-тайма удалены.
4. **Тихий тон.** Без лексики геймификации («рекорд», «разблокирован»), без избыточных празднований.

### Примеры — можно / нельзя
| ❌ Нельзя | ✅ Можно |
|---|---|
| «Ты вернулась к себе» | «Ты снова здесь» |
| «Ты подвигалась» | «Ты в движении» |
| «Ты прочитала» | «Страницы прочитаны» |
| «Рекорд разблокирован» | «Твой первый час» |
| «Сегодня вернула себе X» | «Сегодня: +X» |

---

## Навигация

`HomeView` в `NavigationStack` — единственный root.

### HomeRoute
```swift
enum HomeRoute: Hashable {
    case timer(ActionItem)
    case done(Int, Bool)  // minutes, isMilestone
}
// .between удалён — логика возврата перенесена в onGoHome колбэк DoneView
```

### Поток
```
TrulyApp
  └── RootView (.environment(.trulyTheme, .mint))
        └── HomeView (NavigationStack)
              ├── → TimerFlowView → DoneView → (onGoHome: path.removeAll + nextSuggestion)
              ├── sheet: LibraryView
              ├── sheet: SettingsView
              └── sheet: StatsView
```

---

## Таймер (TimerFlowView)

**Источник правды — `endDate: Date?`**, а не декрементирующий счётчик.

- **Старт:** `endDate = Date().addingTimeInterval(Double(remaining))`
- **Тик (0.5 с):** `remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded()))` — не декрементирует, только пересчитывает
- **Пауза:** `remaining` фиксируется, `endDate = nil`
- **Продолжить:** `endDate = Date().addingTimeInterval(Double(remaining))`
- **Фон:** `@Environment(\.scenePhase)` → при `.active` пересчитывает; если время вышло пока в фоне — запускает `triggerTimeUpFlash()`

### Локальная нотификация завершения
- identifier: `"truly.timer.done"`
- body: `"Готово. Эти минуты — твои."`, без title, звук `.default`
- Планируется при старте, отменяется при паузе/отмене/досрочном завершении/выходе с экрана
- В `NotificationDelegate`: `truly.timer.done` → просто открывает приложение, **не** триггерит `.trulyOpenSuggestion`

---

## Уведомления

**Окна вместо фиксированных часов**, горизонт 7 дней вперёд.

| Окно | Диапазон | sublabel |
|---|---|---|
| morning | 8:00–11:00 | «между 8:00 и 11:00» |
| afternoon | 12:00–16:00 | «между 12:00 и 16:00» |
| evening | 19:00–22:00 | «между 19:00 и 22:00» |

- Хранение: `@AppStorage("nudgeWindowIds")` — строка `"morning,afternoon,evening"`
- 7 дней × выбранные окна × случайное время внутри окна = `repeats: false` запросы
- identifier: `truly.nudge.<timeOfDay>.<dayOffset>`
- Тексты: случайный выбор из `nudgeTexts.json` по окну (4 текста на каждое)
- **Правило «не беспокоить»:** пропускать слоты в первые 3 часа после завершённой сессии
- **Перепланирование:** при каждом запуске приложения и после каждой завершённой сессии
- **Очистка:** `removeAllPendingNotificationRequests()` перед каждым перепланированием

---

## Milestone (первый час)

- Триггер: `logStore.totalMinutes >= 60 && !logStore.milestoneOneHourShown`
- Флаг: `milestoneOneHourShown: Bool` в `LogStore` через `UserDefaults.standard`
- Флаг ставится в `true` в `HomeView` сразу после добавления лога и до `path.append(.done(...))`
- DoneView ветка milestone: bloom rings + CelebrationParticles + medium haptic + «Твой первый час»
- DoneView нормальная: без частиц, light haptic, показывает `"всего возвращено: X ч Y мин"`

---

## Виджет (TrulyWidget)

- systemSmall: «бумажный альманах», Newsreader italic числа, weekly minutes
- Метрика «за эту неделю» (понедельник → воскресенье), сбрасывается в Monday 00:00
- Источник данных: `SharedDefaults` (App Group `group.com.truly.shared`)
- Ключи: `shared.weeklyMinutes`, `shared.weekStartDate`, `shared.totalMinutes`
- Timeline: запись сейчас + reset-запись в следующий понедельник 00:00 + `.after(nextMidnight)` refresh
- Watermark: `returnMarkPath()` — та же геометрия что и иконка (smoothstep easing), opacity 0.07
- Другие размеры: `accessoryCircular`, `accessoryRectangular`, `accessoryInline`

---

## Иконка приложения

Процедурная геометрия `IconReturnFine`:
- `R=0.355×size`, `rEnd=0.085×size`, `wStart=0.082×size`, `wEnd=0.011×size`
- `a0=150°`, `sweep=345°`, `rot=-2°`, `steps=90`
- Smoothstep easing радиуса, линейное затухание толщины
- Round cap в начале штриха (radius `wStart/2`)
- Оптическое центрирование через bounding-box dx/dy
- Light: ink `#015C42` на `#ECF3EE→#DCEDE4`, grain opacity 0.06
- Dark: mint `#36D6A9` на `#06281F→#02180F`, grain opacity 0.05

---

## Файлы проекта

### Активные
```
TrulyApp.swift                      — entry point, font registration, nudge migration + startup reschedule
Views/
  RootView.swift                    — HomeView + mint тема + onboarding gate
  HomeView.swift                    — карточка, statsLine «Сегодня: +X», navigation
  TimerFlowView.swift               — endDate-based таймер, scenePhase-aware, timer done notification
  DoneView.swift                    — нейтральный копирайт, total-строка; milestone: bloom + particles
  SettingsView.swift                — nudgeWindowIds, окна с диапазонами
  LibraryView.swift                 — liked/hidden действия
  StatsView.swift                   — история сессий
  OnboardingView.swift              — 3 шага: welcome, окна уведомлений, разрешение
  Components/DesignSystem.swift     — TrulyButton, TrulyCard, шрифтовые хелперы
Services/
  TrulyTheme.swift                  — mint тема
  HomeRoute.swift                   — .timer(ActionItem), .done(Int, Bool)
  PreferenceStore.swift             — liked/hidden
  LogStore.swift                    — ActionLog хранилище, weeklyMinutes, syncSharedTotal()
  CatalogService.swift              — singleton, lazy load actions.json
  SuggestionEngine.swift            — алгоритм предложения
  NotificationService.swift         — scheduleDailyNudges(windows:lastSessionAt:), 7 дней вперёд
  NotificationDelegate.swift        — nudge → trulyOpenSuggestion; timer.done → просто открыть
  NudgeTextCatalog.swift            — singleton, nudgeTexts.json
  SharedDefaults.swift              — App Group UserDefaults (продублирован в TrulyWidget/)
  HomeRoute.swift                   — enum HomeRoute
  StartShuffleIntent.swift          — widget tap → shuffle
Models/
  ActionItem.swift
  ActionLog.swift
  NudgeWindow.swift                 — 3 окна с диапазонами, randomDateWithin(), Codable
UI/
  DesignConstants.swift             — windowPickerRadius: CGFloat = 16
Data/
  actions.json                      — 85 действий, 6 категорий
  nudgeTexts.json                   — 4+4+4 текста по окнам

TrulyWidget/
  TrulyWidget.swift                 — paper almanac systemSmall + accessory variants
  TrulyWidgetBundle.swift           — font registration из parent app bundle
  SharedDefaults.swift              — дубликат для изолированного процесса виджета
  WidgetColors.swift
```

### Удалённые
| Файл | Причина |
|---|---|
| `BetweenView.swift` | Заменён строкой «всего возвращено» в DoneView |
| `Localizable.xcstrings` | Приложение ru-only, xcstrings не нужен |
| `screenThreshold` (AppStorage key) | Ложное обещание — нет доступа к скрин-тайму |
| `TimerView.swift` | Дублировал TimerFlowView |
| `ActionCardView.swift` | Карточка инлайн в HomeView |
| `ThemeManager.swift` | Всегда возвращал .evening, лишняя абстракция |

---

## Палитра бренда

```
paper      #ECF3EE   фон иконки (светлая), верх градиента
paperDeep  #DCEDE4   фон иконки, низ градиента
ink        #015C42   штрих иконки (light) / цифра виджета
deep       #013D2C   тёмный ink
mint       #36D6A9   штрих иконки (dark)
wm         #02694C   wordmark в виджете
```

```
background:    #F6FAF8
surface:       #FFFFFF
surface2:      #F0F4F2
textPrimary:   #181D1C
textSecondary: #3D4A43
accent:        #3DB88A
accentDeep:    #006C4C
border:        #EBEFED
```

Шрифты: **DM Sans** (UI, подписи) + **Newsreader italic** (голос бренда, числа виджета, поэтичные подписи).
