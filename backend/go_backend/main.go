// * sudo go run ./go_backend/
// package main

// import (
// 	packetcapture "NIDS/go_backend/packet_capture"
// 	"NIDS/go_backend/system_info"
// 	"NIDS/go_backend/terminal"
// 	"fmt"
// 	"log"
// 	"net/http"
// )

// func main() {
// 	// Register API routes
// 	http.HandleFunc("/status", system_info.StatusHandler)
// 	system_info.GetSystemStatus()
// 	terminal.SetupRoutes()
// 	fmt.Println("API routes initialized")

// 	// Start packet capture as a goroutine
// 	iface := "en0" // Replace with your network interface
// 	go func() {
// 		err := packetcapture.CaptureAndBroadcastPackets(iface)
// 		if err != nil {
// 			log.Fatalf("Failed to capture packets: %v", err)
// 		}
// 	}()

// 	// Start the WebSocket + HTTP server on 8080
// 	go packetcapture.WebSocketServer("8080") // This starts the WebSocket + HTTP server once

//		fmt.Println("Server started at :8080")
//		select {} // This makes the main goroutine block forever without using http.ListenAndServe() again
//	}
// package main

// import (
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
// 	// Register API routes
// 	http.HandleFunc("/status", system_info.StatusHandler)
// 	http.HandleFunc("/ws/interfaces", wsInterfacesHandler) // Single WebSocket endpoint
// 	system_info.GetSystemStatus()
// 	terminal.SetupRoutes()
// 	fmt.Println("API routes initialized")

// 	fmt.Println("Server started at :8080")
// 	log.Fatal(http.ListenAndServe(":8080", nil))
// }

// // wsInterfacesHandler handles WebSocket connections for real-time interface updates
// func wsInterfacesHandler(w http.ResponseWriter, r *http.Request) {
// 	conn, err := upgrader.Upgrade(w, r, nil)
// 	if err != nil {
// 		log.Println("WebSocket upgrade failed:", err)
// 		return
// 	}
// 	defer conn.Close()

// 	// Send interface updates every 5 seconds
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

//				// Send the interfaces to the client
//				err = conn.WriteJSON(interfaces)
//				if err != nil {
//					log.Println("WebSocket write failed:", err)
//					return
//				}
//			}
//		}
//	}
// package main

// import (
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
// 	// Register API routes
// 	http.HandleFunc("/status", system_info.StatusHandler)
// 	http.HandleFunc("/ws/interfaces", wsInterfacesHandler) // WebSocket for network interfaces
// 	system_info.GetSystemStatus()
// 	terminal.SetupRoutes()
// 	fmt.Println("API routes initialized")

// 	fmt.Println("Server started at :8080")
// 	log.Fatal(http.ListenAndServe(":8080", nil))
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
package main

import (
	listnetworkinterfaces "NIDS/go_backend/list_interfaces"
	"NIDS/go_backend/system_info"
	"NIDS/go_backend/terminal"
	"NIDS/NIDS/core"
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
	// Register API routes
	http.HandleFunc("/status", system_info.StatusHandler)
	http.HandleFunc("/ws/interfaces", wsInterfacesHandler) // WebSocket for network interfaces
	http.HandleFunc("/ws/packets", wsPacketsHandler) // WebSocket for packet streaming
	
	system_info.GetSystemStatus()
	terminal.SetupRoutes()
	fmt.Println("API routes initialized")

	// Start packet capture in a goroutine
	iface := "en0" // Replace with your desired network interface.
	go core.CapturePacketsStream(iface, false, "rules.json")

	fmt.Println("Server started at :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

// wsInterfacesHandler handles WebSocket connections for real-time interface updates
func wsInterfacesHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade failed:", err)
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
		log.Println("WebSocket upgrade failed:", err)
		return
	}
	defer conn.Close()

	log.Println("New WebSocket client connected for packet stream")
	go core.SendPacketsToWebSocket(conn)
	select {}
}
