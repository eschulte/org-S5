(defvar org-s5-theme "default")

(defvar org-s5-title-format "<h1>%author - %title</h1>"
  "Format template to specify title.  Completed using `org-fill-template'.
Optional keys include %author, %title and %date.")

(defun org-export-as-s5
  (arg &optional hidden ext-plist to-buffer body-only pub-dir)
  "Wrap `org-export-as-html' in setting for S5 export."
  (interactive "P")
  (flet ((join (lst) (mapconcat #'identity lst "\n"))
         (sheet (href media id)
                (org-fill-template
                 (concat "<link rel=\"stylesheet\" href=\"%href\""
                         " type=\"text/css\" media=\"%media\" id=\"%id\" />")
                 `(("href" . ,href)
                   ("media" . ,media)
                   ("id" . ,id)))))
    (let ((org-export-html-style-extra
           (join `("<!-- configuration parameters -->"
                   "<meta name=\"defaultView\" content=\"slideshow\" />"
                   "<meta name=\"controlVis\" content=\"hidden\" />"
                   "<!-- style sheet links -->"
                   ,(sheet (concat "ui/" org-s5-theme "/slides.css")
                           "projection" "slideProj")
                   ,(sheet "ui/default/outline.css" "screen" "outlineStyle")
                   ,(sheet "ui/default/print.css" "print" "slidePrint")
                   ,(sheet "ui/default/opera.css" "projection" "operaFix")
                   "<!-- S5 JS -->"
                   ,(concat "<script src=\"ui/default/slides.js\" "
                            "type=\"text/javascript\"></script>"))))
          (org-export-html-toplevel-hlevel 1)
          (org-export-headline-levels 1)
          (org-export-preprocess-hook
           (list
            (lambda ()
              (let ((class "slide"))
                (org-map-entries
                 (lambda () (save-excursion
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
                 (join `("<div class=\"layout\">"
                         "<div id=\"controls\"><!-- no edit --></div>"
                         "<div id=\"currentSlide\"><!-- no edit --></div>"
                         "<div id=\"header\"></div>"
                         "<div id=\"footer\">"
                         ,(org-fill-template org-s5-title-format
                                             `(("author" . ,author)
                                               ("title"  . ,title)
                                               ("date"   . ,date)))
                         "</div>"
                         "</div>"
                         ""
                         "<div class=\"presentation\">")))))
            (lambda ()
              (save-excursion
                (replace-regexp
                 (regexp-quote "<div id=\"table-of-contents\">")
                 "<div id=\"table-of-contents\" class=\"slide\">"))))))
      (org-export-as-html arg hidden ext-plist to-buffer body-only pub-dir))))
