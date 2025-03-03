// * sudo go run ./go_backend/
package main

import (
	packetcapture "NIDS/go_backend/packet_capture"
	"NIDS/go_backend/system_info"
	"NIDS/go_backend/terminal"
	"fmt"
	"log"
	"net/http"
)

func main() {
	// Register API routes
	http.HandleFunc("/status", system_info.StatusHandler)
	system_info.GetSystemStatus()
	terminal.SetupRoutes()
	fmt.Println("API routes initialized")

	// Start packet capture as a goroutine
	iface := "en0" // Replace with your network interface
	go func() {
		err := packetcapture.CaptureAndBroadcastPackets(iface)
		if err != nil {
			log.Fatalf("Failed to capture packets: %v", err)
		}
	}()

	// Start the WebSocket + HTTP server on 8080
	go packetcapture.WebSocketServer("8080") // This starts the WebSocket + HTTP server once

	fmt.Println("Server started at :8080")
	select {} // This makes the main goroutine block forever without using http.ListenAndServe() again
}
