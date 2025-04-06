import notion
from notion.client import NotionClient
# from notion.block import CollectionViewBlock, BulletedListBlock, CodeBlock, CollectionViewBlock, BulletedListBlock
import markdown
import json
import random 
import sys
import os
import time
from urllib.parse import parse_qs, urlparse




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
        self.icons2Remember = ['🧠', 'https://i.pinimg.com/564x/94/d2/bb/94d2bbf9c6370afca2b19c5f79b4d193.jpg']
        self.icons2RememberProb = ['https://i.pinimg.com/564x/dc/59/25/dc592556e1e37dc8d4f53d72d62b97fa.jpg']
        self.thisBlockLevel = 0
        self.thisBlockIsInsideCallout = False

        # Blocks
        self.Blocks = []
        self.PageBlocks = []
        self.limitBlocks = 500
        self.N_Block2Remember = 8
        self.N_collectedBlocks = 0

        # Auth notion
        self.thisFile = os.path.basename(__file__)
        self.thisFolder = os.path.dirname(os.path.abspath(__file__))
        tokenFile = self.thisFolder + '/TOKENS.token'
        jsonFile = open(tokenFile)
        self.jsonData = json.load(jsonFile)
        self.notion_TOKEN = self.jsonData['notion']['token']
        self.notion_PAGE = self.jsonData['notion']['mainDatabase']
        self.notion_PIECES = self.jsonData['notion']['piecesDatabase']

        # Get email keys
        self.emailPassword = self.jsonData['email']['pass']
        self.emailSender = self.jsonData['email']['sender']
        self.emailReceiver = self.jsonData['email']['receiver']

        # HTML
        self.EmailHTML = ""

        # Actions
        self.notionAuth() # notion auth
        self.getBlocks() # get all the blocks
        self.loopThroughBlocks()
        
      
        # get all the blocks
        print("Finished")
        sys.exit()


    def notionAuth(self):
        try:
            self.client = NotionClient(token_v2=self.notion_TOKEN)  
            print("\033[92m" + "Notion Auth" + "\033[0m")
        except:
            # print in red
            print("\033[91m" + "Error: Notion Auth" + "\033[0m")
            sys.exit()
    

    def getBlocks(self):
        try:
            cv = self.client.get_collection_view(self.notion_PAGE)
            self.AllBlocks = cv.collection.get_rows(limit=self.limitBlocks)
        except:
            time.sleep(1)
            self.__init__(self.errorsNumbers + 1)


    def loopThroughBlocks(self):
        if len(self.AllBlocks) == 0:
            print("\033[91m" + "Error: No blocks" + "\033[0m")
            self.__init__(self.errorsNumbers + 1)
        value = 0
        for row in self.AllBlocks:
            RowTitle = row.title
            print("\033[92m" + "Row: " + RowTitle + "\033[0m")
            # open one md file for each row
            with open(self.thisFolder + "/mdFiles/" + RowTitle + ".md", "w") as mdFile:
                allChildrens = self.children_of(row)
                for blockInsidePage in allChildrens:
                    self.translateTheBlocks(mdFile, blockInsidePage)

            value += 1
            if value == 5:
                sys.exit()
    

    def translateTheBlocks(self, mdFile, blockInsidePage):
        if isinstance(blockInsidePage, notion.block.CalloutBlock): # NOTE: Just callout blocks are to remember
            self.translate_CalloutBlock(mdFile, blockInsidePage)

        elif isinstance(blockInsidePage, notion.block.PageBlock):
            # print in red
            print("\033[91m" + "Error: PageBlock not supported" + "\033[0m")

        elif isinstance(blockInsidePage, notion.block.ColumnListBlock):
            print("\033[91m" + "Error: ColumnListBlock not supported" + "\033[0m")

        elif isinstance(blockInsidePage, notion.block.ImageBlock):
            print("\033[91m" + "Error: ImageBlock not supported" + "\033[0m")

        elif isinstance(blockInsidePage, notion.block.VideoBlock):
            print("\033[91m" + "Error: VideoBlock not supported" + "\033[0m")

        elif isinstance(blockInsidePage, notion.block.TextBlock):
            self.translate_TextBlock(mdFile, blockInsidePage)

        elif isinstance(blockInsidePage,  notion.block.CollectionViewBlock):
            print("\033[91m" + "Error: CollectionViewBlock not supported" + "\033[0m")

        elif isinstance(blockInsidePage,  notion.block.BulletedListBlock):
            self.translate_BulletedListBlock(mdFile, blockInsidePage)

        elif isinstance(blockInsidePage, notion.block.DividerBlock):
            tabs = ""
            for _ in range(self.thisBlockLevel):
                tabs += "\t"
            mdFile.write(tabs + "--------\n")

        elif isinstance(blockInsidePage,  notion.block.HeaderBlock):
            self.translate_HeaderBlock(mdFile, blockInsidePage, 1)

        elif isinstance(blockInsidePage,  notion.block.SubheaderBlock):
            self.translate_HeaderBlock(mdFile, blockInsidePage, 2)

        elif isinstance(blockInsidePage, notion.block.SubsubheaderBlock):
            self.translate_HeaderBlock(mdFile, blockInsidePage, 3)
            # print in blue
            print("\033[94m" + "SubsubheaderBlock" + "\033[0m")

        elif isinstance(blockInsidePage,  notion.block.ToggleBlock):
            print("\033[91m" + "Error: ToggleBlock not supported" + "\033[0m")

        elif isinstance(blockInsidePage,  notion.block.QuoteBlock):
            print("\033[91m" + "Error: QuoteBlock not supported" + "\033[0m")

        elif isinstance(blockInsidePage,  notion.block.CodeBlock):
            print("\033[91m" + "Error: CodeBlock not supported" + "\033[0m")

        elif isinstance(blockInsidePage,  notion.block.NumberedListBlock):
            print("\033[91m" + "Error: NumberedListBlock not supported" + "\033[0m")
        
        elif isinstance(blockInsidePage,  notion.block.TodoBlock):
            self.translate_TodoBlock(mdFile, blockInsidePage)

        elif isinstance(blockInsidePage,  notion.block.BookmarkBlock):
            print("\033[91m" + "Error: BookmarkBlock not supported" + "\033[0m")
        
        else:
            # print in red the class of the block
            print("\033[91m" + "Error: " + blockInsidePage.__class__.__name__ + "\033[0m")
                                        
    def translate_CalloutBlock(self, mdFile, block):
        """
        This function will translate a CalloutBlock to a mdFile.
        """
        self.thisBlockIsInsideCallout = True
        allChildrens = self.children_of(block)
        if len(allChildrens) > 0:
            parentBlockLevel = self.thisBlockLevel
            parentTabs = ""
            for _ in range(parentBlockLevel):
                parentTabs += "\t"
            if self.thisBlockIsInsideCallout:
                parentTabs += "> "
            text = block.title
            # check if there is paragraphs inside the block
            paragraphs = text.split("\n\n")
            mdFile.write(parentTabs + "[!note] \n")
            mdFile.write("> \n")
            for paragraph in paragraphs:
                mdFile.write(parentTabs + paragraph + "\n")
                mdFile.write("> \n")


        else:
            print("CalloutBlock without childrens")
            text = block.title
            parentBlockLevel = self.thisBlockLevel
            parentTabs = ""
            for _ in range(parentBlockLevel):
                parentTabs += "\t"
            if self.thisBlockIsInsideCallout:
                parentTabs += "> "
            paragraphs = text.split("\n\n")
            mdFile.write(parentTabs + "[!note] \n")
            mdFile.write("> \n")
            for paragraph in paragraphs[1:]:
                mdFile.write(parentTabs + paragraph + "\n")
                mdFile.write("> \n")
        self.thisBlockIsInsideCallout = False
        

    def translate_HeaderBlock(self, mdFile, block, level):
        """
        This function will translate a CalloutBlock to a mdFile.
        """
        allChildrens = self.children_of(block)
        if len(allChildrens) != 0:
            parentBlockLevel = self.thisBlockLevel
            parentTabs = ""
            for _ in range(parentBlockLevel):
                parentTabs += "\t"
            if self.thisBlockIsInsideCallout:
                parentTabs += "> "
            levelChar = " "
            for _ in range(level):
                levelChar += "#"
            mdFile.write(parentTabs + levelChar + block.title + "\n")
            for child in allChildrens:
                self.thisBlockLevel += 1
                self.translateTheBlocks(mdFile, child)
                self.thisBlockLevel -= 1

        else:
            levelChar = ""
            for _ in range(level):
                levelChar += "#"
            mdFile.write(levelChar + " " + block.title + "\n")


    def translate_TodoBlock(self, mdFile, block):
        """
        This function will translate a CalloutBlock to a mdFile.
        """
        allChildrens = self.children_of(block)
        if len(allChildrens) != 0:
            parentBlockLevel = self.thisBlockLevel
            parentTabs = ""
            for _ in range(parentBlockLevel):
                parentTabs += "\t"
            if self.thisBlockIsInsideCallout:
                parentTabs += "> "
            mdFile.write(parentTabs + "- [ ] " + block.title + "\n")
            for child in allChildrens:
                self.thisBlockLevel += 1
                self.translateTheBlocks(mdFile, child)
                self.thisBlockLevel -= 1
        else:
            level = self.thisBlockLevel
            tabs = ""
            for _ in range(level):
                tabs += "\t"
            if self.thisBlockIsInsideCallout:
                tabs += "> "
            mdFile.write(tabs + "- [ ] " + block.title + "\n")




    def translate_TextBlock(self, mdFile, block):
        """
        This function will translate a CalloutBlock to a mdFile.
        """
        allChildrens = self.children_of(block)
        if len(allChildrens) != 0:
            parentBlockLevel = self.thisBlockLevel
            parentTabs = ""
            for _ in range(parentBlockLevel):
                parentTabs += "\t"
            if self.thisBlockIsInsideCallout:
                parentTabs += "> "
            mdFile.write(parentTabs + "" + block.title + "\n")
            for child in allChildrens:
                self.thisBlockLevel += 1
                self.translateTheBlocks(mdFile, child)
                self.thisBlockLevel -= 1

        else:
            level = self.thisBlockLevel
            tabs = ""
            for _ in range(level):
                tabs += "\t"
            if self.thisBlockIsInsideCallout:
                tabs += "> "
            mdFile.write(tabs + "" + block.title + "\n")
            

    def translate_BulletedListBlock(self, mdFile, block):
        """
        This function will translate a CalloutBlock to a mdFile.
        """
        allChildrens = self.children_of(block)
        if len(allChildrens) != 0:
            parentBlockLevel = self.thisBlockLevel
            parentTabs = ""
            for _ in range(parentBlockLevel):
                parentTabs += "\t"
            if self.thisBlockIsInsideCallout:
                parentTabs += "> "
            mdFile.write(parentTabs + "- " + block.title + "\n")
            for child in allChildrens:
                self.thisBlockLevel += 1
                self.translateTheBlocks(mdFile, child)
                self.thisBlockLevel -= 1

        else:
            level = self.thisBlockLevel
            tabs = ""
            for _ in range(level):
                tabs += "\t"
            if self.thisBlockIsInsideCallout:
                tabs += "> "
            mdFile.write(tabs + "- " + block.title + "\n")





    def children_of(self, parent):
        """
        This function will return all the childrens of a block.
        """
        try:
            children = parent.children
            allChildrens = []
            for child in children:
                allChildrens.append(child)
            return allChildrens
        except:
            return parent

    





# ==================== CLASS ====================
# ==================== CLASS ====================



if __name__ == "__main__":
    BlocksToRemember()    





