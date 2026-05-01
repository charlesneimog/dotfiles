import requests
import json
from pathlib import Path
from dotenv import load_dotenv
import os
from loguru import logger
import smtplib
from email.mime.text import MIMEText

from pprint import pprint

os.chdir(os.path.dirname(__file__))


class JournalTracker:
    BASE_URL = "https://api.openalex.org/works"

    def __init__(self, issns, json_path="papers.json", per_journal=5):
        if not os.path.exists(".env"):
            logger.warning(".env file is missing")

        self.issns = issns
        self.json_path = Path(json_path)
        self.per_journal = per_journal
        self.db = self._load()

        load_dotenv()

        self.myemail = os.getenv("MYEMAIL")
        self.email = os.getenv("SERVEREMAIL")
        self.password = os.getenv("SERVERPASSWORD")

    def _load(self):
        if self.json_path.exists():
            return json.loads(self.json_path.read_text())
        return {}

    def _save(self):
        self.json_path.write_text(json.dumps(self.db, indent=2, ensure_ascii=False))

    def reconstruct_abstract(self, abstract_inverted_index):
        """
        Reconstruct abstract text from OpenAlex's inverted index format.

        The index is a dict: { "word": [position1, position2, ...] }
        Returns empty string if no abstract available.
        """
        if not abstract_inverted_index:
            return ""

        # Create list of (position, word) tuples
        word_positions = []
        for word, positions in abstract_inverted_index.items():
            for pos in positions:
                word_positions.append((pos, word))

        # Sort by position to reconstruct original order
        word_positions.sort(key=lambda x: x[0])

        # Join words with spaces
        return " ".join(word for pos, word in word_positions)

    def _fetch_latest(self, issn):
        params = {
            "filter": f"primary_location.source.issn:{issn}",
            "sort": "publication_date:desc",
            "per-page": self.per_journal,
        }

        r = requests.get(self.BASE_URL, params=params, timeout=20)
        r.raise_for_status()
        data = r.json()

        results = []
        for w in data["results"]:
            # Get journal name
            source_name = None
            if w.get("primary_location") and w["primary_location"].get("source"):
                source_name = w["primary_location"]["source"].get("display_name")

            if not source_name and w.get("locations"):
                for loc in w["locations"]:
                    if loc.get("source") and loc["source"].get("display_name"):
                        source_name = loc["source"]["display_name"]
                        break

            # RECONSTRUCT abstract from inverted index
            abstract = self.reconstruct_abstract(w.get("abstract_inverted_index"))

            # Optional: truncate very long abstracts
            if abstract and len(abstract) > 500:
                abstract = abstract[:500] + "..."

            results.append(
                {
                    "title": w.get("title"),
                    "date": w.get("publication_date"),
                    "doi": w.get("doi"),
                    "id": w.get("id"),
                    "source": source_name,
                    "abstract": abstract,
                    "authors": [
                        a["author"]["display_name"]
                        for a in w.get("authorships", [])[:3]
                    ],
                }
            )
        return results

    def _merge(self, issn, new_papers):
        existing = self.db.get(issn, [])
        index = {}
        for p in existing:
            key = p.get("doi") or p.get("id")
            if key:
                index[key] = p

        for p in new_papers:
            key = p.get("doi") or p.get("id")
            if key:
                index[key] = p

        merged = sorted(
            index.values(), key=lambda x: x.get("date") or "", reverse=True
        )[: self.per_journal]

        self.db[issn] = merged

    def _get_new_papers(self, issn, fetched):
        existing = self.db.get(issn, [])

        existing_keys = {
            (p.get("doi") or p.get("id"))
            for p in existing
            if (p.get("doi") or p.get("id"))
        }

        new = []
        for p in fetched:
            key = p.get("doi") or p.get("id")
            if key and key not in existing_keys:
                new.append(p)

        return new

    def build_email(self, new_data):
        html = [
            "<html>",
            "<head>",
            "<style>",
            "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; line-height: 1.5; color: #1a1a1a; max-width: 800px; margin: 0 auto; padding: 20px; }",
            "h2 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 8px; }",
            "h3 { color: #34495e; margin-top: 24px; margin-bottom: 8px; font-size: 18px; }",
            ".journal-header { background: #f8f9fa; padding: 12px 16px; border-radius: 8px; margin-top: 24px; }",
            ".article { margin-bottom: 24px; padding: 16px; border-left: 3px solid #3498db; background: #ffffff; }",
            ".article-title { font-size: 16px; font-weight: 600; margin-bottom: 6px; color: #2c3e50; }",
            ".article-meta { font-size: 13px; color: #7f8c8d; margin-bottom: 8px; }",
            ".article-authors { font-size: 13px; color: #7f8c8d; margin-bottom: 8px; font-style: italic; }",
            ".abstract { font-size: 14px; color: #555; margin-top: 10px; padding-top: 8px; border-top: 1px solid #ecf0f1; }",
            ".abstract-label { font-weight: 600; font-size: 12px; text-transform: uppercase; color: #3498db; margin-bottom: 4px; }",
            ".abstract-text { margin: 0; }",
            "a { color: #3498db; text-decoration: none; }",
            "a:hover { text-decoration: underline; }",
            ".link { font-size: 13px; margin-top: 8px; }",
            "hr { border: none; border-top: 1px solid #ecf0f1; margin: 8px 0; }",
            "</style>",
            "</head>",
            "<body>",
            "<h2>📚 New Journal Articles</h2>",
        ]

        for issn, papers in new_data.items():
            journal_name = papers[0].get("source") or f"Journal (ISSN: {issn})"
            html.append(
                f'<div class="journal-header"><strong>📖 {journal_name}</strong></div>'
            )

            for p in papers:
                if not p.get("title"):
                    continue

                # Format date
                date_str = p.get("date", "No date")
                if date_str and date_str != "No date":
                    date_str = date_str.split("-")[0] if len(date_str) > 4 else date_str

                # Get DOI link
                doi = p.get("doi")
                link = f"https://doi.org/{doi}" if doi else p.get("id", "#")

                html.append('<div class="article">')
                html.append(f'<div class="article-title">{p["title"]}</div>')

                # Authors
                if p.get("authors"):
                    authors_str = ", ".join(p["authors"][:3])
                    if len(p["authors"]) > 3:
                        authors_str += f" et al."
                    html.append(f'<div class="article-authors">✍️ {authors_str}</div>')

                html.append(
                    f'<div class="article-meta">📅 {date_str} • 🔗 DOI: {doi if doi else "N/A"}</div>'
                )

                # Abstract (if available)
                if p.get("abstract"):
                    html.append('<div class="abstract">')
                    html.append('<div class="abstract-label">Abstract</div>')
                    # Truncate abstract to 300 chars if needed
                    abstract_text = p["abstract"][:300] + (
                        "..." if len(p["abstract"]) > 300 else ""
                    )
                    html.append(f'<div class="abstract-text">{abstract_text}</div>')
                    html.append("</div>")

                html.append(
                    f'<div class="link">🔗 <a href="{link}">Read full article →</a></div>'
                )
                html.append("</div>")

            html.append("<hr>")

        html.append("</body></html>")
        return "".join(html)

    def send_email(self, subject, body):
        msg = MIMEText(body, "html")
        msg["Subject"] = subject
        msg["From"] = self.email
        msg["To"] = self.myemail

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(self.email, self.password)
            server.send_message(msg)

    def update(self):
        all_new = {}

        for issn in self.issns:
            try:
                papers = self._fetch_latest(issn)
                new = self._get_new_papers(issn, papers)

                if new:
                    all_new[issn] = new

                self._merge(issn, papers)

            except Exception as e:
                logger.exception(f"{issn} failed")

        self._save()
        return all_new

    def get(self, issn):
        return self.db.get(issn, [])


tracker = JournalTracker(
    issns=[
        "2317-9937",  # vortex
        "2317-6776",  # hodie
        "2318-891X",  # percepta
        "2525-5541",  # musica theorica
        "1531-5169",  # computer music
        "1469-8153",  # organized sound
        "1531-4812",  # leonardo music journal
        "1744-5027",  # journal of new music research
        "1477-2256",  # contemporary music review
    ],
    json_path="papers.json",
    per_journal=5,
)

new_data = tracker.update()
if new_data:
    body = tracker.build_email(new_data)
    tracker.send_email("New journal articles", body)
else:
    logger.info("No new articles")
