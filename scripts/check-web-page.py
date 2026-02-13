#!/home/neimog/.config/miniconda3.dir/bin/python

import os

try:
    import requests
    import unicodedata
    import yaml
    from bs4 import BeautifulSoup
except:
    os.system('notify-send "Failed to check pages, missing some package"')
    raise Exception("Something is wrong")


os.chdir(os.path.dirname(__file__))

def normalize(text):
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    return text.lower()

def get_page_text(url):
    resp = requests.get(url, timeout=10)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")
    for tag in soup(["script", "style"]):
        tag.decompose()
    return normalize(soup.get_text(separator=" "))


try:
    with open("webpage.yaml", "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)
    for item in config["checks"]:
        url = item["url"]
        page_text = get_page_text(url)

        for name in item["names"]:
            found = normalize(name) in page_text
            status = "FOUND" if found else "not found"
            if found:
                os.system(f'notify-send "Found {name} in page: {url}"')
            print(f"{name} -> {status} @ {url}")
except Exception as e:
    print(e)
    os.system('notify-send "Failed to check pages"')

