;;; org-lang.el --- a simple package to automate language detection in org-mode                     -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Dominik Keller

;; Author: Dominik Keller <user@user.com>
;; Keywords: org-mode
;; Version: 0.0.1

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

;; This package automates the process of detecting the currently used
;; language and adjusting `ispell-change-dictionary'

;;; Code:

(require 'fuzzy)

(defgroup org-lang nil
  "Simplify multilingual workflow for org-mode"
  :prefix "org-lang-"
  :group 'org-lang)

(defcustom org-lang-fallback-lang ""
  "Set the default fallback language."
  :type 'string
  :group 'org-lang)

(defcustom org-lang-installed-langs '()
  "List with all installed languages."
  :type 'list
  :group 'org-lang)

(defcustom org-lang-prefered-completion 'default
  "Symbol with prefered completion framework"
  :type 'symbol
  :options '('default 'helm 'ivy)
  :group 'org-lang)

(defcustom org-lang-check-after-enable nil
  "Check buffer for spelling mistakes after enabling."
  :type 'boolean
  :group 'org-lang)

(define-minor-mode org-lang-mode
  "Autmatic and easy switching of languages"
  :global nil
  :keymap '(([?\C-c ?l] . org-lang-selector))
  :lighter " org-lang")

(when (equal snipsearch-comp-interface 'helm)
  (require 'helm))

(when (equal snipsearch-comp-interface 'ivy)
  (require 'ivy))

(defun org-lang-get-buffer-lang ()
  "Search the current org-mode buffer for a usable language."
  (interactive)
  (let ((org-lang-str-pos 0)
	(org-lang-lang "")
	(org-lang-FM-candidates '()))
    (save-excursion
      (goto-char 1)
      (setq org-lang-str-pos (search-forward "#+LANGUAGE: " nil t))
      (if (not (equal org-lang-str-pos 0))
	  (progn (setq org-lang-lang (thing-at-point 'symbol))
		 (setq org-lang-FM-candidates
		       (fuzzy-all-completions org-lang-lang org-lang-installed-langs))
		 (if (not (equal org-lang-FM-candidates '()))
		     (progn (ispell-change-dictionary (nth 0 org-lang-FM-candidates))
			    (message "Language detected. Changing to %s"
				     (nth 0 org-lang-FM-candidates)))
		   (progn (ispell-change-dictionary org-lang-fallback-lang)
			  (message "Couldn't detect any language. Using fallback option."))))
	(progn (message "Couldn't detect any language. Using fallback option.")
	       (ispell-change-dictionary org-lang-fallback-lang))))))

(defun org-lang-selector ()
  "Interacitvely select a language with an interactive menu"
  (interactive)
  (let ((org-lang-user-result ""))
    (cond ((equal org-lang-prefered-completion 'default)
	   (progn (setq org-lang-user-result
			(read-string
			 (concat "["
				 (mapconcat 'identity
					    org-lang-installed-langs
					    "], [")
				 "]: ")))
		  (if (member org-lang-user-result org-lang-installed-langs)
		      (progn (ispell-change-dictionary org-lang-user-result)
			     (when org-lang-check-after-enable
			       (flyspell-buffer)))
		    (message "Requested language not listed as installed."))))
	  ((equal org-lang-prefered-completion 'ivy)
	   ;; Docs: https://oremacs.com/swiper/#required-arguments-for-ivy-read"
	   (progn (ivy-read "Select Language: "
			    org-lang-installed-langs
			    :preselect (ivy-thing-at-point)
			    :require-match t
			    :action (lambda (selected)
				      (ispell-change-dictionary selected)))
		  (when org-lang-check-after-enable
		    (flyspell-buffer))))
	  ((equal org-lang-prefered-completion 'helm)
	   (ispell-change-dictionary
	    (helm :sources (helm-build-sync-source "org-lang"
			     :candidates org-lang-installed-langs
			     :fuzzy-match t)
		  :buffer "*org-lang*")))
	  (t
	   (message "%s is not implemented"
		    (symbol-name org-lang-prefered-completion))))))

(provide 'org-lang)
;;; org-lang.el ends here
