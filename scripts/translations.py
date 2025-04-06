import tkinter as tk
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--input', required=True, help='The text to translate')
args = parser.parse_args()

# Run the translation command
input_text = args.input

# Create a new window
window = tk.Tk()

# Set the window background color to white
window.configure(bg="white")

# Run the command and get the output
# output = subprocess.check_output('$(xsel -o | tr -d "\\n") "$(xsel -o | tr -d "\\n" | trans -b -t pt)"', shell=True)

# Decode the output and create a label with the text centered
font = ("Calisto MT", 14)
label = tk.Label(window, text=f" \n {input_text} \n", font=font, bg="white", anchor="center", wraplength=window.winfo_screenwidth())

# Pack the label and set the window size to fit the label
label.pack(expand=True, fill="both")
window.update_idletasks()
window.minsize(label.winfo_width(), label.winfo_height())

# Start the main event loop to display the window
window.mainloop()


