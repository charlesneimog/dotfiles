from anytype import Anytype
from anytype import Object

from pdfannots import process_file
from pdfminer.layout import LAParams
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument

import os
import time


any = Anytype()
any.auth()

spaces = any.get_spaces()
pdf_space = spaces[0]

pdf_file = input("Input the filename of the PDF: ")
pdf_name = pdf_file.split("/")[-1]
pdf_name = pdf_name.split(".")[0]
try:
    laparams = LAParams()
    with open(pdf_file, "rb") as fp:
        doc = process_file(fp, laparams=laparams)
        parser = PDFParser(fp)
        document = PDFDocument(parser)
        metadata = document.info[0]  # metadata is a list of dictionaries

    all_notes = []
    for page in doc.pages:
        pageNumber = page.pageno
        for annot in page.annots:
            result = {}
            result["page"] = pageNumber
            result["text"] = annot.gettext(True)
            result["contents"] = annot.contents
            result["author"] = annot.author
            if result["text"] is not None:
                result["text"] = result["text"].replace("\n", " ")
                result["text"] = result["text"].replace("  ", " ")
            all_notes.append(result)
    note_type = pdf_space.get_type("Article")
    note_type.set_template("Article")
    new_object = Object()
    new_object.name = pdf_name
    new_object.icon = "🐍"
    new_object.description = "This is an object created from Python Api"
    for note in all_notes:
        new_object.body += f"> {note['text']} \n\n"
    created_object = pdf_space.create_object(new_object, note_type)
    time.sleep(0.1)
except:
    
    pass

