# qFioofa-LazyDocker

Персональный конфиг [lazyDocker](https://github.com/jesseduffield/lazydocker):
базовый `config.yml` + тема `yugen-ash`, собранные в один итоговый файл.

## Структура

```
src/
  config.yml            # gui, logs, stats, командные шаблоны, custom/bulk команды
  themes/
    palette.yml         # единственный источник правды для цветов
    yugen-ash.yml       # тема, использует токены @primary, @color600, ...
scripts/
  deploy.sh             # собрать src/* в ~/.config/lazydocker/config.yml
  validate.sh           # проверить merge, токены палитры и частые ошибки
flake.nix               # Home Manager модуль с опцией lazydocker-config.theme
```

## Деплой

Через Home Manager:

```nix
{
  imports = [ ./path/to/qFioofa-LazyDocker ];
  # опционально, по умолчанию "yugen-ash"
  lazydocker-config.theme = "yugen-ash";
}
```

Или вручную (нужен `python3` + `PyYAML`):

```bash
./scripts/deploy.sh
# выбор темы:
LAZYDOCKER_THEME=yugen-ash ./scripts/deploy.sh
```

Проверка без записи в `~/.config`:

```bash
./scripts/validate.sh
```

## Тема и палитра

`palette.yml` содержит словарь `palette:` с hex-цветами. В файлах тем цвета
задаются токенами `@<key>` (например `"@primary"`), а `deploy.sh` / `flake.nix`
подставляют реальные значения при сборке. Если токен неизвестен — сборка
падает с ошибкой.

Настраиваемых цветов в lazyDocker всего четыре:
`activeBorderColor`, `inactiveBorderColor`, `selectedLineBgColor`,
`optionsTextColor`. Цвета статусов контейнеров, health, CPU, портов и образов
зашиты в upstream и не конфигурируются. Для графиков статистики `color`
принимает только именованные цвета (`cyan`, `green`, ...), но не hex.

## Что настроено

- Мышь включена (`gui.mouseEvents: false` — upstream-поле называется
  `IgnoreMouseEvents`, поэтому `true` её отключает).
- Логи: таймстемпы, `since: 60m`, `tail: 500`.
- Графики: CPU, память, сеть RX/TX; сбор статистики 5 минут.
- `replacements.imageNamePrefixes` чистит префиксы `docker.io/` и `ghcr.io/`.
- `ignore` скрывает `<none>` и `buildkit` (недокументированная опция upstream).
- Custom-команды: pause/unpause, system df, compose config/ps/images/watch,
  pull, dive, docker scout.
- Bulk-команды: stop/kill/restart/pause/unpause all, compose ps/config/images,
  system df, prune.

## Опциональные утилиты

Команды `dive` и `docker scout cves` появятся в меню всегда, но сработают
только если установлены `dive` и Docker Scout. `compose watch` требует
Docker Compose v2.17+.
