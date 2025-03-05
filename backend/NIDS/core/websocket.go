package core

import (
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

var (
    clients   = make(map[*websocket.Conn]bool)
    clientsMu sync.Mutex
    upgrader  = websocket.Upgrader{
        CheckOrigin: func(r *http.Request) bool { return true },
    }
    alertChannel = make(chan string, 100) // Buffered channel with capacity
)

// InitWebSocketHandlers sets up WebSocket routes
func InitWebSocketHandlers() {
    http.HandleFunc("/ws/alerts", handleAlertsWebSocket)
    go broadcastAlerts()
}


func handleAlertsWebSocket(w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Println("WebSocket upgrade failed for alerts:", err)
        return
    }
    defer conn.Close()

    clientsMu.Lock()
    clients[conn] = true
    clientsMu.Unlock()

    // Log when a new WebSocket connection is established
    log.Println("New WebSocket connection established for alerts")

    // Keep connection alive
    for {
        _, _, err := conn.ReadMessage()
        if err != nil {
            clientsMu.Lock()
            delete(clients, conn)
            clientsMu.Unlock()
            log.Println("WebSocket connection closed")
            break
        }
    }
}
func broadcastAlerts() {
    for alert := range alertChannel {
        clientsMu.Lock()
        for client := range clients {
            if err := client.WriteMessage(websocket.TextMessage, []byte(alert)); err != nil {
                log.Println("WebSocket write failed:", err)
                client.Close()
                delete(clients, client)
            }
        }
        clientsMu.Unlock()
    }
}

// TriggerAlert sends an alert through the WebSocket channel
func TriggerAlert(sid, message string) {
    alert := "ALERT: Packet matched rule SID " + sid + " - " + message
    log.Println(alert)
    select {
    case alertChannel <- alert:
    default:
        log.Println("Alert channel is full, dropping alert")
    }
}