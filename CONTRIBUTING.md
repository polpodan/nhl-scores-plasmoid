
# Contributing

* English is the source language. Wrap all user-visible strings in `i18n("…")`.
* To update translations:
  ```bash
  ./translate/merge.sh
  # edit translate/fr.po
  ./translate/build.sh
  ```
* Commit `.po` and `template.pot` but **not** compiled `.mo` files.
