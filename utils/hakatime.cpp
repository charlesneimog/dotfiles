#include <cstdio>
#include <iostream>
#include <string>
#include <thread>
#include <libsecret/secret.h>

#include <string>
#include <cstdlib>
#include <cstring>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <nlohmann/json.hpp>

const SecretSchema schema = {"org.freedesktop.Secret.Generic",
                             SECRET_SCHEMA_NONE,
                             {
                                 {"service", SECRET_SCHEMA_ATTRIBUTE_STRING},
                             }};

using json = nlohmann::json;
constexpr char SWAY_IPC_MAGIC[] = "i3-ipc";
constexpr size_t SWAY_IPC_HEADER_SIZE = 14;

// ─────────────────────────────────────
bool send_ipc_message(int sock, uint32_t type, const std::string &payload) {
    uint32_t length = payload.size();
    char header[SWAY_IPC_HEADER_SIZE];
    memcpy(header, SWAY_IPC_MAGIC, 6);
    memcpy(header + 6, &length, 4);
    memcpy(header + 10, &type, 4);

    if (write(sock, header, SWAY_IPC_HEADER_SIZE) != (ssize_t)SWAY_IPC_HEADER_SIZE) {
        return false;
    }
    if (length > 0 && write(sock, payload.data(), length) != (ssize_t)length) {
        return false;
    }

    return true;
}

// ─────────────────────────────────────
std::string recv_ipc_message(int sock) {
    char header[SWAY_IPC_HEADER_SIZE];
    ssize_t r = read(sock, header, SWAY_IPC_HEADER_SIZE);
    if (r != (ssize_t)SWAY_IPC_HEADER_SIZE) {
        return {};
    }

    uint32_t length;
    memcpy(&length, header + 6, 4);

    std::string payload(length, '\0');
    ssize_t rr = read(sock, &payload[0], length);
    if (rr != (ssize_t)length) {
        return {};
    }

    return payload;
}

// ─────────────────────────────────────
bool find_focused_app(const json& node, std::string& out_app_id_or_class, std::string& out_title) {
    if (!node.is_object()) return false;

    if (node.value("focused", false)) {
        std::cout << node.dump(4) << std::endl;
        // Try "app_id"
        if (node.contains("app_id") && node["app_id"].is_string()) {
            out_app_id_or_class = node["app_id"].get<std::string>();
        }

        // If "app_id" missing or null, try "window_properties.class"
        if (out_app_id_or_class.empty() &&
            node.contains("window_properties") &&
            node["window_properties"].contains("class")) {
            out_app_id_or_class = node["window_properties"]["class"].get<std::string>();
        }

        // Try to get "name" or "window_properties.title"
        if (node.contains("name") && node["name"].is_string()) {
            out_title = node["name"].get<std::string>();
        } else if (node.contains("window_properties") &&
                   node["window_properties"].contains("title")) {
            out_title = node["window_properties"]["title"].get<std::string>();
        }

        return !out_app_id_or_class.empty();
    }

    // Recurse into "nodes"
    if (node.contains("nodes") && node["nodes"].is_array()) {
        for (const auto& child : node["nodes"]) {
            if (find_focused_app(child, out_app_id_or_class, out_title)) return true;
        }
    }

    // Recurse into "floating_nodes"
    if (node.contains("floating_nodes") && node["floating_nodes"].is_array()) {
        for (const auto& child : node["floating_nodes"]) {
            if (find_focused_app(child, out_app_id_or_class, out_title)) return true;
        }
    }

    return false;
}

// ─────────────────────────────────────
std::string app_id_on_focus() {
    const char *sock_path = std::getenv("SWAYSOCK");
    if (!sock_path) {
        std::cerr << "SWAYSOCK environment variable is not set\n";
        return {};
    }

    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("socket");
        return {};
    }

    sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, sock_path, sizeof(addr.sun_path) - 1);

    if (connect(sock, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) < 0) {
        perror("connect");
        close(sock);
        return {};
    }

    constexpr uint32_t IPC_GET_TREE = 4;
    if (!send_ipc_message(sock, IPC_GET_TREE, "")) {
        std::cerr << "Failed to send IPC message\n";
        close(sock);
        return {};
    }

    std::string payload = recv_ipc_message(sock);
    close(sock);

    if (payload.empty()) {
        std::cerr << "Failed to receive IPC message\n";
        return {};
    }

    try {
        auto root = json::parse(payload);
        std::string app_id;
        std::string app_title;

        if (find_focused_app(root, app_id, app_title)) {
            printf("%s %s \n", app_id.c_str(), app_title.c_str());
            return app_id;
        }
    } catch (const std::exception &e) {
        std::cerr << "JSON parse error: " << e.what() << "\n";
        return {};
    }

    return {};
}

// ─────────────────────────────────────
static std::string get_api_key() {
    GError *error = nullptr;
    gchar *password =
        secret_password_lookup_sync(&schema, nullptr, &error, "service", "hakatime", nullptr);

    if (error) {
        std::cerr << "Error: " << error->message << std::endl;
        g_error_free(error);
        return "";
    }

    if (password) {
        std::string key(password); // copia antes de liberar
        secret_password_free(password);
        return key;
    } else {
        return "";
    }
}

// ─────────────────────────────────────
int main() {
    // Get Api Key of Wakatime|Hakatime
    std::string api_key = get_api_key();
    if (api_key.empty()) {
        return 1;
    }

    while (true) {
        std::string focused_app = app_id_on_focus();
        if (!focused_app.empty()) {
            std::cout << "Focused app_id/class: " << focused_app << "\n";
        } else {
            std::cout << "No focused app found\n";
        }

        std::this_thread::sleep_for(std::chrono::seconds(2));
    }

}
