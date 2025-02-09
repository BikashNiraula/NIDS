// matcher.go
package main

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	_"flag"
	"log"
	"net"
	"os"
	"strconv"
	"strings"
)

// Rule represents a signature rule from the JSON file.
type Rule struct {
	Action          string `json:"action"`
	Protocol        string `json:"protocol"`
	SourceIP        string `json:"source_ip"`
	SourcePort      string `json:"source_port"`
	DestinationIP   string `json:"destination_ip"`
	DestinationPort string `json:"destination_port"`
	Sid             string `json:"sid"`
	Msg             string `json:"msg"`
	Content         string `json:"content,omitempty"`
	Depth           string `json:"depth,omitempty"`
	Offset          string `json:"offset,omitempty"`
	// (Other fields like flow, flags, metadata, etc. can be added as needed.)
}

// LoadRules loads and unmarshals the JSON signature file.
func LoadRules(filename string) ([]Rule, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	var rules []Rule
	if err := json.Unmarshal(data, &rules); err != nil {
		return nil, err
	}
	return rules, nil
}

// matchIP compares a rule IP field with the packet IP. It handles "any", "$HOME_NET", "$EXTERNAL_NET", and CIDR notation.
func matchIP(ruleIP, packetIP string) bool {
	ruleIP = strings.TrimSpace(ruleIP)
	if strings.ToLower(ruleIP) == "any" {
		return true
	}

	// For demonstration, we define $HOME_NET here.
	homeNet := "192.168.1.0/24"
	if ruleIP == "$HOME_NET" {
		_, cidr, err := net.ParseCIDR(homeNet)
		if err != nil {
			log.Println("Error parsing homeNet:", err)
			return false
		}
		ip := net.ParseIP(packetIP)
		return ip != nil && cidr.Contains(ip)
	}
	if ruleIP == "$EXTERNAL_NET" {
		_, cidr, err := net.ParseCIDR(homeNet)
		if err != nil {
			log.Println("Error parsing homeNet:", err)
			return false
		}
		ip := net.ParseIP(packetIP)
		// Assume external means not in homeNet.
		return ip != nil && !cidr.Contains(ip)
	}
	// If ruleIP is in CIDR notation:
	if strings.Contains(ruleIP, "/") {
		_, cidr, err := net.ParseCIDR(ruleIP)
		if err != nil {
			log.Println("Error parsing CIDR", ruleIP, err)
			return false
		}
		ip := net.ParseIP(packetIP)
		return ip != nil && cidr.Contains(ip)
	}
	// Otherwise, direct comparison.
	return ruleIP == packetIP
}

// matchPort compares the packet port with the rule's port field.
// It handles "any", single ports, ranges (e.g., "0:1023"), lists (e.g., "[139,445]")
// and variables like "$HTTP_PORTS".
func matchPort(rulePort string, packetPort int) bool {
	rulePort = strings.TrimSpace(rulePort)
	if strings.ToLower(rulePort) == "any" {
		return true
	}
	// Example variable: "$HTTP_PORTS"
	if strings.HasPrefix(rulePort, "$") {
		if rulePort == "$HTTP_PORTS" {
			// Define your HTTP ports mapping
			httpPorts := []int{80, 8080}
			for _, p := range httpPorts {
				if p == packetPort {
					return true
				}
			}
		}
		return false
	}
	// Check for port range (e.g., "0:1023")
	if strings.Contains(rulePort, ":") {
		parts := strings.Split(rulePort, ":")
		if len(parts) != 2 {
			return false
		}
		low, err1 := strconv.Atoi(parts[0])
		high, err2 := strconv.Atoi(parts[1])
		if err1 != nil || err2 != nil {
			return false
		}
		return packetPort >= low && packetPort <= high
	}
	// Check for a list (e.g., "[139,445]")
	if strings.HasPrefix(rulePort, "[") && strings.HasSuffix(rulePort, "]") {
		list := rulePort[1 : len(rulePort)-1]
		ports := strings.Split(list, ",")
		for _, p := range ports {
			p = strings.TrimSpace(p)
			val, err := strconv.Atoi(p)
			if err == nil && val == packetPort {
				return true
			}
		}
		return false
	}
	// Otherwise, assume a single port.
	val, err := strconv.Atoi(rulePort)
	if err != nil {
		return false
	}
	return packetPort == val
}

// parseContentPattern converts a rule content string into a byte slice.
// If the content is enclosed in "|" characters, it is assumed to be a hex pattern.
func parseContentPattern(content string) ([]byte, error) {
	content = strings.TrimSpace(content)
	if strings.HasPrefix(content, "|") && strings.HasSuffix(content, "|") {
		hexStr := strings.Trim(content, "|")
		hexStr = strings.ReplaceAll(hexStr, " ", "")
		return hex.DecodeString(hexStr)
	}
	return []byte(content), nil
}

// matchContent searches for the rule's content pattern in the packet payload,
// taking into account any offset and depth constraints.
func matchContent(ruleContent string, payload []byte, offsetStr, depthStr string) bool {
	if ruleContent == "" {
		return true
	}
	offset := 0
	depth := len(payload)
	var err error
	if offsetStr != "" {
		offset, err = strconv.Atoi(offsetStr)
		if err != nil {
			offset = 0
		}
	}
	if depthStr != "" {
		depth, err = strconv.Atoi(depthStr)
		if err != nil {
			depth = len(payload)
		}
	}
	if offset > len(payload) {
		return false
	}
	end := offset + depth
	if end > len(payload) {
		end = len(payload)
	}
	searchRegion := payload[offset:end]
	pattern, err := parseContentPattern(ruleContent)
	if err != nil {
		log.Println("Error parsing content pattern:", err)
		return false
	}
	return bytes.Contains(searchRegion, pattern)
}

// Packet represents a network packet.
type Packet struct {
	Protocol        string
	SourceIP        string
	SourcePort      int
	DestinationIP   string
	DestinationPort int
	Payload         []byte
}

// MatchPacket checks if a given packet matches the provided rule.
func MatchPacket(pkt Packet, rule Rule) bool {
	// Check protocol (case-insensitive).
	if strings.ToLower(rule.Protocol) != strings.ToLower(pkt.Protocol) {
		return false
	}
	// Check source and destination IP addresses.
	if !matchIP(rule.SourceIP, pkt.SourceIP) || !matchIP(rule.DestinationIP, pkt.DestinationIP) {
		return false
	}
	// Check source and destination ports.
	if !matchPort(rule.SourcePort, pkt.SourcePort) || !matchPort(rule.DestinationPort, pkt.DestinationPort) {
		return false
	}
	// Check payload content if specified.
	if rule.Content != "" {
		if !matchContent(rule.Content, pkt.Payload, rule.Offset, rule.Depth) {
			return false
		}
	}
	// (Additional checks for flow, flags, flowbits, etc. can be added here.)
	return true
}

func matching(ruleFile *string,protocol *string,sip *string,sport *int, dip *string,dport *int, payloadStr *string) {
	// Define command-line flags.
	// ruleFile := flag.String("rules", "rules.json", "Path to JSON file containing signature rules")
	// protocol := flag.String("protocol", "", "Packet protocol (tcp/udp)")
	// sip := flag.String("sip", "", "Source IP address")
	// sport := flag.Int("sport", 0, "Source port")
	// dip := flag.String("dip", "", "Destination IP address")
	// dport := flag.Int("dport", 0, "Destination port")
	// payloadStr := flag.String("payload", "", "Packet payload as a string")

	// flag.Parse()

	// Check for required flags.
	// if *protocol == "" || *sip == "" || *dip == "" {
	// 	log.Fatal("protocol, sip, and dip flags are required")
	// }

	// Load signature rules from the specified file.
	rules, err := LoadRules(*ruleFile)
	if err != nil {
		log.Fatal("Error loading rules: ", err)
	}

	// Create a Packet from the provided flags.
	pkt := Packet{
		Protocol:        *protocol,
		SourceIP:        *sip,
		SourcePort:      *sport,
		DestinationIP:   *dip,
		DestinationPort: *dport,
		Payload:         []byte(*payloadStr),
	}

	// Check the packet against all rules.
	matched := false
	for _, rule := range rules {
		if MatchPacket(pkt, rule) {
			matched = true
			log.Printf("ALERT: Packet matched rule SID %s - %s\n", rule.Sid, rule.Msg)
		}
	}
	if !matched {
		log.Println("No matching rules found for the given packet")
	}
}
