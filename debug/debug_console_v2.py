import socket
import threading
import tkinter as tk
from datetime import datetime

log_levels = {
    "TRACE": 0,
    "DEBUG": 1,
    "INFO ": 2,
    "WARN ": 3,
    "ERROR": 4,
    "FATAL": 5
}


class Log:
    def __init__(self, log: str):
        self.timestamp_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')
        self.log_level = "DEBUG"
        self.logger = "DefaultLogger"
        self.log_str = ""
        self.parse_error = False
        log_parts = log.split(" :: ")
        if len(log_parts) == 3:
            self.log_level = log_parts[0]
            self.logger = log_parts[1]
            self.log_str = log_parts[2]
        else:
            self.parse_error = True
            self.log_str = log

    def __str__(self):
        if not self.parse_error:
            return f"{self.timestamp_str} :: {self.log_level} :: {self.logger} :: {self.log_str}\n"
        return f"{self.timestamp_str} :: {self.log_str}\n"


class PlaceholderEntry(tk.Entry):
    def __init__(self, *args, placeholder="", **kwargs):
        super().__init__(*args, **kwargs)
        self.placeholder = placeholder
        self.user_has_interacted = False
        self.insert(0, self.placeholder)
        self.config(fg='grey')
        self.bind('<FocusIn>', self.on_focus_in)
        self.bind('<FocusOut>', self.on_focus_out)
        self.bind('<Control-BackSpace>', self.handle_ctrl_backspace)
        self.bind('<Key>', self.on_key_press)  # Bind key press event

    def on_focus_in(self, event):
        if not self.user_has_interacted and self.get() == self.placeholder:
            self.delete(0, 'end')
            self.config(fg='black')

    def on_focus_out(self, event):
        if not self.get():
            self.insert(0, self.placeholder)
            self.config(fg='grey')
            self.user_has_interacted = False  # Reset flag if entry is empty

    def on_key_press(self, event):
        self.user_has_interacted = True  # User has interacted when any key is pressed

    def reset_interaction_flag(self):
        self.user_has_interacted = False

    def handle_ctrl_backspace(self, event: tk.Event):
        # Get the current content of the entry and the cursor position
        content = self.get()
        cursor_pos = self.index(tk.INSERT)
        # Find the start of the word to the left of the cursor
        pre_cursor = content[:cursor_pos]

        # If the last character before the cursor is a space, delete it
        if len(pre_cursor) > 0 and pre_cursor[-1] == ' ':
            self.delete(cursor_pos - 1, tk.INSERT)
            return "break"  # Prevent default behavior

        word_start = pre_cursor.rfind(' ') + 1 if ' ' in pre_cursor else 0
        # Delete the word
        self.delete(f"{word_start}", tk.INSERT)
        return "break"  # Prevent default behavior


class OptionsFrame(tk.Frame):
    def __init__(self, parent):
        super().__init__(parent)
        self.global_search_frame = GlobalSearchFrame(self, parent)
        self.specific_search_frame = SpecificSearchFrame(self, parent)
        self.create_widgets()

    def inject_console(self, console):
        self.global_search_frame.inject_console(console)
        self.specific_search_frame.inject_console(console)

    def create_widgets(self):
        self.global_search_frame.pack()
        self.specific_search_frame.pack()


class GlobalSearchFrame(tk.Frame):
    def __init__(self, parent, root):
        super().__init__(parent)

        self.after_id = None
        self.root = root
        self.console = None

        # Global search entry
        self.search_entry_placeholder = "Search"
        self.search_entry_var = tk.StringVar()
        self.search_entry = PlaceholderEntry(
            self,
            placeholder=self.search_entry_placeholder,
            textvariable=self.search_entry_var
        )
        self.search_entry_var.trace("w", self.on_entry_changed)
        self.search_entry.bind('<Escape>', lambda event: self.console.text_widget.focus())
        self.search_entry.config(fg='grey')

        self.create_widgets()

    def inject_console(self, console):
        self.console = console

    def create_widgets(self):
        self.search_entry.pack()

    def on_entry_changed(self, *args):
        if self.after_id:
            self.root.after_cancel(self.after_id)
        self.after_id = self.root.after(300, self.apply_search_entry_var)

    def apply_search_entry_var(self):
        self.console.set_filter(global_search_str=self.search_entry_var.get())
        self.after_id = None


class Console(tk.Frame):
    def __init__(self, parent, option_frame: OptionsFrame):
        super().__init__(parent)
        self.all_logs = []
        self.shown_logs = []
        self.option_frame = option_frame
        self.text_widget = tk.Text(self)
        self.scrollbar = tk.Scrollbar(self, command=self.text_widget.yview)
        self.global_search_str = ""
        self.logger_name = ""
        self.log_level = "TRACE"
        self.and_above = True
        self.create_widgets()

    def create_widgets(self):
        self.text_widget.pack(side=tk.LEFT, expand=True, fill='both')
        self.scrollbar.pack(side=tk.RIGHT, fill='y')
        self.text_widget.config(yscrollcommand=self.scrollbar.set)

    def set_filter(
            self,
            global_search_str: str = None,
            logger_name: str = None,
            log_level: str = None,
            and_above: bool = None
    ):
        if global_search_str is not None and self.option_frame.global_search_frame.search_entry.user_has_interacted:
            self.global_search_str = global_search_str
        elif global_search_str is None or not self.option_frame.global_search_frame.search_entry.user_has_interacted:
            self.global_search_str = ""

        if logger_name is not None and self.option_frame.specific_search_frame.logger_entry.user_has_interacted:
            self.logger_name = logger_name
        elif logger_name is None or not self.option_frame.specific_search_frame.logger_entry.user_has_interacted:
            self.logger_name = ""

        if log_level is not None:
            self.log_level = log_level

        if and_above is not None:
            self.and_above = and_above

        self.apply_filters()

    def append_log(self, log: str):
        log_obj = Log(log)
        self.all_logs.append(log_obj)
        if self.filter_log(log_obj):
            self.shown_logs.append(log_obj)
            # Check if the user is at the end before appending
            at_end = self.text_widget.yview()[1] == 1.0
            self.text_widget.insert(tk.END, str(log_obj))
            if at_end:
                self.text_widget.see(tk.END)

    def clear_logs(self):
        self.text_widget.delete('1.0', tk.END)
        self.shown_logs.clear()
        self.all_logs.clear()
        self.apply_filters()

    def apply_filters(self):
        # Re-filter all logs and update the text widget only if necessary
        filtered_logs = [log for log in self.all_logs if self.filter_log(log)]
        if filtered_logs != self.shown_logs:
            self.shown_logs = filtered_logs
            self.update_text_widget()

    def filter_log(self, log):
        if self.and_above:
            flag = log_levels[log.log_level] >= log_levels[self.log_level]
        else:
            flag = log.log_level == self.log_level

        if self.logger_name:
            flag = flag and self.logger_name in log.logger

        return flag

    def update_text_widget(self):
        # Preserve the current view position unless at the end
        at_end = self.text_widget.yview()[1] == 1.0
        self.text_widget.delete('1.0', tk.END)
        for log in self.shown_logs:
            self.text_widget.insert(tk.END, str(log))
        if at_end:
            self.text_widget.see(tk.END)


class SpecificSearchFrame(tk.Frame):
    def __init__(self, parent, root):
        super().__init__(parent)
        self.root = root
        self.after_id = None
        self.console = None

        # Logger name entry
        self.logger_entry_placeholder = "Logger Name"
        self.logger_entry_var = tk.StringVar()
        self.logger_entry = PlaceholderEntry(
            self,
            placeholder=self.logger_entry_placeholder,
            textvariable=self.logger_entry_var
        )
        self.logger_entry_var.trace("w", self.on_entry_changed)
        self.logger_entry.bind('<Escape>', lambda event: self.console.text_widget.focus())
        self.logger_entry.config(fg='grey')

        # Log level dropdown
        self.log_level_dropdown_var = tk.StringVar()
        self.log_level_dropdown_var.set("TRACE")
        self.log_level_dropdown = tk.OptionMenu(
            self,
            self.log_level_dropdown_var,
            *log_levels.keys()
        )
        self.log_level_dropdown_var.trace(
            "w",
            lambda *args: self.console.set_filter(log_level=self.log_level_dropdown_var.get())
        )

        # And above checkbox
        self.and_above_var = tk.BooleanVar()
        self.and_above_var.set(True)
        self.and_above_checkbox = tk.Checkbutton(
            self,
            text="And above",
            variable=self.and_above_var,
            onvalue=True,
            offvalue=False,
            command=lambda: self.console.set_filter(and_above=self.and_above_var.get())
        )

        self.clear_log_button: tk.Button | None = None

        self.create_widgets()

    def inject_console(self, console):
        self.console = console
        self.clear_log_button = tk.Button(
            self,
            text="Clear Logs",
            command=self.console.clear_logs
        )
        self.clear_log_button.pack()

    def create_widgets(self):
        self.logger_entry.pack()
        self.log_level_dropdown.pack()
        self.and_above_checkbox.pack()

    def on_entry_changed(self, *args):
        if self.after_id:
            self.root.after_cancel(self.after_id)
        self.after_id = self.root.after(250, self.apply_logger_entry_var)

    def apply_logger_entry_var(self):
        self.console.set_filter(logger_name=self.logger_entry_var.get())
        self.after_id = None


class MainWindow(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Steamodded Debug Console")
        self.options_frame = OptionsFrame(self)
        self.console = Console(self, self.options_frame)
        self.options_frame.inject_console(self.console)
        self.create_widgets()

        self.bind('<Control-f>', self.focus_search)
        self.bind('<Control-F>', self.focus_search)

    def create_widgets(self):
        self.console.pack(expand=True, fill='both')
        self.options_frame.pack()

    def get_console(self):
        return self.console

    def focus_search(self, event):
        self.options_frame.global_search_frame.search_entry.focus()


def client_handler(client_socket, console: Console):
    while True:
        # Traceback can fit in a single log now
        data = client_socket.recv(8192)
        if not data:
            break

        decoded_data = data.decode()
        logs = decoded_data.split("ENDOFLOG")
        for log in logs:
            if log:
                console.append_log(log)


def listen_for_clients(console: Console):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('localhost', 12345))
    server_socket.listen()
    while True:
        client, addr = server_socket.accept()
        threading.Thread(target=client_handler, args=(client, console)).start()


if __name__ == "__main__":
    root = MainWindow()
    threading.Thread(target=listen_for_clients, daemon=True, args=(root.get_console(),)).start()
    root.mainloop()
