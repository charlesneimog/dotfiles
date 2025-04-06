#!/home/neimog/miniconda3/bin/python3.10

import os
from notion.client import NotionClient
from notion.block import CalloutBlock, SubsubheaderBlock, TextBlock
import sys
import argparse
import webcolors
import datetime
import locale

from pdfannots import process_file
from pdfminer.layout import LAParams

#locale.setlocale(locale.LC_TIME, 'pt_BR.utf8') # change this to your locale


class pdf2Notion():

    def __init__(self):
        self.RED_hex = ['#df1a24', '#e42136', '#ff4d5b', '#eb4949', '#ee5250', '#e52136']
        self.GREEN_hex = ['#33d079', '#69d925', '#00ff00', '#009200', '#009900'] 
        self.BLUE_hex = ['#3583e4', '#42a4f5', '#00ffff']
        self.YELLOW_hex = ['#f6d32c', '#fbf485', '#ffd100', '#fbf485', '#ffed57', '#fff066', '#ffe6a1']

        self.pdfFiles = []
        self.erros = []
        
        # get the folder where this file is located
        parser = argparse.ArgumentParser(description="Sample script with command-line arguments")
        parser.add_argument('--notionToken', required=False, help='Notion token argument')
        parser.add_argument('--mainDataBase', required=False, help='Main database argument')
        
        # parse INFILE, it has no arg, just the name
        parser.add_argument('INFILE', nargs='*')

        args = parser.parse_args()

        self.TOKEN = args.notionToken
        self.MAINDATABASE = args.mainDataBase
        self.pdfFiles = args.INFILE

        self.data = []
        self.allNotes = []

        self.thisFile = os.path.basename(__file__)
        self.thisFolder = os.path.dirname(os.path.abspath(__file__))
        
        # check if pdfFiles is a list
        if type(self.pdfFiles) != list:
            self.pdfFiles = [self.pdfFiles]

        self.notionAuth()
        
        for pdfFile in self.pdfFiles:
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
                    iconLink = '🟢️'
                elif colorName == 'blue':
                    iconLink = '🔵️'
                elif colorName == 'yellow':
                    iconLink = '🟡️'
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
        row.title = self.pdfFileName
        row.icon = 'https://cdn-icons-png.flaticon.com/512/1643/1643231.png'
        row.set_property('Tipo', "Artigo")
        for note in enumerate(self.allNotes):
            noteContent = note[1]
            if noteContent.userComment == '':
                callOutText = f'*{noteContent.text}* \n \n **{noteContent.data}** –  Página {noteContent.page}'
            else:
                callOutText = f'*{noteContent.text}*  \n \n 👨‍🏫️ `{noteContent.userComment}` \n \n **{noteContent.data}** –  Página {noteContent.page}'
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

    
if __name__ == '__main__':
    pdf2Notion()

        
    
        
        
