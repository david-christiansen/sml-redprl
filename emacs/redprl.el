;;; redprl.el --- Major mode for editing RedPRL proofs and interacting with RedPRL  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Jonathan Sterling

;; Author: Jonathan Sterling <jon@jonmsterling.com>
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'cl-lib)

(defgroup redprl nil "RedPRL" :prefix 'redprl :group 'languages)

(defface redprl-declaration-keyword-face
  '((t (:inherit font-lock-keyword-face))) "Face for RedPRL's declaration keywords."
  :group 'redprl)

(defface redprl-sort-face
  '((t (:inherit font-lock-type-face))) "Face for RedPRL's built-in sorts."
  :group 'redprl)

(defcustom redprl-command "redprl"
  "The command to be run for RedPRL."
  :group 'redprl
  :type 'string
  :tag "Command for RedPRL"
  :options '("redprl"))

(defvar redprl-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?- "w" table)
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?= "w" table)
    (modify-syntax-entry ?' "w" table)
    (modify-syntax-entry ?/  "_ 123" table)
    (modify-syntax-entry ?\n ">" table)
    table)
  "Syntax table for RedPRL.")

(defconst redprl-keywords
  '("Def" "Thm" "Tac" "Sym" "Record")
  "RedPRL's keywords.")


(defconst redprl-builtin-sorts
  '("exp" "exn" "lbl" "lvl")
  "RedPRL's built-in sorts.")

(defconst redprl-def-name-regexp
  '(: "Def" (+ whitespace) (group-n 1 (+ word)) not-wordchar))

(defconst redprl-thm-name-regexp
  '(: "Thm" (+ whitespace) (group-n 1 (+ word)) not-wordchar))

(defconst redprl-tac-name-regexp
  '(: "Tac" (+ whitespace) (group-n 1 (+ word)) not-wordchar))

(defconst redprl-sym-name-regexp
  '(: "Sym" (+ whitespace) (group-n 1 (+ word)) not-wordchar))

(defconst redprl-record-name-regexp
  '(: "Record" (+ whitespace) (group-n 1 (+ word)) not-wordchar))

(defconst redprl-declaration-name-regexp
  `(or ,redprl-def-name-regexp
       ,redprl-thm-name-regexp
       ,redprl-tac-name-regexp
       ,redprl-sym-name-regexp
       ,redprl-record-name-regexp))

(defvar redprl-mode-font-lock-keywords
  `(
    ;; Declaration keyword
    (,(regexp-opt redprl-keywords 'words) 0 'redprl-declaration-keyword-face)

    ;; Built-in sorts
    (,(regexp-opt redprl-builtin-sorts 'words) 0 'redprl-sort-face)))

(defun redprl-defined-names ()
  "Find all names defined in this buffer."
  (save-excursion
    (let ((names ()))
      (goto-char (point-min))
      (while (re-search-forward (rx-to-string redprl-declaration-name-regexp) nil t)
        ;; Do not save if inside comment
        (unless (nth 4 (syntax-ppss))
          (push (match-string-no-properties 1) names)))
      names)))

(defun redprl-completion-at-point ()
  "Attempt to perform completion for RedPRL's keywords."
  (when (looking-back (rx (+ word)) nil t)
    (let* ((match (match-string-no-properties 0))
           (start-pos (match-beginning 0))
           (end-pos (match-end 0))
           (candidates (cl-remove-if-not
                        (apply-partially #'string-prefix-p match)
                        (append redprl-keywords
                                redprl-builtin-sorts
                                (redprl-defined-names)))))
      (if (null candidates)
          nil
        (list start-pos end-pos candidates)))))

(defun redprl--compilation-buffer-name-function (_mode)
  "Compute a buffer name for the redprl-mode compilation buffer."
  "*redprl*")

(defun redprl-compile-buffer ()
  "Load the current file into RedPRL."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if filename
        (progn
          (when (buffer-modified-p) (save-buffer))
          (let*
              ((dir (file-name-directory filename))
               (file (file-name-nondirectory filename))
               (command (concat redprl-command " " file))

               ;; Emacs compile config stuff - these are special vars
               (compilation-buffer-name-function
                'redprl--compilation-buffer-name-function)
               (default-directory dir))
            (compile command)))
      (error "Buffer has no file name"))))



;; ###autoload
(define-derived-mode redprl-mode prog-mode "RedPRL" "Major mode for editing RedPRL proofs."

  (set (make-variable-buffer-local 'comment-start) "// ")
  (setq font-lock-defaults '((redprl-mode-font-lock-keywords) nil nil))

  (set (make-local-variable 'imenu-generic-expression)
       `(("Def" (rx-to-string ,redprl-def-name-regexp) 1)
         ("Thm" (rx-to-string ,redprl-thm-name-regexp) 1)
         ("Tac" (rx-to-string ,redprl-tac-name-regexp) 1)
         ("Sym" (rx-to-string ,redprl-sym-name-regexp) 1)
         ("Record" (rx-to-string ,redprl-record-name-regexp) 1)))

  ;; Bind mode-specific commands to keys
  (define-key redprl-mode-map (kbd "C-c C-l") 'redprl-compile-buffer)


  (set (make-local-variable 'completion-at-point-functions)
       '(redprl-completion-at-point)))

;; ###autoload
(add-to-list 'auto-mode-alist '("\\.prl\\'" . redprl-mode))


(provide 'redprl)
;;; redprl.el ends here
