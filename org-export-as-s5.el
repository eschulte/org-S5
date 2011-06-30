(defvar org-s5-theme "default")

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
          (org-export-html-postamble nil)
          (org-export-html-auto-postamble nil)
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
      (org-export-as-html arg hidden ext-plist to-buffer body-only pub-dir))))
