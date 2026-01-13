#include <iostream>
#include <cstdio>
#include <string>
#include <chrono>
#include <thread>

using steady_clock = std::chrono::steady_clock;

/* Estrutura mínima */
struct FocusedWindow {
    int window_id = -1;
    std::string title;
    std::string app_id;
    bool valid = false;
};

/* Parse apenas a janela focada (baixo uso de RAM) */
FocusedWindow get_focused_window() {
    FILE *pipe = popen("niri msg windows", "r");
    if (!pipe) {
        return {};
    }

    char buf[4096];
    FocusedWindow fw;
    bool focused = false;

    while (fgets(buf, sizeof(buf), pipe)) {
        std::string line(buf);

        // Nova janela
        if (line.rfind("Window ID ", 0) == 0) {
            focused = (line.find("(focused)") != std::string::npos);
            if (focused) {
                size_t id_start = 10; // after "Window ID "
                size_t id_end = line.find(':', id_start);
                fw.window_id = std::stoi(line.substr(id_start, id_end - id_start));
            }
            continue;
        }

        if (!focused) {
            continue;
        }

        // Title
        if (line.find("Title:") != std::string::npos) {
            size_t pos = line.find("Title:") + 6;
            fw.title = line.substr(pos);
            fw.title.erase(0, fw.title.find_first_not_of(" \t\""));
            fw.title.erase(fw.title.find_last_not_of("\"\r\n") + 1);
        }
        // App ID
        else if (line.find("App ID:") != std::string::npos) {
            size_t pos = line.find("App ID:") + 7;
            fw.app_id = line.substr(pos);
            fw.app_id.erase(0, fw.app_id.find_first_not_of(" \t\""));
            fw.app_id.erase(fw.app_id.find_last_not_of("\"\r\n") + 1);
            fw.valid = true;
            break; // já temos tudo
        }
    }

    pclose(pipe);
    return fw;
}

int main() {
    int last_window_id = -1;
    std::string last_title;
    std::string last_app_id;

    steady_clock::time_point focus_start;

    while (true) {
        FocusedWindow fw = get_focused_window();
        if (!fw.valid) {
            std::this_thread::sleep_for(std::chrono::seconds(1));
            continue;
        }

        auto now = steady_clock::now();
        if (last_window_id == -1) {
            last_window_id = fw.window_id;
            last_title = fw.title;
            last_app_id = fw.app_id;
            focus_start = now;
        } else if (fw.window_id != last_window_id) {
            double elapsed = std::chrono::duration<double>(now - focus_start).count();
            std::cout << "You spent " << elapsed << " seconds focused on \"" << last_title << "\" ("
                      << last_app_id << ")" << std::endl;
            last_window_id = fw.window_id;
            last_title = fw.title;
            last_app_id = fw.app_id;
            focus_start = now;
        }

        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}
