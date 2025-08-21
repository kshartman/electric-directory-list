# electric-list-directory

[![MELPA](https://melpa.org/packages/electric-list-directory-badge.svg)](https://melpa.org/#/electric-list-directory)
[![MELPA Stable](https://stable.melpa.org/packages/electric-list-directory-badge.svg)](https://stable.melpa.org/#/electric-list-directory)

A lightweight “electric” popup directory browser for Emacs.

## Features
- Popup buffer: `*Electric Directory*` (reused every time).
- Header line shows the current directory (abbreviated).
- `RET` on a file opens it **and exits**; `RET` on a directory **drills into it**. Works with both **column** layouts (`-C/-x/-m`) and **long** listings (`-l`).
- `d` deletes the file/dir at point (with prompt) and **refreshes in place**.
- `~` deletes backup/autosave files (`*~` and `#*#`) and **refreshes**.
- `Backspace` (`DEL`) goes **up one directory**.
- `SPC` **or** `q` quits and restores your previous window layout.
- With a prefix argument (`C-u`), run plain `list-directory`.

### Switches
The popup preserves your layout flags but sanitizes only `-d/--directory` and `-F/--classify` so filename parsing remains stable. Use a prefix argument (`C-u`) when invoking to be prompted for switches.

### Key bindings (inside *Electric Directory*)
- `RET` — visit file (exit) / enter directory (stay)
- `SPC` — quit (same as `q`)
- `q` — quit
- `DEL` — up one directory
- `n` / `p` — next / previous line
- `d` — delete file or directory at point (prompts; refreshes)
- `~` — delete backup & autosave files in current dir (prompts; refreshes)
- Scrolling: `C-v` and `M-v` still work as usual

## Installation

### From MELPA (once available)
```
M-x package-install RET electric-list-directory RET
```

Using `use-package`:
```elisp
(use-package electric-list-directory
  :ensure t
  :bind ("C-x C-d" . electric-list-directory))  ; Replaces default `list-directory`
```

### Manual / local checkout
If the file is in your load-path (e.g., `~/.e/`):
```elisp
(autoload 'electric-list-directory "electric-list-directory"
  "Browse DIRNAME in an electric directory buffer." t)
;; Bind to C-x C-d (Note: this replaces the default `list-directory` binding):
(global-set-key (kbd "C-x C-d") #'electric-list-directory)
```

## Usage
```
M-x electric-list-directory
```
- Invoke with a prefix arg (`C-u`) to get the built-in `list-directory` and a prompt for switches.

## Changelog
- **1.4** — Fix visiting behavior: `RET` on a file now opens it and stays in that buffer (the popup is closed). Only `q`/`SPC` restore the previous window layout. `RET` on a directory still drills in.
- **1.3** — RET now works with **column** layouts (`-C/-x/-m`) and **long** listings (`-l`); sanitize only `-d/--directory` and `-F/--classify`; docstrings wrapped and key names quoted for package-lint; README updated.
- **1.2** — Space quits (`SPC` behaves like `q`); docstrings cleaned; Emacs 26.1+ compatibility.
- **1.1** — Header line with current dir; drill-in on directories; delete helpers.
