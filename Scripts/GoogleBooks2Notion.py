# Python 3.8.0
from notion.client import NotionClient
from notion.block import CalloutBlock, VideoBlock, ColumnListBlock, SubsubheaderBlock, TextBlock
import imaplib
import smtplib
import email.message
from email.header import decode_header

from unidecode import unidecode

from bs4 import BeautifulSoup

import os
import traceback 
import re
import quopri
import urllib.request
from urllib.parse import quote
import json

import argparse
import sys

# -------------------------------------------------
#
# Utility to read email from Gmail Using Python
#
# ------------------------------------------------

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


class BookToAdd():

    def __init__(self, errorsNumbers=0) -> None:
        self.errorsNumbers = errorsNumbers
        self.htmlFiles = []
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
        self.allNotes = []

        self.thisFile = os.path.basename(__file__)
        self.thisFolder = os.path.dirname(os.path.abspath(__file__))
        self.attachments_dir = os.path.join(self.thisFolder, 'attachments')
        
        self.BookAuthor = ""
        self.BookTitle = ""
        self.BookCoverLink = ""
        self.BookYear = ""

        try: 
            if not os.path.exists(self.attachments_dir):
                os.makedirs(self.attachments_dir)

            self.notionAuth() # notion auth

            self.readEmails()

            if self.htmlFiles == []:
                # print in green 
                print("\033[92m" + "No new emails" + "\033[0m")
                sys.exit()

            self.getNotes(self.htmlFiles)
            self.findBookProperties()
            self.addNotesToNotion()

        except Exception as e:
            print("\033[91m" + f"{e}" + "\033[0m")
            self.sendErrorEmail(f"Error in {e}")
            sys.exit(-1)


    def notionAuth(self):
        try:
            self.client = NotionClient(token_v2=self.TOKEN)  
            print("\033[92m" + "Notion Auth" + "\033[0m")
        except:
            # print in red
            print("\033[91m" + "Error: Notion Auth" + "\033[0m")
            self.sendErrorEmail("Notion Auth Error")
            sys.exit()


    def fix_string(self, encoded_string):
        decoded_parts = []
        for part, encoding in decode_header(encoded_string):
            if isinstance(part, bytes):
                decoded_parts.append(part.decode(encoding or 'utf-8', errors='replace'))
            else:
                decoded_parts.append(part)
        return ''.join(decoded_parts)


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
                print("No text inside quotes found.")

            filename = part.get_filename()
            if filename[-3:] != 'html':
                continue

            filename = subject + ".html"
            filepath = os.path.join(directory, filename)
            with open(filepath, 'wb') as f:
                f.write(part.get_payload(decode=True))
            files.append(filepath)
        return files


    def findBookProperties(self):
        try:
            BOOK_TITLE = unidecode(self.BookTitle)
            self.BookTitle = BOOK_TITLE
            base_api_link = "https://www.googleapis.com/books/v1/volumes?q="
            encoded_book_title = quote(BOOK_TITLE)
            url = base_api_link + encoded_book_title
            with urllib.request.urlopen(url) as f:
                text = f.read()

            decoded_text = text.decode("utf-8", errors="ignore")
            obj = json.loads(decoded_text) # deserializes decoded_text to a Python object
            volume_info = obj["items"][0] # getting the first book
            volume_info_inside = volume_info["volumeInfo"]

            try:
                self.BookAuthor = volume_info_inside["authors"]
            except:
                pass
            try:
                self.BookYear = volume_info_inside["publishedDate"]
            except: 
                pass
            try:
                self.BookCoverLink = volume_info_inside["imageLinks"]["thumbnail"]
            except:
                pass
        except Exception as e:
            #print in red
            print("\033[91m" + f"{e}" + "\033[0m")
            # self.sendErrorEmail("Error finding book properties")
            # sys.exit()


    def getNotes(self, htmlFiles):
        for file in htmlFiles:
            if isinstance(file, list):
                self.getNotes(file)
                return
            with open(file, 'r', encoding="utf-8") as f:
                html_string = f.read()
            soup = BeautifulSoup(html_string, 'html.parser')
            startToAdd = False
            lastSubTitle = ""
            for x in soup.html.body.find_all(['td', 'span', 'h2']):
                if x.text == 'All your annotations':
                    startToAdd = True
                if x.name == 'h2':
                    lastSubTitle = x.text
                if startToAdd:
                    if x.name == 'td' and 'style' in x.attrs:
                        style_attr = x['style']
                        if 'border-right-style:solid;border-bottom-color:#bdbdbd' in style_attr:
                            noteSoup = BeautifulSoup(str(x), 'lxml')
                            newNote = Note()
                            target_td = noteSoup.find('td', style='border-right-style:solid;border-bottom-color:#000000;border-top-width:0pt;border-right-width:0pt;border-left-color:#000000;vertical-align:top;border-right-color:#000000;border-left-width:0pt;border-top-style:solid;border-left-style:solid;border-bottom-width:0pt;width:358.5pt;border-top-color:#000000;border-bottom-style:solid')
                            if 'fde096' in str(x):
                                newNote.Cor = "Yellow"
                                newNote.CorHex = "#fde096"
                                newNote.iconLink = '🟡️'
                            elif 'c5e1a5' in str(x):
                                newNote.Cor = "Green"
                                newNote.CorHex = "#c5e1a5"
                                newNote.iconLink = '🟢️'

                            elif '93e3ed' in str(x):
                                newNote.Cor = "Blue"
                                newNote.CorHex = "#93e3ed"
                                newNote.iconLink = '🔵️'
                            elif 'ffb8a1' in str(x):
                                newNote.Cor = "Vermelho"
                                newNote.CorHex = "#ffb8a1"
                                newNote.iconLink = '🔴️'


                            if target_td:
                                try:
                                    book_Text = target_td.find('span', style=f'background-color:{newNote.CorHex};color:#000000;font-weight:400;text-decoration:none;vertical-align:baseline;font-size:13pt;font-family:"Georgia";font-style:italic').text.strip()
                                except:
                                    book_Text = ''

                                try:
                                    userComment = target_td.find('span', style=f'color:#424242;font-weight:400;text-decoration:none;vertical-align:baseline;font-size:11pt;font-family:"Roboto";font-style:normal').text.strip()

                                except:
                                    userComment = ''
                            else:
                                print("The specified <td> element was not found.")
                                book_Text = ''
                                userComment = ''


                            link = x.find('a', href=True)
                            match = re.search(r'(\d{1,2} de \w+ de \d{4})', x.text) # JUST WORKS FOR PORTUGUESE
                            if match:
                                newNote.data = match.group(1)
                            # NOW INSIDE MYSTRING get the page number
                            page_element = x.find('a', href=True)
                            page_number = page_element.get_text(strip=True)

                            newNote.linkforGoogleBooks = link['href']
                            newNote.subTitle = lastSubTitle
                            newNote.page = page_number
                            newNote.text = book_Text
                            newNote.userComment = userComment

                            self.allNotes.append(newNote)


    def addNotesToNotion(self):
        mainDatabase = self.client.get_collection_view(self.MAINDATABASE)
        row = mainDatabase.collection.add_row()
        row.title = self.BookTitle
        row.set_property('Author', self.BookAuthor)
        row.set_property('Tipo', "Livro")
        row.icon = self.BookCoverLink
        
        # check if self.BookYear is in date as YYYY-MM-DD, convert to YYYY
        if self.BookYear:
            match = re.search(r'(\d{4})', self.BookYear)
            if match:
                self.BookYear = match.group(1)

        row.set_property('Year', self.BookYear)

        for note in enumerate(self.allNotes):
            noteContent = note[1]
            noteIndex = note[0]
            if noteIndex != 0:
                oldTitle = self.allNotes[noteIndex - 1].subTitle
                if noteContent.subTitle != oldTitle:
                    row.children.add_new(SubsubheaderBlock, title=noteContent.subTitle)
                    row.children.add_new(TextBlock, title=' ')
            
            elif noteIndex == 0:
                row.children.add_new(SubsubheaderBlock, title=noteContent.subTitle)
                row.children.add_new(TextBlock, title=' ')
            
            if noteContent.userComment == '':
                callOutText = f'*"{noteContent.text}"* \n \n **{noteContent.data}** –  [Página {noteContent.page}]({noteContent.linkforGoogleBooks})'
            else:
                callOutText = f'*"{noteContent.text}"*  \n \n 📝 {noteContent.userComment} 📝 \n \n **{noteContent.data}** –  [Página {noteContent.page}]({noteContent.linkforGoogleBooks})'
            row.children.add_new(CalloutBlock, title=callOutText, icon=noteContent.iconLink)
            row.children.add_new(TextBlock, title=' ')


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

                # check if how sender is drive-shares-noreply@google.com
                if status == 'OK':
                    raw_email = msg_data[0][1]
                    msg = email.message_from_bytes(raw_email)
                    from_address = msg.get("From")
                    from_address = from_address.split("<")[1]
                    from_address = from_address.split(">")[0]
                    if from_address == 'drive-shares-noreply@google.com':
                        subject = quopri.decodestring(msg['Subject']).decode('utf-8')
                        subject = subject.replace("_", " ")
                        self.htmlFiles.append(self.saveAttachments(msg, self.attachments_dir, subject)) 
                    else:
                        # mark email as unread if it is not from Google Drive
                        mail.store(email_id, '-FLAGS', '\Seen')
            mail.logout()
                        
                        


        except Exception as e:
            traceback.print_exc() 
            print(str(e))
            return None


    def sendErrorEmail(self, message):
        """
        This function sends the email when some error happens.
        """
        emailHtml = "<h1> Error: " + message + "</h1>"
        msg = email.message.Message()
        msg['Subject'] = '[ERRO] Minhas anotações'
        msg['From'] = self.emailSender
        msg['To'] = self.emailReceiver
        password = self.emailPassword
        msg.add_header('Content-Type', 'text/html')
        msg.set_payload(emailHtml)
        s = smtplib.SMTP('smtp.gmail.com: 587')
        s.starttls()
        s.login(msg['From'], password)
        s.sendmail(msg['From'], [msg['To']], msg.as_string().encode('utf-8'))


    def deep_search(self, needles, haystack):
        found = {}
        if type(needles) != type([]):
            needles = [needles]
        if type(haystack) == type(dict()):
            for needle in needles:
                if needle in haystack.keys():
                    found[needle] = haystack[needle]
                elif len(haystack.keys()) > 0:
                    for key in haystack.keys():
                        result = self.deep_search(needle, haystack[key])
                        if result:
                            for k, v in result.items():
                                found[k] = v
        elif type(haystack) == type([]):
            for node in haystack:
                result = self.deep_search(needles, node)
                if result:
                    for k, v in result.items():
                        found[k] = v
        return found





if __name__ == "__main__":
    BookToAdd()





