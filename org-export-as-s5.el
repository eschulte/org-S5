;;; org-export-as-s5.el --- Org-mode export backend for the S5 slideshow engine

;; Copyright (C) 2013  Eric Schulte

;; Author: Eric Schulte <schulte.eric@gmail.com>
;; Keywords: org S5 javascript html slideshow

;; This file is not (yet) part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'org)

(defvar org-s5-theme "default")

(defvar org-s5-ui-dir "ui")

(defvar org-s5-title-string-fmt "<h1>%author - %title</h1>"
  "Format template to specify title string.  Completed using `org-fill-template'.
Optional keys include %author, %title and %date.")

(defvar org-s5-title-page-fmt (mapconcat #'identity
                                         '("<div class=\"slide\">"
                                           "<h1>%title</h1>"
                                           "<h1>%author</h1>"
                                           "<h1>%date</h1>"
                                           "</div>")
                                         "\n")
  "Format template to specify title page.  Completed using `org-fill-template'.
Optional keys include %author, %title and %date.")

(defun org-export-format-drawer-s5 (name content)
  (if (string-equal name "NOTES")
      (concat "\n#+BEGIN_HTML\n<div class=\"notes\">\n#+END_HTML\n" content "\n#+BEGIN_HTML\n</div\n#+END_HTML\n")
    (org-export-format-drawer name content)))

(defun org-export-as-s5
  (arg &optional ext-plist to-buffer body-only pub-dir)
  "Wrap `org-export-as-html' in setting for S5 export."
  (interactive "P")
  (add-to-list 'org-drawers "NOTES")
  (flet ((join (lst) (mapconcat #'identity lst "\n"))
         (sheet (href media id)
                (org-fill-template
                 (concat "<link rel=\"stylesheet\" href=\""
                         org-s5-ui-dir
                         "/%href\""
                         " type=\"text/css\" media=\"%media\" id=\"%id\" />")
                 `(("href" . ,href)
                   ("media" . ,media)
                   ("id" . ,id)))))
    (let ((org-export-html-style-extra
           (join `("<!-- configuration parameters -->"
                   "<meta name=\"defaultView\" content=\"slideshow\" />"
                   "<meta name=\"controlVis\" content=\"hidden\" />"
                   "<!-- style sheet links -->"
                   ,(sheet (concat org-s5-theme "/slides.css")
                           "projection" "slideProj")
                   ,(sheet "default/outline.css" "screen" "outlineStyle")
                   ,(sheet "default/print.css" "print" "slidePrint")
                   ,(sheet "default/opera.css" "projection" "operaFix")
                   "<!-- S5 JS -->"
                   ,(concat "<script src=\"" org-s5-ui-dir
                            "/default/slides.js\" "
                            "type=\"text/javascript\"></script>"))))
          (org-export-html-toplevel-hlevel 1)
          (org-export-html-postamble nil)
          (org-export-html-auto-postamble nil)
          (org-export-with-drawers (list "NOTES"))
          (org-export-format-drawer-function 'org-export-format-drawer-s5)
          (org-export-preprocess-hook
           (list
            (lambda ()
              (let ((class "slide"))
                (org-map-entries
                 (lambda ()
                   (save-excursion
                     (org-back-to-heading t)
                     (when (= (car (org-heading-components)) 1)
                       (put-text-property (point-at-bol) (point-at-eol)
                                          'html-container-class class)))))))))
          (org-export-html-final-hook
           (list
            (lambda ()
              (save-excursion
                (replace-regexp
                 (regexp-quote "<div id=\"content\">")
                 (let ((info `(("author" . ,author)
                               ("title"  . ,title)
                               ("date"   . ,(substring date 0 10)))))
                   (join `("<div class=\"layout\">"
                           "<div id=\"controls\"><!-- no edit --></div>"
                           "<div id=\"currentSlide\"><!-- no edit --></div>"
                           "<div id=\"header\"></div>"
                           "<div id=\"footer\">"
                           ,(org-fill-template org-s5-title-string-fmt info)
                           "</div>"
                           "</div>"
                           ""
                           "<div class=\"presentation\">"
                           ,(org-fill-template org-s5-title-page-fmt info)))))))
            (lambda ()
              (save-excursion
                (replace-regexp
                 (regexp-quote "<div id=\"table-of-contents\">")
                 "<div id=\"table-of-contents\" class=\"slide\">"))))))
      (org-export-as-html arg ext-plist to-buffer body-only pub-dir))))

(provide 'org-export-as-s5)
