;;; .doom.d/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here

;; Rust lang
(add-hook 'rust-mode-hook
          (lambda () (setq indent-tabs-mode nil)))
(setq rust-format-on-save t)
(add-hook 'foo-mode-hook 'eglot-ensure)
(add-hook 'rust-mode-hook 'cargo-minor-mode)
(setq rustic-lsp-client 'eglot)



;; Javascript
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
                                        ; Better imenu
(add-hook 'js2-mode-hook #'js2-imenu-extras-mode)
(add-hook 'js2-mode-hook #'js2-refactor-mode)
(js2r-add-keybindings-with-prefix "C-c C-r")
(define-key js2-mode-map (kbd "C-k") #'js2r-kill)
                                        ; js-mode (which js2 is based on) binds "M-." which conflicts with xref, so
                                        ; unbind it.
(define-key js-mode-map (kbd "M-.") nil)
(add-hook 'js2-mode-hook (lambda ()
                           (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))
(add-to-list 'company-backends 'company-tern)
(add-hook 'js2-mode-hook (lambda ()
                           (tern-mode)
                           (company-mode)))
                                        ; Disable completion keybindings, as we use xref-js2 instead
;(define-key tern-mode-keymap (kbd "M-.") nil)
;(define-key tern-mode-keymap (kbd "M-,") nil)
(add-hook 'js2-mode-hook 'ac-js2-mode)
(setq js2-highlight-level 4)
(defun delete-tern-process ()
  (interactive)
  (delete-process "Tern"))

(eval-after-load 'js2-mode
  '(define-key js2-mode-map (kbd "C-c b") 'web-beautify-js))
;; Or if you're using 'js-mode' (a.k.a 'javascript-mode')
(eval-after-load 'js
  '(define-key js-mode-map (kbd "C-c b") 'web-beautify-js))

(eval-after-load 'json-mode
  '(define-key json-mode-map (kbd "C-c b") 'web-beautify-js))

(eval-after-load 'sgml-mode
  '(define-key html-mode-map (kbd "C-c b") 'web-beautify-html))

(eval-after-load 'web-mode
  '(define-key web-mode-map (kbd "C-c b") 'web-beautify-html))

(eval-after-load 'css-mode
  '(define-key css-mode-map (kbd "C-c b") 'web-beautify-css))

;; Auto Complete
;(require 'yasnippet)
(yas-global-mode 1)
;(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
(ac-config-default)
(ac-set-trigger-key "TAB")
(ac-set-trigger-key "<tab>")

;; Smart Tab
(smart-tabs-insinuate 'c 'javascript 'php 'python 'rust 'cpp)

;; Php
; Wordpress
(defun drupal-mode ()
  "Drupal php-mode."
  (interactive)
  (php-mode)
  (message "Drupal mode activated.")
  (set 'tab-width 4)
  (set 'c-basic-offset 2)
  (set 'indent-tabs-mode nil)
  (c-set-offset 'case-label '+)
  (c-set-offset 'arglist-intro '+) ; for FAPI arrays and DBTNG
  (c-set-offset 'arglist-cont-nonempty 'c-lineup-math) ; for DBTNG fields and values
  ; More Drupal-specific customizations here
)

(defun setup-php-drupal ()
  ; Drupal
  (add-to-list 'auto-mode-alist '("\\.\\(module\\|test\\|install\\|theme\\)$" . drupal-mode))
  (add-to-list 'auto-mode-alist '("/drupal.*\\.\\(php\\|inc\\)$" . drupal-mode))
  (add-to-list 'auto-mode-alist '("\\.info" . conf-windows-mode))
)

(setup-php-drupal)
