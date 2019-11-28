;;; .doom.d/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here
(add-hook 'rust-mode-hook
          (lambda () (setq indent-tabs-mode nil)))
(setq rust-format-on-save t)
(add-hook 'foo-mode-hook 'eglot-ensure)
(add-hook 'rust-mode-hook 'cargo-minor-mode)
(setq rustic-lsp-client 'eglot)
