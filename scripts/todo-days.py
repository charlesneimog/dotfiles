# pip install git+https://github.com/wsykala/notion-py.git
from notion.client import NotionClient
import sys
import argparse
from datetime import date

dayNumber = date.today().day
print(dayNumber)

parser = argparse.ArgumentParser(description="Sample script with command-line arguments")
parser.add_argument('--notionToken', required=True, help='Notion token argument')
parser.add_argument('--TodoBase', required=True, help='Main database argument')
args = parser.parse_args()


# get notion keys
TOKEN = args.notionToken
DATABASE = args.TodoBase

try:                                                
    client = NotionClient(token_v2=TOKEN)
    print("Notion client created")
except:                                           
    print('TOKEN not working!') 
    sys.exit()                                   


cv = client.get_collection_view(DATABASE)
for row in cv.collection.get_rows(limit=500):
    row.set_property('Todo', False)
    

