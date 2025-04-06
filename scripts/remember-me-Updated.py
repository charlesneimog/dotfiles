from notion.client import NotionClient
from notion.block import CalloutBlock, VideoBlock, ColumnListBlock
from urllib.parse import parse_qs, urlparse
import markdown
import random 
import smtplib
import email.message
import sys
import os
import time
import argparse

class BlocksToRemember():
    """ 
        This represents all the process to get the blocks, then format it to html and finally send it to the email.
        The initialization of the class will do all the process.
    """

    # =============================================
    class RememberBlock():
        """
            This represent each block that should be remembered in the email
        """
        def __init__(self, block) -> None:

            self.block = block
            self.text = block.title
            self.childrens = block.children
            self.id = block.id
            self.icon = block.icon
            self.type = block.__class__.__name__
            self.url = block.get_browseable_url()
            self.video = None
            self.image = None
            self.PieceVideoLink = ''
            self.PieceDescription = ''
            self.PiecePageLink = ''
            self.PieceName = ''


            # actions
            self.getParentPage(block)

        def getParentPage(self, block):
            """
            This function get the ParentPage of the block, this page must have the properties: Author and Year.
            """
            try:
                self.author = block.get_property("Author")
                if (len(self.author) == 1):
                    self.author = self.author[0]
                else:
                    self.author = self.author[0] #  TODO: Fix author for more than 1.
                self.year = block.get_property("Year")
                self.title =  block.title
                self.ParentPage = block
                return None
            except:
                self.getParentPage(block.parent)

    # =============================================

    # this class is to get the blocks from notion
    def __init__(self, errorsNumbers=0) -> None:
        # Errors
        self.errorsNumbers = errorsNumbers
        if self.errorsNumbers > 5:
            print("\033[91m" + "Error: To many errors" + "\033[0m")
            sys.exit()

        # Blocks that will be remembered
        self.icons2Remember = ['🧠', 'https://i.pinimg.com/564x/94/d2/bb/94d2bbf9c6370afca2b19c5f79b4d193.jpg', '🔴️']
        self.icons2RememberProb = ['https://i.pinimg.com/564x/dc/59/25/dc592556e1e37dc8d4f53d72d62b97fa.jpg', '🟡️']

        # Blocks
        self.Blocks = []
        self.PageBlocks = []
        self.limitBlocks = 5000
        self.N_Block2Remember = 5
        self.N_collectedBlocks = 0

        # Auth notion
        parser = argparse.ArgumentParser(description="Sample script with command-line arguments")
        parser.add_argument('--notionToken', required=True, help='Notion token argument')
        parser.add_argument('--mainDataBase', required=True, help='Main database argument')
        parser.add_argument('--piecesDatabase', required=True, help='Pieces database argument')

        parser.add_argument('--emailPass', required=True, help='Email password argument')
        parser.add_argument('--emailSender', required=True, help='Email sender argument')
        parser.add_argument('--emailReceiver', required=True, help='Email receiver argument')
        args = parser.parse_args()

        # important things
        self.email_pass = args.emailPass
        self.notion_token = args.notionToken

        self.thisFile = os.path.basename(__file__)
        self.thisFolder = os.path.dirname(os.path.abspath(__file__))
        self.notion_TOKEN = args.notionToken
        self.notion_PAGE = args.mainDataBase
        self.notion_PIECES = args.piecesDatabase

        # Get email keys
        self.emailPassword = args.emailPass
        self.emailSender = args.emailSender
        self.emailReceiver = args.emailReceiver

        # HTML
        self.EmailHTML = ""

        # Actions
        self.notionAuth() # notion auth
        self.getBlocks() # get all the blocks
        self.loopThroughBlocks()
        
        for block in self.Blocks:
            self.getHtmlForBlock(block) 

        try:
            self.getPieceBlock()
        except:
           pass

        self.createBodyOfEmail()

        self.sendEmail()
        
        # get all the blocks
        print("Finished")
        sys.exit(0)


    def notionAuth(self):
        try:
            self.client = NotionClient(token_v2=self.notion_TOKEN)  
            print("\033[92m" + "Notion Auth" + "\033[0m")
        except:
            # print in red
            print("\033[91m" + "Error: Notion Auth" + "\033[0m")
            self.sendErrorEmail("Notion Auth Error")
            sys.exit()
    

    def getBlocks(self):
        try:
            cv = self.client.get_collection_view(self.notion_PAGE)
            collections = cv.collection.get_rows(limit=self.limitBlocks)
            self.AllBlocks = random.sample(list(collections), len(collections))
        except:
            time.sleep(0.5)
            self.__init__(self.errorsNumbers + 1)


    def loopThroughBlocks(self):
        if len(self.AllBlocks) == 0:
            print("\033[91m" + "Error: No blocks" + "\033[0m")
            self.__init__(self.errorsNumbers + 1)
        for row in self.AllBlocks:
            try:
                self.PageBlocks = []
                if self.N_collectedBlocks < self.N_Block2Remember:
                    allChildrens = self.children_of(row)
                    allChildrens = random.sample(list(allChildrens), len(allChildrens))
                    for blockInsidePage in allChildrens:
                        if isinstance(blockInsidePage, CalloutBlock): # NOTE: Just callout blocks are to remember
                            if blockInsidePage.icon in self.icons2Remember: 
                                rememberBlockClass = self.RememberBlock(blockInsidePage)
                                self.PageBlocks.append(rememberBlockClass)
                                break ## this will make just one block per page
                            elif blockInsidePage.icon in self.icons2RememberProb and random.random() > 0.75:
                                rememberBlockClass = self.RememberBlock(blockInsidePage)
                                self.PageBlocks.append(rememberBlockClass)
                                break
                        else:
                            if self.searchForCallout(blockInsidePage):
                                break

                # select one block from the page
                if len(self.PageBlocks) > 0:
                    self.Blocks.append(random.choice(self.PageBlocks))
                    print("Selected block: " + str(self.Blocks[-1].title))
                    self.N_collectedBlocks += 1
            except Exception as e:
                print(f"The block not work: {e}")
                pass

                            
    def searchForCallout(self, block): #  NOTE: Just callout is remebered
        """
        This function will search for a callout block inside a page. This callout
        must have the icon in the list of icons2Remember.
        """
        childrens = self.children_of(block)
        for child in childrens:
            if isinstance(child, CalloutBlock):
                if child.icon in self.icons2Remember:
                    rememberBlockClass = self.RememberBlock(child)
                    self.PageBlocks.append(rememberBlockClass)
                elif child.icon in self.icons2RememberProb and random.random() > 0.75:
                    rememberBlockClass = self.RememberBlock(child)
                    self.PageBlocks.append(rememberBlockClass)
            else:
                self.searchForCallout(child)


    def children_of(self, parent):
        """
        This function will return all the childrens of a block.
        """
        try:
            children = parent.children
            allChildrens = []
            for child in children:
                allChildrens.append(child)
            return random.sample(list(allChildrens), len(allChildrens))
        except:
            return parent

    
    def getHtmlForBlock(self, block):
        """
        This function will convert one block of Notion to HTML.
        """

        if (len(block.childrens) != 0):
            print("Collected block has childrens")
            return None

        title = markdown.markdown(block.title)
        image = ""
        text = markdown.markdown(block.text)
        try:
            year = str(block.year[0])
        except:
            year = '____'
        author = block.author.replace('_', '')
        author = "_" + author + "_" # make italic
        authorYear = author + ' | ' + year
        if len(image) != 0:
            image_is_true = f'<img src={image} alt="{title}" width=75% height=75%>'
        else:
            image_is_true = ''
    
        # create markdown link for page_link with the name 'Link of the page'
        pageLink = f'[Link of the page]({block.url})'
        subtitle = authorYear + ' | ' + pageLink
        subtitle = markdown.markdown(subtitle.replace('\n', ''))
        html4Block = f"""
            <div>
                <header>
                    <div style="display: inline-block;">
                        <h4><b>{title}</b></h4><h6>{subtitle}</h6>
                    </div>
                </header> 
            </div>
            <p></p>
            <p>{text}</p>
            {image_is_true}
            <p></p>
            <hr>
            """
        self.EmailHTML += html4Block


    def getPieceBlock(self):
        # Access a database using the URL of the database page or the inline block
        AllPiecesOfComposers = self.client.get_collection_view(self.notion_PIECES)
        composerOfToday = AllPiecesOfComposers.collection.get_rows(limit=5000)
        permutedCollections = random.sample(list(composerOfToday), len(composerOfToday))
        randomComposer = random.choice(permutedCollections)
        composerName = randomComposer.title        
        composerPieces = randomComposer.children
        blockFounded = False
        for Obras in composerPieces:
            if isinstance(Obras, ColumnListBlock) and not blockFounded:
                self.children_of(Obras)
                self.PiecePageLink = Obras.get_browseable_url()
                id = Obras.id
                blocos = self.client.get_block(id)
                blocos_dentro  = self.children_of(blocos)
                for information in blocos_dentro:
                    id = information.id
                    informacoes = self.client.get_block(id)
                    callout = self.children_of(informacoes)
                    if callout is not None:
                        for callout_children in callout:
                            if isinstance(callout_children, CalloutBlock) and not blockFounded:
                                self.PieceName = callout_children.title
                                video_block_and_description = callout_children.children
                                for data in video_block_and_description:
                                    if isinstance(data, VideoBlock):
                                        self.PieceVideoLink = data.source
                                        blockFounded = True
                                    elif isinstance(data, CalloutBlock):
                                        self.PieceDescription = data.title
                                        pass
                                    
        pageLink = f'[Link of the page]({self.PiecePageLink})'
        subtitle = pageLink
        subtitle = markdown.markdown(subtitle.replace('\n', ''))
        VIDEO_TITULO =  markdown.markdown(composerName + ' | ' + self.PieceName)
        VIDEO_ID = parse_qs(urlparse(self.PieceVideoLink).query).get('v')[0]
        Link_da_thumbnail = f'https://img.youtube.com/vi/{VIDEO_ID}/0.jpg'
        youtube_link_video = f"""<!---------- Bloco de texto -->
        <div>
            <div>
                <header style="text-align: center;">
                    <h4><b>{VIDEO_TITULO}</b></h4> 
                    <h6>{subtitle} </h6>
                </header> 
            </div>
            <div style="text-align: center;">
                <a href={self.PieceVideoLink}>
                    <img alt="Obra Musical" src={Link_da_thumbnail} width=50% height=50%>    
                </a>
            </div>
            <p>{self.PieceDescription}</p>
        </div>
        """
        self.EmailHTML += youtube_link_video


    def createBodyOfEmail(self):
        """ 
        This function creates the HTML body of the email.
        """
        formato = '{font-family: "Raleway", sans-serif}'
        all_email = f"""
            <!DOCTYPE html>
            <html>
            <title>Remember</title>
            <meta charset="UTF-8">
            <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Raleway">
            <style>
            body,h1,h2,h3,h4,h5 {formato}
            </style>
            <body>
            <div style="max-width:1400px">
            {self.EmailHTML}
            </div>
            </body>
            </html>
            """
        self.emailBody = all_email

    
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


# ==================== CLASS ====================
# ==================== CLASS ====================

if __name__ == "__main__":
    BlocksToRemember()    



