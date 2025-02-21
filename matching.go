package main

import (
	"bytes"
	_ "encoding/hex"
	_ "encoding/json"
	"log"
	"net"
	"strconv"
	"strings"
	_ "os"
	_"time"
	_"sync"
	_"fmt"
)

// --- Snort Rule and Packet Definitions ---

// SnortRule represents a complete JSON rule.
type SnortRule struct {
	// Required header fields:
	Action          string            `json:"action"`
	Protocol        string            `json:"protocol"`
	SourceIP        string            `json:"source_ip"`
	SourcePort      string            `json:"source_port"`
	DestinationIP   string            `json:"destination_ip"`
	DestinationPort string            `json:"destination_port"`

	// Unique rule identifier (SID) is required.
	SID string `json:"sid"`

	// Options that are usually unique:
	Message   string            `json:"msg"`
	Revision  string            `json:"rev"`
	GID       string            `json:"gid,omitempty"`
	Classtype string            `json:"classtype,omitempty"`
	Content   string            `json:"content,omitempty"`
	Flow      string            `json:"flow,omitempty"`
	Depth     string            `json:"depth,omitempty"`
	Offset    string            `json:"offset,omitempty"`
	Flags     string            `json:"flags,omitempty"`
	Priority  string            `json:"priority,omitempty"`

	// Options that can occur multiple times:
	Flowbits  []string          `json:"flowbits,omitempty"`
	Reference []string          `json:"reference,omitempty"`

	// Metadata parsed into a key/value mapping.
	Metadata  map[string]string `json:"metadata,omitempty"`

	// For content matching – assuming rule.Pattern holds the raw pattern bytes.
	Pattern   []byte            `json:"pattern,omitempty"`
}

// Packet represents a network packet.
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
	Flowbits []string // e.g. list of flowbits that are set (from flow tracking)
}

// --- Matching Helpers (IP, Port, Flags, Content, contains) ---

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

func tcpFlagsMatch(packetFlags, ruleFlags string) bool {
	packetFlagSet := make(map[rune]bool)
	for _, flag := range packetFlags {
		packetFlagSet[flag] = true
	}
	for _, flag := range ruleFlags {
		if !packetFlagSet[flag] {
			return false
		}
	}
	return true
}

func matchContent(pattern []byte, payload []byte, offsetStr, depthStr string) bool {
	if len(pattern) == 0 {
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
	return bytes.Contains(searchRegion, pattern)
}

func contains(slice []string, s string) bool {
	for _, v := range slice {
		if v == s {
			return true
		}
	}
	return false
}



// --- Packet Matching ---

func MatchPacket(pkt Packet, rule LoadedJsonRules) bool {
	// Check protocol (case-insensitive)
	if strings.ToLower(rule.Protocol) != strings.ToLower(pkt.Protocol) {
		return false
	}
	// Check IP addresses
	if !matchIP(rule.SourceIP, pkt.SourceIP) || !matchIP(rule.DestinationIP, pkt.DestinationIP) {
		return false
	}
	// Check ports
	if !matchPort(rule.SourcePort, pkt.SourcePort) || !matchPort(rule.DestinationPort, pkt.DestinationPort) {
		return false
	}
	// Check payload content if specified
	if rule.Content != "" {
		if !matchContent(rule.Pattern, pkt.Payload, rule.Offset, rule.Depth) {
			return false
		}
	}
	// Check Flow field if specified
	if rule.Flow != "" {
		flowTokens := strings.Split(rule.Flow, ",")
		for _, token := range flowTokens {
			token = strings.TrimSpace(token)
			if token != "" && !strings.Contains(pkt.Flow, token) {
				return false
			}
		}
	}
	// Check Flags field if specified
	if rule.Flags != "" {
		if !tcpFlagsMatch(rule.Flags, pkt.Flags) {
			return false
		}
	}
	// Note: We now handle flowbits tests separately in matching()
	return true
}

// --- Flowbits Matching Helpers ---

// flowbitsTest checks test conditions in the rule's Flowbits array.
// For entries like "isnotset,bitname" or "isset,bitname", it verifies whether
// the packet's current Flowbits satisfy the condition.
func flowbitsTest(pkt Packet, ruleBits []string) bool {
	for _, entry := range ruleBits {
		entry = strings.TrimSpace(entry)
		// Skip non-test modifiers like "noalert"
		if strings.ToLower(entry) == "noalert" {
			continue
		}
		parts := strings.SplitN(entry, ",", 2)
		if len(parts) < 2 {
			// If not in "operator,bit" format, assume a plain test for existence.
			if !contains(pkt.Flowbits, entry) {
				return false
			}
			continue
		}
		operator := strings.ToLower(strings.TrimSpace(parts[0]))
		bit := strings.TrimSpace(parts[1])
		switch operator {
		case "isnotset":
			if contains(pkt.Flowbits, bit) {
				return false
			}
		case "isset":
			if !contains(pkt.Flowbits, bit) {
				return false
			}
		// "set" and "unset" are action operators, not tests.
		}
	}
	return true
}

// flowbitsActions processes action operators in the rule's Flowbits array.
// It performs actions such as "set" or "unset" on the flow record.
func flowbitsActions(pkt Packet, ruleBits []string) {
	for _, entry := range ruleBits {
		entry = strings.TrimSpace(entry)
		parts := strings.SplitN(entry, ",", 2)
		if len(parts) < 2 {
			continue
		}
		operator := strings.ToLower(strings.TrimSpace(parts[0]))
		bit := strings.TrimSpace(parts[1])
		switch operator {
		case "set":
			SetFlowbit(pkt, bit)
		case "unset":
			UnsetFlowbit(pkt, bit)
		}
	}
}

// flowbitsNoAlert checks if the rule includes the "noalert" modifier.
func flowbitsNoAlert(ruleBits []string) bool {
	for _, entry := range ruleBits {
		if strings.ToLower(strings.TrimSpace(entry)) == "noalert" {
			return true
		}
	}
	return false
}

// --- Matching Process ---

// matching simulates the matching process based on input parameters.
// It builds a Packet and checks each rule, integrating proper flowbits matching:
// first, it tests any flowbit conditions (via flowbitsTest); if these pass, it then
// calls MatchPacket; on a match, it executes any flowbit actions (via flowbitsActions)
// and logs an alert unless the rule includes a "noalert" modifier.
func matching(rules []LoadedJsonRules, protocol *string, sip *string, sport *int, dip *string, dport *int, payload *[]byte, flow *string, flags *string, pktFlowbits *[]string) {

	// Build the packet from command-line parameters.
	pkt := Packet{
		Protocol:        *protocol,
		SourceIP:        *sip,
		SourcePort:      *sport,
		DestinationIP:   *dip,
		DestinationPort: *dport,
		Payload:         []byte(*payload),
		Flow:            *flow,
		Flags:           *flags,
		Flowbits:        *pktFlowbits,
	}
	matched := false
	for _, rule := range rules {
		// If the rule has flowbits test conditions, check them first.
		if len(rule.Flowbits) > 0 {
			if !flowbitsTest(pkt, rule.Flowbits) {
				continue // Skip rule if flowbit test fails.
			}
		}
		// Then check the remainder of the rule.
		if MatchPacket(pkt, rule) {
			matched = true
			// Perform any flowbit actions (e.g. set or unset) after a match.
			if len(rule.Flowbits) > 0 {
				flowbitsActions(pkt, rule.Flowbits)
			}
			// Log an alert unless the rule includes a "noalert" modifier.
			if !flowbitsNoAlert(rule.Flowbits) {
				log.Printf("ALERT: Packet matched rule SID %s - %s\n", rule.SID, rule.Message)
			}
		}
	}
	if !matched {
		log.Println("No matching rules found for the given packet")
	}
}
