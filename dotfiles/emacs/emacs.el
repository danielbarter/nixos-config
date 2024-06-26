
;; disable scratch message
(setq initial-scratch-message nil)

;; disable splash screen
(setq inhibit-startup-message t)

;; show column numbers
(setq column-number-mode t)

;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))


;; don't use tabs to indent. indent-tabs-mode is buffer local.
;; to set globally, we use setq-default
(setq-default indent-tabs-mode nil)
(setq tab-bar-show nil)

;; removing window noise
(blink-cursor-mode 0)
(menu-bar-mode -1)

;; if we are running a graphical emacs session
;; remove additional window noise + set fonts
(if (display-graphic-p)
    (progn
      (message "running in gui mode")
      (toggle-scroll-bar -1)
      (tool-bar-mode -1)

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

      (set-face-font
         'mode-line-active
         (font-spec
          :family source-code-pro
          :size my-font-size
          :weight 'normal
          :width 'normal
          :slant 'normal))

      (set-fontset-font
         t 'symbol
         (font-spec
          :family noto-color-emoji
          :size my-font-size
          :weight 'normal
          :width 'normal
          :slant 'normal)))

    (message "running in ncurses mode"))


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
                      dracula-theme
                      rainbow-delimiters
                      eglot
                      company ;; completion boxes
                      tree-sitter
                      tree-sitter-langs
                      direnv

                      ;; language modes
                      nix-mode
                      markdown-mode
                    ))


;; cmake mode is bundled with the cmake system package
(require 'cmake-mode nil `noerror)


;; install the missing melpa packages
(dolist (package package-list)
  (unless (package-installed-p package)
    (package-install package)))

(load-theme 'dracula t)

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

;; enable evil surround
(require 'evil-surround)
(global-evil-surround-mode 1)

;; evil configuration
(evil-set-leader 'normal (kbd "SPC"))
(evil-set-leader 'normal (kbd ",") t)
(evil-set-leader 'visual (kbd "SPC"))
(evil-set-leader 'visual (kbd ",") t)


(evil-set-undo-system 'undo-redo)

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
  (interactive "sRegex: ")
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

(with-eval-after-load 'eglot
  ;; stop eglot from redefining mouse-2
  (keymap-unset eglot-diagnostics-map "<mouse-2>" t)
)

;; hook company mode to eglot mode
(add-hook 'eglot-managed-mode-hook 'company-mode)

(defun ide-mode ()
  "start eglot mode"
  (interactive)
  (call-interactively 'eglot))


;; general key bindings
(evil-define-key 'normal 'global
  (kbd "<leader>ide") 'ide-mode
  (kbd "<leader>egi") 'eglot-inlay-hints-mode
  (kbd "<leader>env") 'direnv-update-environment

  (kbd "<leader>tc") 'toggle-camelcase-underscores

  (kbd "<leader>!") 'async-shell-command

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
  (kbd "<leader>jd") 'xref-find-definitions
  (kbd "<leader>jr") 'xref-find-references
  (kbd "<leader>jh") 'eldoc-doc-buffer
  (kbd "<leader>je") 'flymake-goto-next-error
  (kbd "<leader>jE") 'flymake-goto-prev-error


  (kbd "<leader>rp") 'insert-register

  (kbd "u") 'evil-undo
  (kbd "U") 'evil-redo

  (kbd "<leader>ms") 'kmacro-start-macro
  (kbd "<leader>me") 'kmacro-end-or-call-macro
)

;; we use C-SPC as the prefix key for tmux. previously bound to
;; set-mark-command
(define-key global-map (kbd "C-SPC") nil)

;; stop evil from aliasing C-n and C-p for company in insert mode
(with-eval-after-load 'evil
  (with-eval-after-load 'company
    (define-key evil-insert-state-map (kbd "C-n") nil)
    (define-key evil-insert-state-map (kbd "C-p") nil)
    (evil-define-key nil company-active-map (kbd "C-n") 'company-select-next)
    (evil-define-key nil company-active-map (kbd "C-p") 'company-select-previous)))

;; visual mode key bindings
(evil-define-key 'visual 'global

  (kbd "s") 'evil-surround-region
  (kbd "TAB") 'indent-rigidly
  (kbd "<leader>rc") 'copy-to-register
  (kbd "<leader>!") 'shell-command-on-region
  (kbd "<leader>/") 'project-grep-visual

  )

;; return should select a buffer in the buffer-menu
(add-to-list 'evil-motion-state-modes 'Buffer-menu-mode-map)
(evil-define-key 'motion Buffer-menu-mode-map
  (kbd "RET") 'Buffer-menu-this-window)

;; return to jump from xref buffer
(add-to-list 'evil-motion-state-modes 'xref--xref-buffer-mode)
(evil-define-key 'motion xref--xref-buffer-mode-map
  (kbd "RET") 'xref-quit-and-goto-xref)

;; fill out motion map for completion lists
(add-to-list 'evil-motion-state-modes 'completion-list-mode)
(evil-add-hjkl-bindings completion-list-mode-map 'motion
  (kbd "TAB") 'next-completion
  (kbd "RET") 'choose-completion)

;; set keybindings for indent-rigidly. ?char gives the ascii code
(setq indent-rigidly-map
      '(keymap (?l . indent-rigidly-right) (?h . indent-rigidly-left)))


;; mini buffer keybindings
(define-key minibuffer-local-map (kbd "C-p") 'previous-history-element)
(define-key minibuffer-local-map (kbd "C-n") 'next-history-element)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; lisp interaction mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; lisp interaction mode key bindings

(evil-define-key 'normal lisp-interaction-mode-map

  (kbd "<localleader>ep") 'eval-print-last-sexp
  (kbd "<localleader>ee") 'eval-last-sexp

)

(evil-define-key 'visual lisp-interaction-mode-map

  (kbd "<localleader>e") 'eval-region

)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tree sitter mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; enable tree sitter mode for all supported langs
(global-tree-sitter-mode)

;; use tree-sitter-highligting when possible
(add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; C/C++ mode config ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq-default c-basic-offset 4)

;;;;;;;;;;;;;;;;;;;;;;;;;;;; misc functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun insert-numbers (start end)
  (interactive "nStart: \nnEnd: ")
  (dolist (ind (number-sequence start end))
    (insert (format "%d\n" ind))))


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
