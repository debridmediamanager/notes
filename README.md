# notes

Source for **[notes.debridmediamanager.com](https://notes.debridmediamanager.com/)**, the docs and guides for
[Debrid Media Manager](https://debridmediamanager.com/), [zurg](https://zurg.debridmediamanager.com/) and
[rex](https://rex.debridmediamanager.com/).

It is a [Retype](https://retype.com/) site. `npx retype build` must finish with 0 errors. Pushing `main` publishes it.
A page that moves keeps its old URL as a 301 line in `_redirects`.

`bash i18n/build.sh` builds English and every translation into `.retype/`, the way the workflow does.

## Translations

Write English only. Every push to `main` translates what changed into Chinese, Spanish, Arabic, Indonesian,
Portuguese, French, Japanese, Russian and German with `i18n/translate.py` (OpenRouter, repository secret
`OPENROUTER_TRANSLATE_KEY`) and publishes each language under `/<lang>/`. Translations are cached in
`i18n/cache/` by a hash of the English text, so only changed text costs anything; the workflow commits the cache
back as `chore: translations for …`. Do not edit the cache by hand: change the English and the next push
translates it again. Text whose translation fails the checks (code, links, tables or markup changed) is published in
English and tried again on the next push (a warning on the run). If OpenRouter fails (key, monthly limit) the run goes red. The same `translate.py` lives in notes, zurg-site and rex-site; change it in one and copy it
to the other two.

---

**More from DMM:** [Debrid Media Manager](https://debridmediamanager.com/) · [zurg](https://zurg.debridmediamanager.com/) · [rex](https://rex.debridmediamanager.com/) · [Docs](https://notes.debridmediamanager.com/) · [Sponsor](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP) · [Reddit](https://www.reddit.com/r/debridmediamanager/)
