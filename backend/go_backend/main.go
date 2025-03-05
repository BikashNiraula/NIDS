// // * sudo go run ./go_backend/

// package main

// import (
// 	"NIDS/NIDS/core"
// 	listnetworkinterfaces "NIDS/go_backend/list_interfaces"
// 	"NIDS/go_backend/system_info"
// 	"NIDS/go_backend/terminal"
// 	"fmt"
// 	"log"
// 	"net/http"
// 	"time"

// 	"github.com/gorilla/websocket"
// )

// var upgrader = websocket.Upgrader{
// 	CheckOrigin: func(r *http.Request) bool {
// 		return true // Allow all connections
// 	},
// }

// func main() {
// 		core.StartWebSocketServer("8081")
// 	// Register API routes
// 	http.HandleFunc("/status", system_info.StatusHandler)
// 	http.HandleFunc("/ws/interfaces", wsInterfacesHandler) // WebSocket for network interfaces
// 	http.HandleFunc("/ws/packets", wsPacketsHandler) // WebSocket for packet streaming
// 	http.HandleFunc("/ws/alerts", wsAlertsHandler)

// 	system_info.GetSystemStatus()
// 	terminal.SetupRoutes()
// 	fmt.Println("API routes initialized")

// 	// Start packet capture in a goroutine
// 	iface := "en0" // Replace with your desired network interface.
// 	go core.CapturePacketsStream(iface, false, "rules.json")

// 	fmt.Println("Server started at :8085")
// 	log.Fatal(http.ListenAndServe(":8085", nil))
// }

// // wsInterfacesHandler handles WebSocket connections for real-time interface updates
// func wsInterfacesHandler(w http.ResponseWriter, r *http.Request) {
// 	conn, err := upgrader.Upgrade(w, r, nil)
// 	if err != nil {
// 		log.Println("WebSocket upgrade failed:", err)
// 		return
// 	}
// 	defer conn.Close()

// 	ticker := time.NewTicker(5 * time.Second)
// 	defer ticker.Stop()

// 	for {
// 		select {
// 		case <-ticker.C:
// 			interfaces, err := listnetworkinterfaces.ListNetworkInterfacesUI()
// 			if err != nil {
// 				log.Println("Failed to fetch interfaces:", err)
// 				continue
// 			}

// 			// Log the interfaces being sent
// 			log.Printf("Sending %d network interfaces:\n", len(interfaces))
// 			for _, iface := range interfaces {
// 				log.Printf("Interface: %s, Description: %s, IP: %s\n", iface.Name, iface.Description, iface.IPAddress)
// 			}

// 			// Send the interfaces to the client
// 			err = conn.WriteJSON(interfaces)
// 			if err != nil {
// 				log.Println("WebSocket write failed:", err)
// 				return
// 			}
// 		}
// 	}
// }

// // wsPacketsHandler handles WebSocket connections for real-time packet streaming
// func wsPacketsHandler(w http.ResponseWriter, r *http.Request) {
// 	conn, err := upgrader.Upgrade(w, r, nil)
// 	if err != nil {
// 		log.Println("WebSocket upgrade failed:", err)
// 		return
// 	}
// 	defer conn.Close()

// 	log.Println("New WebSocket client connected for packet stream")
// 	go core.SendPacketsToWebSocket(conn)
// 	select {}
// }

// // wsAlertsHandler handles WebSocket connections for real-time alert streaming
// func wsAlertsHandler(w http.ResponseWriter, r *http.Request) {
// 	conn, err := upgrader.Upgrade(w, r, nil)
// 	if err != nil {
// 		log.Println("WebSocket upgrade failed:", err)
// 		return
// 	}
// 	defer conn.Close()

// 	log.Println("New WebSocket client connected for alert stream")
// 	go core.StartWebSocketServer("8081")

//		select {}
//	}
//
// * sudo go run ./go_backend/
package main

// var upgrader = websocket.Upgrader{
// 	CheckOrigin: func(r *http.Request) bool {
// 		return true // Allow all connections
// 	},
// }

// func main() {
// 	// Start WebSocket server for alerts on port 8081

// 	// Register API routes
// 	http.HandleFunc("/status", system_info.StatusHandler)
// 	http.HandleFunc("/ws/interfaces", wsInterfacesHandler) // WebSocket for network interfaces
// 	http.HandleFunc("/ws/packets", wsPacketsHandler)       // WebSocket for packet streaming
// 	http.HandleFunc("/ws/alerts", wsAlertsHandler)         // WebSocket for alerts

// 	// Initialize system info
// 	system_info.GetSystemStatus()

// 	// Setup terminal routes
// 	terminal.SetupRoutes()

// 	fmt.Println("API routes initialized")

// 	// Start packet capture in a goroutine
// 	iface := "en0" // Replace with your desired network interface
// 	go core.CapturePacketsStream(iface, false, "rules.json")

// 	fmt.Println("Server started at :8085")
// 	log.Fatal(http.ListenAndServe(":8085", nil))
// }

import (
	"NIDS/NIDS/core"
	listnetworkinterfaces "NIDS/go_backend/list_interfaces"
	"NIDS/go_backend/system_info"
	"NIDS/go_backend/terminal"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all connections
	},
}

func main() {


	// Register other API routes
	http.HandleFunc("/status", system_info.StatusHandler)
	http.HandleFunc("/ws/interfaces", wsInterfacesHandler)
	http.HandleFunc("/ws/packets", wsPacketsHandler)

	// Initialize system info
	system_info.GetSystemStatus()

	// Setup terminal routes
	terminal.SetupRoutes()

	fmt.Println("API routes initialized")

	// Start packet capture in a goroutine
	iface := "en0" // Replace with your desired network interface
	go core.CapturePacketsStream(iface, false, "rules.json")
		// Initialize WebSocket handlers
core.InitWebSocketHandlers()
	fmt.Println("Server started at :8085")
	log.Fatal(http.ListenAndServe(":8085", nil))
}

// ... (rest of the code remains the same)

// wsInterfacesHandler handles WebSocket connections for real-time interface updates
func wsInterfacesHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade failed for interface:", err)
		return
	}
	defer conn.Close()

	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			interfaces, err := listnetworkinterfaces.ListNetworkInterfacesUI()
			if err != nil {
				log.Println("Failed to fetch interfaces:", err)
				continue
			}

			// Log the interfaces being sent
			log.Printf("Sending %d network interfaces:\n", len(interfaces))
			for _, iface := range interfaces {
				log.Printf("Interface: %s, Description: %s, IP: %s\n", iface.Name, iface.Description, iface.IPAddress)
			}

			// Send the interfaces to the client
			err = conn.WriteJSON(interfaces)
			if err != nil {
				log.Println("WebSocket write failed:", err)
				return
			}
		}
	}
}

// wsPacketsHandler handles WebSocket connections for real-time packet streaming
func wsPacketsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade failed for packet capture:", err)
		return
	}
	defer conn.Close()

	log.Println("New WebSocket client connected for packet stream")
	go core.SendPacketsToWebSocket(conn)
	select {}
}

