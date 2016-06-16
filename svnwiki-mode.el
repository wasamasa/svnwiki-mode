;;; svnwiki-mode.el --- Major mode for editing svnwiki markup

;; Copyright (C) 2016 Vasilij Schneidermann <v.schneidermann@gmail.com>

;; Author: Vasilij Schneidermann <v.schneidermann@gmail.com>
;; URL: https://github.com/wasamasa/svnwiki-mode
;; Version: 0.0.1
;; Keywords: text

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; A major mode for editing svnwiki markup as specified on
;; <https://wiki.call-cc.org/edit-help>.

;; See the README for more info:
;; https://github.com/wasamasa/svnwiki-mode

;;; Code:

(defgroup svnwiki nil
  "svnwiki markup support"
  :group 'text)

;; NOTE: headings go from level 2 to 6 by design

(defconst svnwiki-level-2-re
  (rx bol "== " (* any) eol))

(defface svnwiki-level-2
  '((t :inherit outline-1))
  "Level 2 face"
  :group 'svnwiki)

(defconst svnwiki-level-3-re
  (rx bol "=== " (* any) eol))

(defface svnwiki-level-3
  '((t :inherit outline-2))
  "Level 3 face"
  :group 'svnwiki)

(defconst svnwiki-level-4-re
  (rx bol "==== " (* any) eol))

(defface svnwiki-level-4
  '((t :inherit outline-3))
  "Level 4 face"
  :group 'svnwiki)

(defconst svnwiki-level-5-re
  (rx bol "===== " (* any) eol))

(defface svnwiki-level-5
  '((t :inherit outline-4))
  "Level 5 face"
  :group 'svnwiki)

(defconst svnwiki-level-6-re
  (rx bol "====== " (* any) eol))

(defface svnwiki-level-6
  '((t :inherit outline-5))
  "Level 6 face"
  :group 'svnwiki)

(defconst svnwiki-strong-re
  (rx "'''"
      (group (+ (not (any " \t\n")))
             (* (: (+ (any " \t\n"))
                   (+ (not (any " \t\n"))))))
      "'''"))

(defface svnwiki-strong
  '((t :inherit bold))
  "Strong face"
  :group 'svnwiki)

(defconst svnwiki-emphasis-re
  (rx (: (or bol (not (any "'"))))
      "''"
      (group
       (: (+ (not (any " \t\n'"))))
       (* (: (+ (any " \t\n"))
             (+ (not (any " \t\n'"))))))
      "''"
      (: (or eol (not (any "'"))))))

(defface svnwiki-emphasis
  '((t :inherit italic))
  "Emphasis face"
  :group 'svnwiki)

(defconst svnwiki-literal-re
  (rx (group "{{")
      (group (+? any))
      (group "}}")))

(defface svnwiki-literal
  '((t :inherit font-lock-constant-face))
  "Literal face"
  :group 'svnwiki)

(defface svnwiki-literal-delimiter
  '((t :inherit bold))
  "Literal delimiter face"
  :group 'svnwiki)

(defconst svnwiki-link-re
  (rx (group "[[")
      (? (: (group (or "toc" "image")) ":"))
      (*? any)
      (? (: "|" (group (+? any))))
      (group "]]")))

(defface svnwiki-link-delimiter
  '((t :inherit bold))
  "Link delimiter face"
  :group 'svnwiki)

(defface svnwiki-link-prefix
  '((t :inherit font-lock-function-name-face))
  "Link prefix face"
  :group 'svnwiki)

(defface svnwiki-link-caption
  '((t :inherit font-lock-string-face))
  "Link caption face"
  :group 'svnwiki)

(defconst svnwiki-ruler-re
  (rx bol "----" eol))

(defface svnwiki-ruler
  '((t :inherit font-lock-keyword-face))
  "Ruler face"
  :group 'svnwiki)

(defconst svnwiki-bullet-re
  (rx bol (group (+ (any "*#"))) " " (* any) eol))

(defface svnwiki-bullet
  '((t :inherit bold))
  "Bullet/number item face"
  :group 'svnwiki)

(defconst svnwiki-definition-re
  (rx bol (group ";")
      " " (group (*? any))
      " " (group ":")
      " " (* any) eol))

(defface svnwiki-definition
  '((t :inherit font-lock-variable-name-face))
  "Definition list item face"
  :group 'svnwiki)

(defface svnwiki-definition-delimiter
  '((t :inherit bold))
  "Definition list item delimiter face"
  :group 'svnwiki)

(defconst svnwiki-doc-re
  (rx (group
       "<" (group (or "procedure" "macro" "read" "parameter" "record" "string"
                      "class" "method" "constant" "setter" "syntax" "type"))
       ">")
      (group (*? any))
      (group "</" (backref 2) ">")))

(defface svnwiki-doc-tag
  '((t :inherit font-lock-builtin-face))
  "Doc tag face"
  :group 'svnwiki)

;; NOTE multi-line stuff
;; TODO indented text == code block
;; TODO <enscript highlight="c">...</enscript>
;; TODO <table>...</table>
;; TODO <nowiki>...</nowiki>

;; NOTE wishlist stuff
;; - inserting headlines/bullets
;; - manipulating (indent) level
;; - folding
;; - hiding url with caption
;; - yasnippet snippets

(defconst svnwiki-font-lock-keywords
  `((,svnwiki-level-2-re . 'svnwiki-level-2)
    (,svnwiki-level-3-re . 'svnwiki-level-3)
    (,svnwiki-level-4-re . 'svnwiki-level-4)
    (,svnwiki-level-5-re . 'svnwiki-level-5)
    (,svnwiki-level-6-re . 'svnwiki-level-6)

    ;; FIXME potentially multi-line after wrapping
    ;; NOTE strong first to avoid emphasis overriding it
    ;; FIXME overlap possible with ''foo'''bar'''
    (,svnwiki-strong-re 1 'svnwiki-strong)
    (,svnwiki-emphasis-re 1 'svnwiki-emphasis)
    (,svnwiki-literal-re
     (1 'svnwiki-literal-delimiter)
     (2 'svnwiki-literal)
     (3 'svnwiki-literal-delimiter))

    ;; FIXME potentially multi-line with multi-word captions and wrapping
    (,svnwiki-link-re
     (1 'svnwiki-link-delimiter)
     (2 'svnwiki-link-prefix nil t)
     (3 'svnwiki-link-caption nil t)
     (4 'svnwiki-link-delimiter))
    (,svnwiki-ruler-re . 'svnwiki-ruler)
    (,svnwiki-bullet-re 1 'svnwiki-bullet)
    (,svnwiki-definition-re
     (1 'svnwiki-definition-delimiter)
     (2 'svnwiki-definition)
     (3 'svnwiki-definition-delimiter))

    (,svnwiki-doc-re
     (1 'svnwiki-doc-tag)
     (3 'svnwiki-literal)
     (4 'svnwiki-doc-tag))
    ))

;;;###autoload
(define-derived-mode svnwiki-mode text-mode "svnwiki"
  "Major mode for editing svnwiki markup"
  (setq font-lock-defaults '(svnwiki-font-lock-keywords t)))

(provide 'svnwiki-mode)
;;; svnwiki-mode.el ends here
