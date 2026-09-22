import datetime as dt
import unittest
from unittest.mock import patch

from calendar_events import parse_events, event_document, create_event, discover
import xml.etree.ElementTree as ET


class CalendarEventsTest(unittest.TestCase):
    def parse(self, content):
        return parse_events("BEGIN:VCALENDAR\r\n" + content + "\r\nEND:VCALENDAR", "Personal")

    def test_expanded_recurrences_and_cancelled_exception(self):
        events = self.parse("\r\n".join(
            f"BEGIN:VEVENT\r\nUID:weekly\r\nDTSTART:202609{day}T120000Z\r\n"
            f"DTEND:202609{day}T130000Z\r\n{extra}SUMMARY:Meeting\r\nEND:VEVENT"
            for day, extra in [("07", ""), ("14", "RECURRENCE-ID:20260914T120000Z\r\n"),
                               ("21", "STATUS:CANCELLED\r\n")]))
        self.assertEqual(len(events), 2)
        self.assertEqual(dt.datetime.fromisoformat(events[1]["start"]).astimezone(dt.timezone.utc).day, 14)

    def test_all_day_exclusive_end_and_missing_end(self):
        events = self.parse("BEGIN:VEVENT\nDTSTART;VALUE=DATE:20260921\n"
                            "DTEND;VALUE=DATE:20260924\nEND:VEVENT\n"
                            "BEGIN:VEVENT\nDTSTART;VALUE=DATE:20260925\nEND:VEVENT")
        self.assertTrue(events[0]["allDay"])
        self.assertEqual(dt.datetime.fromisoformat(events[0]["end"]).day, 24)
        self.assertEqual(dt.datetime.fromisoformat(events[1]["end"]).day, 26)

    def test_timezone_duration_folding_escaping_and_alarm(self):
        event = self.parse("BEGIN:VEVENT\r\nDTSTART;TZID=America/Sao_Paulo:20260921T090000\r\n"
                           "DURATION:PT1H30M\r\nSUMMARY:Long évent\\,\r\n title\\nSecond line\r\n"
                           "LOCATION:Room\\; 1\r\nBEGIN:VALARM\r\nSUMMARY:Alarm\r\n"
                           "END:VALARM\r\nEND:VEVENT")[0]
        start = dt.datetime.fromisoformat(event["start"])
        end = dt.datetime.fromisoformat(event["end"])
        self.assertEqual(start.astimezone(dt.timezone.utc).hour, 12)
        self.assertEqual(end - start, dt.timedelta(minutes=90))
        self.assertEqual(event["title"], "Long évent,title\nSecond line")
        self.assertEqual(event["location"], "Room; 1")


class CreateEventTest(unittest.TestCase):
    def event(self, **overrides):
        return {"title": "Meeting", "calendar": "/cal/personal/", "allDay": False,
                "startDate": "2026-09-21", "endDate": "2026-09-21",
                "startTime": "09:00", "endTime": "10:00", **overrides}

    def test_creation_roundtrip_and_utf8_folding(self):
        title = "é" * 100 + "; test, slash\\ and\nnew line"
        _, document = event_document(self.event(title=title))
        self.assertTrue(all(len(line.encode()) <= 75 for line in document.split("\r\n")))
        event = parse_events(document, "Personal")[0]
        self.assertEqual(event["title"], title)
        self.assertEqual(dt.datetime.fromisoformat(event["end"]) - dt.datetime.fromisoformat(event["start"]), dt.timedelta(hours=1))

    def test_all_day_inclusive_form_end(self):
        _, document = event_document(self.event(allDay=True, endDate="2026-09-23"))
        self.assertIn("DTEND;VALUE=DATE:20260924", document)

    def test_invalid_dates_and_times(self):
        for changes in [{"title": " "}, {"startDate": "2026-02-30"},
                        {"endTime": "08:00"}, {"startTime": "25:00"},
                        {"allDay": True, "endDate": "2026-09-20"}]:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                event_document(self.event(**changes))

    @patch("calendar_events.discover")
    @patch("calendar_events.connect")
    def test_create_targets_chosen_writable_calendar(self, connect, discover_mock):
        discover_mock.return_value = [{"href": "/cal/personal/", "writable": True},
                                      {"href": "/cal/shared/", "writable": False}]
        self.assertTrue(create_event("https://example.org", "user", self.event())["created"])
        args, kwargs = connect.return_value.call_args
        self.assertEqual(args[0], "PUT")
        self.assertTrue(args[1].startswith("/cal/personal/"))
        self.assertTrue(args[1].endswith(".ics"))
        self.assertTrue(kwargs["create"])
        connect.return_value.reset_mock()
        with self.assertRaises(ValueError):
            create_event("https://example.org", "user", self.event(calendar="/cal/shared/"))
        connect.return_value.assert_not_called()

    def test_discovery_permissions_and_arbitrary_xml_prefix(self):
        xml = ET.fromstring('''<x:multistatus xmlns:x="DAV:" xmlns:z="urn:ietf:params:xml:ns:caldav">
          <x:response><x:href>/cal/personal/</x:href><x:propstat><x:status>HTTP/1.1 200 OK</x:status>
          <x:prop><x:displayname>Personal</x:displayname><x:resourcetype><z:calendar/></x:resourcetype>
          <z:supported-calendar-component-set><z:comp name="VEVENT"/></z:supported-calendar-component-set>
          <x:current-user-privilege-set><x:privilege><x:bind/></x:privilege></x:current-user-privilege-set>
          </x:prop></x:propstat></x:response></x:multistatus>''')
        calendars = discover(lambda *args: xml, "user")
        self.assertEqual(calendars, [{"href": "/cal/personal/", "name": "Personal", "writable": True}])


if __name__ == "__main__":
    unittest.main()
