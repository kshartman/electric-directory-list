# electric-list-directory

[![MELPA](https://melpa.org/packages/electric-list-directory-badge.svg)](https://melpa.org/#/electric-list-directory)
[![MELPA Stable](https://stable.melpa.org/packages/electric-list-directory-badge.svg)](https://stable.melpa.org/#/electric-list-directory)

A lightweight popup directory browser for Emacs.

## Features
- Popup buffer: `*Electric Directory*` (reused every time).
- Header line shows the current directory (abbreviated).
- `RET` on a file opens it and exits; `RET` on a directory drills into it.
- `d` deletes file/dir at point (prompt, refreshes in place).
- `~` deletes backup/autosave files (`*~` and `#*#`) and refreshes.
- `Backspace` goes up a directory level.
- `q` quits and restores your previous window layout.
- Prefix arg (`C-u`) runs plain `list-directory`.

## Installation

```elisp
(use-package electric-list-directory
  :ensure t
  :bind ("C-x C-d" . electric-list-directory))
```

Or with `autoload` from a local copy:

```elisp
(add-to-list 'load-path "/path/to/electric-list-directory")
(autoload 'electric-list-directory "electric-list-directory"
  "List DIRNAME in an *Electric Directory* popup." t)
(global-set-key (kbd "C-x C-d") #'electric-list-directory)
```

## License
GPL-3.0-or-later
