import tkinter as tk
import socket
import threading


def clientHandler(clientSocket):
    while True:
        data = clientSocket.recv(1024)
        if not data:
            break
        text_widget.insert(tk.END, data.decode() + "\n")


def listenForClients():
    serverSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serverSocket.bind(("localhost", 12345))
    serverSocket.listen()
    while True:
        client, addr = serverSocket.accept()
        threading.Thread(target=clientHandler, args=(client,)).start()


root = tk.Tk()
text_widget = tk.Text(root)
text_widget.pack()

threading.Thread(target=listenForClients, daemon=True).start()

root.mainloop()
