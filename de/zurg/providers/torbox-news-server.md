# TorBox-Newsserver {#torbox-news-server}

Ein TorBox-Pro-Abo enthält einen Usenet-Account. Dabei handelt es sich um einen echten NNTP-Server, und zurg kann ihn als ganz normalen `type: nzb`-Provider nutzen. Diese Seite beschreibt, was dieser Server ist und was er als Provider-Slot taugt. Alles unten wurde am 2026-09-02 und 2026-09-03 von zwei Hosts in getrennten Netzen gemessen.

## Was auf der Leitung antwortet {#what-answers-on-the-wire}

`nntp.torbox.app:563` spricht NNTP über TLS 1.3 hinter einem Let's-Encrypt-Zertifikat für `nntp.torbox.app`. Die Begrüßung lautet `200 Welcome to TorBox`. Die Liste der Fähigkeiten nennt die Software.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
POST
```

Diese Implementierungszeichenfolge ist weder INN noch Diablo und auch nicht der `nntpd`, den manche Anbieter angeben.
Es ist eigene Software, und der Name sagt, was sie tut. Vor einem oder mehreren Artikel-Spools sitzt ein Switch.

## Wer betreibt ihn {#who-runs-it}

Vierzig öffentliche Reader-Hostnamen wurden auf diesen Implementierungs-String geprüft. Zweiunddreißig antworteten mit NNTP
und sechs davon melden `nntpswitch2`. Alle sechs liefern identische Capability-Listen in identischer Reihenfolge.

| Reader | Adresse | Begrüßung |
|---|---|---|
| `nntp.torbox.app` | 78.152.55.171 | `200 Welcome to TorBox` |
| `news.cheapnews.eu` | 78.152.55.164 | `200 Welcome to Cheapnews` |
| `reader.xsnews.nl` | 94.232.116.131 | `200 Welcome to XS News` |
| `news.easyusenet.nl` | 94.232.116.128 | `200 Welcome to Easyusenet` |
| `news.hitnews.com` | 94.232.116.174 | `200 Welcome to Hitnews` |
| `news.usenext.de` | 94.232.116.150 | `200 Welcome to Aviteo Ltd DE` |

Alles andere antwortete anders. Dazu gehören die Omicron-Marken sowie Eweka, Frugal, UsenetExpress, Giganews und Usenet.Farm.

Die Adressen klären den Rest. `94.232.112.0/21` ist auf Abavia S.r.l. aus San Marino registriert, mit `abuse@abavia.com` im Register hinterlegt. Ein Reverse-Scan von `94.232.116.0/24` liefert mehr als sechzig Reader-Namen in diesem einen Block. XS News, Easyusenet, Hitnews und UseNeXT sitzen dort neben Dutzenden kleinerer Marken. Das benachbarte `94.232.117.0/24` nutzt durchgehend das Hostnaming von XS News.

TorBox liegt nicht in diesem Block. Es sitzt in einem Amsterdamer Adressbereich, sieben Adressen von `news.cheapnews.eu` entfernt.

**Gemessen** sind der Software-Fingerprint, der Adressbesitz und die Nachbarschaft. **Abgeleitet** ist die kommerzielle Vereinbarung. TorBox beschreibt sein Usenet als hochwertige Mischung mehrerer Usenet-Anbieter, und die Switch-Software passt dazu. Die sichere Aussage lautet also: TorBox schaltet sich vor dieselbe Reader-Plattform, die auch die Abavia- und XS-News-Marken betreiben. Nicht sicher ist dagegen die Aussage, TorBox verkaufe einen bestimmten benannten Spool weiter.

## Was dein Account dir bietet {#what-the-account-gives-you}

| Eigenschaft | Wert |
|---|---|
| Host | `nntp.torbox.app:563` TLS, antwortet auch auf 119 |
| Gruppen in `LIST ACTIVE` | 103,415 |
| Verbindungen | 10, eine harte Obergrenze, exakt gezählt, auch während des Handshakes |
| Aufbewahrung | 3900+ Tage, von TorBox für diesen Server angegeben |
| Posten | erlaubt, `POST` antwortet mit `340 Start posting` |
| Overview-Felder | Subject, From, Date, Message-ID, References, Bytes, Lines, Xref:full |
| Komprimierung | `XZVER` und `XZHDR` werden beide angeboten |
| Bandbreite | unbegrenzt, wird aber im TorBox-Dashboard in der Nutzungsangabe mitgezählt |

Die Zugangsdaten bekommst du auf torbox.app unter tools und View Usenet Connection Details. Der Benutzername ist deine Auth-ID. Das Passwort wird nur einmal angezeigt. Jedes Zurücksetzen macht das alte Passwort ungültig, und dadurch funktioniert jeder bereits eingerichtete Client nicht mehr.

Zwei Fehlermeldungen sind wichtig, wenn etwas schiefgeht. `482 too many connections for your user` ist das Limit, und es verschwindet, sobald eine Verbindung wieder freigegeben wird. `482 Invalid username or password` bedeutet, dass die Zugangsdaten wirklich ungültig sind. Beide Fehler kommen erst nach etwa zwei Sekunden. Eine erfolgreiche Anmeldung ist viel schneller: Im Produktivbetrieb über einen Tag gemessen lag sie zwischen 64 ms und 592 ms.

## Das Artikelnummern-Fenster ist zwei Wochen breit {#the-article-number-window-is-two-weeks-wide}

`GROUP` auf einer stark genutzten Binärgruppe meldet eine Anzahl, die genau der oberen Marke minus der unteren Marke entspricht. Echte Spools haben Lücken, deshalb ist diese Gleichheit ein Zeichen für künstlich erzeugte Nummerierung. Außerdem ist das Fenster kurz.

| Gruppe | Untere Marke | Obere Marke | Nummern im Fenster |
|---|---|---|---|
| `alt.binaries.boneless` | 148068410000 | 150053594960 | 1,985,184,960 |
| `alt.binaries.teevee` | 2992135000 | 3392153099 | 400,018,099 |
| `alt.binaries.multimedia` | 31901685000 | 32301734812 | 400,049,812 |

Wenn du die ältesten Nummern in `alt.binaries.boneless` abfragst, bekommst du Artikel, die am 2026-08-19 gepostet wurden. Das war vierzehn Tage, bevor dies geschrieben wurde. Alles, was älter ist, hat auf diesem Server keine Nummer.

Das betrifft zurg nicht. Eine NZB spricht Artikel über die Message-ID an, und eine Message-ID-Suche erreicht Artikel, die weit älter als das Fenster sind. Es betrifft aber alles, was Artikelnummern durchläuft. Ein Header-Downloader oder ein Indexer, der auf diesen Server zeigt, sieht zwei Wochen Usenet und nichts davor.

## Leitet es deine Anfrage an andere Anbieter weiter {#is-it-proxying-your-request-to-other-providers}

Nein. Drei Messungen zeigen, dass die Antwort aus einem Spool kommt, den die Plattform bereits hat.

**Es lehnt schneller ab, als es irgendjemanden fragen könnte.** Fünfundzwanzig Message-IDs, die nirgendwo existiert haben, wurden bei drei Servern abgefragt.

| Server | `STAT` bei Treffer | `STAT` bei einer ID, die nie existierte |
|---|---|---|
| `nntp.torbox.app` | 37 ms | **43 ms** |
| `news.eweka.nl` | 20 ms | 471 ms |
| `newshosting.tweaknews.eu` | 44 ms | 909 ms |

Ein Server, der die Upstreams abfragt, bevor er antwortet, ist beim Nein am langsamsten, weil jeder Upstream erst antworten muss. Dieser hier sagt Nein in derselben Zeit, in der er ein Ja bestätigt. Das ist ein lokaler Index, der antwortet.

**Beim ersten Abruf gibt es keinen Aufschlag.** Zehn Artikel aus den Jahren 2012 bis 2018 wurden zuerst kalt abgerufen und dann sofort noch einmal über dieselbe Verbindung.

| Server | kalter Median | warmer Median |
|---|---|---|
| `nntp.torbox.app` | 49.6 ms | 30.9 ms |
| `news.eweka.nl` | 98.0 ms | 78.1 ms |

Das Verhältnis kalt zu warm liegt hier bei 1.6, gegenüber 1.25 bei einem einfachen Spool. Das sind TCP und Page Cache. Ein Abruf bei einem Drittanbieter beim ersten Request würde deutlich mehr kosten und nur beim kalten Durchlauf auftauchen. Ein 792 KB großer Artikel kam kalt in 49 bis 73 ms an, also etwa 11 bis 16 MB/s, und dafür bleibt kein Platz für einen Round Trip zu einem anderen Provider.

**Ein Mix kann keine Teilmenge eines seiner Mitglieder sein.** Das ist das Argument, das die Frage entscheidet. Wenn der Server mehrere Backbones zusammengeführt hätte, wäre seine Abdeckung deren Vereinigung, und er würde Artikel enthalten, die mindestens ein Mitglied nicht hatte. Er enthielt aber keinen davon. Er ist eine echte Teilmenge des Omicron-Accounts mit 71.2 Prozent. Zusammengeführte Provider können das nicht erzeugen.

Ein verwandtes Detail für alle, die die Quelle nachverfolgen wollen. Die Header kommen normalisiert zurück statt im Originalwortlaut. Die Reihenfolge der Felder ändert sich, und die Groß- und Kleinschreibung wird umgeschrieben, sodass aus `X-Received-Body-CRC` `X-Received-Body-Crc` wird und aus `Message-ID` `Message-Id`. `Path` ist bei jedem geprüften Artikel `not-for-mail`. Ein einfacher Spool kann die echte Kette erhalten, und einer der oben genannten Server gibt für denselben Artikel `news.tweak-news.eu!spooler.pl1!...!feed.tweaknews.nl!path-stripped` zurück. Die Header werden also aus geparsten Feldern neu aufgebaut, und der Feed-Pfad lässt sich daraus nicht mehr rekonstruieren.

## Einrichtung in zurg {#configuring-it-in-zurg}

Das Konto ist ein ganz normaler `type: nzb`-Server-Eintrag. Zwei Schlüssel sind wichtiger als die anderen.

```yaml
providers:
  - type: nzb
    nntp:
      host: your-primary.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 40
      backbone: primary-backbone
      servers:
        - name: torbox-news
          host: nntp.torbox.app
          port: 563
          tls: true
          username: YOUR_TORBOX_AUTH_ID
          password: YOUR_TORBOX_NEWS_PASSWORD
          connections: 8
          backbone: torbox
          backup: true
```

`backup: true` hält die zehn Verbindungen für Artikel frei, die alle anderen Konten bereits abgelehnt haben. Ein
stark ausgelasteter Primärserver leitet nicht dorthin um. Nur ein echtes *no such article* tut das. Siehe
[die Provider-Schlüssel](../reference/config.md), wie sich `backup` und `backbone` verhalten.

Stell 8 statt 10 ein. Das Limit zählt auch Verbindungen, die noch im Handshake stecken. Ein Pool, der bis zum Limit aufgeht, lehnt sich beim Kaltstart also selbst ab. Zwei freie Plätze lassen außerdem Raum, um eine Prüfung von Hand laufen zu lassen, ohne die Produktion zu stören. Richte niemals einen zweiten Client mit denselben Zugangsdaten ein. Zwei Verbraucher eines Kontos mit zehn Verbindungen blockieren sich gegenseitig, und der Server verweigert dann eher die ältere Verbindung statt der neueren.

## Was es tatsächlich speichert {#what-it-actually-holds}

Die Abdeckung wurde gegen drei andere Backbones mit denselben Artikel-IDs gemessen. Die Stichprobe umfasst 177
Releases aus einer echten zurg-NZB-Bibliothek. Die Veröffentlichungsdaten reichen von 2011 bis 2026. Aus jedem Release
wurden drei Artikel gleichmäßig verteilt über die Datei genommen. Das ergibt 531 Message-IDs. Jede ID wurde bei vier Accounts
abgefragt, jeweils über eine Verbindung. Die drei anderen sind ein Omicron-Account über Tweaknews, ein Eweka-Account und ein
Frugal-Account.

| Veröffentlichungsjahr | IDs | `nntp.torbox.app` | `newshosting.tweaknews.eu` | `news.eweka.nl` | `newswest.frugalusenet.com` |
|---|---|---|---|---|---|
| 2011 | 9 | 0 | 9 | 0 | 0 |
| 2012 | 21 | 16 | 21 | 21 | 21 |
| 2013 | 36 | 30 | 33 | 33 | 33 |
| 2014 | 36 | 33 | 36 | 36 | 36 |
| 2015 | 33 | 17 | 31 | 24 | 26 |
| 2016 | 36 | 31 | 36 | 36 | 36 |
| 2017 | 36 | 21 | 33 | 27 | 19 |
| 2018 | 36 | 16 | 36 | 24 | 24 |
| 2019 | 36 | 30 | 36 | 36 | 36 |
| 2020 | 36 | 34 | 36 | 36 | 36 |
| 2021 | 36 | 25 | 36 | 33 | 30 |
| 2022 | 36 | 29 | 36 | 27 | 27 |
| 2023 | 36 | 15 | 29 | 22 | 16 |
| 2024 | 36 | 23 | 35 | 32 | 33 |
| 2025 | 36 | 28 | 36 | 31 | 31 |
| 2026 | 36 | 30 | 36 | 30 | 30 |
| **Gesamt** | **531** | **378 (71.2%)** | **515 (97.0%)** | **448 (84.4%)** | **434 (81.7%)** |

TorBox hat von dieser Bibliothek weniger Artikel beantwortet als alle drei bezahlten Backbones.

Die Zahl, die entscheidet, ob der Slot seinen Platz verdient, ist eine andere. **TorBox hatte nichts, was den anderen
fehlte.** Kein einziger Artikel von 531. Im Vergleich mit dem Omicron-Account ist es eine echte Teilmenge ohne jeglichen
eigenen Artikel. TorBox hatte 9 Artikel, die Frugal fehlten, und 6, die Eweka fehlten. Jeder davon war auch bei Omicron
vorhanden. Der Omicron-Account allein hatte dagegen 61 Artikel, die kein anderer Backbone hatte.

Ein Miss auf diesem Server ist echt und keine Antwort eines ausgelasteten Servers, die schlecht ausfällt. Alle 153 Misses
wurden Minuten später auf einer frischen Verbindung erneut abgefragt, und keiner kam zurück. Ein früherer Lauf mit der
gleichen Struktur fragte 77 Misses erneut ab und bekam 1 zurück. Also sind etwa 1 Prozent einer negativen Antwort Rauschen,
und der Rest ist Abwesenheit.

Ein Hit ist ebenfalls echt. Zwanzig Artikel, die alle vier Server angeblich hatten, wurden danach mit `BODY` vollständig
abgerufen. Alle vier lieferten 20 von 20. `STAT` auf diesem Server kann man also als Zusage verstehen, dass die Daten
tatsächlich ankommen.

Die Durchsatzrate einer einzelnen Verbindung wurde in denselben Läufen gemessen, wird hier aber nicht angegeben, weil sie
nicht stabil war. Drei Durchgänge von einem Host ergaben für TorBox Werte zwischen 1,6 und 7,4 MB/s, die anderen drei
lagen in diesem Bereich und ohne eindeutige Reihenfolge. Wer einen Pool dimensioniert, sollte von seinem eigenen Host aus
messen.

Zu der Tabelle gehören drei Einschränkungen. Die Stichprobe stammt aus der Bibliothek eines einzelnen Betreibers, sie
spiegelt also wider, was diese Bibliothek sammelt. Drei Artikel aus einem Release sind nicht unabhängig voneinander, daher
entspricht eine Zelle pro Jahr eigentlich zwölf Releases und nicht sechsunddreißig. Und eine `STAT`-Antwort ist eine
Aussage über einen einzelnen Artikel und kein Urteil über ein ganzes Release.

## Lohnt sich ein Platz dafür? {#is-it-worth-a-slot}

Das Konto kostet nichts extra, weil es bei Pro schon dabei ist. Das ist das stärkste Argument dafür.

Es ist kein Retention-Backbone, und wer es so einrichtet, wird enttäuscht sein. Es hat einen kleineren Teil einer echten Bibliothek beantwortet als die drei bezahlten Konten, mit denen es verglichen wurde, und es hat keinen einzigen Artikel geliefert, den ein anderes Konto nicht schon abgelehnt hatte. Ein Stack, der bereits ein Omicron-Konto hat, gewinnt nichts, wenn er dieses hier dazunimmt.

Zwei ehrliche Einsatzzwecke bleiben. Ein Setup mit nur einem Provider bekommt eine kostenlose zweite Meinung, und jede zweite Meinung ist besser als keine. Und `backup: true` macht einen falschen Tipp billig, weil ein Backup-Konto erst gefragt wird, nachdem alle primären Konten gesagt haben, dass es den Artikel nicht gibt.
