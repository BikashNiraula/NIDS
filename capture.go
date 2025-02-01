package main
import (
	_ "NIDS/rulesparser"
	_ "encoding/json"
	"fmt"
	_ "log"
	_ "net"
	_ "os"
	_ "path/filepath"
	_ "strings"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	_ "github.com/olekukonko/tablewriter"
	_ "github.com/spf13/cobra"
)

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

		// Extract network layer (IPv4, IPv6)
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

		// Extract transport layer (TCP/UDP)
		if transportLayer := packet.TransportLayer(); transportLayer != nil {
			protocol = transportLayer.LayerType().String()
			switch transLayer := transportLayer.(type) {
			case *layers.TCP:
				src, dst := transLayer.TransportFlow().Endpoints()
				sourcePort = src.String()
				destinationPort = dst.String()
				tcpFlags = fmt.Sprintf("SYN:%t ACK:%t FIN:%t RST:%t PSH:%t URG:%t",
					transLayer.SYN, transLayer.ACK, transLayer.FIN, transLayer.RST, transLayer.PSH, transLayer.URG)
			case *layers.UDP:
				src, dst := transLayer.TransportFlow().Endpoints()
				sourcePort = src.String()
				destinationPort = dst.String()
			}
		}

		// Extract application layer (FTP, SMTP, HTTP, etc.)
		if applicationLayer := packet.ApplicationLayer(); applicationLayer != nil {
			payload = applicationLayer.Payload()

			// Infer application protocol based on port numbers
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
		}

		fmt.Printf(
			"Packet:\n  Timestamp: %s\n  Network Protocol: %s\n  Application Protocol: %s\n  Source IP: %s\n  Source Port: %s\n  Destination IP: %s\n  Destination Port: %s\n  TTL: %d\n  Flags: %s\n  Length: %d\n  Payload: %x\n\n",
			timestamp, protocol, appProtocol, sourceIP, sourcePort, destinationIP, destinationPort, ttl, tcpFlags, packetLength, payload,
		)
	}
	return nil
}