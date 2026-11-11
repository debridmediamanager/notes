# ElfHosted-Newsserver {#elfhosted-news-server}

ElfHosted bündelt einen Usenet-Account mit seinen Stremio-Addon-Tarifen und nennt ihn Usenet Essential. Diese Seite hält fest, was dieser Server ist. Alles unten wurde am 2026-09-04 von einem einzigen Host aus gemessen. Den Account selbst konnte ich nicht messen, denn der einzige Zugang, den ElfHosted jemals veröffentlicht hat, ist tot, und genau das ist der erste Befund.

## Was auf der Leitung antwortet {#what-answers-on-the-wire}

`news.elfhosted.com` löst auf `94.232.116.124` auf und spricht NNTP über TLS 1.3 auf 563, hinter einem
Let's-Encrypt-Zertifikat für `news.elfhosted.com`. Das Zertifikat trägt genau diesen einen Namen und
sonst keinen, und es wurde am 2026-08-17 ausgestellt. Derselbe Server antwortet unverschlüsselt auf 119 mit
derselben Begrüßung. Die Begrüßung lautet `200 Welcome to elfhosted`.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
AUTHINFO USER
```

Das ist derselbe `nntpswitch2`-String, den der [TorBox-Reader](torbox-news-server.md) meldet. Diese Liste ist die unauthentifizierte, daher endet sie bei `AUTHINFO USER` statt bei `POST`. `HELP` antwortet ohne Zugangsdaten und listet den vollen Befehlssatz inklusive `POST`, `IHAVE`, `XPAT` und `XGTITLE` auf. Das fehlende `POST` liegt also an der Session und nicht am Server.

Drei Befehle funktionieren vor der Authentifizierung, sonst keiner.

| Befehl | Antwort |
|---|---|
| `DATE` | `111 20260903225242` |
| `HELP` | `100 Help follows.` |
| `CAPABILITIES` | `101 Capabilities.` |
| `MODE READER` | `480 Authentication required for command.` |
| `GROUP` and `LIST` and `STAT` and `POST` | `480 Authentication required for command.` |

## Wer betreibt ihn {#who-runs-it}

Beim TorBox-Teil musste ich den Betreiber aus der Nachbarschaft ableiten. Hier geht das nicht. `news.elfhosted.com` liegt direkt im Abavia-Reader-Block.

`94.232.116.124` gehört zu `94.232.112.0/21`, `AS48345 AS-ABAVIA`, registriert auf Abavia S.r.l. aus San Marino. Ein Reverse-Sweep über `94.232.116.0/24` liefert 79 Namen. Fünfundvierzig davon antworten auf NNTP über 563, und alle fünfundvierzig melden `nntpswitch2 (local-dev)` mit byte-identischen Capability-Listen in gleicher Reihenfolge. Die Border-Router von Abavia stehen im selben /24, dazu die XS-News-Feeder, der Webhost und der Nameserver.

| Adresse | Reader | Begrüßung |
|---|---|---|
| `94.232.116.122` | `reader2.newsxs.nl` | `200 Welcome to Newsxs` |
| `94.232.116.124` | `news.elfhosted.com` | `200 Welcome to elfhosted` |
| `94.232.116.125` | `reader.spotnews.nl` | `200 Welcome to Spotnews` |
| `94.232.116.128` | `reader.easyusenet.nl` | `200 Welcome to Easyusenet` |
| `94.232.116.131` | `reader.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.135` | `reader-usenetfarm.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.136` | `reader.torrentclaw.com` | `200 Welcome to TorrentClaw` |
| `94.232.116.140` | `reader.usenet.nl` | `200 Usenet.nl S.r.l.` |
| `94.232.116.147` | `giganews.hostredirects.com` | `200 Welcome to giganews` |
| `94.232.116.150` | `news.usenext.de` | `200 Welcome to Aviteo Ltd DE` |
| `94.232.116.174` | `news.hitnews.com` | `200 Welcome to Hitnews` |

ElfHosted hat vier Adressen von Easyusenet, sieben von XS News und zwölf von TorrentClaw. TorrentClaw ist ein weiteres Stremio-Addon, das dieselbe Plattform vorschaltet.

Es gibt kein namensbasiertes Multiplexing. Wenn man sich mit einem servername von `reader.xsnews.nl` verbindet, oder mit einem Namen, den es gar nicht gibt, kommt immer dasselbe Zertifikat und dieselbe Begrüßung `200 Welcome to elfhosted` zurück. Pro Marke gibt es eine Adresse.

TorBox ist nicht in diesem Block. Es sitzt auf `78.152.55.171` in `AS3257 GTT` in den Niederlanden. Deshalb ist die Zuordnung zu ElfHosted die stärkere der beiden. TorBox betreibt dieselbe Software neben einer Marke aus dieser Familie. ElfHosted betreibt sie im eigenen Adressraum von Abavia.

**Gemessen** sind der Software-Fingerabdruck, die Adressbesitzverhältnisse, das Zertifikat und das Fehlen von namensbasiertem Multiplexing. **Abgeleitet** ist, dass der Spool dahinter Abavia gehört und nicht eine Mischung, die ElfHosted selbst zusammengestellt hat. Ohne Zugangsdaten lässt sich das auf dem Netzwerkverkehr nicht unterscheiden.

## Die veröffentlichten Zugangsdaten sind tot {#the-published-credential-is-dead}

Am 2025-12-20 kündigte ElfHosted NNTP-Zugang an, der bei NzbDav mitgeliefert wird, als zweimonatiger Proof of Concept mit einem nicht genannten Usenet-Infrastrukturanbieter, und veröffentlichte in der Ankündigung ein einziges gemeinsames Zugangsdaten-Paar.

| Feld | Wie veröffentlicht, 2025-12-20 |
|---|---|
| Host | `news.elfhosted.com` |
| Port | 563 SSL |
| Benutzername | `elfie` |
| Passwort | `elfie` |
| Verbindungen | 100 |
| Kosten | keine bis Februar 2026 |

Für neue Nutzer war er in NzbDav bereits vorkonfiguriert. Im Beitrag stand, dass die Vereinbarung nach Abschluss des Proof of Concept überprüft werden sollte. Das ist passiert. Die Zugangsdaten funktionieren nicht mehr.

```
200 Welcome to elfhosted
381 Need more.
482 Invalid username or password
```

Bei dieser Software ist `482 Invalid username or password` die wirklich endgültige Absage und nicht das Verbindungslimit, das stattdessen `482 too many connections for your user` meldet. Auch das Timing passt. Fünf Versuche mit einem Benutzernamen, den es nie gab, und zwei Versuche mit `elfie` sind dieselbe Ablehnung im selben Rahmen.

| Verbindungsversuch | Antwort | Zeit |
|---|---|---|
| Zufälliger Benutzername, fünf Versuche | `482 Invalid username or password` | Median 2066 ms, Spanne 2043 bis 2070 ms |
| `elfie` und `elfie`, zwei Versuche | `482 Invalid username or password` | 2043 ms und 2212 ms |

Ein abgeschaltetes Zugangsdaten-Paar und ein Benutzername, der nie vergeben wurde, sind hier nicht zu unterscheiden, weder im Code noch im Timing. Rund zwei Sekunden braucht diese Software, um Nein zu sagen. Das macht der TorBox-Reader genauso.

Die Zahl von 100 Verbindungen beschreibt also ein Angebot, das ausgelaufen ist. Es ist die einzige Zahl, die ElfHosted je zu diesem Server veröffentlicht hat, und sie gilt für nichts, was du heute kaufen kannst. Der bezahlte Usenet Essential vergibt vermutlich pro Kunde ein eigenes Zugangsdaten-Paar. Das lässt sich von außen nicht prüfen.

In derselben Ankündigung wurde außerdem ein interner Newznab-Endpunkt unter `elfhosted-internal.zyclops` veröffentlicht. Er akzeptiert jeden API-Key und lässt sich für ein bestimmtes Backbone auf bekannte gesunde Ergebnisse filtern. Dieser Endpunkt ist gemeint, wenn der ElfHosted-Shop sagt, ein Usenet-Tarif enthalte den Indexer. Er liefert Verfügbarkeits- und Gesundheitssignale statt Inhalte, und laut ihrer eigenen Formulierung ist er eine Kristallkugel für die Gesundheit der Infrastruktur und keine Schatzkarte. Ein Tarif braucht trotzdem noch einen echten Indexer daneben.

## Was sich nicht messen ließ {#what-could-not-be-measured}

Alles, was darüber entscheidet, ob sich ein Provider-Slot lohnt. Dafür brauchst du überall Zugangsdaten.

| Eigenschaft | Stand |
|---|---|
| Verbindungslimit | unbekannt, die 100 gelten nur für den eingestellten Proof of Concept |
| Retention | nie veröffentlicht |
| Gruppen in `LIST ACTIVE` | braucht Auth |
| Artikelnummern-Fenster | braucht Auth |
| Abdeckung gegenüber anderen Backbones | braucht Auth |
| Durchsatz pro Einzelverbindung | braucht Auth |
| Posting | der Server bietet `POST`, ob das Konto es darf, ist unbekannt |

Eine siebentägige Testphase kostet einen Dollar und bringt dir die Zugangsdaten. Wenn du in dieser Woche denselben Durchlauf mit 531 Message-IDs machst, wie auf der [TorBox-Seite](torbox-news-server.md#what-it-actually-holds), beantwortet das jede Zeile oben.

## Was die Plattform dir bereits sagt {#what-the-platform-already-tells-you}

Zwei Punkte lassen sich von den TorBox-Messungen übertragen, einer nicht.

Übertragbar ist die Ablehnungslogik und das Timing der Ablehnung. Gleiche Software, gleiche Antworten. Das heißt, `482 Invalid username or password` bedeutet auch hier einen toten Zugang, und das Limit ist ein anderer String.

Übertragbar ist auch das Artikelnummern-Fenster. Ein `nntpswitch2`-Reader erzeugt Artikelnummern nur in einem kurzen Fenster. Alles, was Nummern statt Message-IDs durchläuft, sieht deshalb nur etwa zwei Wochen Usenet. Das ist eine Eigenschaft der Plattform und nicht eines einzelnen Accounts. NZB-gesteuerte Lesevorgänge sprechen Artikel über die Message-ID an und sind davon nicht betroffen.

Nicht übertragbar ist die Abdeckung. Der TorBox-Reader wurde als echte Teilmenge eines Omicron-Accounts gemessen: 71.2 Prozent, und in 531 hatte er keine eigenen Artikel. Das war der Endpunkt von TorBox, nicht dieser hier, und TorBox gehört nicht einmal zu diesem Block. Er ist der nächstliegende Vergleichswert, mit derselben Software und demselben Betreiber, aber keine Messung von ElfHosted. Behandle ihn als Hypothese, die man prüfen muss, nicht als Antwort.

## Einrichtung in zurg {#configuring-it-in-zurg}

Wenn ein Zugang (Credential) erhalten wurde, ist er ein ganz normaler `type: nzb`-Server-Eintrag neben dem primären Server.

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
        - name: elfhosted-news
          host: news.elfhosted.com
          port: 563
          tls: true
          username: YOUR_ELFHOSTED_USERNAME
          password: YOUR_ELFHOSTED_PASSWORD
          connections: 8
          backbone: abavia
          backup: true
```

Fang mit 8 Verbindungen an und erhöhe sie erst, nachdem das echte Limit gemessen wurde. Die veröffentlichte 100 ist
veraltet, und ein Pool, der über ein unbekanntes Limit hinaus Verbindungen öffnet, wird sich beim Kaltstart selbst abweisen. Setze
`backbone: abavia` statt eines Markennamens, denn XS News, Easyusenet, Hitnews, UseNeXT und dieser hier laufen auf derselben Plattform. Würdest du sie als separate Backbones behandeln, könnte ein Pool einen Spool als mehrere zählen. `backup: true` behält ihn für Artikel, die bereits jeder primäre Server abgelehnt hat.

Verbinde niemals einen zweiten Client mit demselben Zugang. Der Server weist den älteren Nutzer ab und nicht den neueren, sodass ein zweiter Verbraucher den ersten aus dem Rennen wirft.

## Lohnt sich ein Platz dafür? {#is-it-worth-a-slot}

Es kann nicht allein gekauft werden. Es kommt mit einem Stremio-Addon-Plan für neun Dollar im Monat, der außerdem ein gehostetes Addon, eine NzbDav-Instanz und ein TorBox-Essentials-Konto enthält. Als Posten darin kostet es nichts extra, und das ist das Stärkste, was sich ohne Zugangsdaten dafür sagen lässt.

Gegenüber einem Stack, der schon einen Omicron-Account sowie Eweka und Frugal hat, ist ein vierter Leser von dieser Plattform dieselbe Wette, die die TorBox-Seite eingegangen ist und verloren hat. Diese Wette wurde hier nicht gemessen. Es ist also eine Vermutung und kein Urteil. Was das klären würde, sind ein Dollar, eine Woche und der 531-ID-Sweep.
