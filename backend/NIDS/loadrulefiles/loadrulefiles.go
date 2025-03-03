package loadrulefiles

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

// Threshold represents the threshold configuration for a rule.
type ThresholdOptions struct {
	Type    string `json:"type"`
	Count   string `json:"count"`
	Seconds string `json:"seconds"`
	Track   string `json:"track"`
}

// LoadedJsonRules represents a complete JSON rule including threshold.
type LoadedJsonRules struct {
	// Required header fields:
	Action          string            `json:"action"`
	Protocol        string            `json:"protocol"`
	SourceIP        string            `json:"source_ip"`
	SourcePort      string            `json:"source_port"`
	DestinationIP   string            `json:"destination_ip"`
	DestinationPort string            `json:"destination_port"`
	SID             string            `json:"sid"`
	Message         string            `json:"msg"`
	Revision        string            `json:"rev"`
	GID             string            `json:"gid,omitempty"`
	Classtype       string            `json:"classtype,omitempty"`
	Content         string            `json:"content,omitempty"`
	Flow            string            `json:"flow,omitempty"`
	Depth           string            `json:"depth,omitempty"`
	Offset          string            `json:"offset,omitempty"`
	Flags           string            `json:"flags,omitempty"`
	Priority        string            `json:"priority,omitempty"`
	Flowbits        []string          `json:"flowbits,omitempty"`
	Reference       []string          `json:"reference,omitempty"`
	Metadata        map[string]string `json:"metadata,omitempty"`

	// New: Threshold configuration
	Threshold *ThresholdOptions `json:"threshold,omitempty"`

	// Pattern holds the processed content as raw bytes.
	Pattern []byte `json:"-"`
}

// processContent converts a rule's Content string into a []byte.
// It handles both plain text and mixed content with hex segments.
// For example, a Content value of "google|17 56|" will be converted to
// []byte("google") concatenated with hex-decoded bytes from "17 56".
func processContent(content string) ([]byte, error) {
	// If there is no '|' character, treat the whole string as plain text.
	if !strings.Contains(content, "|") {
		return []byte(content), nil
	}
	// Split on the delimiter "|". Even-indexed parts are plain text,
	// odd-indexed parts are hex.
	parts := strings.Split(content, "|")
	var result []byte
	for i, part := range parts {
		// Even index: literal text.
		if i%2 == 0 {
			result = append(result, []byte(part)...)
		} else {
			// Odd index: hex content. Remove any spaces.
			clean := strings.ReplaceAll(part, " ", "")
			if clean == "" {
				continue
			}
			decoded, err := hex.DecodeString(clean)
			if err != nil {
				return nil, fmt.Errorf("error decoding hex segment '%s': %v", part, err)
			}
			result = append(result, decoded...)
		}
	}
	return result, nil
}

// LoadRules loads and unmarshals a JSON file containing an array of rules.
// It processes the Content field by converting it into a Pattern ([]byte).
// Plain text content is simply converted to []byte,
// while content enclosed in "|" characters is parsed as hexadecimal.
// Mixed content is supported as well.
func LoadRules(filename string) ([]LoadedJsonRules, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	var rules []LoadedJsonRules
	if err := json.Unmarshal(data, &rules); err != nil {
		return nil, err
	}
	// Process each rule's Content field.
	for i, rule := range rules {
		trimmed := strings.TrimSpace(rule.Content)
		if trimmed == "" {
			rules[i].Pattern = nil
		} else {
			pattern, err := processContent(trimmed)
			if err != nil {
				return nil, fmt.Errorf("error processing content for rule SID %s: %v", rule.SID, err)
			}
			rules[i].Pattern = pattern
		}
	}
	return rules, nil
}
