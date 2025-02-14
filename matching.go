package main

import (
	"bytes"
	"encoding/hex"
	_ "encoding/json"
	"log"
	"net"
	"strconv"
	"strings"
	_ "os"
)


// SnortRule represents a complete JSON rule.
type SnortRule struct {
	// Required header fields:
	Action          string `json:"action"`
	Protocol        string `json:"protocol"`
	SourceIP        string `json:"source_ip"`
	SourcePort      string `json:"source_port"`
	DestinationIP   string `json:"destination_ip"`
	DestinationPort string `json:"destination_port"`

	// Unique rule identifier (SID) is required.
	SID string `json:"sid"`

	// Options that are usually unique:
	Message   string `json:"msg"`
	Revision  string `json:"rev"`
	GID       string `json:"gid,omitempty"`
	Classtype string `json:"classtype,omitempty"`
	Content   string `json:"content,omitempty"`
	Flow      string `json:"flow,omitempty"`
	Depth     string `json:"depth,omitempty"`
	Offset    string `json:"offset,omitempty"`
	Flags     string `json:"flags,omitempty"`
	Priority  string `json:"priority,omitempty"`

	// Options that can occur multiple times:
	Flowbits  []string          `json:"flowbits,omitempty"`
	Reference []string          `json:"reference,omitempty"`

	// Metadata parsed into a key/value mapping.
	Metadata map[string]string `json:"metadata,omitempty"`
}

// Packet represents a network packet. In addition to the fields already
// used for matching, we add some extra properties (Flow, Flags, Flowbits)
// that could be used to match the extra rule fields.
type Packet struct {
	Protocol        string
	SourceIP        string
	SourcePort      int
	DestinationIP   string
	DestinationPort int
	Payload         []byte
	// Additional packet properties for matching rule options:
	Flow     string   // e.g. "established,to_server"
	Flags    string   // e.g. "S, A" (comma-separated if multiple)
	Flowbits []string // e.g. list of flowbits that are set
}

// matchIP compares a rule IP field with the packet IP. It handles "any",
// "$HOME_NET", "$EXTERNAL_NET", and CIDR notation.
func matchIP(ruleIP, packetIP string) bool {
	ruleIP = strings.TrimSpace(ruleIP)
	if strings.ToLower(ruleIP) == "any" {
		return true
	}
	// For demonstration, define $HOME_NET here.
	
	if ruleIP == "$HOME_NET" {
		_, cidr, err := net.ParseCIDR(homeNet)
		log.Println("This is homenet", homeNet)
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
		// External if not in $HOME_NET
		return ip != nil && !cidr.Contains(ip)
	}
	if strings.Contains(ruleIP, "/") {
		_, cidr, err := net.ParseCIDR(ruleIP)
		if err != nil {
			log.Println("Error parsing CIDR", ruleIP, err)
			return false
		}
		ip := net.ParseIP(packetIP)
		return ip != nil && cidr.Contains(ip)
	}
	return ruleIP == packetIP
}

// matchPort compares the packet port with the rule port field.
// It handles "any", a single port, ranges (e.g. "0:1023"), lists (e.g. "[139,445]")
// and variables like "$HTTP_PORTS".
func matchPort(rulePort string, packetPort int) bool {
	rulePort = strings.TrimSpace(rulePort)
	if strings.ToLower(rulePort) == "any" {
		return true
	}
	if strings.HasPrefix(rulePort, "$") {
		if rulePort == "$HTTP_PORTS" {
			httpPorts := []int{80, 8080}
			for _, p := range httpPorts {
				if p == packetPort {
					return true
				}
			}
		}
		return false
	}
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
// taking into account offset and depth constraints.
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

// contains is a helper that checks if a slice of strings contains a given string.
func contains(slice []string, s string) bool {
	for _, v := range slice {
		if v == s {
			return true
		}
	}
	return false
}

// MatchPacket checks if a given packet matches the provided SnortRule.
// It compares header fields (protocol, IPs, ports) and, if specified,
// payload content (using content, offset, depth) as well as additional
// matching fields such as Flow, Flags, and Flowbits.
func MatchPacket(pkt Packet, rule SnortRule) bool {
	// Check protocol (case-insensitive)
	if strings.ToLower(rule.Protocol) != strings.ToLower(pkt.Protocol) {
		return false
	}
	// Check source and destination IP addresses
	if !matchIP(rule.SourceIP, pkt.SourceIP) || !matchIP(rule.DestinationIP, pkt.DestinationIP) {
		return false
	}
	// Check source and destination ports
	if !matchPort(rule.SourcePort, pkt.SourcePort) || !matchPort(rule.DestinationPort, pkt.DestinationPort) {
		return false
	}
	// Check payload content if specified
	if rule.Content != "" {
		if !matchContent(rule.Content, pkt.Payload, rule.Offset, rule.Depth) {
			return false
		}
	}
	// Check Flow field if specified (for example, expecting certain flow tokens)
	if rule.Flow != "" {
		flowTokens := strings.Split(rule.Flow, ",")
		for _, token := range flowTokens {
			token = strings.TrimSpace(token)
			if token != "" && !strings.Contains(pkt.Flow, token) {
				return false
			}
		}
	}
	// Check Flags field if specified (for TCP flags)
	if rule.Flags != "" {
		ruleFlags := strings.Split(rule.Flags, ",")
		packetFlags := strings.Split(pkt.Flags, ",")
		for _, flag := range ruleFlags {
			flag = strings.TrimSpace(flag)
			if flag != "" && !contains(packetFlags, flag) {
				return false
			}
		}
	}
	// Check Flowbits if specified
	if len(rule.Flowbits) > 0 {
		for _, bit := range rule.Flowbits {
			if !contains(pkt.Flowbits, bit) {
				return false
			}
		}
	}
	// Note: Revision, GID, Classtype, Priority, Reference, and Metadata are typically not used
	// for matching packet characteristics.
	return true
}



// matching simulates the matching process based on input parameters.
// It loads the rules from a file, builds a Packet, and checks each rule.
func matching(rules []SnortRule, protocol *string, sip *string, sport *int, dip *string, dport *int, payloadStr *string, flow *string, flags *string, pktFlowbits *[]string) {
	
	// Build the packet from command-line parameters
	pkt := Packet{
		Protocol:        *protocol,
		SourceIP:        *sip,
		SourcePort:      *sport,
		DestinationIP:   *dip,
		DestinationPort: *dport,
		Payload:         []byte(*payloadStr),
		Flow:            *flow,
		Flags:           *flags,
		Flowbits:        *pktFlowbits,
	}
	matched := false
	for _, rule := range rules {
		if MatchPacket(pkt, rule) {
			matched = true
			log.Printf("ALERT: Packet matched rule SID %s - %s\n", rule.SID, rule.Message)
		}
	}
	if !matched {
		log.Println("No matching rules found for the given packet")
	}
}

