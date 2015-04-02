;;; smart-region.el --- Select region, rectangle, multi cursol in smart way.

;;-------------------------------------------------------------------
;;
;; Copyright (C) 2015 Yuuki Arisawa
;;
;; This file is NOT part of Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA
;;
;;-------------------------------------------------------------------

;; Author: Yuuki Arisawa <yuuki.ari@gmail.com>
;; URL: https://github.com/uk-ar/smart-region
;; Package-Requires: ((expand-region "20141223")(region-bindings-mode "20140407.1514")(multiple-cursors "20150307.2322"))
;; Created: 1 April 2015
;; Version: 1.0
;; Keywords: region

;;; Commentary:
;; ########   Compatibility   ########################################

(require 'expand-region)
(require 'region-bindings-mode)
(require 'multiple-cursors)

(defun er/mark-outside-quotes ()
  "Mark the current string, including the quotation marks. It will returns t if region expanded."
  (interactive)
  (let ((before (cons (mark) (point))))
    (if (er--point-inside-string-p)
        (er--move-point-backward-out-of-string)
      (when (and (not (use-region-p))
                 (er/looking-back-on-line "\\s\""))
        (backward-char)
        (er--move-point-backward-out-of-string)))
    (when (looking-at "\\s\"")
      (set-mark (point))
      (forward-char)
      (er--move-point-forward-out-of-string)
      (exchange-point-and-mark))
    (message "%S,%S" before (cons (mark) (point)))
    (not (equal (cons (mark) (point)) before))
    ))

(defun er/mark-outside-pairs ()
  "Mark pairs (as defined by the mode), including the pair chars."
  (interactive)
  (let ((before (cons (mark) (point))))
    (if (er/looking-back-on-line "\\s)+\\=")
        (ignore-errors (backward-list 1))
      (skip-chars-forward er--space-str))
    (when (and (er--point-inside-pairs-p)
               (or (not (er--looking-at-pair))
                   (er--looking-at-marked-pair)))
      (goto-char (nth 1 (syntax-ppss))))
    (when (er--looking-at-pair)
      (set-mark (point))
      (forward-list)
      (exchange-point-and-mark))
    (not (equal (cons (mark) (point)) before))
    ))

;;TODO: u c-SPC for pop mark
(defun smart-region ()
  (interactive)
  (if (or (eq last-command 'set-mark-command)
          (eq last-command 'smart-region)
          (eq last-command 'er/expand-region)
          )
      (cl-case (char-syntax (char-after))
        (?\"
         (unless (er/mark-outside-quotes)
           (call-interactively 'er/expand-region)))
        (?\)
         (unless (er/mark-outside-pairs)
           (call-interactively 'er/expand-region)))
        (?\(
         (unless
             ;; mark-paris.feature
             ;; er/mark-outside-pairs has bug (((a) (b))) (((a)(b)))
             (er/mark-outside-pairs)
           (call-interactively 'er/expand-region)))
        (t (call-interactively 'er/expand-region)))
            ;;(setq this-command 'er/expand-region)
            ;;https://github.com/magnars/expand-region.el/issues/31
    ;;multi line
    (let ((column-of-mark
           (save-excursion
             (goto-char (mark))
             (current-column))))
      (if (eq column-of-mark (current-column))
          (call-interactively 'mc/edit-lines)
        (call-interactively 'rectangle-mark-mode)
        ))))

(define-key region-bindings-mode-map (kbd "C-SPC") 'smart-region)

(provide 'smart-region)
;;; smart-region.el ends here
