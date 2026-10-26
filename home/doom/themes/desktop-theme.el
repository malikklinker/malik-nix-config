;;; desktop-theme.el --- Shared desktop colors for Doom -*- lexical-binding: t; no-byte-compile: t; -*-

(require 'doom-themes)
(require 'json)

(defvar malik/desktop-palette nil)
(setq malik/desktop-palette
      (let ((file (expand-file-name "desktop-theme/theme.json"
                                   (or (getenv "XDG_STATE_HOME") "~/.local/state/"))))
        (when (file-readable-p file)
          (with-temp-buffer
            (insert-file-contents file)
            (json-parse-buffer :object-type 'alist)))))

(defun malik/desktop-color (key fallback &optional role)
  "Read KEY from the shared palette, or ROLE from its semantic colors."
  (let ((color (alist-get (or role key)
                          (alist-get (if role 'colors 'palette)
                                     malik/desktop-palette))))
    ;; Doom's base faces expect color lists, including in wave underlines.
    (list (if (and (stringp color)
                   (string-match-p "\\`#[[:xdigit:]]\\{6\\}\\'" color))
              color
            fallback))))

(def-doom-theme desktop
  "A quiet editor that follows the desktop's Base16 palette."
  ((bg         (malik/desktop-color 'base00 "#090c14"))
   (bg-alt     (malik/desktop-color 'base01 "#121824"))
   (fg         (malik/desktop-color 'base05 "#c5cbd6"))
   (fg-alt     (malik/desktop-color 'base04 "#8a98aa"))
   (base0 bg) (base1 bg-alt) (base2 bg-alt)
   (base3      (malik/desktop-color 'base02 "#26364b"))
   (base4      (malik/desktop-color 'base03 "#536479"))
   (base5 fg-alt) (base6 fg) (base7 fg)
   (base8      (malik/desktop-color 'base07 "#ecf0f6"))
   (grey base4)
   (red        (malik/desktop-color 'base08 "#cf8993"))
   (orange     (malik/desktop-color 'base09 "#cca17e"))
   (yellow     (malik/desktop-color 'base0A "#c9bc8b"))
   (green      (malik/desktop-color 'base0B "#96b3a3"))
   (teal       (malik/desktop-color 'base0C "#8cbabc"))
   (blue       (malik/desktop-color 'base0D "#8aafd0"))
   (magenta    (malik/desktop-color 'base0E "#ada0d5"))
   (violet magenta) (cyan teal) (dark-cyan teal) (dark-blue blue)
   (highlight  (malik/desktop-color nil "#8aafd0" 'accent))
   (vertical-bar bg-alt) (selection base3)
   (builtin cyan) (comments fg-alt) (doc-comments fg-alt)
   (constants orange) (functions blue) (keywords magenta)
   (methods blue) (operators cyan) (type yellow) (strings green)
   (variables fg) (numbers orange) (region base3)
   (error red) (warning yellow) (success green)
   (vc-modified yellow) (vc-added green) (vc-deleted red))

  ((cursor :background highlight)
   (fringe :background bg)
   (vertical-border :foreground bg-alt)
   (window-divider :foreground bg-alt)
   (hl-line :background bg-alt)
   (line-number :foreground base4 :background bg)
   (line-number-current-line :foreground highlight :background bg :weight 'bold)
   (font-lock-comment-face :slant 'italic)
   (mode-line :background bg-alt :foreground fg :box nil)
   (mode-line-inactive :background bg :foreground fg-alt :box nil)
   (doom-modeline-bar :background highlight)
   (doom-modeline-buffer-modified :foreground orange)
   (solaire-default-face :background bg)
   (solaire-hl-line-face :background bg-alt)
   (+dashboard-banner :foreground highlight :weight 'bold)
   (+dashboard-menu-title :foreground fg)
   (+dashboard-menu-desc :foreground fg-alt)
   (org-document-title :foreground highlight :height 1.5 :weight 'bold)
   (org-level-1 :foreground blue :height 1.25 :weight 'bold)
   (org-level-2 :foreground magenta :height 1.15 :weight 'bold)
   (org-level-3 :foreground cyan :height 1.05 :weight 'bold)
   (org-block :background bg-alt)
   (org-code :foreground green)
   (org-ellipsis :foreground fg-alt :underline nil)))

;;; desktop-theme.el ends here
