;; removing window noise
(tool-bar-mode -1)
(menu-bar-mode -1)
(toggle-scroll-bar -1)
(setq tab-bar-show nil)

;; stop cursor blinking
(blink-cursor-mode 0)

;; disable scratch message
(setq initial-scratch-message nil)

;; disable splash screen
(setq inhibit-startup-message t)


;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))


;; don't use tabs to indent. indent-tabs-mode is buffer local.
;; to set globally, we use setq-default
(setq-default indent-tabs-mode nil)


;; set font
(setq source-code-pro "Source Code Pro")
(setq noto-color-emoji "Noto Color Emoji")
(setq my-font-size 18)

(set-face-font
   'default
   (font-spec
    :family source-code-pro
    :size my-font-size
    :weight 'normal
    :width 'normal
    :slant 'normal))

(if (>= emacs-major-version 29)
  (set-face-font
     'mode-line-active
     (font-spec
      :family source-code-pro
      :size my-font-size
      :weight 'normal
      :width 'normal
      :slant 'normal))
  (message "no mode-line-active symbol on this version of emacs")
)


(set-fontset-font
   t 'symbol
   (font-spec
    :family noto-color-emoji
    :size my-font-size
    :weight 'normal
    :width 'normal
    :slant 'normal))

;; use ssh configuration from ~/.ssh/config
(customize-set-variable 'tramp-use-ssh-controlmaster-options nil)

;; load package.el
(require 'package)
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))
(package-initialize)



;; stop emacs from writing code into .emacs.el.
;; Instead write to .emacs-custom.el and load it if it exists
(setq custom-file "~/.emacs-custom.el")
(if (file-exists-p custom-file) (load custom-file) )


;; fetch the list of packages available if we haven't done so before
(or (file-exists-p package-user-dir) (package-refresh-contents))

;; list of packages to download from melpa
(setq package-list '( evil
                      evil-surround
                      solarized-theme
                      rainbow-delimiters
                      flycheck
                      company ;; completion boxes
                      undo-fu


                      haskell-mode
                      rust-mode
                      yaml-mode
                      lsp-mode
                      lsp-pyright ;; https://github.com/microsoft/pyright
                      nix-mode
                      markdown-mode
                      gdscript-mode
                    ))



;; install the missing melpa packages
(dolist (package package-list)
  (unless (package-installed-p package)
    (package-install package)))


;; enable solarized theme


(require 'solarized-palettes)

(defun my-dark-theme ()
  (load-theme 'solarized-dark t)

  ;; remove underline from mode-line and set color
  (setq mode-line-active-color
        (cdr (assq 'blue-2bg solarized-dark-color-palette-alist)))
  (setq mode-line-inactive-color
        (cdr (assq 'base02 solarized-dark-color-palette-alist)))

  (custom-set-faces
   `(mode-line
     ((t (:underline nil :overline nil :background ,mode-line-active-color))))
   `(mode-line-inactive
     ((t (:underline nil :overline nil :background ,mode-line-inactive-color)))))
)

(defun my-light-theme ()
  (load-theme 'solarized-light t)

  ;; remove underline from mode-line and set color
  (setq mode-line-active-color
        (cdr (assq 'green-2bg solarized-light-color-palette-alist)))
  (setq mode-line-inactive-color
        (cdr (assq 'base2 solarized-light-color-palette-alist)))

  (custom-set-faces
   `(mode-line
     ((t (:underline nil :overline nil :background ,mode-line-active-color))))
   `(mode-line-inactive
     ((t (:underline nil :overline nil :background ,mode-line-inactive-color)))))
)


(my-dark-theme)


;; enable rainbow-delimiters
(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;; enable hideshow mode
(add-hook 'prog-mode-hook 'hs-minor-mode)

;; highlight matching parens
(show-paren-mode 1)

;; auto reload files if they change on disk
(global-auto-revert-mode 1)


;; enable global whitespace mode
(global-whitespace-mode 1)
(setq-default whitespace-style '(face trailing))


;; use flex completion
(setq completion-styles '(flex))

;; enable Evil
(require 'evil)
(evil-mode 1)

;; enable evil motion state for completion list mode
(add-to-list 'evil-motion-state-modes 'completion-list-mode)

;; enable evil surround
(require 'evil-surround)
(global-evil-surround-mode 1)

;; evil configuration
(evil-set-leader 'normal (kbd "SPC"))
(evil-set-leader 'normal (kbd ",") t)
(evil-set-leader 'visual (kbd "SPC"))
(evil-set-leader 'visual (kbd ",") t)


;; once Emacs28 hits, will be able to use undo-redo which is built in
;; when that happens, remove unfo-fu from package installs
(evil-set-undo-system 'undo-fu)

;; setup recentf
(require 'recentf)
(recentf-mode 1)
(setq recentf-auto-cleanup 'never) ;; auto-cleanup messes with tramp
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)

(defun find-emacs-dotfile ()
  (interactive)
  (find-file "~/.emacs.el"))


;; make sure this is in your gitconfig
;; [alias]
;; root = rev-parse --show-toplevel

(defun project-grep (regex)
  (interactive "s")
  (let ((project-grep-buffer-name "*project grep*"))
    (when (get-buffer project-grep-buffer-name)
      (kill-buffer project-grep-buffer-name))
    (call-process-shell-command
     (concat "cd $(git root) && git grep "
             "--only-matching "
             "--fixed-strings "
             (concat "\"" regex "\""))
       nil (get-buffer-create project-grep-buffer-name))
    (pop-to-buffer project-grep-buffer-name)))

(defun project-grep-visual (start end)
  (interactive "r")
  (let ((regex (if (use-region-p) (buffer-substring start end))))
    (project-grep regex)
  ))

(defun toggle-camelcase-underscores ()
  "Toggle between camelcase and underscore notation for the symbol at point."
  (interactive)
  (save-excursion
    (let* ((bounds (bounds-of-thing-at-point 'symbol))
           (start (car bounds))
           (end (cdr bounds))
           (currently-using-underscores-p (progn (goto-char start)
                                                 (re-search-forward "_" end t))))
      (if currently-using-underscores-p
          (progn
            (upcase-initials-region start end)
            (replace-string "_" "" nil start end)
            (downcase-region start (1+ start)))
        (replace-regexp "\\([A-Z]\\)" "_\\1" nil (1+ start) end)
        (downcase-region start (cdr (bounds-of-thing-at-point 'symbol)))))))


;; general key bindings
(evil-define-key 'normal 'global

  (kbd "<leader>t") 'toggle-camelcase-underscores

  (kbd "<leader>!") 'shell-command

  (kbd "<leader>/") 'project-grep

  (kbd "<leader>ff") 'find-file
  (kbd "<leader>fs") 'save-buffer
  (kbd "<leader>fr") 'recentf-open-files
  (kbd "<leader>fed") 'find-emacs-dotfile

  (kbd "<leader>df") 'describe-function
  (kbd "<leader>dv") 'describe-variable
  (kbd "<leader>dk") 'describe-key

  (kbd "<leader>qq") 'save-buffers-kill-terminal

  (kbd "<leader>bb") 'buffer-menu

  (kbd "<leader>w/") 'split-window-horizontally
  (kbd "<leader>wd") 'delete-window
  (kbd "<leader>wD") 'kill-buffer-and-window
  (kbd "<leader>w-") 'split-window-vertically
  (kbd "<leader>wj") 'evil-window-down
  (kbd "<leader>wk") 'evil-window-up
  (kbd "<leader>wh") 'evil-window-left
  (kbd "<leader>wl") 'evil-window-right
  (kbd "<leader>wm") 'delete-other-windows
  (kbd "<leader>ws") 'window-swap-states

  (kbd "<leader>jl") 'goto-line

  (kbd "<leader>rp") 'insert-register

  (kbd "u") 'evil-undo
  (kbd "U") 'evil-redo
)



;; visual mode key bindings
(evil-define-key 'visual 'global

  (kbd "s") 'evil-surround-region
  (kbd "TAB") 'indent-rigidly
  (kbd "<leader>rc") 'copy-to-register
  (kbd "<leader>!") 'shell-command-on-region
  (kbd "<leader>/") 'project-grep-visual

  )

;; return should select a buffer in the buffer-menu
(evil-define-key 'motion Buffer-menu-mode-map
  (kbd "RET") 'Buffer-menu-this-window
  )

;; fill out motion map for completion lists
(evil-add-hjkl-bindings completion-list-mode-map 'motion
  (kbd "TAB") 'next-completion
  (kbd "RET") 'choose-completion
)

;; set keybindings for indent-rigidly. ?char gives the ascii code
(setq indent-rigidly-map
      '(keymap (?l . indent-rigidly-right) (?h . indent-rigidly-left)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; lisp interaction mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; lisp interaction mode key bindings

(evil-define-key 'normal lisp-interaction-mode-map

  (kbd "<localleader>ep") 'eval-print-last-sexp
  (kbd "<localleader>ee") 'eval-last-sexp

)

(evil-define-key 'visual lisp-interaction-mode-map

  (kbd "<localleader>e") 'eval-region

)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; c/c++ mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-hook 'c-mode-hook 'lsp)
(add-hook 'c++-mode-hook 'lsp)
(setq c-default-style "linux"
      c-basic-offset 4)
(setq lsp-clients-clangd-args
    '("--header-insertion=never"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; rust mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-hook 'rust-mode-hook 'lsp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; python mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-hook 'python-mode-hook 'lsp)
;; disable pyright type checking
(setq lsp-pyright-typechecking-mode "off")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; godot mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-hook 'gdscript-mode-hook 'lsp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; lsp mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; stop lsp-mode from looking for yasnippet
(setq lsp-enable-snippet nil)

;; remove the lsp headline
(setq lsp-headerline-breadcrumb-enable nil)

;; disable inline lsp buttons
(setq lsp-lens-enable nil)

;; When using lsp-mode most of the features depend on server capabilities.
;; lsp-mode provides default bindings which are dynamically enabled/disabled
;; based on the server functionality. all the commands are in lsp-command-map,
;; to which we bind localleader
(with-eval-after-load 'lsp-mode
  (evil-define-key '(normal visual) 'lsp-mode
    (kbd "<localleader>") lsp-command-map))


;; stop lsp-mode from auto formatting
(setq lsp-enable-on-type-formatting nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; haskell mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; setting up haskell mode
(require 'haskell-interactive-mode)
(require 'haskell-process)
(add-hook 'haskell-mode-hook 'interactive-haskell-mode)

;; Here is a list of available process types:
;;     ghci
;;     cabal-repl
;;     cabal-new-repl
;;     cabal-dev
;;     cabal-ghci
;;     stack-ghci
(setq haskell-process-type 'cabal-new-repl)
(setq haskell-interactive-popup-errors nil)



;; elisp function for generating list of seeds
;; (defun insert-numbers (start end)
;;   (interactive "nStart: \nnEnd: ")
;;   (dolist (ind (number-sequence start end))
;;     (insert (format "%d\n" ind))))
