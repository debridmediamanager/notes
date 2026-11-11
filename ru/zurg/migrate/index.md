# Переход на zurg {#migrating-to-zurg}

Страница не пришла, в сообщении только её описание. Вставьте текст страницы, и я переведу его.

## Коротко {#the-short-version}

**zurg публикует каждый медиафайл, который публикует сервер, с которого ты уходишь, и даже больше.** Это замерили 2026-09-01. Одни и те же пять релизов загрузили во все
пять серверов, а потом смонтированные папки проверили командой `tree`. Вот [полное сравнение](https://github.com/debridmediamanager/usenet-streaming-benchmark).
Единственное, чего zurg публикует *меньше*, — это par2-паритет. Plex никогда не превращает его в элемент библиотеки.

Так что **контент ты не потеряешь.** Часть файлов просто придёт под другим
именем. Вот в этом и вся проблема, о которой эта страница. Plex привязывает элемент библиотеки
к пути к файлу. Файл по новому пути — это новый элемент.

Меняешь ты не файлы. Меняешь ты **кураторство**.

| Сохраняется | Пропадает вместе со старым элементом |
|---|---|
| Отметки просмотра, счётчики просмотров, позиции продолжения | Принадлежность к коллекциям |
| Оценки пользователей | Записи в плейлистах (они хранят id элементов) |
| Сами файлы | Выбранные постеры, арт и ручные исправления матчинга |
| | `added_at`. Твоя библиотека зальёт раздел Recently Added |

Состояние просмотра сохраняется, потому что `metadata_item_settings` привязана к аккаунту и
GUID `plex://`, а не к пути или id элемента. Оно снова прикрепится, когда новый элемент
сопоставится с тем же GUID. Если Plex неправильно сопоставит заново добавленный элемент, то
состояние не вернётся. Проверь несколько штук после первого сканирования.

Этого обмена можно полностью избежать, но за определённую цену. Перепиши `media_parts.file` в
базе Plex, чтобы строки никогда не пропадали. Или собери дерево symlink-заглушек, которое воссоздаёт каждый старый путь поверх монтирования zurg. Оба варианта работают. Оба — неподдерживаемая операция над недокументированной схемой, которая меняется между версиями Plex. Наполовину применённая перезапись хуже любого из двух исходов, которых она должна была избежать.

Эти гайды идут простым путём и честно говорят, чего он стоит.

## Ваша библиотека попадает в `__magic__`, а не в ферму симлинков {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

Каждый сервер из этого списка отдаёт свою библиотеку \*arrs через целую ферму симлинков. **zurg так не делает, и не стоит строить такую ферму самому.** Вместо этого есть [`__magic__`](../guides/magic.md). Это единственная директория, где пути *сохраняются*, а не вычисляются. Перемещение внутри неё просто переписывает строку в небольшой таблице. Байты не двигаются, ничего не копируется. Релиз остаётся на месте в аккаунте. Направь Sonarr и Radarr на неё, и они могут организовывать и переименовывать файлы как угодно, и это ничего не стоит.

Это не просто одна лишняя движущаяся деталь. Это слой, который не может сломаться так, как старая схема. Симлинк должен указывать на реальный путь. Очевидная цель, `__all__/<release>/<file>`, это путь, который *вычисляется*. Он меняется, когда релиз переименовывают. Он меняется снова, когда два релиза конфликтуют и zurg добавляет одному из них суффикс `{shorthash}`. Каждое такое изменение тихо ломает ссылку. Размещение в `__magic__` привязано к хэшу содержимого релиза плюс пути файла внутри него. Поэтому оно переживает переименование. Переживает суффикс `{shorthash}`. Переживает и ремонт, который добавляет релиз заново под совершенно новым id.

Так что с тем, что у тебя есть сейчас, **пути поменяются, и библиотеку придётся добавить заново**. Это касается и библиотеки симлинков для \*arr, и Plex, подключённого напрямую к старому маунту. Об этом говорилось выше, и это вся цена любой миграции здесь.

## Что у вас есть сейчас, зависит от платформы {#what-you-have-today-depends-on-your-platform}

Это определяет, описывают ли таблицы переименования на следующих страницах вашу библиотеку Plex или только источник, из которого она была собрана. Разберитесь с этим, прежде чем их читать.

### Linux и macOS. Ваши \*arrs уже всё переименовали {#linux-and-macos-your-arrs-already-renamed-everything}

Стратегия с симлинками — документированная настройка для всех четырёх серверов здесь, и она работает только на этих платформах. Сервер публикует
`completed-symlinks/<category>/<release>/<file>.rclonelink`. Затем `rclone mount
--links` превращает каждый из них в настоящий симлинк. Затем **Sonarr и Radarr импортируют из этой фермы в библиотеку по путям, которые они сами выбрали.** Монтирование — это источник, а не библиотека.

Два следствия.

- **Пути, которые видит Plex, — это пути \*arr.** Всегда. Корневая папка, затем папка сериала, затем папка сезона. Ни в одной из них нет имени релиза.
- **Имена файлов тоже принадлежат \*arr, если вы оставили переименование включённым.** Это "Rename Episodes" и "Rename Movies". Если переименование выключено, имена остаются именами исходного сервера, и таблицы на следующих страницах описывают именно то, что вы видите.

Итак, если вы используете \*arr с включённым переименованием, таблицы переименования для каждого сервера **не** описывают вашу библиотеку. Они описывают то, что \*arr получил в момент импорта. Это всё равно важно. Более удачное имя исходного файла — это более удачный парсинг, а вы собираетесь переимпортировать.

### Windows. Никакого слоя симлинков вообще {#windows-no-symlink-layer-at-all}

Ферма симлинков требует `rclone mount --links`, а это не входит в настройку для Windows. Монтирование выполняется как буква диска через WinFsp, и Plex и \*arrs обращаются прямо к нему. Поэтому **Plex показывает собственные имена файлов сервера**, а таблицы переименования точно описывают, что именно будет меняться. На странице [Настройка Windows](../setup/windows.md) описаны буква диска и правило её сессии.

Команды оболочки на страницах для отдельных серверов написаны для Linux и macOS (на macOS читайте `/mnt/zurg` как `/Volumes/Zurg`). В Windows читайте `/mnt/zurg` как `Z:\`, старый сервер останавливайте тем способом, которым он был запущен, а папки создавайте и файлы перемещайте в `__magic__` командами PowerShell из [руководства по `__magic__`](../guides/magic.md).

### Переход с библиотеки на симлинках {#coming-off-a-symlink-library}

You are not moving a library. You are rebuilding one. And `__magic__` gives the
\*arrs exactly what the symlink farm gave them without the farm. They move and
rename inside it as freely as before. Each move is a row write instead of a
file operation.

!!!danger Never let an \*arr move the old library into `__magic__`
Changing a series or movie root folder makes Sonarr or Radarr offer to **move**
the files. Say no. A move inside `__magic__` is free. A move from anywhere else crosses the
mount boundary and that is a copy. So is a move between two volumes of the same
mount. In Docker give the \*arr one volume that holds zurg's whole mount. A copy off a streaming mount pulls your
entire library down through your news or debrid allowance. Your old library is
a tree of symlinks so what gets copied is every target they resolve to.
!!!

Move each file into place yourself instead. Every move is one rename through
zurg's mount. Nothing is copied and nothing on your account changes. The script
below does it from your old library of symlinks. A link's path under the old
root folder is where Sonarr or Radarr expects the episode or film. Its target
names the file. So each file lands at the same path under the new root folder
that its link had under the old one. The old library is only read. It keeps
working until you switch the \*arr over.

1. **Build zurg beside the old server** as its page shows. Let it list the
   whole library first.
2. **Turn on `__magic__`** as its page shows. Keep Plex scans off and the
   \*arr queues paused.
3. **Save the `zurg_path` function from your server's page** as
   `zurg_path.sh` beside the script. It turns an old link's target into the
   file zurg serves. Each server lays its files out differently.
4. **Run the script** once per root folder. Set `OLD` and `NEW` and `LOG` for
   each one. A setup with `sonarr4k` and `radarr4k` beside the regular pair
   needs four runs.

   ```bash
   #!/bin/bash
   # adopt.sh — move every file an old root folder links to into __magic__.
   # One rename per file through zurg's mount. Nothing is copied or downloaded.
   # The old root folder is only read. GNU find and bash required.
   ZURG=/mnt/zurg                  # zurg's own mount
   OLD=/data/media/tv              # the old root folder, a tree of symlinks
   NEW="$ZURG/__magic__/tv"        # the new root folder inside __magic__
   LOG=./adopt-tv.log              # what went where
   . ./zurg_path.sh                # the zurg_path function from your server's page
   find "$OLD" -type l | while IFS= read -r link; do
     dest="$NEW/${link#"$OLD"/}"
     [ -e "$dest" ] && { echo "ALREADY THERE: $dest"; continue; }
     src=$(zurg_path "$(readlink "$link")")
     [ -n "$src" ] && [ -f "$src" ] || { echo "NOT IN ZURG: $link"; continue; }
     mkdir -p "$(dirname "$dest")"
     if mv "$src" "$dest"; then
       printf '%s\t%s\n' "$src" "$dest" >> "$LOG"
     else
       echo "FAILED: $link"
     fi
   done
   # Real files such as subtitles are small. They are copied and land on zurg's own disk.
   find "$OLD" -type f -size -32M | while IFS= read -r file; do
     dest="$NEW/${file#"$OLD"/}"
     [ -e "$dest" ] || { mkdir -p "$(dirname "$dest")" && cp "$file" "$dest"; }
   done
   ```

   It prints a line for every link it leaves alone.

   - `NOT IN ZURG` is a link to a file zurg does not have. Its NZB could not be
     recovered or its account is not in zurg's config.
   - `FAILED` is a move zurg refused. A second link to a file the script
     already moved prints this after a line from `mv` that says `No such file
     or directory`. A file can sit at only one path in `__magic__`. It stays
     where the first link put it.
   - `ALREADY THERE` is a path the new root folder already holds. Running the
     script again skips everything it placed before.

5. **Switch each \*arr over.** Select every series or every movie and edit them
   together. Set the root folder to the new one under `__magic__`. When it asks
   whether to move the files answer **No, I'll Move the Files Myself**. The
   script already put them there. Then run **Update All** so it finds them.
6. **Point Plex at the new root folders** and at nothing else. The next box
   says why.

Each move took about 15 milliseconds on a test library and nothing was copied.
Watch `data/local` on zurg's `/magic/` dashboard while the script runs. It
grows only by the subtitles and other small files the script copies. A number
that grows by gigabytes means something is being copied. Stop and look.

The old links keep working. A moved file still shows at its old `__all__` path
as well as at its new one. Builds before the 2026.10.04 nightly hid it at the
old path for up to 12 hours even though zurg still served it there. On one of
those builds restart zurg once the script is done. Keep Plex away from the old
folders and from `__all__` until you have.

The zurg side of this was measured on 2026-10-03. The \*arr side is its
ordinary root folder edit and was not tested for this guide. Do one series
first.

!!!warning Point each Plex library at one directory and not two
A library that scans a filter directory such as `movies` or `shows` or
`__all__` **and** scans `__magic__` finds every episode twice — and `__magic__`
holds its own `__all__`, so pointing a library at the root of the namespace
scans the whole library along with what you organised. Pick one. If you use the
\*arrs then point Plex at the root folders you made, `__magic__/tv` and
`__magic__/movies`. If you browse a library nobody organises then pick the
filter directories and leave `__magic__` off.
!!!

## Единственная защита, которую нельзя пропускать {#the-one-guard-you-must-not-skip}

**`autoEmptyTrash` должен быть `0` до того, как вы что-либо трогаете.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

В Windows, в PowerShell:

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex показывает настройку как `0` или `false`, когда она выключена.

Plex удаляет мягко. При `0` элемент, файл которого перестал существовать, остаётся в корзине и вернётся, если файл появится снова. При `1` он пропадает навсегда, как только сканирование его замечает. Если монтирование сбоит на десять секунд во время сканирования, вместе с ним пропадает вся библиотека. Такое уже стоило десятков тысяч элементов.

В этих упрощённых гайдах эта настройка делает больше работы, чем раньше, а не меньше. **Корзина — это место, где ваши старые элементы ждут, пока вы проверяете новые.** Очищайте её, когда всё устроило, и не раньше. Это единственный шаг, который делает потерю реальной, и это единственное необратимое действие во всех этих гайдах.

Пока вы там, отключите **"Generate video preview thumbnails"** для затронутых библиотек. На стриминговом монтировании каждый проход генерации миниатюр — это полное чтение релиза через ваш лимит Usenet или debrid. Миграция сразу передаёт Plex много новых элементов.

## Что дает каждый переход {#what-every-migration-gains}

Два из этих пунктов - это новые файлы, которые появляются в папках, которые Plex уже сканирует. Лучше знать о них заранее, чтобы они не стали неприятным сюрпризом.

- **Образцы клипов.** zurg - единственный из пяти инструментов, который публикует файл-образец из папки `Sample/` внутри релиза в RAR. Plex может принять файл `-sample.mp4` размером 9 МБ за дополнительный материал или за вторую версию серии. Если это не нужно, задайте
  [`only_show_the_biggest_file: true`](../reference/config.md) для папок, которые сканируют ваши медиатеки.
- **Файлы `.nfo`.** zurg - единственный, который их сохраняет. По умолчанию агенты Plex их не используют. Их читает агент XBMC и NFO, если вы его применяете.
- **`thumbnail.jpg` и рекламные файлы `.url`.** Ничего не делают. `thumbnail.jpg` - не то имя файла, которое Plex использует для постеров, а файлы `.url` - это реклама постера.
- **Пустые папки**, в которых цепочка архивов релиза нарушена. Plex игнорирует папки без медиафайлов.
- **par2 и sfv исчезают.** zurg скрывает их, определяя тип файла по его содержимому, а не по имени. Plex их никогда не индексировал, поэтому в вашей медиатеке это незаметно. Важно это только для инструментов, которые обходят эти файлы.

## Руководства {#the-guides}

- [Из AltMount](altmount.md). Переименовывает только релизы-архивы
- [Из decypharr](decypharr.md). Переименовывает одиночные файлы и релизы-архивы
- [Из InfiniDysk](infinidysk.md). Переименовывает одиночные файлы и релизы-архивы
- [Из nzbdav](nzbdav.md). Ничего не переименовывает, и это самый простой из пяти вариантов
- [Из streamnzb](streamnzb.md). Библиотеку переносить не нужно. У zurg есть собственный аддон для Stremio

Хотите перейти с Plex не на zurg, а наоборот? [Перейти с Plex на rex](../../rex/from-plex.md) — здесь zurg и ваши приложения Plex остаются на месте, а rex запускается рядом с вашим сервером Plex или вместо него.

Поведение при переименовании на каждой странице измеряли 2026-09-01 на корпусе из пяти релизов.
Использовались сборки zurg `bda7e3c3`, AltMount `0614008b`, InfiniDysk
`cd9b1205`, nzbdav `794948be` и decypharr `0dd1cbbd`. Более старые или
более новые сборки могут называть файлы по-другому. Прежде чем доверять списку
для повторного сканирования целиком, проверьте несколько релизов в своём дереве файлов.
