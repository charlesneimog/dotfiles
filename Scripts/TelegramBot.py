import telebot
from notion.client import NotionClient
from datetime import datetime, timedelta
import smtplib
import email.message
import argparse
import sys


class NotionBot():
    def __init__(self):
        parser = argparse.ArgumentParser(description="Sample script with command-line arguments")
        parser.add_argument('--notionToken', help='Notion token argument')
        parser.add_argument('--dailyBase', help='Main database argument')
        parser.add_argument('--telegramToken', help='Email password argument')
        parser.add_argument('--emailPass', help='Email password argument')
        parser.add_argument('--emailSender', help='Email sender argument')
        parser.add_argument('--emailReceiver', help='Email receiver argument')
        args = parser.parse_args()
        
        self.TelegramTOKEN = args.telegramToken
        self.NotionTOKEN = args.notionToken
        self.DailyBase = args.dailyBase
        self.emailPassword = args.emailPass
        self.emailSender = args.emailSender
        self.emailReceiver = args.emailReceiver
        
        self.AllCommand = []

        # Start Run Thing
        self.TelegramAuth()
        self.NotionAuth()
        
        self.getTimeOfMessage()
        self.GetMessages()
        self.GetMessagesFromTelegram()
        
        self.GetMainDataBase()


    class TelegramMessage4Notion():
        def __init__(self):
            self.message = ""
            self.command = ""
            self.priority = ""
            
    def TelegramAuth(self):
        try:
            self.TelegramBot = telebot.TeleBot(self.TelegramTOKEN)
            print("\033[92m" + "Telegram Auth" + "\033[0m")
        except Exception as e:
            self.sendErrorEmail(e)
            sys.exit()
        
    def NotionAuth(self):
        try:
            self.client = NotionClient(token_v2=self.NotionTOKEN)  
            print("\033[92m" + "Notion Auth" + "\033[0m")
        except Exception as e:
            print("\033[91m" + "Error: Notion Auth" + "\033[0m")
            self.sendErrorEmail(e)
            sys.exit()


    def getTimeOfMessage(self):
        now = datetime.now()
        self.endOfMessage = now.replace(hour=now.hour, minute=0, second=0, microsecond=0)
        self.beginOfMessage = self.endOfMessage - timedelta(hours=24)
        print(f"Range of time is from {self.beginOfMessage} to {self.endOfMessage}")
        # sys.exit()
        
        
    def GetMessages(self):
        self.messages = self.TelegramBot.get_updates()


    def GetMessagesFromTelegram(self):
        for message in self.messages:
            data = message.message
            text = data.text
            time = data.date
            if (time < self.beginOfMessage.timestamp() or time > self.endOfMessage.timestamp()):
                pass
            else:
                try: 
                    command = text.split(":")[0]
                    text = text.split(":")[1]
                    newThing = self.TelegramMessage4Notion()
                    newThing.message = text
                    newThing.command = command
                    # check if in the text has the string " P0 ", " P1 ", " P2 ", " P3 "
                    if " P0 " in text:
                        newThing.priority = "P0"
                        newThing.message = text.replace(" P0 ", "")
                    elif " P1 " in text:
                        newThing.priority = "P1"
                        newThing.message = text.replace(" P1 ", "")
                    elif " P2 " in text:
                        newThing.priority = "P2"
                        newThing.message = text.replace(" P2 ", "")
                    elif " P3 " in text:
                        newThing.priority = "P3"
                        newThing.message = text.replace(" P3 ", "")
                    elif " P4 " in text:
                        newThing.priority = "P4"
                        newThing.message = text.replace(" P4 ", "")
                    else:
                        newThing.priority = ""
                    self.AllCommand.append(newThing)
                except Exception as e:
                    print("\033[91m" + f"Error: {e}" + "\033[0m")
                    pass
    
    def GetMainDataBase(self):
        self.MainDataBase = self.client.get_collection_view(self.DailyBase)
        for newrow in self.AllCommand:
            row = self.MainDataBase.collection.add_row()
            if newrow.priority != "":
                row.set_property('Priority', newrow.priority)


            row.title = newrow.message
            if (newrow.command == "a" or newrow.command == "A" or 
                newrow.command == "Artigo"):
                row.set_property('Tags', "Artigo")
                row.icon = "📰"
                print("\033[92m" + f"Artigo: {newrow.message}" + "\033[0m")
            
            elif (newrow.command == "l" or newrow.command == "L" or 
                newrow.command == "Livro"):
                row.set_property('Tags', "Livro")
                row.icon = "📚"
                print("\033[92m" + f"Livro: {newrow.message}" + "\033[0m")
            
            elif (newrow.command == "f" or newrow.command == "F" or 
                newrow.command == "Filme"):
                row.set_property('Tags', "Filme")
                row.icon = "🎬"
                print("\033[92m" + f"Filme: {newrow.message}" + "\033[0m")
            
            elif (newrow.command == "s" or newrow.command == "S" or 
                newrow.command == "Software"):
                row.set_property('Tags', "Software")
                row.icon = "💻"
                print("\033[92m" + f"Software: {newrow.message}" + "\033[0m")

            elif (newrow.command == "p" or newrow.command == "P" or 
                newrow.command == "Pintura"):
                row.set_property('Tags', "Pintura")
                row.icon = "🎨"
                print("\033[92m" + f"Pintura: {newrow.message}" + "\033[0m")

            elif (newrow.command == "m" or newrow.command == "M" or 
                newrow.command == "Música"):
                row.set_property('Tags', "Música")
                row.icon = "🎵"
                print("\033[92m" + f"Música: {newrow.message}" + "\033[0m")

            else:
                self.sendErrorEmail(f'The command {newrow.command} is not valid')
                print("\033[91m" + f"Error: The command {newrow.command} is not valid" + "\033[0m")
                
        
    def sendErrorEmail(self, message):
        """
        This function sends the email when some error happens.
        """
        emailHtml = "<h1> Error: " + str(message) + "</h1>"
        msg = email.message.Message()
        msg['Subject'] = '[ERRO] Telegram Boot'
        msg['From'] = self.emailSender
        msg['To'] = self.emailReceiver
        password = self.emailPassword
        msg.add_header('Content-Type', 'text/html')
        msg.set_payload(emailHtml)
        s = smtplib.SMTP('smtp.gmail.com: 587')
        s.starttls()
        s.login(msg['From'], password)
        s.sendmail(msg['From'], [msg['To']], msg.as_string().encode('utf-8'))   
            
                
if __name__ == "__main__":
    NotionBot()

