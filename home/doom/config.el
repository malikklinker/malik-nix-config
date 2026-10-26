;;; config.el --- Malik's Doom desktop -*- lexical-binding: t; -*-

(setq user-full-name "Malik"
      doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 13)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font" :size 20)
      doom-variable-pitch-font (font-spec :family "DejaVu Sans" :size 14)
      doom-theme 'desktop
      display-line-numbers-type 'relative
      org-directory "~/org/"
      frame-title-format '("%b — Doom")
      scroll-margin 5
      hscroll-margin 4
      scroll-conservatively 101)

(add-to-list 'custom-theme-load-path (expand-file-name "themes/" doom-user-dir))
(setq-default line-spacing 0.18
              left-margin-width 1
              right-margin-width 1)
(add-to-list 'default-frame-alist '(internal-border-width . 14))
(add-to-list 'initial-frame-alist '(background-color . "#090c14"))

(after! doom-modeline
  (setq doom-modeline-height 30
        doom-modeline-bar-width 3
        doom-modeline-buffer-file-name-style 'relative-from-project
        doom-modeline-major-mode-icon t
        doom-modeline-buffer-encoding 'nondefault
        doom-modeline-minor-modes nil
        doom-modeline-persp-name t))

(after! corfu
  (setq corfu-auto-delay 0.15
        corfu-count 10
        corfu-max-width 70))

(after! which-key
  (setq which-key-idle-delay 0.4))

(after! org
  (setq org-hide-emphasis-markers t
        org-startup-indented t
        org-ellipsis " ▾"
        org-pretty-entities t))

(defun malik/dashboard-banner ()
  "Return a compact, centered constellation for the start screen."
  (concat
   (propertize (concat "         ✦                 ·\n"
                       "    ·         .       ✧\n"
                       "         .        ·\n\n")
               'face 'font-lock-comment-face)
   (propertize "Z E P H Y R U S\n" 'face '+dashboard-banner)
   (propertize "a quiet place to think\n" 'face 'font-lock-doc-face)))

(setq fancy-splash-image nil
      +dashboard-ascii-banner-fn #'malik/dashboard-banner
      +dashboard-banner-vertical-padding '(1 . 2)
      +dashboard-functions '(+dashboard-widget-banner
                             +dashboard-widget-shortmenu))

;; Read the atomically published desktop palette. No extra Emacs packages or
;; shell processes are needed; a stat every three seconds also works over TTY.
(defvar malik/palette-file
  (expand-file-name "desktop-theme/theme.json"
                    (or (getenv "XDG_STATE_HOME") "~/.local/state/")))
(defvar malik/palette-stamp nil)
(defvar malik/palette-timer nil)

(defun malik/refresh-desktop-theme ()
  "Reload the desktop theme when the shared palette changes."
  (when (eq doom-theme 'desktop)
    (let ((stamp (file-attribute-modification-time
                  (file-attributes malik/palette-file))))
      (unless (equal stamp malik/palette-stamp)
        (condition-case err
            (progn
              (load-theme 'desktop t)
              (setq malik/palette-stamp stamp))
          (error (message "Desktop palette: %s" (error-message-string err))))))))

(defun malik/start-palette-sync ()
  "Keep only one palette watcher when reloading the configuration."
  (when (timerp malik/palette-timer)
    (cancel-timer malik/palette-timer))
  (setq malik/palette-stamp
        (file-attribute-modification-time (file-attributes malik/palette-file))
        malik/palette-timer
        (run-with-timer 3 3 #'malik/refresh-desktop-theme)))

(add-hook 'doom-after-init-hook #'malik/start-palette-sync)
(when (bound-and-true-p doom-init-time)
  (malik/start-palette-sync))
