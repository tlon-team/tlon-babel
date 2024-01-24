;;; tlon-babel-dispatch.el --- Transient dispatchers -*- lexical-binding: t -*-

;; Copyright (C) 2024

;; Author: Pablo Stafforini
;; Homepage: https://github.com/tlon-team/tlon-babel
;; Version: 0.1

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;  Transient dispatchers.

;;; Code:

(require 'tlon-babel-core)

;;;; Functions

;; TODO: add flag to set translation language, similar to Magit dispatch
(transient-define-prefix tlon-babel-dispatch ()
  "Dispatch a `tlon-babel' command."
  [["Main"
    ("j" "job"                            tlon-babel-jobs-create-job)
    ("r" "dwim"                           tlon-babel-jobs-dwim)
    ("m" "Magit"                          tlon-babel-magit-repo-dispatch)
    ("." "gh-notify"                      gh-notify)
    """Request"
    ("q q" "uqbar"                        tlon-babel-api-request)
    ]
   ["Add or modify"
    ("a a" "glossary"                     tlon-babel-glossary-dwim)
    ("a s" "section corresp"              tlon-babel-section-correspondence-dwim)
    ("a u" "URL corresp"                  tlon-babel-url-correspondence-dwim)
    """Search"
    ("s s" "multi"                        tlon-babel-search-multi)
    ("s c" "commits"                      tlon-babel-search-commits)
    ("s d" "commit-diffs"                 tlon-babel-search-commit-diffs)
    ("s f" "files"                        tlon-babel-search-files)
    ("s i" "issues"                       tlon-babel-search-issues)
    ("s t" "translation"                  tlon-babel-search-for-translation)
    ]
   ["Browse in Dired"
    ("d" "dir"                            tlon-babel-dired-dir-dispatch)
    ("H-d" "repo"                         tlon-babel-dired-repo-dispatch)
    ""
    """Browse externally"
    ("b" "current file"                   tlon-babel-browse-file)
    ("H-b" "current repo"                 tlon-babel-browse-repo)
    """Open"
    ("o" "in repo"                        tlon-babel-open-repo-dispatch)
    ("H-o" "in all repos"                 tlon-babel-open-file-in-all-repos)
    ]
   [
    "File changes"
    ("h h" "log"                          magit-log-buffer-file)
    ("h d" "diffs since last user change" tlon-babel-log-buffer-latest-user-commit)
    ("h e" "ediff with last user change"  tlon-babel-log-buffer-latest-user-commit-ediff)
    """Counterpart"
    ("f" "current win"                    tlon-babel-open-counterpart-dwim)
    ("H-f" "other win"                    tlon-babel-open-counterpart-other-window-dwim)
    """AI"
    ("g r" "rewrite"                      tlon-babel-ai-rewrite)
    ("g s" "summarize"                    tlon-babel-ai-summarize)
    ("g t" "translate"                    tlon-babel-ai-translate)]
   ["Clock"
    ("c c" "issue"                        tlon-babel-open-clock-issue)
    ("c f" "file"                         tlon-babel-open-clock-file )
    ("c o" "heading"                      org-clock-goto)
    """Issue"
    ("i i" "open counterpart"             tlon-babel-ogh-open-forge-counterpart)
    ("i I" "open file"                    tlon-babel-ogh-open-forge-file)
    ]
   ["Sync"
    ("y y" "visit or capture"             tlon-babel-ogh-visit-counterpart-or-capture)
    ("y v" "visit"                        tlon-babel-ogh-visit-counterpart)
    ("y p" "post"                         tlon-babel-ogh-create-issue-from-todo)
    ("y c" "capture"                      tlon-babel-ogh-capture-issue)
    ("y C" "capture all"                  tlon-babel-ogh-capture-all-issues)
    ("y r" "reconcile"                    tlon-babel-ogh-reconcile-issue-and-todo)
    ("y R" "reconcile all"                tlon-babel-ogh-reconcile-all-issues-and-todos)
    ("y x" "close"                        tlon-babel-ogh-close-issue-and-todo)]
   ]
  )

(transient-define-prefix tlon-babel-magit-repo-dispatch ()
  "Browse a Tlön repo in Magit."
  [["Babel"
    ("b c" "babel-core"                       tlon-babel-magit-browse-babel-core)
    ("b r" "babel-refs"                       tlon-babel-magit-browse-babel-refs)
    ("b s" "babel-es"                         tlon-babel-magit-browse-babel-es)
    ]
   ["Uqbar"
    ("q i" "uqbar-issues"                     tlon-babel-magit-browse-uqbar-issues)
    ("q f" "uqbar-front"                      tlon-babel-magit-browse-uqbar-front)
    ("q a" "uqbar-api"                        tlon-babel-magit-browse-uqbar-api)
    ("q n" "uqbar-en"                         tlon-babel-magit-browse-uqbar-en)
    ("q s" "uqbar-es"                         tlon-babel-magit-browse-uqbar-es)
    ]
   ["Utilitarismo"
    ("u n" "utilitarismo-en"                     tlon-babel-magit-browse-utilitarismo-en)
    ("u s" "utilitarismo-es"                     tlon-babel-magit-browse-utilitarismo-es)
    ]
   ["Ensayos sobre largoplacismo"
    ("e n" "ensayos-en"                     tlon-babel-magit-browse-ensayos-en)
    ("e s" "ensayos-es"                     tlon-babel-magit-browse-ensayos-es)
    ]
   ["EA News"
    ("n i" "ean-issues"                     tlon-babel-magit-browse-ean-issues)
    ("n f" "ean-front"                     tlon-babel-magit-browse-ean-front)
    ("n a" "ean-api"                     tlon-babel-magit-browse-ean-api)
    ]
   ["La Bisagra"
    ("s s" "bisagra"                     tlon-babel-magit-browse-bisagra)
    ]
   ["Docs"
    ("d d" "tlon-docs"                     tlon-babel-magit-browse-docs)
    ]
   ]
  )

(transient-define-prefix tlon-babel-open-repo-dispatch ()
  "Interactively open a file from a Tlön repo."
  [["Babel"
    ("b c" "babel-core"                       tlon-babel-open-file-in-babel-core)
    ("b r" "babel-refs"                       tlon-babel-open-file-in-babel-refs)
    ("b s" "babel-es"                         tlon-babel-open-file-in-babel-es)
    ]
   ["Uqbar"
    ("q i" "uqbar-issues"                     tlon-babel-open-file-in-uqbar-issues)
    ("q f" "uqbar-front"                      tlon-babel-open-file-in-uqbar-front)
    ("q a" "uqbar-api"                        tlon-babel-open-file-in-uqbar-api)
    ("q n" "uqbar-en"                         tlon-babel-open-file-in-uqbar-en)
    ("q s" "uqbar-es"                         tlon-babel-open-file-in-uqbar-es)
    ]
   ["Utilitarismo"
    ("u n" "utilitarismo-en"                     tlon-babel-open-file-in-utilitarismo-en)
    ("u s" "utilitarismo-es"                     tlon-babel-open-file-in-utilitarismo-es)
    ]
   ["Ensayos sobre largoplacismo"
    ("e n" "ensayos-en"                     tlon-babel-open-file-in-ensayos-en)
    ("e s" "ensayos-es"                     tlon-babel-open-file-in-ensayos-es)
    ]
   ["EA News"
    ("n i" "ean-issues"                     tlon-babel-open-file-in-ean-issues)
    ("n f" "ean-front"                     tlon-babel-open-file-in-ean-front)
    ("n a" "ean-api"                     tlon-babel-open-file-in-ean-api)
    ]
   ["La Bisagra"
    ("s s" "bisagra"                     tlon-babel-open-file-in-bisagra)
    ]
   ["Docs"
    ("d d" "tlon-docs"                     tlon-babel-open-file-in-docs)
    ]
   ]
  )

(transient-define-prefix tlon-babel-dired-repo-dispatch ()
  "Browse a Tlön repo in Dired."
  [["Babel"
    ("b c" "babel-core"                       tlon-babel-dired-browse-babel-core)
    ("b r" "babel-refs"                       tlon-babel-dired-browse-babel-refs)
    ("b s" "babel-es"                         tlon-babel-dired-browse-babel-es)
    ]
   ["Uqbar"
    ("q i" "uqbar-issues"                     tlon-babel-dired-browse-uqbar-issues)
    ("q f" "uqbar-front"                      tlon-babel-dired-browse-uqbar-front)
    ("q a" "uqbar-api"                        tlon-babel-dired-browse-uqbar-api)
    ("q n" "uqbar-en"                         tlon-babel-dired-browse-uqbar-en)
    ("q s" "uqbar-es"                         tlon-babel-dired-browse-uqbar-es)
    ]
   ["Utilitarismo"
    ("u n" "utilitarismo-en"                     tlon-babel-dired-browse-utilitarismo-en)
    ("u s" "utilitarismo-es"                     tlon-babel-dired-browse-utilitarismo-es)
    ]
   ["Ensayos sobre largoplacismo"
    ("e n" "ensayos-en"                     tlon-babel-dired-browse-ensayos-en)
    ("e s" "ensayos-es"                     tlon-babel-dired-browse-ensayos-es)
    ]
   ["EA News"
    ("n i" "ean-issues"                     tlon-babel-dired-browse-ean-issues)
    ("n f" "ean-front"                     tlon-babel-dired-browse-ean-front)
    ("n a" "ean-api"                     tlon-babel-dired-browse-ean-api)
    ]
   ["La Bisagra"
    ("s s" "bisagra"                     tlon-babel-dired-browse-bisagra)
    ]
   ["Docs"
    ("d d" "tlon-docs"                     tlon-babel-dired-browse-docs)
    ]
   ]
  )

(transient-define-prefix tlon-babel-dired-dir-dispatch ()
  "Browse a Tlön repo directory in Dired."
  [
   ;; ["Babel"
   ;; ("b c" "babel-core"                       tlon-babel-dired-babel-core)
   ;; ("b r" "babel-refs"                       tlon-babel-dired-babel-refs)
   ;; ("b s" "babel-es"                         tlon-babel-dired-babel-es)
   ;; ]
   ["Uqbar"
    ;; ("q i" "uqbar-issues"                     )
    ;; ("q f" "uqbar-front"                      )
    ;; ("q a" "uqbar-api"                        )
    ("q n" "uqbar-en"                         tlon-babel-browse-entity-in-uqbar-en-dispatch)
    ("q s" "uqbar-es"                         tlon-babel-browse-entity-in-uqbar-es-dispatch)
    ]
   ["Utilitarismo"
    ("u n" "utilitarismo-en"                     tlon-babel-browse-entity-in-utilitarismo-en-dispatch)
    ("u s" "utilitarismo-es"                     tlon-babel-browse-entity-in-utilitarismo-es-dispatch)
    ]
   ["Ensayos sobre largoplacismo"
    ("e n" "ensayos-en"                     tlon-babel-browse-entity-in-ensayos-en-dispatch)
    ("e s" "ensayos-es"                     tlon-babel-browse-entity-in-ensayos-es-dispatch)
    ]
   ;; ["EA News"
   ;; ("n i" "ean-issues"                     )
   ;; ("n f" "ean-front"                     )
   ;; ("n a" "ean-api"                     )
   ;; ]
   ;; ["La Bisagra"
   ;; ("s s" "bisagra"                     )
   ;; ]
   ;; ["Docs"
   ;; ("d d" "tlon-docs"                     )
   ;; ]
   ]
  )

(defmacro tlon-babel-generate-entity-dispatch (name)
  "Generate a dispatcher for browsing an entity named NAME in a repo."
  `(transient-define-prefix ,(intern (format "tlon-babel-browse-entity-in-%s-dispatch" name)) ()
     ,(format "Browse a directory in the `%s' repo." name)
     [["directories"
       ("a" "articles"         ,(intern (format "tlon-babel-dired-browse-articles-dir-in-%s" name)))
       ("t" "tags"             ,(intern (format "tlon-babel-dired-browse-tags-dir-in-%s" name)))
       ("u" "authors"          ,(intern (format "tlon-babel-dired-browse-authors-dir-in-%s" name)))
       ("c" "collections"      ,(intern (format "tlon-babel-dired-browse-collections-dir-in-%s" name)))
       ;; ("i" "images"           ,(intern (format "tlon-babel-dired-browse-images-dir-in-%s" name)))
       ]]
     ))

(dolist (repo (tlon-babel-core-repo-lookup-all :abbrev :type 'content))
  (eval `(tlon-babel-generate-entity-dispatch ,repo)))

(provide 'tlon-babel-dispatch)
;;; tlon-babel-dispatch.el ends here
