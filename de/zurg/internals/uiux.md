# Bewertung der UI/UX der Verzeichniskonfiguration {#directory-configuration-uiux-assessment}

## Umfang und aktueller Stand {#scope-and-current-state}
- Page: `Directory Configuration` at `http://localhost:9999/directories/`.
- Current UI: single flat table listing directories under headings like "MEDIA" and "RECENT" with columns for directory name, numeric order, and action links ("Edit", "Delete").
- Behavior: edit/delete trigger simple actions; no grouping beyond headings, no dedicated creation/editing flow for full YAML options.

## Wichtigste UX-Lücken {#key-ux-gaps}
- **Informationsarchitektur**
  - Gruppen sind optisch eingeebnet; Nutzer können sich nicht auf jeweils eine Gruppe konzentrieren.
  - Die Reihenfolge hängt von manuellen Zahlen ab (`group_order`), was unintuitiv und fehleranfällig ist.
  - Keine Suchleiste/kein Filter, um Verzeichnisse schnell zu finden.
  - Keine Massenaktionen (Löschen/Verschieben) und keine Auswahlmöglichkeiten.
- **Erstellen und Bearbeiten**
  - Bearbeiten- und Hinzufügen-Abläufe zeigen nicht das vollständige YAML-Schema (allgemeine Einstellungen, Filter für Größe/Datei/Tags/Zeit).
  - Kein strukturiertes Layout; Felder sind nicht gruppiert, was bei wachsender Optionenzahl zu Überforderung führt.
  - Kein verschachtelter UND/ODER-Regel-Editor, der die verschachtelte Filterlogik von YAML abbildet.
  - Tag-Felder (`tags_match_all`, `tags_match_any`) sind schwer auffindbar und bieten keine Hilfe bei der Auswahl.
  - Keine Live-Vorschau der Torrents, die den aktuellen Filtereinstellungen entsprechen.
- **Hilfestellung und Validierung**
  - Fehlende Tooltips/Info-Symbole pro Feld und keine Links zu ausführlicherer Dokumentation (z. B. `tags.md`).
  - Keine frühzeitige Warnung, wenn ein Verzeichnis keine Torrents liefern würde oder erforderliche Filter fehlen.
  - Regex- und andere Mustervorgaben-Felder bieten keine Echtzeit-Validierung.
  - Löschvorgänge erfolgen ohne Bestätigung oder Rückgängig-Option.
- **Barrierefreiheit und Responsivität**
  - Kontrast und Lesbarkeit sind nicht nach WCAG geprüft; Aktionen mit reinen Symbolen haben möglicherweise keine Beschriftung.
  - Drag-and-drop ist nicht verfügbar; es gibt keinen tastaturbedienbaren Weg zum Umsortieren.
  - Das mobile Layout ist nicht optimiert (die Tabelle passt sich nicht an gestapelte Karten an; Formulare lassen sich möglicherweise schlecht scrollen).
  - Aktionen basieren auf reinen Textlinks; Symbole und klare Klickflächen fehlen.
- **Performance und Feinschliff bei der Interaktion**
  - Suche/Filter (sobald vorhanden) braucht Debouncing und Paginierung bzw. Virtualisierung für große Listen.
  - Drag-and-drop (sobald vorhanden) braucht Speicherung und einen sauberen Rückfall, falls das Speichern fehlschlägt.

## Empfohlene UI/UX-Änderungen {#recommended-uiux-changes}
- **Gruppendarstellung**
  - Stelle jede oberste `group` (z. B. media/recent/example) als Karte oder einklappbaren Bereich mit eigener Liste dar.
  - Biete pro Gruppe schnelle Aktionen an (einklappen/ausklappen, Massenauswahl).
- **Sortierung**
  - Ersetze die numerische Reihenfolgespalte durch Ziehgriffe, mit denen du Einträge innerhalb einer Gruppe umsortierst. Zeige die berechnete Reihenfolge per Tooltip oder als Inline-Badge an.
  - Biete tastaturfreundliche Steuerelemente zum Verschieben an (Buttons für hoch/runter) als Barrierefreiheits- und Mobil-Alternative.
- **Suche und Massenaktionen**
  - Füge eine Such- und Filterleiste über der Liste hinzu. Entprelle die Eingabe (Debounce).
  - Füge Checkboxen für Massenlöschen und Massenverschieben hinzu, inklusive der Option "select all in group".
- **Hinzufügen/Bearbeiten**
  - Nutze ein Modal oder ein Seitenpanel mit einem gegliederten Layout: General, Size Filters, File Filters, Tag Filters, Time Filters und Advanced.
  - Ergänze einklappbare Unterbereiche, damit alles weniger überfordernd wirkt. Merke dir den Aufklappzustand während einer Sitzung.
- **Regel-Builder**
  - Stelle einen visuellen AND/OR-Builder bereit, der die YAML-Struktur abbildet: verschachtelte Gruppen, Bedingungs-Pills sowie Auswahlfelder für Eigenschaft, Operator und Wert (z. B. has_episodes, Regex mit matches/does not match).
  - Erlaube, auf jeder Ebene zwischen AND und OR zu wechseln. Zeige vorab vorschaubar den resultierenden Ausdruck an.
- **Tag-Auswahl**
  - Mehrfachauswahl mit Autovervollständigung, die aus den verfügbaren Tags gespeist wird. Zeige Tag-Beschreibungen und Tooltips sowie Anzahlen an, wenn verfügbar.
  - Unterscheide klar zwischen `tags_match_all` und `tags_match_any`.
- **Vorschau**
  - Füge "Preview matching torrents" hinzu, um Beispielergebnisse für den aktuellen Filterstand abzurufen. Zeige Skeleton- bzw. Ladezustände und behandle Fehler.
- **Hilfestellungen**
  - Nutze Inline-Tooltips oder Info-Icons für jedes Feld. Verlinke bei Bedarf auf tiefergehende Doku (z. B. [tags.md](../reference/tags.md)).
  - Zeige kontextbezogene Hinweise an, z. B. erklärt "Only show largest file" die Nebenwirkungen des Verhaltens.
- **Validierung und Sicherheit**
  - Blockiere das Speichern, wenn Pflichtfilter leer sind oder die Validierung fehlschlägt. Zeige Fehler inline an.
  - Prüfe Regex in Echtzeit clientseitig und bestätige beim Absenden zusätzlich auf dem Server, damit beide nicht voneinander abweichen.
  - Warne, wenn eine Konfiguration keine Torrents treffen würde (anhand der Vorschau oder Heuristiken).
  - Zeige vor dem Löschen einen Bestätigungsdialog. Biete nach Möglichkeit ein kurzes Rückgängig in einer Snackbar an (Soft Delete, falls unterstützt).
- **Barrierefreiheit und responsives Design**
  - Prüfe den Kontrast der gewählten Farbpalette. Sorge für sichtbare Fokuszustände und ARIA-Labels für alle Steuerelemente.
  - Stelle sicher, dass einklappbare Bereiche, Ziehgriffe und Aktionen per Tastatur bedienbar sind.
  - Zeige Gruppen auf dem Handy als gestapelte Karten. Modale Fenster und Panels müssen scrollbar sein, und die Aktions-Header sollen fixiert bleiben (Sticky-Header).
  - Kombiniere Icons bei wichtigen Aktionen mit Beschriftungen. Icon-only-Schaltflächen brauchen einen barrierefreien Namen.
- **Visuelle Politur**
  - Verwende einheitliche Icons für Bearbeiten, Löschen und Sortieren. Setze dezente Trennlinien und Chips, um Gruppenzugehörigkeit oder Status zu kennzeichnen.
  - Erwäge eine Farbcodierung pro Gruppe, damit sich alles schneller überfliegen lässt (mit barrierefreiem Kontrast).

## Abhängigkeiten und Annahmen zur Bestätigung {#dependencies-and-assumptions-to-confirm}
- API-Unterstützung für: Speichern der Gruppenreihenfolge, Massenoperationen, verschachtelte UND/ODER-Serialisierung, Tag-Metadatenquelle und Vorschau-Abfrage-Endpunkt.
- Löschverhalten: Soft- vs. Hard-Delete, Rückgängig-Zeitfenster und Audit-Anforderungen.
- Eigentums- und Berechtigungsmodell (falls Mehrbenutzerbetrieb) für die Anzeige der letzten Bearbeitung und zur Vermeidung von Konflikten.
- Leistungsanforderungen für Vorschau und Suche; Paging- oder Virtualisierungsstrategie für große Datenmengen.

## Umsetzungsprioritäten {#implementation-priorities}
1) Die Liste in gruppierte Karten/Ausklappbereiche umbauen; Suchleiste/Filter und Bestätigungsdialoge hinzufügen.
2) Modal oder Seitenpanel für Hinzufügen/Bearbeiten mit Abschnitten, Tooltips und einfacher Validierung einführen; Mehrfachauswahl für Tags hinzufügen.
3) Drag-and-drop und Neuordnen per Tastatur mit Speicherung hinzufügen; AND/OR-Regelbauer implementieren.
4) Vorschau der passenden Torrents mit entprellten Anfragen und Fehlerbehandlung hinzufügen.
5) Barrierefreiheit abschließen (Tastaturbedienung, ARIA) und ein responsives Karten-Layout für Mobilgeräte mit gestapelten Karten umsetzen.
