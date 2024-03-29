import tkinter as tk
import socket
import threading
from datetime import datetime


def client_handler(client_socket):
    while True:
        data = client_socket.recv(1024)
        if not data:
            break
        text_widget.insert(tk.END, datetime.now().strftime("%Y-%m-%d %H:%M:%S") + " :: " + data.decode() + '\n')
        text_widget.see(tk.END)


def listen_for_clients():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('localhost', 12345))
    server_socket.listen()
    while True:
        client, addr = server_socket.accept()
        threading.Thread(target=client_handler, args=(client,)).start()


def on_search_entry_change(varName, index, mode):
    global search_after_id
    if search_after_id:
        root.after_cancel(search_after_id)
    search_after_id = root.after(300, search_text)  # 300 ms delay before searching


def clear_logs():
    text_widget.delete('1.0', tk.END)


def search_text(event=None):  # Allow for binding to events
    global last_search_start, last_search_end, search_after_id
    search_after_id = None
    text_widget.tag_remove('found', '1.0', tk.END)
    query = search_var.get()
    if query:
        start_idx = last_search_end if last_search_start and last_search_end else '1.0'
        idx = text_widget.search(query, start_idx, nocase=search_mode.get() != 'match_case',
                                 regexp=search_mode.get() == 'regex', stopindex=tk.END)
        if idx:
            last_search_start = idx
            lastidx = f"{idx}+{len(query)}c" if search_mode.get() != 'regex' else f"{idx}+{len(text_widget.get(idx, tk.END).split(None, 1)[0])}c"
            text_widget.tag_add('found', idx, lastidx)
            text_widget.tag_config('found', foreground='white', background='blue')
            text_widget.see(idx)
            last_search_end = f"{lastidx}+1c"
        else:
            last_search_start = None
            last_search_end = None


def focus_search(event=None):
    search_entry.focus_set()


def handle_ctrl_backspace(event):
    # Delete the word left of the cursor in the search entry
    content = search_entry.get()
    cursor_pos = search_entry.index(tk.INSERT)
    pre_cursor = content[:cursor_pos]
    word_start = pre_cursor.rfind(' ') + 1 if ' ' in pre_cursor else 0
    search_entry.delete(f"{word_start}", tk.INSERT)
    return "break"  # Prevent default behavior


if __name__ == "__main__":
    root = tk.Tk()

    last_search_start = None
    last_search_end = None
    search_after_id = None

    # Frame for text widget and scrollbar
    text_frame = tk.Frame(root)
    text_frame.pack(expand=True, fill='both')

    text_widget = tk.Text(text_frame)
    text_widget.pack(side=tk.LEFT, expand=True, fill='both')

    scrollbar = tk.Scrollbar(text_frame, command=text_widget.yview)
    scrollbar.pack(side=tk.RIGHT, fill='y')
    text_widget.config(yscrollcommand=scrollbar.set)

    # Frame for search functionality
    search_frame = tk.Frame(root)
    search_frame.pack(fill='x')

    search_var = tk.StringVar()
    search_var.trace("w", lambda name, index, mode, sv=search_var: on_search_entry_change(name, index, mode))
    search_entry = tk.Entry(search_frame, textvariable=search_var)
    search_entry.pack(side=tk.LEFT, fill='x', expand=True)
    search_entry.bind('<Return>', search_text)  # Bind the Enter key to the search function
    search_entry.bind('<Control-BackSpace>', handle_ctrl_backspace)

    # Bind Ctrl+F to focus on the search bar
    root.bind('<Control-f>', focus_search)
    root.bind('<Control-F>', focus_search)  # For capital 'F' if Caps Lock is on or Shift is pressed

    # Frame for search options
    options_frame = tk.Frame(root)
    options_frame.pack(fill='x')

    search_mode = tk.StringVar(value='normal')
    modes = [('normal', 'normal'), ('match_case', 'match case'), ('regex', 'regex')]
    for mode, text in modes:
        b = tk.Radiobutton(options_frame, text=text, variable=search_mode, value=mode)
        b.pack(side=tk.LEFT)

    clear_button = tk.Button(root, text="Clear Logs", command=clear_logs)
    clear_button.pack(side=tk.BOTTOM, fill='x')

    threading.Thread(target=listen_for_clients, daemon=True).start()

    root.mainloop()
