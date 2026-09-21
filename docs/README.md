# Документация TinySoNet

| Где | Что | Правило |
|---|---|---|
| [design/](design/) | живые спецификации | таблицы и списки, без прозы; правятся по мере решений |
| [adr/](adr/) | принятые решения | одно решение — один файл ≤ 1 страницы; не переписываются, а заменяются |
| [research/](research/) | обзоры и источники | вывод — ссылкой на ADR |
| [backlog.md](backlog.md) | повестка и открытые вопросы | закрытый вопрос → ADR или правка спеки, из backlog удаляется |

## Спецификации

| Файл | Тема |
|---|---|
| [00-overview.md](design/00-overview.md) | что строим, требования, принципы |
| [01-threat-model.md](design/01-threat-model.md) | противники и гарантии |
| [02-objects.md](design/02-objects.md) | объект, конверт, синхронизация |
| [03-keys.md](design/03-keys.md) | ключи, эпохи, коммиты, сведение форков |
| [04-membership.md](design/04-membership.md) | кто член: голоса, кворум, закрытие заявок, устройства |

## Идентификаторы

Только латиница.

| Префикс | Что | Где определены |
|---|---|---|
| F# | функциональное требование | [00-overview.md](design/00-overview.md) |
| NF# | нефункциональное требование | [00-overview.md](design/00-overview.md) |
| AS# | актив | [01-threat-model.md](design/01-threat-model.md) |
| A# | противник | [01-threat-model.md](design/01-threat-model.md) |
| G# | гарантия безопасности | [01-threat-model.md](design/01-threat-model.md) |
| D# ≡ ADR-000# | принятое решение | [adr/](adr/) |
| Q# | открытый вопрос | [research/](research/) | обзоры и источники | вывод — ссылкой на ADR |
| [backlog.md](backlog.md) |
