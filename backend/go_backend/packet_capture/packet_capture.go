package packetcapture

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"sync"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	"github.com/gorilla/websocket"
)

// CapturedPacket holds the fields extracted from a captured packet.
type CapturedPacket struct {
	Timestamp       string // Formatted timestamp when the packet was captured.
	NetworkProtocol string // Network-layer protocol (IPv4, IPv6, etc.)
	AppProtocol     string // Application-layer protocol (HTTP, FTP, etc.)
	SourceIP        string // Source IP address.
	SourcePort      string // Source port.
	DestinationIP   string // Destination IP address.
	DestinationPort string // Destination port.
	TTL             uint8  // Time To Live (only applicable for IPv4).
	Flags           string // TCP flags (if applicable).
	Length          int    // Packet length (from network-layer header).
	Payload         []byte // Application-layer payload (raw bytes).
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var clients = make(map[*websocket.Conn]bool)
var mutex = &sync.Mutex{}

func WebSocketServer(port string) {
	http.HandleFunc("/ws/packets", handleWebSocket)
	log.Printf("WebSocket server started on ws://localhost:%s/ws/packets", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade error:", err)
		return
	}
	defer conn.Close()

	mutex.Lock()
	clients[conn] = true
	mutex.Unlock()

	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			log.Println("WebSocket read error:", err)
			mutex.Lock()
			delete(clients, conn)
			mutex.Unlock()
			break
		}
	}
}

func BroadcastPacket(packet CapturedPacket) {
	packetJSON, err := json.Marshal(packet)
	if err != nil {
		log.Println("Error marshaling packet:", err)
		return
	}

	mutex.Lock()
	defer mutex.Unlock()

	for client := range clients {
		err := client.WriteMessage(websocket.TextMessage, packetJSON)
		if err != nil {
			log.Println("WebSocket write error:", err)
			client.Close()
			delete(clients, client)
		}
	}
}

func CaptureAndBroadcastPackets(iface string) error {
	handle, err := pcap.OpenLive(iface, 1600, true, pcap.BlockForever)
	if err != nil {
		return fmt.Errorf("failed to open interface: %v", err)
	}
	defer handle.Close()

	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	fmt.Println("Listening for packets and extracting fields...")

	for packet := range packetSource.Packets() {
		timestamp := packet.Metadata().Timestamp.Format("2006-01-02 15:04:05.000")
		var protocol, sourceIP, destinationIP, sourcePort, destinationPort, appProtocol string
		var payload []byte
		var ttl uint8
		var tcpFlags string
		var flagsBuilder strings.Builder

		if networkLayer := packet.NetworkLayer(); networkLayer != nil {
			switch netLayer := networkLayer.(type) {
			case *layers.IPv4:
				sourceIP = netLayer.SrcIP.String()
				destinationIP = netLayer.DstIP.String()
				ttl = netLayer.TTL
			case *layers.IPv6:
				sourceIP = netLayer.SrcIP.String()
				destinationIP = netLayer.DstIP.String()
			}
		}

		if transportLayer := packet.TransportLayer(); transportLayer != nil {
			protocol = transportLayer.LayerType().String()
			switch transLayer := transportLayer.(type) {
			case *layers.TCP:
				src, dst := transLayer.TransportFlow().Endpoints()
				sourcePort = src.String()
				destinationPort = dst.String()
				if transLayer.SYN {
					flagsBuilder.WriteString("S")
				}
				tcpFlags = flagsBuilder.String()
			case *layers.UDP:
				src, dst := transLayer.TransportFlow().Endpoints()
				sourcePort = src.String()
				destinationPort = dst.String()
			}
		}

		if applicationLayer := packet.ApplicationLayer(); applicationLayer != nil {
			payload = applicationLayer.Payload()
			payloadStr := string(payload)
			if strings.Contains(payloadStr, "HTTP/1.1") || strings.Contains(payloadStr, "GET ") || strings.Contains(payloadStr, "POST ") {
				appProtocol = "HTTP"
			} else if strings.Contains(payloadStr, "USER") || strings.Contains(payloadStr, "PASS") {
				appProtocol = "FTP"
			} else if len(payload) > 12 && protocol == "UDP" {
				appProtocol = "DNS"
			} else if len(payload) == 0 {
				appProtocol = "No Application Data"
			} else {
				appProtocol = "Unknown"
			}
		}

		capturedPkt := CapturedPacket{
			Timestamp:       timestamp,
			NetworkProtocol: protocol,
			AppProtocol:     appProtocol,
			SourceIP:        sourceIP,
			SourcePort:      sourcePort,
			DestinationIP:   destinationIP,
			DestinationPort: destinationPort,
			TTL:             ttl,
			Flags:           tcpFlags,
			Payload:         payload,
		}

		BroadcastPacket(capturedPkt)
	}

	return nil
}
