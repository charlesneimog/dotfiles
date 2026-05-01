# pip install qrcode[pil]

import qrcode

# Conteúdo do QR Code
data = "https://charlesneimog.github.io/Nis/"

# Configuração do QR Code
qr = qrcode.QRCode(
    version=1,  # tamanho do QR (1 a 40)
    error_correction=qrcode.constants.ERROR_CORRECT_M,
    box_size=10,
    border=4,
)

qr.add_data(data)
qr.make(fit=True)

# Gerar imagem
img = qr.make_image(fill_color="black", back_color="white")

# Salvar arquivo
img.save("qrcode.png")

print("QR Code salvo como qrcode.png")
