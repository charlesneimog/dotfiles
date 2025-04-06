import argparse
import datetime
import email.message
import imaplib
import os
import quopri
import re
import smtplib
import sys
from email.header import decode_header

import webcolors
from notion.block import CalloutBlock, TextBlock
from notion.client import NotionClient
from pdfannots import process_file
from pdfminer.layout import LAParams


class pdf2Notion():

    def __init__(self):
        self.RED_hex = ['#df1a24', '#e42136', '#ee5250', '#ff6666', 
                        '#ff9999', '#ff809d', '#ff6e6e', '#e44234'
                        '#ec333a', '#ff809d', '#e42036']
        self.GREEN_hex = ['#33d079', '#69d925', '#00ff00', '#009200',
                          '#00ff00', '#33cc00', '#00ff65', '#009900']
        self.BLUE_hex = ['#3583e4', '#42a4f5', '#00ffff', '#8080ff',]
        self.YELLOW_hex = ['#f6d32c', '#fbf485', '#ffd100', '#fbf485', 
                           '#ffed57', "#ffe6a1", "#fff066", '#ffd400',
                           '#ff6f01', '#ff6f01', '#fbed72', '#ff5400'
                           '#f69a00', '#f69a00', '#ffed58', '#ffee58', '#ffd400', 
                           '#ffd400', '#ffd400', '#9900ff', '#ffd000']
        self.pdfFiles = []
        self.erros = []
        # get the folder where this file is located
        parser = argparse.ArgumentParser(description="Sample script with command-line arguments")
        parser.add_argument('--notionToken', required=False, help='Notion token argument')
        parser.add_argument('--mainDataBase', required=False, help='Main database argument')
        parser.add_argument('--emailPass', required=True, help='Email password argument')
        parser.add_argument('--emailSender', required=True, help='Email sender argument')
        parser.add_argument('--emailReceiver', required=True, help='Email receiver argument')
        args = parser.parse_args()
        self.TOKEN = args.notionToken
        self.MAINDATABASE = args.mainDataBase
        self.emailPassword = args.emailPass
        self.emailSender = args.emailSender
        self.emailReceiver = args.emailReceiver
        self.data = []
        self.allNotes = []
        self.thisFile = os.path.basename(__file__)
        self.thisFolder = os.path.dirname(os.path.abspath(__file__))
        self.attachments_dir = os.path.join(self.thisFolder, 'attachments')
        self.folder = os.path.dirname(os.path.abspath(__file__))
        
        if not os.path.exists(self.attachments_dir):
            os.makedirs(self.attachments_dir)

        self.notionAuth()
        self.readEmails()

        print(self.pdfFiles)

        if self.pdfFiles == []:
            print("\033[92m" + "No new emails" + "\033[0m")
            sys.exit()

        for pdfFilesOnEmail in self.pdfFiles:
            for pdfFile in pdfFilesOnEmail:
                try:
                    self.data = []
                    self.pdfFile = pdfFile
                    print("\033[94m" + "Processing: " + os.path.basename(self.pdfFile) + "\033[0m")
                    self.pdfFileName = os.path.basename(self.pdfFile)
                    self.pdfFileName = self.pdfFileName[:-4]
                    self.allNotes = []
                    self.pdfNotes2Dict()
                    self.Data2Notes()
                    self.addNotes2Notion()
                    print("\033[92m" + "Done: " + os.path.basename(self.pdfFile) + "\033[0m")
                except Exception as e:
                    self.erros.append(e)
                    print("\033[91m" + f"Error: {e}" + "\033[0m")
                print("\n")

        if len(self.erros) > 0:
            self.emailBody = f"Erros: {str(self.erros)}" 
            self.sendEmail()


    class Note():
        def __init__(self):
            self.text = ""
            self.page = ""
            self.userComment = ""
            self.data = ""
            self.linkforGoogleBooks = ""
            self.isSubTitle = False
            self.subTitle = ""
            self.Cor = ""
            self.CorHex = ""
            self.iconLink = ""


    def pdfNotes2Dict(self):
        try:
            laparams = LAParams()
            with open(self.pdfFile, "rb") as fp:
                self.doc = process_file(
                    fp,
                    columns_per_page=None,
                    emit_progress_to=None,
                    laparams=laparams)

            for page in self.doc.pages:
                pageNumber = page.pageno
                for annot in page.annots:
                    result = {}
                    result['page'] = pageNumber
                    result['text'] = annot.gettext(True)
                    result['contents'] = annot.contents
                    result['author'] = annot.author
                    result['created'] = annot.created.strftime("%d-%m-%Y")
                    result['color'] = annot.color.ashex()
                    self.data.append(result)
            return True 
        except Exception as e:
            self.erros.append(e)
    

    def notionAuth(self):
        try:
            self.client = NotionClient(token_v2=self.TOKEN)  
            print("\033[92m" + "Notion Auth" + "\033[0m")
        except:
            # print in red
            print("\033[91m" + "Error: Notion Auth" + "\033[0m")
            sys.exit()


    def saveAttachments(self, msg, directory, subject):
        files = []
        for part in msg.walk():
            if part.get_content_maintype() == 'multipart':
                continue
            if part.get('Content-Disposition') is None:
                continue
            # subject is Notes from "Os Pré Socráticos", I want just what is inside the quotes
            match = re.search(r'"([^"]+)"', subject)
            if match:
                fixed_string = self.fix_string(match.group(1))
                self.BookTitle = fixed_string
            else:
                pass  
            ## check if file name is pdf
            filename = part.get_filename()
            decoded_text = ""
            for encoding, text in re.findall(r'=\?(.*?)\?(.*?)\?=', filename):
                decoded = text.encode('utf-8').decode(encoding)
                without_underscores = decoded.replace("_", " ")
                without_Q = without_underscores.replace("Q?", "")
                decoded_text += without_Q
            if '.pdf' not in decoded_text:
                continue
            filepath = os.path.join(directory, decoded_text)
            with open(filepath, 'wb') as f:
                f.write(part.get_payload(decode=True))
            files.append(filepath)

        return files

    
    def readEmails(self):
        try:
            mail = imaplib.IMAP4_SSL("imap.gmail.com")
            mail.login(self.emailSender, self.emailPassword)
            mail.select('inbox')
            status, message_ids = mail.search(None, 'UNSEEN')
            if status == 'OK':
                unread_email_ids = message_ids[0].split()
            else:
                unread_email_ids = []
            for email_id in unread_email_ids:
                status, msg_data = mail.fetch(email_id, '(RFC822)')
                if status == 'OK':
                    raw_email = msg_data[0][1]
                    msg = email.message_from_bytes(raw_email)
                    from_address = msg.get("From")
                    from_address = from_address.split("<")[1]
                    from_address = from_address.split(">")[0]

                    if 'neimog' in from_address:
                        subject = quopri.decodestring(msg['Subject']).decode('utf-8')
                        subject = subject.replace("_", " ")
                        self.pdfFiles.append(self.saveAttachments(msg, self.attachments_dir, subject))
                    else:
                        mail.store(email_id, '-FLAGS', '\Seen')

        except Exception as e:
            print("\033[91m" + f"Error: Read Emails {e}" + "\033[0m")
            sys.exit()


    def Data2Notes(self):
        for i in range(len(self.data)):
            try:
                commentario = self.data[i]['contents']
                commentario = commentario.replace('\n', '')
            except:
                commentario = ''
            try:
                page = self.data[i]['page']
            except:
                page = ''
            try:
                text = self.data[i]['text']
                text = text.replace('\n', '')
            except:
                text = ''
            try:
                color = self.data[i]['color']
                colorName = self.hex_to_color_name(color)
                if colorName is None:
                    if color in self.RED_hex:
                        colorName = 'red'
                    elif color in self.GREEN_hex:
                        colorName = 'green'
                    elif color in self.BLUE_hex:
                        colorName = 'blue'
                    elif color in self.YELLOW_hex:
                        colorName = 'yellow'
                    else:
                        colorName = ''

                if colorName == 'red':
                    iconLink = '🔴️'
                elif colorName == 'green':
                    iconLink = '🟢'
                elif colorName == 'blue':
                    iconLink = '🔵'
                elif colorName == 'yellow':
                    iconLink = '🟡'
                else:
                    # print in red not found color {hex}
                    print("\033[91m" + f"Error: not found color {color}" + "\033[0m")
                    self.erros.append(f'not found color {color}')
                    iconLink = ''
            except:
                color = ''
                colorName = ''
                iconLink = ''
            try:
                date = self.data[i]['created']
                date = date.replace('\n', '')
            except:
                date = datetime.datetime.now()
                date = date.strftime("%d de %B de %Y")
            newNote = self.Note()
            newNote.text = text
            newNote.page = page
            newNote.data = date
            newNote.userComment = commentario
            newNote.CorHex = color
            newNote.Cor = colorName
            newNote.iconLink = iconLink
            self.allNotes.append(newNote)


    def addNotes2Notion(self):
        mainDatabase = self.client.get_collection_view(self.MAINDATABASE)
        row = mainDatabase.collection.add_row()
        print("Page created in %s" % row.get_browseable_url())
        row.title = self.pdfFileName
        row.icon = 'https://cdn-icons-png.flaticon.com/512/1643/1643231.png'
        row.set_property('Tipo', 'New Notes')
        for note in enumerate(self.allNotes):
            noteContent = note[1]
            if noteContent.userComment == '':
                callOutText = f'*{noteContent.text}* \n \n **{noteContent.data}** –  Página {noteContent.page}'
            else:
                callOutText = f'*{noteContent.text}*  \n \n 📝 {noteContent.userComment} 📝 \n \n **{noteContent.data}** –  Página {noteContent.page}'
            row.children.add_new(CalloutBlock, title=callOutText, icon=noteContent.iconLink)
            row.children.add_new(TextBlock, title=' ')

    
    def hex_to_color_name(self, hex_code):
        try:
            # Convert the hexadecimal color code to an RGB tuple
            rgb = webcolors.hex_to_rgb(hex_code)

            # Get the closest color name from the color database
            color_name = webcolors.rgb_to_name(rgb)

            return color_name
        except ValueError:
            # If the hex_code is invalid or not found in the database, handle the exception
            return None

    
    def fix_string(self, encoded_string):
        decoded_parts = []
        for part, encoding in decode_header(encoded_string):
            if isinstance(part, bytes):
                decoded_parts.append(part.decode(encoding or 'utf-8', errors='replace'))
            else:
                decoded_parts.append(part)
        return ''.join(decoded_parts)


    def sendEmail(self):
        """
        This function sends the email.
        """
        emailHtml = self.emailBody
        msg = email.message.Message()
        msg['Subject'] = 'Minhas anotações'
        msg['From'] = self.emailSender
        msg['To'] = self.emailReceiver
        password = self.emailPassword
        msg.add_header('Content-Type', 'text/html')
        msg.set_payload(emailHtml)
        s = smtplib.SMTP('smtp.gmail.com: 587')
        s.starttls()
        s.login(msg['From'], password)
        s.sendmail(msg['From'], [msg['To']], msg.as_string().encode('utf-8'))


if __name__ == '__main__':
    pdf2Notion()

        
    
        
        
