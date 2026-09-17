// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W E A T H E R   S E R V I C E                                          │
// │   weather · current conditions and forecast                              │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Uses the same IP-based city lookup and wttr.in provider as Waybar.
// curl fetches the forecast; QML parses it without a Python helper.
//
// Polled every 15 minutes while something is subscribed. The last reading
// stays in between.
Singleton {
    id: root

    readonly property int pollInterval: 900000

    property int watchers: 0
    property bool available: false
    property string error: ""
    readonly property bool checking: query.running || locationQuery.running || forecastQuery.running
    property bool primarySucceeded: false
    property var fallbackLocation: null
    property string provider: ""

    // Query on construction: the bar needs `available` before the module
    // exists to subscribe. Only reached while the module is enabled.
    Component.onCompleted: root.refresh()

    property string place: ""
    property string region: ""
    property int temperature: 0
    property int feelsLike: 0
    property string description: ""
    property string glyph: ""
    property int humidity: 0
    property int wind: 0
    property int low: 0
    property int high: 0
    property var hourly: []

    // So the card can show how old the reading is.
    property date readAt: new Date(0)

    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Minutes
        enabled: root.watchers > 0
    }

    readonly property string age: {
        if (!root.available)
            return ""
        const minutes = Math.floor((root.clock.date.getTime() - root.readAt.getTime()) / 60000)
        if (minutes < 2)
            return "just now"
        if (minutes < 60)
            return `${minutes} min ago`
        const hours = Math.round(minutes / 60)
        return `${hours} h ago`
    }

    // The next four three-hour blocks, running into tomorrow when today has
    // none left.
    readonly property var ahead: {
        const hour = root.clock.date.getHours()
        return (root.hourly ?? [])
            .filter(block => block.tomorrow || block.hour > hour)
            .slice(0, 4)
    }

    function subscribe(): void {
        root.watchers += 1
        // Only if never read or older than ten minutes.
        const minutes = (new Date().getTime() - root.readAt.getTime()) / 60000
        if (!root.available || minutes > 10)
            root.refresh()
    }

    function release(): void {
        root.watchers = Math.max(0, root.watchers - 1)
    }

    function refresh(): void {
        if (root.checking) return
        root.primarySucceeded = false
        root.query.running = true
    }

    readonly property Timer poller: Timer {
        interval: root.pollInterval
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    // A new place is a different reading; fetch it now.
    Connections {
        target: SettingsService

        function onWeatherPlaceChanged(): void {
            if (root.watchers > 0)
                root.refresh()
        }
    }

    property bool placeUnknown: false

    function icon(code: int, day: bool): string {
        if (code === 113) return day ? "󰖨" : "󰖔"
        if (code === 116) return day ? "󰖕" : "󰼱"
        if ([143, 248, 260].includes(code)) return "󰖑"
        if ([176, 263, 266, 293, 296, 353].includes(code)) return "󰼳"
        if ([299, 302, 305, 308, 356, 359].includes(code)) return "󰖖"
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(code)) return "󰼶"
        if ([200, 386, 389, 392, 395].includes(code)) return "󰙾"
        return "󰖐"
    }

    readonly property Process query: Process {
        // The city is passed as an argument, then URL-encoded; never evaluated
        // as shell code. A failed city lookup falls back to wttr.in geolocation.
        command: ["sh", "-c",
            "place=\"$1\"; if [ -z \"$place\" ]; then place=$(curl -fsS --connect-timeout 5 --max-time 10 https://ipinfo.io/json | jq -r '.city // empty'); fi; encoded=$(printf %s \"$place\" | jq -sRr @uri); exec curl -fsS --connect-timeout 5 --max-time 30 \"https://wttr.in/$encoded?format=j1&lang=pt\"",
            "weather", SettingsService.weatherPlace.trim()]
        onExited: {
            if (!root.primarySucceeded) root.locationQuery.running = true
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const current = data.current_condition[0]
                    const area = data.nearest_area[0]
                    const today = data.weather[0]
                    const temperature = Number(current.temp_C)
                    if (!Number.isFinite(temperature) || current.temp_C === undefined)
                        throw new Error("Missing temperature")
                    const hourly = data.weather.slice(0, 2).reduce((rows, day, index) => rows.concat(
                        day.hourly.map(block => {
                            const hour = Math.floor(Number(block.time) / 100)
                            return { hour: hour, temperature: Number(block.tempC),
                                glyph: root.icon(Number(block.weatherCode), hour >= 6 && hour < 21),
                                rain: Number(block.chanceofrain), tomorrow: index > 0 }
                        })), [])
                    root.place = area.areaName[0].value
                    root.region = area.country[0].value
                    root.temperature = temperature
                    root.feelsLike = Number(current.FeelsLikeC)
                    root.description = (current.lang_pt ?? current.weatherDesc)[0].value
                    const hour = new Date().getHours()
                    root.glyph = root.icon(Number(current.weatherCode), hour >= 6 && hour < 21)
                    root.humidity = Number(current.humidity)
                    root.wind = Number(current.windspeedKmph)
                    root.low = Number(today.mintempC)
                    root.high = Number(today.maxtempC)
                    root.hourly = hourly
                    root.readAt = new Date()
                    root.primarySucceeded = true
                    root.provider = "wttr.in"
                    root.available = true
                    root.placeUnknown = false
                    root.error = ""
                } catch (error) {
                    root.error = "Weather unavailable; retrying every 15 minutes"
                }
            }
        }
    }

    // wttr.in occasionally fails or presents an expired certificate. Keep
    // TLS validation enabled and fall back to Open-Meteo instead.
    readonly property Process locationQuery: Process {
        command: ["curl", "-fsS", "--connect-timeout", "5", "--max-time", "15",
            SettingsService.weatherPlace.trim() !== ""
                ? "https://geocoding-api.open-meteo.com/v1/search?count=1&language=pt&name=" + encodeURIComponent(SettingsService.weatherPlace.trim())
                : "https://ipinfo.io/json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    let location
                    if (SettingsService.weatherPlace.trim() !== "") {
                        const match = data.results?.[0]
                        if (!match) throw new Error("Unknown location")
                        location = { latitude: match.latitude, longitude: match.longitude,
                            name: match.name, region: match.country }
                    } else {
                        const coords = data.loc.split(",").map(Number)
                        location = { latitude: coords[0], longitude: coords[1],
                            name: data.city, region: data.country }
                    }
                    if (!Number.isFinite(location.latitude) || !Number.isFinite(location.longitude))
                        throw new Error("Missing coordinates")
                    root.fallbackLocation = location
                    root.forecastQuery.command = ["curl", "-fsS", "--connect-timeout", "5", "--max-time", "20",
                        `https://api.open-meteo.com/v1/forecast?latitude=${location.latitude}&longitude=${location.longitude}`
                        + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m"
                        + "&hourly=temperature_2m,precipitation_probability,weather_code"
                        + "&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=2"]
                    root.forecastQuery.running = true
                } catch (error) {
                    root.error = "Weather location unavailable; retrying every 15 minutes"
                }
            }
        }
    }

    // Open-Meteo uses WMO codes, unlike wttr.in's World Weather Online codes.
    function condition(code: int, day: bool): var {
        if (code === 0) return { glyph: day ? "󰖨" : "󰖔", text: "Céu limpo" }
        if (code <= 2) return { glyph: "󰖕", text: "Parcialmente nublado" }
        if (code === 3) return { glyph: "󰖐", text: "Nublado" }
        if (code <= 48) return { glyph: "󰖑", text: "Nevoeiro" }
        if (code >= 95) return { glyph: "󰙾", text: "Trovoada" }
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return { glyph: "󰼶", text: "Neve" }
        return { glyph: "󰖖", text: "Chuva" }
    }

    readonly property Process forecastQuery: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const current = data.current
                    if (typeof current.temperature_2m !== "number") throw new Error("Missing temperature")
                    const condition = root.condition(current.weather_code, current.is_day === 1)
                    const today = current.time.slice(0, 10)
                    const hourly = data.hourly.time.map((time, index) => {
                        const hour = Number(time.slice(11, 13))
                        return { hour: hour, tomorrow: time.slice(0, 10) !== today,
                            temperature: Math.round(data.hourly.temperature_2m[index]),
                            rain: data.hourly.precipitation_probability[index],
                            glyph: root.condition(data.hourly.weather_code[index], hour >= 6 && hour < 21).glyph }
                    }).filter(block => block.hour % 3 === 0)
                    root.place = root.fallbackLocation.name
                    root.region = root.fallbackLocation.region
                    root.temperature = Math.round(current.temperature_2m)
                    root.feelsLike = Math.round(current.apparent_temperature)
                    root.humidity = current.relative_humidity_2m
                    root.wind = Math.round(current.wind_speed_10m)
                    root.description = condition.text
                    root.glyph = condition.glyph
                    root.low = Math.round(data.daily.temperature_2m_min[0])
                    root.high = Math.round(data.daily.temperature_2m_max[0])
                    root.hourly = hourly
                    root.readAt = new Date()
                    root.available = true
                    root.placeUnknown = false
                    root.provider = "Open-Meteo"
                    root.error = ""
                } catch (error) {
                    root.error = "Weather unavailable; retrying every 15 minutes"
                }
            }
        }
    }
}
