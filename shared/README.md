# shared

Ядро TinySoNet на Cangjie. Хостовые приложения содержат только вьюхи и вызывают
ядро через сгенерированные мосты.

## Артефакты

Что собирает `cjpm`, и что из этого подключают приложения:

| | iOS | Android |
|---|---|---|
| Мост | `@ObjCImpl` → `.h`/`.m` в `native/ios/generated` | `@JavaImpl` → `.java` в `native/android/generated` (планируется) |
| Артефакт | `target/<triple>/<profile>/TinySoNetKit.xcframework` | `.aar` (планируется) |
| Форма | статическая либа + заголовки + `module.modulemap` | classes.jar + `.so` на ABI |
| Слайсы | `aarch64-apple-ios`, `aarch64-apple-ios-simulator` | `arm64-v8a`, `x86_64` |
| Упаковка | `scripts/package-ios.sh` | `scripts/package-android.sh` (планируется) |
| Подключение | Frameworks → **Do Not Embed**, `import TinySoNetKit` | Gradle-зависимость на модуль |

Приложению на iOS нужны два флага линковки: `-ObjC` (иначе `+initialize`
в ObjC-прослойке не доживёт до рантайма) и `-lc++` (рантайм Cangjie написан
на C++).

Форма артефактов у платформ разная и общей не станет: XCFramework нужен из-за
того, что `aarch64-apple-ios` и `aarch64-apple-ios-simulator` — одна архитектура
на разных платформах и в один `ar`-архив не ложатся; у Android деление идёт по
ABI внутри одного `.aar`. Общим остаётся только правило ниже.

## Правило

`cjpm build` всегда оставляет готовый к подключению артефакт — хостовому
приложению нечего знать про то, что лежит рядом, и про тулчейн Cangjie.

Раскладка вывода повторяет соглашение cjpm, платформа и режим сборки в пути:

| | |
|---|---|
| `target/<triple>/<profile>/tsn/` | либы пакетов, кладёт cjpm |
| `target/<triple>/<profile>/TinySoNetKit/` | слайс: либа, заголовки, объектники |
| `target/<triple>/<profile>/TinySoNetKit.xcframework` | артефакт |

xcframework по природе держит слайсы всех triple сразу, поэтому в каталог каждого
triple кладётся одна и та же копия — Xcode указывают на любую. Переписываются они
все и на каждой сборке, чтобы копия не оказалась устаревшей. `release` и `debug`
не затирают друг друга.

Запускает упаковку `build.cj` на стадии post-build; сам скрипт можно прогнать
отдельно, когда правишь флаги:

```
bash scripts/package-ios.sh
```

## Каталоги

| | |
|---|---|
| `src/shared/` | логика, общая для платформ |
| `src/ios/` | `@ObjCMirror` и `@ObjCImpl` — граница с iOS |
| `native/<платформа>/generated/` | вывод cjc, в git не хранится, пересоздаётся |
| `native/<платформа>/support/` | руками: то, что cjc не генерирует, но чего требует его вывод |
| `target/` | сборка и артефакты; сносится по `cjpm clean` |

И мост, и поддержка к нему платформенные: у iOS это заголовки и
`module.modulemap`, у Android будет своё. Общего слоя `native/` нет.

На каждый новый `@ObjCMirror` нужен шим в `native/ios/support/` — см.
`native/ios/support/NSObject.h`.
