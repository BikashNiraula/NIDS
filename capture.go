package main

import (
	"fmt"
	_ "log"
	_ "os"
	"strconv"
	"strings"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
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

// inferAppProtocolByPayload performs simple pattern matching on the payload.
// This is a basic form of deep packet inspection.
func inferAppProtocolByPayload(payload []byte) string {
	payloadStr := string(payload)
	// Check for HTTP patterns.
	if strings.HasPrefix(payloadStr, "GET ") ||
		strings.HasPrefix(payloadStr, "POST ") ||
		strings.Contains(payloadStr, "HTTP/1.1") ||
		strings.Contains(payloadStr, "HTTP/1.0") {
		return "HTTP"
	}
	// Check for SMTP response (commonly starts with "220").
	if strings.HasPrefix(payloadStr, "220 ") && strings.Contains(payloadStr, "SMTP") {
		return "SMTP"
	}
	// Check for SMTP commands (e.g., EHLO/HELO).
	if strings.HasPrefix(payloadStr, "EHLO ") || strings.HasPrefix(payloadStr, "HELO ") {
		return "SMTP"
	}
	// Check for FTP response (e.g., "220-" may indicate FTP service).
	if strings.HasPrefix(payloadStr, "220-") && strings.Contains(payloadStr, "FTP") {
		return "FTP"
	}
	// Add additional heuristics as needed.
	return "Unknown"
}

// CaptureAndLogAllFields listens for packets on the specified interface,
// extracts various fields, and then calls matching() with the proper parameters.
func CaptureAndLogAllFields(iface string) error {
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
		var packetLength int
		var ttl uint8
		var tcpFlags string
		var flagsBuilder strings.Builder
		

		// Extract network layer (IPv4, IPv6).
		if networkLayer := packet.NetworkLayer(); networkLayer != nil {
			switch netLayer := networkLayer.(type) {
			case *layers.IPv4:
				sourceIP = netLayer.SrcIP.String()
				destinationIP = netLayer.DstIP.String()
				ttl = netLayer.TTL
				packetLength = int(netLayer.Length)
			case *layers.IPv6:
				sourceIP = netLayer.SrcIP.String()
				destinationIP = netLayer.DstIP.String()
			}
		}

		// Extract transport layer (TCP/UDP).
		if transportLayer := packet.TransportLayer(); transportLayer != nil {
			protocol = transportLayer.LayerType().String()
			switch transLayer := transportLayer.(type) {
			case *layers.TCP:
				src, dst := transLayer.TransportFlow().Endpoints()
				sourcePort = src.String()
				destinationPort = dst.String()
				fmt.Printf("SYN:%t ACK:%t FIN:%t RST:%t PSH:%t URG:%t",
					transLayer.SYN, transLayer.ACK, transLayer.FIN, transLayer.RST, transLayer.PSH, transLayer.URG)
				if transLayer.FIN {
					flagsBuilder.WriteString("F")
				}
				if transLayer.SYN {
					flagsBuilder.WriteString("S")
				}
				if transLayer.RST {
					flagsBuilder.WriteString("R")
				}
				if transLayer.PSH {
					flagsBuilder.WriteString("P")
				}
				if transLayer.ACK {
					flagsBuilder.WriteString("A")
				}
				if transLayer.URG {
					flagsBuilder.WriteString("U")
				}
				tcpFlags = flagsBuilder.String()
			case *layers.UDP:
				src, dst := transLayer.TransportFlow().Endpoints()
				sourcePort = src.String()
				destinationPort = dst.String()
			}
		}

		// Extract application layer payload and try to infer the application protocol.
		if applicationLayer := packet.ApplicationLayer(); applicationLayer != nil {
			payload = applicationLayer.Payload()

			// Use port-based heuristics.
			switch {
			case protocol == "TCP" && (sourcePort == "21" || destinationPort == "21"):
				appProtocol = "FTP"
			case protocol == "TCP" && (sourcePort == "25" || destinationPort == "25"):
				appProtocol = "SMTP"
			case protocol == "TCP" && (sourcePort == "80" || destinationPort == "80"):
				appProtocol = "HTTP"
			case protocol == "TCP" && (sourcePort == "443" || destinationPort == "443"):
				appProtocol = "HTTPS"
			case protocol == "UDP" && (sourcePort == "53" || destinationPort == "53"):
				appProtocol = "DNS"
			case protocol == "TCP" && (sourcePort == "110" || destinationPort == "110"):
				appProtocol = "POP3"
			case protocol == "TCP" && (sourcePort == "143" || destinationPort == "143"):
				appProtocol = "IMAP"
			case protocol == "TCP" && (sourcePort == "22" || destinationPort == "22"):
				appProtocol = "SSH"
			case protocol == "TCP" && (sourcePort == "587" || destinationPort == "587"):
				appProtocol = "SMTP (Secure)"
			default:
				appProtocol = "Unknown"
			}

			// If still unknown, inspect the payload.
			if appProtocol == "Unknown" && len(payload) > 0 {
				inferred := inferAppProtocolByPayload(payload)
				if inferred != "Unknown" {
					appProtocol = inferred + " (via payload)"
				}
			}
		} else {
			payload = []byte{}
			appProtocol = "No Application Data"
		}

		// --- Prepare parameters for matching() ---
		// Define the rule file path.
		//ruleFile := ".\\Rules\\JsonRules\\emerging-dos.rules.json"
		ruleFile := ".\\test-rules-000.json"

		// Convert sourcePort and destinationPort to integers.
		sportInt, err := strconv.Atoi(sourcePort)
		if err != nil {
			sportInt = 0
		}
		dportInt, err := strconv.Atoi(destinationPort)
		if err != nil {
			dportInt = 0
		}
		// Convert payload (a []byte) to string.
		payloadStr := string(payload)

		// Set default values for the additional matching parameters.
		flowParam := "" // Default flow (adjust as needed, e.g., "established,to_server")
		//process the flag param properly

		// Reuse the extracted TCP flags
		pktFlowbits := []string{} // Empty slice; populate if needed

		// Call matching() with 10 pointer parameters.
		matching(&ruleFile, &protocol, &sourceIP, &sportInt, &destinationIP, &dportInt, &payloadStr, &flowParam, &tcpFlags, &pktFlowbits)

		// Log the captured packet fields.
		fmt.Printf(
			"Packet:\n  Timestamp: %s\n  Network Protocol: %s\n  Application Protocol: %s\n  Source IP: %s\n  Source Port: %s\n  Destination IP: %s\n  Destination Port: %s\n  TTL: %d\n  Flags: %s\n  Length: %d\n  Payload (hex): %x\n\n",
			timestamp, protocol, appProtocol, sourceIP, sourcePort, destinationIP, destinationPort, ttl, tcpFlags, packetLength, payload,
		)
	}
	return nil
}
