(defvar org-s5-theme "default") ;; based off of the color-theme

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
                         (put-text-property (point-at-bol) (point-at-eol)
                                            'html-container-class class))))))))
          (org-export-html-final-hook
           (list
            (lambda ()
              (save-excursion
                (replace-regexp
                 (regexp-quote "<div id=\"content\">")
                 (mapconcat #'identity
                            `("<div class=\"layout\">"
                              "<div id=\"controls\"><!-- no edit --></div>"
                              "<div id=\"currentSlide\"><!-- no edit --></div>"
                              "<div id=\"header\"></div>"
                              "<div id=\"footer\">"
                              ,(format "<h1>%s</h1>" title)
                              "</div>"
                              "</div>"
                              ""
                              "<div class=\"presentation\">") "\n"))))
            (lambda ()
              (save-excursion
                (replace-regexp
                 (regexp-quote "<div id=\"table-of-contents\">")
                 "<div id=\"table-of-contents\" class=\"slide\">"))))))
      (org-export-as-html arg hidden ext-plist to-buffer body-only pub-dir))))
