package main

import (
	"bytes"
	"fmt"
	"log"
	_ "net"
	_ "os"
	"strings"
	"time"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
)

func CaptureAndLogAllFields(iface string) error {
	handle, err := pcap.OpenLive(iface, 1600, true, pcap.BlockForever)
	if err != nil {
		return fmt.Errorf("error opening interface: %v", err)
	}
	defer handle.Close()

	// Set BPF filter to capture common application protocols
	err = handle.SetBPFFilter("tcp or udp")
	if err != nil {
		return fmt.Errorf("error setting BPF filter: %v", err)
	}

	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	packetSource.DecodeOptions.Lazy = true
	packetSource.DecodeOptions.NoCopy = true

	fmt.Printf("Starting packet capture on %s...\n", iface)
	
	for packet := range packetSource.Packets() {
		var (
			timestamp    time.Time
			ethLayer     *layers.Ethernet
			ipv4Layer    *layers.IPv4
			ipv6Layer    *layers.IPv6
			tcpLayer     *layers.TCP
			udpLayer     *layers.UDP
			dnsLayer     *layers.DNS
			httpProtocol string
			payload      []byte
		)

		// Initialize metadata
		timestamp = packet.Metadata().Timestamp
		protocol := "UNKNOWN"
		applicationLayer := packet.ApplicationLayer()

		// Parse network layers
		for _, layer := range packet.Layers() {
			switch layer.LayerType() {
			case layers.LayerTypeEthernet:
				ethLayer = layer.(*layers.Ethernet)
			case layers.LayerTypeIPv4:
				ipv4Layer = layer.(*layers.IPv4)
			case layers.LayerTypeIPv6:
				ipv6Layer = layer.(*layers.IPv6)
			case layers.LayerTypeTCP:
				tcpLayer = layer.(*layers.TCP)
			case layers.LayerTypeUDP:
				udpLayer = layer.(*layers.UDP)
			case layers.LayerTypeDNS:
				dnsLayer = layer.(*layers.DNS)
			}
		}

		// Get source/destination information
		srcIP, dstIP := getIPAddresses(ipv4Layer, ipv6Layer)
		srcPort, dstPort := getPorts(tcpLayer, udpLayer)
		
		// Protocol classification
		if applicationLayer != nil {
			payload = applicationLayer.Payload()
			protocol = classifyProtocol(packet, payload, tcpLayer, udpLayer)
			
			// Special handling for HTTP
			if isHTTP(payload) {
				httpProtocol = extractHTTPProtocol(payload)
			}
		}

		// Build log output
		logOutput := fmt.Sprintf("[%s] %s %s:%s -> %s:%s",
			timestamp.Format(time.RFC3339),
			protocol,
			srcIP,
			srcPort,
			dstIP,
			dstPort,
		)

		// Add protocol-specific details
		switch {
		case dnsLayer != nil:
			logOutput += fmt.Sprintf(" | DNS: %v", dnsLayer.Questions)
		case httpProtocol != "":
			logOutput += fmt.Sprintf(" | HTTP: %s", httpProtocol)
		case len(payload) > 0:
			logOutput += fmt.Sprintf(" | Payload: %.64q", payload)
		}

		// Add Ethernet details if available
		if ethLayer != nil {
			logOutput += fmt.Sprintf(" | MAC: %s->%s",
				ethLayer.SrcMAC,
				ethLayer.DstMAC)
		}

		log.Println(logOutput)
	}

	return nil
}

func classifyProtocol(packet gopacket.Packet, payload []byte, tcp *layers.TCP, udp *layers.UDP) string {
	// Check known port-based protocols first
	if tcp != nil {
		switch {
		case tcp.SrcPort == 80 || tcp.DstPort == 80:
			return "HTTP"
		case tcp.SrcPort == 443 || tcp.DstPort == 443:
			return "HTTPS"
		case tcp.SrcPort == 22 || tcp.DstPort == 22:
			return "SSH"
		case tcp.SrcPort == 25 || tcp.DstPort == 25:
			return "SMTP"
		case tcp.SrcPort == 21 || tcp.DstPort == 21:
			return "FTP"
		case tcp.SrcPort == 53 || tcp.DstPort == 53:
			return "DNS"
		}
	}

	if udp != nil {
		switch {
		case udp.SrcPort == 53 || udp.DstPort == 53:
			return "DNS"
		case udp.SrcPort == 67 || udp.DstPort == 68:
			return "DHCP"
		}
	}

	// Content-based detection
	switch {
	case isHTTP(payload):
		return "HTTP"
	case isSMTP(payload):
		return "SMTP"
	case isFTP(payload):
		return "FTP"
	case isDNS(packet):
		return "DNS"
	case isTLS(payload):
		return "TLS"
	}

	return "UNKNOWN"
}

func getIPAddresses(ipv4 *layers.IPv4, ipv6 *layers.IPv6) (srcIP, dstIP string) {
	if ipv4 != nil {
		return ipv4.SrcIP.String(), ipv4.DstIP.String()
	}
	if ipv6 != nil {
		return ipv6.SrcIP.String(), ipv6.DstIP.String()
	}
	return "", ""
}

func getPorts(tcp *layers.TCP, udp *layers.UDP) (srcPort, dstPort string) {
	if tcp != nil {
		return tcp.SrcPort.String(), tcp.DstPort.String()
	}
	if udp != nil {
		return udp.SrcPort.String(), udp.DstPort.String()
	}
	return "", ""
}

func isHTTP(payload []byte) bool {
	return bytes.HasPrefix(payload, []byte("HTTP/")) ||
		bytes.Contains(payload, []byte("GET ")) ||
		bytes.Contains(payload, []byte("POST ")) ||
		bytes.Contains(payload, []byte("Host: "))
}

func extractHTTPProtocol(payload []byte) string {
	if bytes.HasPrefix(payload, []byte("HTTP/")) {
		return "Response"
	}
	return "Request"
}

func isSMTP(payload []byte) bool {
	str := string(payload)
	return strings.HasPrefix(str, "EHLO") ||
		strings.HasPrefix(str, "HELO") ||
		strings.Contains(str, "MAIL FROM:")
}

func isFTP(payload []byte) bool {
	str := string(payload)
	return strings.HasPrefix(str, "USER ") ||
		strings.HasPrefix(str, "PASS ") ||
		strings.HasPrefix(str, "220 ")
}

func isDNS(packet gopacket.Packet) bool {
	return packet.Layer(layers.LayerTypeDNS) != nil
}

func isTLS(payload []byte) bool {
	return len(payload) > 0 && (payload[0] == 0x16 || payload[0] == 0x17)
}

