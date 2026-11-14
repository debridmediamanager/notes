# Библиотека Real-Debrid в Plex с zurg {#a-real-debrid-library-in-plex-with-zurg}

zurg показывает всё, что есть в вашем аккаунте Real-Debrid, как папки на вашем компьютере, уже разложенные по `movies` и `shows`. Добавьте эти две папки в Plex Media Server, и вся ваша библиотека Real-Debrid будет доступна в любом приложении Plex. Всё стримится из Real-Debrid, ничего заранее не скачивается. zurg нужно установить один раз; он сам несёт в себе rclone, так что больше ничего настраивать не нужно.

Не хотите запускать Plex Media Server или подключённый диск? [rex с zurg](../rex/with-zurg.md) показывает ту же библиотеку приложениям Plex без того и другого.

## Что понадобится {#what-you-need}

- **Спонсорство.** Ночные сборки zurg доступны только спонсорам. Станьте спонсором на [gatekeeper](https://gatekeeper.debridmediamanager.com/), и это даст вашему аккаунту GitHub доступ к загрузке. [Что даёт спонсорство](sponsorship.md) — там остальные подробности.
- **Премиум-аккаунт Real-Debrid** и его API-токен: [Ваш API-токен Real-Debrid](real-debrid-api-token.md) подскажет, где его найти.
- **Plex Media Server на том же компьютере, что и zurg.** Plex читает файлы из папок zurg, поэтому он должен их видеть. После этого смотреть можно через любое приложение Plex.
- **Компьютер, который работает постоянно**: Windows 10 или 11, Linux, Mac или Linux-машина с Docker.

## 1. Установите zurg {#1-install-zurg}

Каждая страница установки начинается с установщика в одну строку. Когда он покажет `Choose one or more providers in priority order:`, введите `1` для Real-Debrid, а затем вставьте свой токен.

| Ваш компьютер | Установка через | Ваша библиотека появится здесь |
|---|---|---|
| Windows | [zurg on Windows](../zurg/setup/windows.md) | `Z:\movies` и `Z:\shows` |
| Linux | [zurg on Linux](../zurg/setup/linux.md) | `/mnt/zurg/movies` и `/mnt/zurg/shows` |
| Mac | [zurg on macOS](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` и `/Volumes/Zurg/shows` |
| Linux с Docker | [Один файл Docker Compose](../zurg/guides/docker-compose.md), который запускает Plex Media Server вместе с zurg | `/zurg_mnt/zurg/movies` и `/zurg_mnt/zurg/shows` |

Установщик заканчивается командой `zurg doctor`, которая выводит список строк `PASS`.

## 2. Проверьте папки {#2-check-the-folders}

Откройте папку или диск zurg. Вы должны увидеть `movies`, `shows`, `__all__`, `__downloads__`, `__unplayable__` и `version.txt`.

При первом запуске zurg читает всю вашу библиотеку Real-Debrid. Пока это не закончится, папки останутся пустыми. Чтобы проверить, откройте `http://localhost:9999/ready` в браузере: когда библиотека загрузится, там появится `ready`.

## 3. Добавьте папки в Plex {#3-add-the-folders-in-plex}

В Plex Web нажмите **Add Library**, кнопку рядом с именем вашего сервера в боковой панели:

1. Выберите **Movies** и нажмите **Next**.
2. Нажмите **Browse for media folder** и выберите папку `movies` от zurg из таблицы выше, например `Z:\movies` в Windows.
3. Нажмите **Add Library**.

То же самое сделайте для **TV Shows** и папки `shows`. Plex после этого просканирует обе папки и подтянет постеры и названия.

## 4. Пусть zurg сообщит Plex о новых файлах {#4-let-zurg-tell-plex-about-new-things}

Plex не замечает, когда в вашем аккаунте Real-Debrid появляется что-то новое. zurg может сообщить ему об этом. Откройте панель управления zurg по адресу `http://localhost:9999/config/`, перейдите в **Media Server Integration** и нажмите **Login with Plex**. Войдите в Plex и выберите свой сервер.

![Раздел Media Server Integration на панели управления zurg с кнопкой Login with Plex](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

После этого zurg просит Plex сканировать каждую папку, которая изменилась. Он также отключает некоторые настройки Plex, которые рискованны для библиотеки со стримингом, например **Empty trash automatically after every scan**: [Recommended Plex Settings](../zurg/guides/plex.md#recommended-plex-settings) перечисляет их.

## Если что-то не работает {#when-something-is-wrong}

| Что вы видите | Что делать |
|---|---|
| Plex ничего не находит, или папки zurg пустые | zurg ещё читает ваш аккаунт. Подождите, пока `http://localhost:9999/ready` не покажет `ready`, затем снова запустите сканирование в Plex. |
| В Windows нет диска `Z:`, или Plex не может найти `Z:\movies` | `Z:` принадлежит вашей сессии рабочего стола Windows, и установщик zurg запускает zurg там при входе в систему. PowerShell, открытый от имени администратора, его тоже не видит. [Что делать, если что-то не так в Windows](../zurg/setup/windows.md#when-something-is-wrong) описывает каждый случай. |
| В Linux Plex видит пустую папку или не может её открыть, а `./zurg doctor` выдаёт `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` | Plex запускается от другого пользователя, чем zurg. Разрешите доступ другим пользователям командой <code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code>, затем выполните `./zurg service restart` в папке zurg. |
| В Docker библиотеки Plex пустеют после перезапуска zurg, а `docker exec plex ls /zurg_mnt/zurg` выдаёт `Transport endpoint is not connected` | Передайте контейнеру Plex папку zurg с опцией `rslave`: `/zurg_mnt:/zurg_mnt:rslave`. [В одном файле Docker Compose](../zurg/guides/docker-compose.md) это уже есть. |
| Новые файлы появляются в папках zurg, но не в Plex | Выполните шаг 4. До этого нажмите **Scan Library Files** в библиотеке Plex. |
| zurg выдаёт `bad_token` | Токен Real-Debrid неверный или обрезан. [Ваш API-токен Real-Debrid](real-debrid-api-token.md#when-something-is-wrong) описывает, как это исправить. |
| Диск заполняется | zurg хранит копию того, что вы смотрите, до 256G по умолчанию. Ограничить это можно, как показано в разделе [Keeping the cache small](../zurg/setup/windows.md#keeping-the-cache-small) (Windows) или [Disk the mount uses](../zurg/setup/linux.md#disk-the-mount-uses) (Linux). |

Всё ещё не получается? Спросите на форуме **zurg-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В [Getting help](remote-help.md) написано, что приложить к вопросу.

## Вопросы {#questions}

### Есть ли гайд, как настроить DMM, zurg и rclone для стриминга в Plex? {#is-there-a-guide-to-set-up-dmm-zurg-and-rclone-to-stream-in-plex}

Эта страница. Вам не нужно настраивать rclone самостоятельно: установщик zurg скачивает его, и zurg сам его запускает. DMM — это то место, где вы находите релизы и добавляете их в свой аккаунт Real-Debrid ([Что такое DMM и как им пользоваться](../dmm/index.md)). Затем zurg показывает их в своих папках, а Plex их подхватывает.

### Фильмы скачиваются на мой компьютер? {#do-the-movies-download-to-my-computer}

Нет. Plex читает каждый файл с Real-Debrid через zurg, когда вы нажимаете «Play». zurg хранит кэш того, что уже проигрывалось, и он может стать довольно большим: см. строку про диск выше.

### Можно ли обойтись без Plex Media Server? {#can-i-skip-plex-media-server}

Да, с rex. [rex with zurg](../rex/with-zurg.md) показывает вашу библиотеку zurg в приложениях Plex, без Plex Media Server и без монтирования. Можно и то, и другое: [One Docker Compose file](../zurg/guides/docker-compose.md) запускает zurg, Plex Media Server и rex на одной машине.

### Работает ли это и с TorBox или Usenet? {#does-it-work-with-torbox-or-usenet-too}

Да. Установщик zurg также предлагает TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud и Usenet и складывает их все в одни и те же папки `movies` и `shows`. На странице [Providers](../zurg/providers/index.md) есть отдельная страница для каждого из них.
