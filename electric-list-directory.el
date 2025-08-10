;;; electric-list-directory.el --- Lightweight popup directory browser -*- lexical-binding: t; -*-
;;
;; Author: K. Shane Hartman <shane@ai.mit.edu>
;; Version: 1.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: files, convenience
;; URL: https://github.com/kshartman/electric-list-directory
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;;; Commentary:
;;
;; Lightweight “electric” popup directory browser.
;;
;; Features:
;; - Popup buffer: *Electric Directory* (reused every time).
;; - Header line shows the current directory (abbreviated).
;; - RET on a file opens it and exits; RET on a directory drills into it.
;; - d deletes file/dir at point (with prompt) and refreshes in place.
;; - ~ deletes backup/autosave files (*~ and #*#) and refreshes.
;; - Backspace (DEL) goes up one directory level.
;; - q quits and restores your previous window layout.
;; - Prefix arg (C-u) runs plain `list-directory`.
;;
;; Install:
;;   (require 'electric-list-directory)
;;
;; Usage:
;;   M-x electric-list-directory
;;   (Optionally bind it to C-x C-d with `electric-list-directory-setup-keys`)
;;
;;; Code:

(defgroup electric-list-directory nil
  "Lightweight popup directory browser."
  :group 'files
  :prefix "electric-list-directory-")

(defcustom electric-list-directory-replace-list-directory nil
  "If non-nil, bind `electric-list-directory' to C-x C-d at load time."
  :type 'boolean
  :group 'electric-list-directory)

;;;###autoload
(defun electric-list-directory-setup-keys ()
  "Bind `electric-list-directory' to C-x C-d, replacing `list-directory'."
  (interactive)
  (global-set-key (kbd "C-x C-d") #'electric-list-directory))

;;;###autoload
(when electric-list-directory-replace-list-directory
  (electric-list-directory-setup-keys))

(defvar-local electric-list-directory--winconf nil
  "Saved window configuration for restoring after quit.")
(defvar-local electric-list-directory--dir nil
  "Directory currently shown in *Electric Directory*.")
(defvar-local electric-list-directory--switches nil
  "Switches used to render the listing (sanitized).")

(define-derived-mode electric-list-directory-mode special-mode "Electric-Dir"
  "Read-only directory listing with quick navigation and delete commands.")

(let ((m electric-list-directory-mode-map))
  (define-key m (kbd "q")   #'electric-list-directory-quit)
  (define-key m (kbd "RET") #'electric-list-directory-visit)
  (define-key m (kbd "SPC") #'scroll-up-command)
  (define-key m (kbd "DEL") #'electric-list-directory-up)
  (define-key m (kbd "n")   #'next-line)
  (define-key m (kbd "p")   #'previous-line)
  (define-key m (kbd "~")   #'electric-list-directory-delete-backups)
  (define-key m (kbd "d")   #'electric-list-directory-delete-at-point))

(defun electric-list-directory--sanitize-switches (sw)
  "Remove -d/--directory from SW so we list contents, not the dir itself."
  (let* ((src (or sw list-directory-brief-switches))
         (tokens (split-string src "[ \t]+" t))
         (out '()))
    (dolist (tok tokens)
      (cond
       ((string= tok "--directory") nil)
       ((string-prefix-p "--" tok) (push tok out))
       ((string-prefix-p "-" tok)
        (let* ((flags (substring tok 1))
               (flags (replace-regexp-in-string "d" "" flags)))
          (unless (string= flags "")
            (push (concat "-" flags) out))))
       (t (push tok out))))
    (mapconcat #'identity (nreverse out) " ")))

(defun electric-list-directory--update-header ()
  "Update the header line to show the current directory."
  (setq header-line-format
        (concat "  📁 "
                (abbreviate-file-name (or electric-list-directory--dir default-directory)))))

(defun electric-list-directory--refresh ()
  "Re-render the listing for current buffer settings."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert-directory electric-list-directory--dir
                      electric-list-directory--switches
                      nil t)
    (goto-char (point-min))
    (setq buffer-read-only t)
    (setq default-directory electric-list-directory--dir)
    (electric-list-directory--update-header)))

;;;###autoload
(defun electric-list-directory (dirname &optional switches)
  "List DIRNAME in an *Electric Directory* popup.
With prefix arg, run plain `list-directory` instead."
  (interactive
   (list (read-directory-name "Electric List Directory: " nil default-directory t)
         (when current-prefix-arg
           (read-string "ls switches: " list-directory-brief-switches))))
  (if current-prefix-arg
      (list-directory dirname switches)
    (let* ((buf-name "*Electric Directory*")
           (buf  (get-buffer-create buf-name))
           (conf (current-window-configuration))
           (sw   (electric-list-directory--sanitize-switches switches))
           (dir  (file-name-as-directory (expand-file-name dirname))))
      (with-current-buffer buf
        (electric-list-directory-mode)
        (setq electric-list-directory--winconf  conf
              electric-list-directory--dir      dir
              electric-list-directory--switches sw)
        (electric-list-directory--refresh))
      (pop-to-buffer buf))))

(defun electric-list-directory--filename-at-point ()
  "Return absolute filename under point, or nil."
  (let* ((tap (thing-at-point 'filename t))
         (cand (when tap (expand-file-name tap default-directory))))
    (cond
     ((and cand (file-exists-p cand)) cand)
     (t
      (save-excursion
        (let* ((bol (line-beginning-position))
               (eol (line-end-position))
               (line (buffer-substring-no-properties bol eol)))
          (cond
           ((string-match "\\([^ ]\\(?:.*[^ ]\\)?\\)\\s-*->\\s-.*$" line)
            (expand-file-name (match-string 1 line) default-directory))
           ((string-match "\\s-\\{2,\\}\\([^ ].*\\)$" line)
            (expand-file-name (match-string 1 line) default-directory))
           (t nil))))))))

(defun electric-list-directory-visit ()
  "If point is on a directory, drill into it; if on a file, visit and exit."
  (interactive)
  (let ((path (electric-list-directory--filename-at-point)))
    (cond
     ((null path)
      (message "No file at point"))
     ((file-directory-p path)
      (setq electric-list-directory--dir (file-name-as-directory (expand-file-name path)))
      (electric-list-directory--refresh)
      (message "Entered %s" electric-list-directory--dir))
     (t
      (let ((conf electric-list-directory--winconf))
        (find-file path)
        (when (get-buffer "*Electric Directory*")
          (kill-buffer "*Electric Directory*"))
        (when conf
          (set-window-configuration conf)))))))

(defun electric-list-directory-up ()
  "Go up one directory level."
  (interactive)
  (let ((parent (file-name-directory (directory-file-name electric-list-directory--dir))))
    (setq electric-list-directory--dir (file-name-as-directory (expand-file-name parent)))
    (electric-list-directory--refresh)
    (message "Up to %s" electric-list-directory--dir)))

(defun electric-list-directory-delete-at-point ()
  "Prompt and delete the file/dir at point, then refresh (stay in list)."
  (interactive)
  (let ((file (electric-list-directory--filename-at-point)))
    (cond
     ((not file)
      (message "No file at point"))
     ((file-directory-p file)
      (when (y-or-n-p (format "Delete directory %s recursively? "
                              (file-name-nondirectory (directory-file-name file))))
        (delete-directory file t)
        (message "Deleted %s" file)
        (electric-list-directory--refresh)))
     (t
      (when (y-or-n-p (format "Delete file %s? " (file-name-nondirectory file)))
        (delete-file file)
        (message "Deleted %s" file)
        (electric-list-directory--refresh))))))

(defun electric-list-directory-delete-backups ()
  "Prompt and delete *~ and #*# files in the current listing dir, then refresh."
  (interactive)
  (let* ((dir (or electric-list-directory--dir default-directory))
         (cands (append (file-expand-wildcards (expand-file-name "*~" dir) t)
                        (file-expand-wildcards (expand-file-name "#*#" dir) t))))
    (if (null cands)
        (message "No backup/autosave files in %s" dir)
      (when (y-or-n-p (format "Delete %d backup/autosave files in %s? "
                              (length cands) dir))
        (dolist (f cands)
          (ignore-errors (delete-file f)))
        (message "Deleted %d backup/autosave files" (length cands))
        (electric-list-directory--refresh)))))

(defun electric-list-directory-quit ()
  "Quit the electric directory buffer, restoring prior windows."
  (interactive)
  (let ((conf electric-list-directory--winconf))
    (when (get-buffer "*Electric Directory*")
      (bury-buffer "*Electric Directory*"))
    (when conf
      (set-window-configuration conf))
    (message nil)))

(provide 'electric-list-directory)

;;; electric-list-directory.el ends here
