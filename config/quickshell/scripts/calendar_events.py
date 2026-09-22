"""Read Nextcloud events using the same Secret Service entry as TodoService.

CalDAV expands recurrence rules and exceptions on the server (RFC 4791 9.6.5).
Only Python's standard library is required; event creation uses conditional PUT requests.
"""

import base64
import datetime as dt
import json
import re
import subprocess
import sys
import uuid
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from zoneinfo import ZoneInfo

DAV = "{DAV:}"
CAL = "{urn:ietf:params:xml:ns:caldav}"


def parse_date(value, parameters):
    if len(value) == 8:
        return dt.datetime.strptime(value, "%Y%m%d").astimezone(), True
    utc = value.endswith("Z")
    date = dt.datetime.strptime(value.rstrip("Z"), "%Y%m%dT%H%M%S")
    if utc:
        date = date.replace(tzinfo=dt.timezone.utc)
    elif "TZID" in parameters:
        date = date.replace(tzinfo=ZoneInfo(parameters["TZID"].strip('"')))
    return date.astimezone(), False


def unescape(value):
    return re.sub(r"\\([nN,;\\])", lambda m: "\n" if m[1].lower() == "n" else m[1], value)


def parse_events(data, calendar):
    events = []
    fields = None
    depth = 0
    for line in re.sub(r"\r?\n[ \t]", "", data).splitlines():
        if line == "BEGIN:VEVENT":
            fields, depth = {}, 0
        elif fields is None:
            continue
        elif line == "END:VEVENT":
            if "DTSTART" in fields and fields.get("STATUS", ("", {}))[0] != "CANCELLED":
                start, all_day = parse_date(*fields["DTSTART"])
                end = start + (dt.timedelta(days=1) if all_day else dt.timedelta())
                if "DTEND" in fields:
                    end, _ = parse_date(*fields["DTEND"])
                elif "DURATION" in fields:
                    match = re.fullmatch(r"P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?", fields["DURATION"][0])
                    if match:
                        end = start + dt.timedelta(**dict(zip(
                            ("weeks", "days", "hours", "minutes", "seconds"),
                            (int(v or 0) for v in match.groups()))))
                events.append({
                    "title": unescape(fields.get("SUMMARY", ("Untitled event", {}))[0]),
                    "location": unescape(fields.get("LOCATION", ("", {}))[0]),
                    "calendar": calendar, "start": start.isoformat(),
                    "end": end.isoformat(), "allDay": all_day,
                })
            fields = None
        elif line.startswith("BEGIN:"):
            depth += 1
        elif line.startswith("END:"):
            depth -= 1
        elif depth == 0 and ":" in line:
            key, value = line.split(":", 1)
            parts = key.split(";")
            parameters = dict(p.split("=", 1) for p in parts[1:] if "=" in p)
            fields[parts[0].upper()] = (value, parameters)
    return events


def connect(server, username):
    secret = subprocess.run(
        ["secret-tool", "lookup", "service", "impasto-nextcloud", "username", username],
        capture_output=True, text=True, timeout=15, check=True).stdout.strip()
    if not secret:
        raise ValueError("Nextcloud password not found")
    auth = base64.b64encode(f"{username}:{secret}".encode()).decode()

    # Never forward credentials to an origin supplied in a calendar href.
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *args, **kwargs):
            return None

    opener = urllib.request.build_opener(NoRedirect())

    def request(method, href, body, create=False):
        url = urllib.parse.urljoin(server + "/", href)
        if urllib.parse.urlsplit(url)[:2] != urllib.parse.urlsplit(server)[:2]:
            raise ValueError("Unexpected calendar server")
        req = urllib.request.Request(url, data=body.encode(), method=method, headers={
            "Authorization": "Basic " + auth, "Depth": "1",
            "Content-Type": "text/calendar; charset=utf-8" if create else "application/xml; charset=utf-8",
            **({"If-None-Match": "*"} if create else {})})
        with opener.open(req, timeout=25) as response:
            return None if create else ET.fromstring(response.read())

    return request


def discover(request, username):
    discovery = request("PROPFIND", "/remote.php/dav/calendars/" + urllib.parse.quote(username) + "/",
        '<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">'
        '<d:prop><d:displayname/><d:resourcetype/><d:current-user-privilege-set/><c:supported-calendar-component-set/>'
        '</d:prop></d:propfind>')
    calendars = []
    for response in discovery.findall(DAV + "response"):
        props = [p.find(DAV + "prop") for p in response.findall(DAV + "propstat")
                 if " 200 " in p.findtext(DAV + "status", "")]
        if not any(p.find(".//" + CAL + "calendar") is not None for p in props):
            continue
        if not any(c.get("name") == "VEVENT" for p in props for c in p.iter(CAL + "comp")):
            continue
        href = response.findtext(DAV + "href")
        name = next((p.findtext(DAV + "displayname") for p in props if p.findtext(DAV + "displayname")), "Calendar")
        writable = any(p.find(".//" + DAV + "bind") is not None
                       or p.find(".//" + DAV + "write") is not None
                       or p.find(".//" + DAV + "all") is not None for p in props)
        calendars.append({"href": href, "name": name, "writable": writable})
    return calendars


def fetch(server, username, start, end):
    request = connect(server, username)
    calendars = discover(request, username)
    events = []
    for calendar in calendars:
        href, name = calendar["href"], calendar["name"]
        result = request("REPORT", href,
            '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">'
            f'<d:prop><c:calendar-data><c:expand start="{start}" end="{end}"/>'
            '</c:calendar-data></d:prop><c:filter><c:comp-filter name="VCALENDAR">'
            f'<c:comp-filter name="VEVENT"><c:time-range start="{start}" end="{end}"/>'
            '</c:comp-filter></c:comp-filter></c:filter></c:calendar-query>')
        for propstat in result.iter(DAV + "propstat"):
            if " 200 " not in propstat.findtext(DAV + "status", ""):
                raise ValueError("Could not read a Nextcloud calendar")
            for data in propstat.iter(CAL + "calendar-data"):
                events.extend(parse_events(data.text or "", name))
    return {"events": sorted(events, key=lambda event: (event["start"], event["title"])),
            "calendars": calendars}


def escape(value):
    return str(value).replace("\\", "\\\\").replace("\r\n", "\n").replace("\r", "\n").replace("\n", "\\n").replace(";", "\\;").replace(",", "\\,")


def event_document(event):
    title = str(event.get("title", "")).strip()
    if not title:
        raise ValueError("Enter an event title")
    all_day = event.get("allDay", False)
    if all_day:
        start = dt.date.fromisoformat(event["startDate"])
        # The form uses inclusive dates; iCalendar uses an exclusive end.
        last = dt.date.fromisoformat(event["endDate"])
        if last < start:
            raise ValueError("End date must not precede start date")
        end = last + dt.timedelta(days=1)
        dates = ["DTSTART;VALUE=DATE:" + start.strftime("%Y%m%d"),
                 "DTEND;VALUE=DATE:" + end.strftime("%Y%m%d")]
    else:
        start = dt.datetime.fromisoformat(event["startDate"] + "T" + event["startTime"]).astimezone()
        end = dt.datetime.fromisoformat(event["endDate"] + "T" + event["endTime"]).astimezone()
        if end <= start:
            raise ValueError("End time must be after start time")
        dates = ["DTSTART:" + start.astimezone(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
                 "DTEND:" + end.astimezone(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")]
    uid = str(uuid.uuid4())
    lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Impasto//Calendar//EN",
             "BEGIN:VEVENT", "UID:" + uid,
             "DTSTAMP:" + dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
             *dates, "SUMMARY:" + escape(title),
             "LOCATION:" + escape(event.get("location", "")), "END:VEVENT", "END:VCALENDAR"]
    # Fold by UTF-8 octets without splitting characters.
    folded = []
    for line in lines:
        part = ""
        for char in line:
            if len((part + char).encode()) > 75:
                folded.append(part)
                part = " "
            part += char
        folded.append(part)
    return uid, "\r\n".join(folded) + "\r\n"


def create_event(server, username, event):
    uid, document = event_document(event)
    request = connect(server, username)
    target = next((c for c in discover(request, username)
                   if c["href"] == event.get("calendar") and c["writable"]), None)
    if target is None:
        raise ValueError("Choose a writable calendar")
    request("PUT", target["href"].rstrip("/") + "/" + uid + ".ics", document, create=True)
    return {"created": True}


def main():
    try:
        server, username, *args = sys.argv[1:]
        if args == ["create"]:
            result = create_event(server, username, json.loads(sys.stdin.readline()))
        else:
            start, end = args
            for value in (start, end):
                dt.datetime.strptime(value, "%Y%m%dT%H%M%SZ")
            result = fetch(server, username, start, end)
        print(json.dumps(result))
    except urllib.error.HTTPError as error:
        print(json.dumps({"error": f"Nextcloud returned HTTP {error.code}"}))
    except ValueError:
        print(json.dumps({"error": "Check the event title, dates, times and selected calendar."}))
    except Exception:
        print(json.dumps({"error": "Could not reach Nextcloud. Check your connection and saved credentials."}))


if __name__ == "__main__":
    main()
