# pip install git+https://github.com/wsykala/notion-py.git
from notion.client import NotionClient
import random
import json 
import urllib
import sys
import argparse
from unidecode import unidecode
from datetime import date
from crossref.restful import Works

dayNumber = date.today().day

# just execute if number is even
if dayNumber % 2 != 0:
    pass
else:
    sys.exit(0)

parser = argparse.ArgumentParser(description="Sample script with command-line arguments")
parser.add_argument('--notionToken', required=True, help='Notion token argument')
parser.add_argument('--mainDataBase', required=True, help='Main database argument')
args = parser.parse_args()


# get notion keys
TOKEN = args.notionToken
DATABASE = args.mainDataBase

try:                                                
    client = NotionClient(token_v2=TOKEN)
    print("Notion client created")
except:                                           
    print('TOKEN not working!') 
    sys.exit()                                   


cv = client.get_collection_view(DATABASE)
for row in cv.collection.get_rows(limit=600):
    tipo_list = row.get_property("tipo")
    name = row.get_property("name")
    try:
        tipo = tipo_list[0]
    except:
        print('A categoria da página "' + name + '" não esta definida!')
        tipo = None
    icon = row.icon
    if icon is not None and tipo != 'Livro' and tipo != 'Capítulo de Livro' and tipo != 'Artigo':
        pass
    else:
        if tipo == 'Vídeo':
            row.icon = 'https://cdn-icons-png.flaticon.com/512/183/183606.png'
            print(f'Icone para Vídeo')
            print(f'Nome: {name}')
        
        ## LIVRO ##
        elif tipo == 'Livro' or tipo == 'Capítulo de Livro':
            bookIcon = row.icon
            if bookIcon is None or bookIcon == '' or bookIcon == 'https://cdn0.iconfinder.com/data/icons/zlico-education-1-lineal-color/64/Open_Book_1-512.png':
                row.cover = 'https://wallpapercave.com/wp/wp2045946.jpg'
                try: 
                    name = unidecode(name)
                    BOOK_TITLE = name
                    base_api_link = "https://www.googleapis.com/books/v1/volumes?q="
                    mystring = BOOK_TITLE.replace(' ', '%20')
                    user_input = mystring
                    url = base_api_link + user_input
                    with urllib.request.urlopen(url) as f:
                        text = f.read()
                    decoded_text = text.decode("utf-8", errors="ignore")
                    obj = json.loads(decoded_text) # deserializes decoded_text to a Python object
                    volume_info = obj["items"][0]
                    volume_info_inside = volume_info["volumeInfo"]
                    try:
                        BOOK_COVER = volume_info_inside["imageLinks"]["thumbnail"]
                    except:
                        # print link in blue
                        print('\033[94m' + url + '\033[0m')
                        BOOK_COVER = 'https://cdn0.iconfinder.com/data/icons/zlico-education-1-lineal-color/64/Open_Book_1-512.png'
                    row.cover = BOOK_COVER
                    row.icon = BOOK_COVER
                except Exception as e:
                    print("Error to get book cover: " + str(e))
                    row.icon = 'https://cdn0.iconfinder.com/data/icons/zlico-education-1-lineal-color/64/Open_Book_1-512.png'
                    print('\033[91mIcone para LIVRO definido - SEM CAPA\033[0m')
                    # print(f'Nome: {name}')


        elif tipo == 'Palestras':
            row.icon = random.choice(['https://png.pngtree.com/png-vector/20190226/ourlarge/pngtree-vector-speech-vector-icon-png-image_705773.jpg', 'https://library.kissclipart.com/20180920/ie/kissclipart-public-speaking-clipart-public-speaking-speech-com-935663d57a0bdd1e.png'])
            row.cover = 'https://wallpaperaccess.com/full/1655790.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')

        elif tipo == 'Artigo':
            row.icon = 'https://cdn-icons-png.flaticon.com/512/1643/1643231.png'
            row.cover = 'https://wallpapercave.com/wp/wp3124740.jpg'
            authors = row.get_property("Author")
            # print in REd the authors
            if authors is None or authors == []:
                # update info using Doi:
                try:
                    DOI_Paper = Works()
                    doi = row.get_property("DOI")
                    print(doi)
                    doi = doi.replace('https://doi.org/', '')
                    thisPaper = DOI_Paper.doi(doi)
                    if thisPaper is not None:
                        authors = thisPaper['author']
                        ano = thisPaper['created']['date-parts'][0][0]
                        row.set_property('Year', ano)
                        AuthorsList = []
                        for author in authors:
                            AuthorsList.append(author['given'] + ' ' + author['family'])
                        row.set_property('Author', authors)
                    else:
                        print('DOI not found')
                        pass
                except Exception as e:
                    print('\033[91m' + f'Error to get info about DOI: {e}' + '\033[0m')
                    pass
        elif tipo == 'Aulas':
            row.icon = 'https://cdn2.iconfinder.com/data/icons/e-learning-17/96/timetable_classes_school_schedule-512.png'
            row.cover = 'https://png.pngtree.com/thumb_back/fh260/background/20200809/pngtree-simple-back-to-school-background-with-green-color-image_390182.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
        elif tipo == 'Memória':
            row.icon = 'https://thumbs.dreamstime.com/b/nbrain-memory-digital-brain-line-vector-icon-which-can-easily-modify-editn-brain-memory-digital-brain-line-vector-icon-which-173292475.jpg'
            row.cover = 'https://i.pinimg.com/736x/b8/13/d6/b813d6df1a2698410dd9efbe179b4f47.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
        elif tipo == 'Workshops':
            row.icon = 'https://st2.depositphotos.com/3616015/5362/v/950/depositphotos_53625087-stock-illustration-speaker-at-business-workshop-flat.jpg'
            row.cover = 'https://images.ctfassets.net/a6zo0szqvm4a/4206xsMAsXBGDTkf7wVsXL/288b46a258193dc089b4b16d451308e6/Collaborative_workshop_meta2.png'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
        elif tipo == 'Verbetes': 
            row.icon = 'https://cdn-icons-png.flaticon.com/512/2178/2178189.png'
            row.cover = 'https://wallpaperaccess.com/full/84248.png'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
        elif tipo == 'Artigos online':
            row.icon = 'https://cdn-icons-png.flaticon.com/512/3696/3696925.png'
            row.cover = 'https://i.pinimg.com/originals/bd/a5/be/bda5be61177acdb5fd46c3219f8b81a0.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
        elif tipo == 'Tese':
            row.icon = 'https://cdn-icons-png.flaticon.com/512/648/648137.png'
            row.cover = 'https://i.ytimg.com/vi/mDEw8J-FDIU/maxresdefault.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
        elif tipo == 'Reportagens':
            row.icon = 'https://st.depositphotos.com/1432405/53899/v/600/depositphotos_538994360-stock-illustration-laptop-actualization-icon-color-outline.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
            row.cover = 'https://cdn.theatlantic.com/media/img/photo/2021/12/2021-hubble-space-telescope-advent/Advent_01_1EVT1EV3DQG5MQ-1/original.jpg'
        elif tipo == 'Documentação de Algoritmos':
            row.icon = 'https://cdn-icons-png.flaticon.com/512/1119/1119005.png'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
            row.cover = 'http://www.nasa.gov/sites/default/files/thumbnails/image/potw2120a.jpg'
        elif tipo == 'Anotações':
            row.icon = 'https://icon-icons.com/downloadimage.php?id=93762&root=1381/ICO/512/&file=gnomestickynotesapplet_93762.ico'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
            row.cover = 'https://wallpaperaccess.com/full/54547.jpg'
            row.cover = 'https://wallpaperaccess.com/full/3382403.jpg'
        elif tipo == 'BrainStore':
            row.icon = 'https://cdn-icons-png.flaticon.com/512/3775/3775731.png'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
            row.cover = 'https://wallpaperaccess.com/full/3382398.jpg'
        elif tipo == 'Lembretes':
            row.icon = 'https://cdn-icons-png.flaticon.com/512/1792/1792931.png'
            row.cover = 'https://www.mundoecologia.com.br/wp-content/gallery/bufo-real/Bufo-Real-5.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
            row.cover = 'https://th-thumbnailer.cdn-si-edu.com/6iVpfZGfNCq0noV27oBRhTX_OwA=/1072x720/filters:no_upscale()/https://tf-cmsv2-smithsonianmag-media.s3.amazonaws.com/filer/Japanese-Bird-Print-Edo-470.jpg'
        elif tipo == 'NEIMOG':
            row.icon = 'https://thumbs.dreamstime.com/b/me-myself-icon-149342282.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
            row.cover = 'https://ychef.files.bbci.co.uk/976x549/p00xnqmc.jpg'
        elif tipo == 'Seminários':
            row.icon = 'https://i.pinimg.com/564x/d0/32/21/d0322161f7f9a316ceaa89792abc74fe.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')
            row.cover = 'https://ychef.files.bbci.co.uk/976x549/p00xnqmc.jpg'

        elif tipo == 'Coleções':
            row.icon = 'https://i.pinimg.com/564x/d0/32/21/d0322161f7f9a316ceaa89792abc74fe.jpg'
            print(f'Icone para {tipo} definido')
            print(f'Nome: {name}')

        else:
            print(f'Tipo não encontrado: {tipo}')
