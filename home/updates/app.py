"""Desktop NixOS updates: prepare, review, authenticate, and reboot when ready."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import threading

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gio, GLib, Gtk

from backend import Updater


class UpdateWindow(Gtk.ApplicationWindow):
    def __init__(self, application, config, state):
        super().__init__(application=application, title="OS Updates")
        self.set_default_size(900, 680)
        self.set_size_request(680, 520)
        self.config = config
        self.working = False
        self.updater = Updater(config, state, self.report)
        self.connect("delete-event", self.close_requested)

        provider = Gtk.CssProvider()
        provider.load_from_data(b"""
            window { background: #090c14; color: #c5cbd6; }
            label { color: #c5cbd6; }
            .heading { font-size: 26px; color: #ecf0f6; }
            .muted { color: #8a98aa; }
            button { border-radius: 0; background: #121824; color: #c5cbd6;
                     border: 1px solid #26364b; padding: 10px 16px; box-shadow: none; }
            button:hover { background: #26364b; }
            button:disabled { color: #536479; }
            button:disabled label { color: #536479; }
            button:focus { border-color: #8aafd0; }
            .suggested-action { background: #8aafd0; color: #090c14; }
            .suggested-action label { color: #090c14; }
            .suggested-action:disabled { background: #121824; }
            textview, textview text { background: #121824; color: #c5cbd6; }
            progressbar trough { background: #121824; border-radius: 0; }
            progressbar progress { background: #8aafd0; border-radius: 0; }
        """)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
                                                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_border_width(28)
        self.add(box)
        title = Gtk.Label(label="OS updates", xalign=0)
        title.get_style_context().add_class("heading")
        box.pack_start(title, False, False, 0)
        details = Gtk.Label(label="Build and review first. Install for the next boot. Restart when you're ready.", xalign=0)
        details.set_line_wrap(True)
        details.get_style_context().add_class("muted")
        box.pack_start(details, False, False, 0)
        self.status = Gtk.Label(xalign=0)
        self.status.set_line_wrap(True)
        self.status.set_selectable(True)
        self.status.set_can_focus(False)
        box.pack_start(self.status, False, False, 0)
        self.progress = Gtk.ProgressBar()
        box.pack_start(self.progress, False, False, 0)
        actions = Gtk.Box(spacing=10)
        box.pack_start(actions, False, False, 0)
        self.update = self.button(actions, "Prepare OS update", lambda *_: self.prepare(True))
        self.local = self.button(actions, "Apply local changes", lambda *_: self.prepare(False))
        self.install = self.button(actions, "Install for next boot", lambda *_: self.start(self.updater.install, prompt_reboot=True))
        self.install.get_style_context().add_class("suggested-action")

        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        self.log = Gtk.TextView(editable=False, cursor_visible=False, monospace=True)
        self.log.set_left_margin(12)
        self.log.set_right_margin(12)
        self.log.set_top_margin(10)
        self.log.set_bottom_margin(10)
        scroller.add(self.log)
        box.pack_start(scroller, True, True, 0)
        footer = Gtk.Box(spacing=10)
        box.pack_start(footer, False, False, 0)
        self.preview = self.button(footer, "Preview login screen", self.preview_login)
        self.restart = self.button(footer, "Restart now…", self.ask_restart)
        self.button(footer, "Close", lambda *_: self.close())
        self.sync()
        if self.updater.candidate and (self.updater.state / "update.log").exists():
            self.log.get_buffer().set_text((self.updater.state / "update.log").read_text()[-200000:])
        GLib.timeout_add(100, self.pulse)

    def button(self, box, text, callback):
        button = Gtk.Button(label=text)
        button.connect("clicked", callback)
        box.pack_start(button, False, False, 0)
        return button

    def ready_to_reboot(self):
        candidate = self.updater.candidate
        return bool(candidate and candidate["phase"] == "installed"
                    and Path("/run/booted-system").resolve() != Path(candidate["system"]))

    def sync(self):
        candidate = self.updater.candidate
        self.update.set_sensitive(not self.working)
        self.local.set_sensitive(not self.working)
        self.preview.set_sensitive(not self.working)
        self.install.set_sensitive(not self.working and bool(candidate and candidate["phase"] == "prepared"))
        self.restart.set_sensitive(not self.working and self.ready_to_reboot())
        if not self.working:
            self.progress.set_fraction(0)
            if candidate and candidate["phase"] == "prepared":
                self.status.set_text("Build ready. Review the package changes below, then install with administrator authentication.")
            elif self.ready_to_reboot():
                self.status.set_text("Installed for the next boot. Save your work before restarting.")
            else:
                self.status.set_text("Prepare OS update refreshes all pinned inputs. Apply local changes uses the current lock file.")

    def pulse(self):
        if self.working:
            self.progress.pulse()
        return True

    def report(self, phase, line):
        GLib.idle_add(self.append, phase, line)

    def append(self, phase, line):
        self.status.set_text(phase)
        buffer = self.log.get_buffer()
        buffer.insert(buffer.get_end_iter(), line + "\n")
        if buffer.get_line_count() > 3000:
            buffer.delete(buffer.get_start_iter(), buffer.get_iter_at_line(500))
        self.log.scroll_to_iter(buffer.get_end_iter(), 0, False, 0, 1)
        return False

    def prepare(self, update_inputs):
        self.log.get_buffer().set_text("")
        self.start(lambda: self.updater.prepare(update_inputs))

    def start(self, operation, prompt_reboot=False):
        if self.working:
            return
        self.working = True
        self.sync()
        self.status.set_text("Starting…")

        def worker():
            error = None
            try:
                operation()
            except Exception as failure:
                error = str(failure)
            GLib.idle_add(self.finished, error, prompt_reboot)

        threading.Thread(target=worker, daemon=True).start()

    def finished(self, error, prompt_reboot=False):
        self.working = False
        self.sync()
        if error:
            self.status.set_text(error)
            self.append_error(error)
        elif prompt_reboot and self.ready_to_reboot():
            self.ask_restart()
        return False

    def append_error(self, error):
        buffer = self.log.get_buffer()
        buffer.insert(buffer.get_end_iter(), "\n" + error + "\n")

    def close_requested(self, *_):
        if self.working:
            self.status.set_text("An update is running. Keep this window open until it finishes.")
        return self.working

    def ask_restart(self, *_):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True,
            message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.NONE,
            text="Restart to use the new system?")
        dialog.format_secondary_text("Save your work first. Restarting closes your current desktop session.")
        dialog.add_buttons("Later", Gtk.ResponseType.CANCEL, "Restart now", Gtk.ResponseType.OK)
        response = dialog.run()
        dialog.destroy()
        if response == Gtk.ResponseType.OK:
            self.start(lambda: self.updater.run([self.config["systemctl"], "reboot"], "Requesting restart"))

    def preview_login(self, *_):
        self.status.set_text("Opening the installed login theme in test mode. Close its window to return.")
        environment = dict(os.environ, QML_DISABLE_DISK_CACHE="1")
        try:
            subprocess.Popen(["/run/current-system/sw/bin/sddm-greeter-qt6", "--test-mode", "--theme",
                              "/run/current-system/sw/share/sddm/themes/midnight-blue"], env=environment)
        except OSError as error:
            self.status.set_text(str(error))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    args = parser.parse_args()
    config = json.loads(Path(args.config).read_text())
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "os-update"
    application = Gtk.Application(application_id="org.malikk.OSUpdates", flags=Gio.ApplicationFlags.FLAGS_NONE)

    def activate(app):
        window = app.get_active_window()
        if window is None:
            window = UpdateWindow(app, config, state)
            window.show_all()
        window.present()

    application.connect("activate", activate)
    application.run([])


if __name__ == "__main__":
    main()
