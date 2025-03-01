package main

import (
	_"bytes"

	_ "encoding/hex"
	_ "encoding/json"
	_"log"
	_"net"
	"strconv"
	"strings"
	_ "os"
	"time"
	"sync"
	"fmt"
)



// --- Flow Tracking Code (for reference) ---

// FlowKey uniquely identifies a flow.
type FlowKey struct {
	SourceIP        string
	DestinationIP   string
	SourcePort      string
	DestinationPort string
	Protocol        string
}

// FlowRecord stores aggregated flow information, including state and flowbits.
type FlowRecord struct {
	Key         FlowKey
	PacketCount int
	ByteCount   int
	StartTime   time.Time
	LastUpdate  time.Time
	// New fields for flow state and flowbits.
	FlowState string          // e.g., "SYN_SENT", "SYN_RECEIVED", "ESTABLISHED", "FIN_WAIT", "RESET"
	Flowbits  map[string]bool // Use a map for quick lookup of set flowbits.
}

var (
	flowTable   = make(map[FlowKey]*FlowRecord)
	flowTableMu sync.Mutex
)

// computeFlowState computes the updated TCP state based on packet flags and the current state.
func computeFlowState(flags string, currentState string) string {
	// Highest precedence: RST always resets the connection.
	if strings.Contains(flags, "R") {
		return "RESET"
	}
	// FIN indicates the connection is closing.
	if strings.Contains(flags, "F") {
		return "FIN_WAIT"
	}
	// SYN only (without ACK): initial client request.
	if strings.Contains(flags, "S") && !strings.Contains(flags, "A") {
		return "SYN_SENT"
	}
	// SYN+ACK: server response. Transition from SYN_SENT/new to SYN_RECEIVED.
	if strings.Contains(flags, "S") && strings.Contains(flags, "A") {
		if currentState == "SYN_SENT" || currentState == "new" || currentState == "" {
			return "SYN_RECEIVED"
		}
	}
	// ACK only: if coming after a SYN exchange, move to ESTABLISHED.
	if strings.Contains(flags, "A") {
		if currentState == "SYN_SENT" || currentState == "SYN_RECEIVED" || currentState == "new" || currentState == "" {
			return "ESTABLISHED"
		}
	}
	// If none of the above conditions apply, retain the current state.
	return currentState
}

// UpdateFlow updates the flow record with the new packet.
// It uses computeFlowState() to update the TCP state based on the packet flags.
func UpdateFlow(packet CapturedPacket) {
	key := FlowKey{
		SourceIP:        packet.SourceIP,
		DestinationIP:   packet.DestinationIP,
		SourcePort:      packet.SourcePort,
		DestinationPort: packet.DestinationPort,
		Protocol:        packet.NetworkProtocol,
	}
	now := time.Now()

	flowTableMu.Lock()
	defer flowTableMu.Unlock()

	if flow, exists := flowTable[key]; exists {
		flow.PacketCount++
		flow.ByteCount += packet.Length
		flow.LastUpdate = now
		// Update flow state using enhanced TCP state logic.
		flow.FlowState = computeFlowState(packet.Flags, flow.FlowState)
	} else {
		// Create a new flow record using the initial TCP state computed from packet flags.
		initialState := computeFlowState(packet.Flags, "")
		flowTable[key] = &FlowRecord{
			Key:         key,
			PacketCount: 1,
			ByteCount:   packet.Length,
			StartTime:   now,
			LastUpdate:  now,
			FlowState:   initialState,
			Flowbits:    make(map[string]bool),
		}
	}
}

// GetFlowInfo retrieves the flow state and flowbits for a given packet.
func GetFlowInfo(packet  CapturedPacket) (string, []string) {
	key := FlowKey{
		SourceIP:        packet.SourceIP,
		DestinationIP:   packet.DestinationIP,
		SourcePort:      packet.SourcePort,
		DestinationPort: packet.DestinationPort,
		Protocol:        packet.NetworkProtocol,
	}

	flowTableMu.Lock()
	defer flowTableMu.Unlock()

	if flow, exists := flowTable[key]; exists {
		var bits []string
		for bit := range flow.Flowbits {
			bits = append(bits, bit)
		}
		return flow.FlowState, bits
	}
	return "", nil
}

// SetFlowbit sets a flowbit on the corresponding flow record.
func SetFlowbit(packet Packet, bit string) {
	key := FlowKey{
		SourceIP:        packet.SourceIP,
		DestinationIP:   packet.DestinationIP,
		SourcePort:      strconv.Itoa(packet.SourcePort),
		DestinationPort: strconv.Itoa(packet.DestinationPort),
		Protocol:        packet.Protocol,
	}
	flowTableMu.Lock()
	defer flowTableMu.Unlock()

	if flow, exists := flowTable[key]; exists {
		flow.Flowbits[bit] = true
	} else {
		now := time.Now()
		flowTable[key] = &FlowRecord{
			Key:         key,
			PacketCount: 1,
			ByteCount:   0,
			StartTime:   now,
			LastUpdate:  now,
			FlowState:   "",
			Flowbits:    map[string]bool{bit: true},
		}
	}
}

// UnsetFlowbit removes a flowbit from the flow record associated with the provided packet.
func UnsetFlowbit(packet Packet, bit string) {
	key := FlowKey{
		SourceIP:        packet.SourceIP,
		DestinationIP:   packet.DestinationIP,
		SourcePort:      strconv.Itoa(packet.SourcePort),
		DestinationPort: strconv.Itoa(packet.DestinationPort),
		Protocol:        packet.Protocol,
	}
	flowTableMu.Lock()
	defer flowTableMu.Unlock()

	if flow, exists := flowTable[key]; exists {
		delete(flow.Flowbits, bit)
	}
}

// HasFlowbit checks whether a given flowbit is set on the flow record for the provided packet.
func HasFlowbit(packet CapturedPacket, bit string) bool {
	key := FlowKey{
		SourceIP:        packet.SourceIP,
		DestinationIP:   packet.DestinationIP,
		SourcePort:      packet.SourcePort,
		DestinationPort: packet.DestinationPort,
		Protocol:        packet.NetworkProtocol,
	}
	flowTableMu.Lock()
	defer flowTableMu.Unlock()

	if flow, exists := flowTable[key]; exists {
		_, existsBit := flow.Flowbits[bit]
		return existsBit
	}
	return false
}

// CleanupFlows removes flows that have not been updated within the specified timeout.
func CleanupFlows(timeout time.Duration) {
	now := time.Now()
	flowTableMu.Lock()
	defer flowTableMu.Unlock()

	for key, flow := range flowTable {
		if now.Sub(flow.LastUpdate) > timeout {
			delete(flowTable, key)
		}
	}
}

// PrintFlows logs current flow records (useful for debugging).
func PrintFlows() {
	flowTableMu.Lock()
	defer flowTableMu.Unlock()

	for key, flow := range flowTable {
		var bits []string
		for b := range flow.Flowbits {
			bits = append(bits, b)
		}
		fmt.Printf("Flow: [%s:%s -> %s:%s | %s] State: %s, Packets: %d, Bytes: %d, Flowbits: %v\n",
			key.SourceIP, key.SourcePort, key.DestinationIP, key.DestinationPort, key.Protocol,
			flow.FlowState, flow.PacketCount, flow.ByteCount, bits)
	}
}