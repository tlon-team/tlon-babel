;;; tlon-babel-core.el --- Core Babel functionality  -*- lexical-binding: t -*-

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

;; Core Babel functionality.

;;; Code:

(require 'paths)

;;;; Variables

(defconst tlon-babel-core-repos
  `((:name "babel-core"
	   :project "babel"
	   :subproject "babel"
	   :abbrev "babel-core"
	   :type meta
	   :key "b c")
    (:name "babel-refs"
	   :project "babel"
	   :subproject "babel"
	   :abbrev "babel-refs"
	   :type meta
	   :subtype biblio
	   :key "b r")
    (:name "babel-es"
	   :project "babel"
	   :subproject "babel"
	   :abbrev "babel-es"
	   :type meta
	   :language "es"
	   :key "b s")
    (:name "uqbar-issues"
	   :project "babel"
	   :subproject "uqbar"
	   :abbrev "uqbar-issues"
	   :type development
	   :subtype issues
	   :key "q i")
    (:name "uqbar-front"
	   :project "babel"
	   :subproject "uqbar"
	   :abbrev "uqbar-front"
	   :type development
	   :subtype front
	   :key "q f")
    (:name "uqbar-api"
	   :project "babel"
	   :subproject "uqbar"
	   :abbrev "uqbar-api"
	   :type development
	   :subtype api
	   :key "q a")
    (:name "uqbar-en"
	   :project "babel"
	   :subproject "uqbar"
	   :abbrev "uqbar-en"
	   :type content
	   :subtype originals
	   :language "en"
	   :key "q n")
    (:name "uqbar-es"
	   :project "babel"
	   :subproject "uqbar"
	   :abbrev "uqbar-es"
	   :type content
	   :subtype translations
	   :language "es"
	   :key "q s"
	   :url "https://altruismoeficaz.net/")
    (:name "utilitarianism-en"
	   :project "babel"
	   :subproject "utilitarianism"
	   :abbrev "utilitarianism-en"
	   :type content
	   :subtype originals
	   :key "u n")
    (:name "utilitarianism-es"
	   :project "babel"
	   :subproject "utilitarianism"
	   :abbrev "utilitarianism-es"
	   :type content
	   :subtype translations
	   :key "u s"
	   :url "https://utilitarismo.net/")
    (:name "essays-en"
	   :project "babel"
	   :subproject "essays"
	   :abbrev "essays-en"
	   :type content
	   :subtype originals
	   :key "l n")
    (:name "essays-es"
	   :project "babel"
	   :subproject "essays"
	   :abbrev "essays-es"
	   :type content
	   :subtype translations
	   :key "l s")
    (:name "ea.news-issues"
	   :project "other"
	   :subproject "ea.news"
	   :abbrev "ean-issues"
	   :type development
	   :subtype issues
	   :key "e i")
    (:name "ea.news-front"
	   :project "other"
	   :subproject "ea.news"
	   :abbrev "ean-front"
	   :type development
	   :subtype front
	   :key "f")
    (:name "ea.news-api"
	   :project "other"
	   :subproject "ea.news"
	   :abbrev "ean-api"
	   :type development
	   :subtype api
	   :key "a")
    (:name "bisagra"
	   :project "other"
	   :subproject "bisagra"
	   :abbrev "bisagra"
	   :type misc
	   :key "b")
    (:name "meetings-leo-pablo"
	   :abbrev "meetings-leo-pablo"
	   )
    (:name "meetings-fede-pablo"
	   :abbrev "meetings-fede-pablo")
    (:name "meetings-fede-leo"
	   :abbrev "meetings-fede-leo")
    (:name "tlon-docs"
	   :project "other"
	   :subproject "docs"
	   :abbrev "docs"
	   :type docs
	   :key "d"))
  "List of repos and associated properties.
The `:name' property is the full name of the repo, as it appears in the URL. The
`:abbrev' property is an abbreviated form of the name, used, for example, for
creating `org-mode' TODOs.")

;;;;; To sort

(defconst tlon-babel-core-labels
  '((:label "Awaiting processing"
	    :action "Process"
	    :assignee "worldsaround")
    (:label "Awaiting translation"
	    :action "Translate"
	    :assignee "")
    (:label "Awaiting revision"
	    :action "Revise"
	    :assignee "worldsaround")
    (:label "Awaiting check"
	    :action "Check"
	    :assignee "worldsaround")
    (:label "Awaiting review"
	    :action "Review"
	    :assignee "benthamite")
    (:label "Published"
	    :action "Publish"
	    :assignee ""))
  "List of labels and associated properties.")

(defvar tlon-babel-core-users
  '((:name "Pablo Stafforini"
	   :git "Pablo Stafforini"
	   :github "benthamite"
	   :substitute "worldsaround")
    (:name "Federico Stafforini"
	   :git "Federico Stafforini"
	   :github "fstafforini")
    (:name "Leonardo Picón"
	   :git "cartago"
	   :github "worldsaround"
	   :substitute "benthamite"))
  "Property list of users and associated properties.
The special property `:substitute' is used to determine which user should
perform a given phase of the translation process when the designated user is not
the actual user.")

(defvar tlon-babel-core-translation-language "es"
  "The current translation language.")

(defconst tlon-babel-core-bare-dirs
  '((("en" . "articles")
     ("es" . "articulos"))
    (("en" . "tags")
     ("es" . "temas"))
    (("en". "authors")
     ("es" . "autores"))
    (("en" . "collections")
     ("es" . "colecciones")))
  "Alist of bare directories and associated translations.")

(defconst tlon-babel-core-languages
  '(("en" . "english")
    ("es" . "spanish")
    ("it" . "italian")
    ("fr" . "french")
    ("de" . "german")
    ("pt" . "portuguese"))
  "Alist of languages and associated names.")

;;;; Functions

(defun tlon-babel-core-set-dir (repo)
  "Set the `:directory' property for REPO in `tlon-babel-core-repos'."
  (let* ((dir (file-name-as-directory
	       (file-name-concat paths-dir-tlon-repos
				 (plist-get repo :name)))))
    (plist-put repo :dir dir)))

(mapc #'tlon-babel-core-set-dir tlon-babel-core-repos)

;;;;; Ger repo

(defun tlon-babel-core-get-repo (&optional no-prompt include-all)
  "Get Babel repository path.
If the current directory matches any of the directories in
`tlon-babel-core-repos', return it. Else, prompt the user to select a repo from
that list, unless NO-PROMPT is non-nil. In that case, signal an error if its
value is `error', else return nil. If INCLUDE-ALL is non-nil, include all repos.
In that case, matching will be made against repos with any value for the
property `:type'."
  (if-let ((current-repo (tlon-babel-core-get-repo-from-file)))
      current-repo
    (if no-prompt
	(when (eq no-prompt 'error)
	  (user-error "Not in a recognized Babel repo"))
      (let* ((content (tlon-babel-core-repo-lookup-all :name :subtype 'translations))
	     (all (tlon-babel-core-repo-lookup-all :name)))
	(tlon-babel-core-repo-lookup :dir :name
				     (completing-read "Select repo: "
						      (if include-all all content)))))))

(defun tlon-babel-core-get-repo-from-file (&optional file)
  "Return the repo to which FILE belongs.
If FILE is nil, use the current buffer's file name."
  (let* ((file (or file (tlon-babel-core-buffer-file-name) default-directory))
	 (directory-path (file-name-directory file)))
    (catch 'found
      (dolist (dir (tlon-babel-core-repo-lookup-all :dir))
	(when (string-prefix-p (file-name-as-directory dir)
			       directory-path)
	  (throw 'found dir))))))

;;;;; Lookup

(defun tlon-babel-lookup (list key &rest pairs)
  "Return the value of KEY in LIST matching all PAIRS.
PAIRS is expected to be an even-sized list of <key value> tuples.
If multiple matches are found, return the first match."
  (cl-loop for entry in list
           when (cl-loop for (prop value) on pairs by #'cddr
                         always (equal (if (stringp key)
					   (alist-get prop entry nil nil 'string=)
                                         (plist-get entry prop))
				       value))
           return (if (stringp key)
		      (alist-get key entry nil nil 'string=)
		    (plist-get entry key))))

(defun tlon-babel-lookup-all (list key &rest pairs)
  "Return all unique values of KEY in LIST matching all PAIRS.
PAIRS is expected to be an even-sized list of <key value> tuples."
  (let ((results '()))
    (cl-loop for entry in list
             do (when (cl-loop for (prop value) on pairs by #'cddr
                               always (equal (if (stringp key)
                                                 (alist-get prop entry nil nil 'string=)
                                               (plist-get entry prop))
                                             value))
		  (when-let* ((result (if (stringp key)
					  (alist-get key entry nil nil 'string=)
					(plist-get entry key)))
			      (flat-result (if (listp result) result (list result))))
		    (dolist (r flat-result)
		      (push r results)))))
    (delete-dups (nreverse results))))

(defun tlon-babel-metadata-lookup (metadata key &rest key-value)
  "Return the value of KEY in METADATA matching all KEY-VALUE pairs."
  (apply #'tlon-babel-lookup metadata key key-value))

(defun tlon-babel-metadata-lookup-all (metadata key &rest key-value)
  "Return all unique values of KEY in METADATA matching alll KEY-VALUE pairs."
  (apply #'tlon-babel-lookup-all metadata key key-value))

(defun tlon-babel-core-repo-lookup (key &rest key-value)
  "Return the value of KEY in repos matching all KEY-VALUE pairs."
  (apply #'tlon-babel-lookup tlon-babel-core-repos key key-value))

(defun tlon-babel-core-repo-lookup-all (key &rest key-value)
  "Return all unique values of KEY in repos matching all KEY-VALUE pairs."
  (apply #'tlon-babel-lookup-all tlon-babel-core-repos key key-value))

(defun tlon-babel-core-user-lookup (key &rest key-value)
  "Return the value of KEY in users matching all KEY-VALUE pairs."
  (apply #'tlon-babel-lookup tlon-babel-core-users key key-value))

(defun tlon-babel-core-user-lookup-all (key &rest key-value)
  "Return all unique values of KEY in users matching all KEY-VALUE pairs."
  (apply #'tlon-babel-lookup-all tlon-babel-core-users key key-value))

(defun tlon-babel-core-label-lookup (key &rest key-value)
  "Return the value of KEY in labels matching all KEY-VALUE pairs."
  (apply #'tlon-babel-lookup tlon-babel-core-labels key key-value))

(defun tlon-babel-core-label-lookup-all (key &rest key-value)
  "Return all values of KEY in labels matching all KEY-VALUE pairs."
  (apply #'tlon-babel-lookup-all tlon-babel-core-labels key key-value))

(defun tlon-babel-core-buffer-file-name ()
  "Return name of file BUFFER is visiting, handling `git-dirs' path."
  ;; check that current buffer is visiting a file
  (when-let ((file (buffer-file-name)))
    (replace-regexp-in-string
     "/git-dirs/"
     "/Library/CloudStorage/Dropbox/repos/"
     (buffer-file-name))))

;;;;; Misc
;; this function will eventually be deleted once we migrate to a system of English-only directory names

(defun tlon-babel-core-get-bare-dir-translation (target-lang source-lang bare-dir)
  "For BARE-DIR in SOURCE-LANG, get its translation into TARGET-LANG."
  (let (result)
    (dolist (outer tlon-babel-core-bare-dirs result)
      (dolist (inner outer)
	(when (and (equal (cdr inner) bare-dir)
		   (equal (car inner) source-lang))
	  (setq result (cdr (assoc target-lang outer))))))))

(provide 'tlon-babel-core)
;;; tlon-babel-core.el ends here
