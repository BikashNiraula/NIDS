package rulesparser

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"strings"
)

type Metadata struct {
	CreatedAt         string `json:"created_at,omitempty"`
	UpdatedAt         string `json:"updated_at,omitempty"`
	SignatureSeverity string `json:"signature_severity,omitempty"`
}

type SnortRule struct {
	ID             string     `json:"id"`
	Action         string     `json:"action"`
	Protocol       string     `json:"protocol"`
	SourceIP       string     `json:"source_ip"`
	SourcePort     string     `json:"source_port"`
	DestinationIP  string     `json:"destination_ip"`
	DestinationPort string    `json:"destination_port"`
	Classtype      string     `json:"classtype,omitempty"`
	Content        string     `json:"content,omitempty"`
	Flow           string     `json:"flow,omitempty"`
	Depth          string     `json:"depth,omitempty"`
	Offset         string     `json:"offset,omitempty"`
	Metadata       Metadata   `json:"metadata,omitempty"`
	Message        string     `json:"message"`
	Revision       string     `json:"revision"`
}

func ParseSnortRule(rule string) (*SnortRule, error) {
	ruleRegex := regexp.MustCompile(`(?P<action>\w+)\s+(?P<protocol>\w+)\s+(?P<source_ip>[\S]+)\s+(?P<source_port>[\S]+)\s+->\s+(?P<destination_ip>[\S]+)\s+(?P<destination_port>[\S]+)\s*\((?P<options>.*)\)`)
	matches := ruleRegex.FindStringSubmatch(rule)

	if matches == nil {
		return nil, fmt.Errorf("invalid rule format")
	}

	// Extract fields using named groups
	groups := make(map[string]string)
	for i, name := range ruleRegex.SubexpNames() {
		if i != 0 && name != "" {
			groups[name] = matches[i]
		}
	}

	// Parse options into structured fields
	var metadata Metadata
	conditions := make(map[string]string)
	options := strings.Split(groups["options"], ";")
	var content, classtype, flow, depth, offset string

	for _, option := range options {
		option = strings.TrimSpace(option)
		if option == "" {
			continue
		}
		if strings.HasPrefix(option, "msg:") {
			groups["message"] = strings.Trim(option[4:], "\" ")
		} else if strings.HasPrefix(option, "rev:") {
			groups["revision"] = strings.Trim(option[4:], " ")
		} else if strings.HasPrefix(option, "classtype:") {
			classtype = strings.Trim(option[10:], " ")
		} else if strings.HasPrefix(option, "content:") {
			content = strings.Trim(option[8:], "\" ")
		} else if strings.HasPrefix(option, "flow:") {
			flow = strings.Trim(option[5:], " ")
		} else if strings.HasPrefix(option, "depth:") {
			depth = strings.Trim(option[6:], " ")
		} else if strings.HasPrefix(option, "offset:") {
			offset = strings.Trim(option[7:], " ")
		} else if strings.HasPrefix(option, "metadata:") {
			metadataParts := strings.Split(option[9:], ",")
			for _, part := range metadataParts {
				kv := strings.SplitN(part, " ", 2)
				if len(kv) == 2 {
					switch strings.TrimSpace(kv[0]) {
					case "created_at":
						metadata.CreatedAt = strings.TrimSpace(kv[1])
					case "updated_at":
						metadata.UpdatedAt = strings.TrimSpace(kv[1])
					case "signature_severity":
						metadata.SignatureSeverity = strings.TrimSpace(kv[1])
					}
				}
			}
		} else {
			keyValue := strings.SplitN(option, ":", 2)
			if len(keyValue) == 2 {
				conditions[strings.TrimSpace(keyValue[0])] = strings.TrimSpace(keyValue[1])
			}
		}
	}

	return &SnortRule{
		ID:             conditions["sid"],
		Action:         groups["action"],
		Protocol:       groups["protocol"],
		SourceIP:       groups["source_ip"],
		SourcePort:     groups["source_port"],
		DestinationIP:  groups["destination_ip"],
		DestinationPort: groups["destination_port"],
		Classtype:      classtype,
		Content:        content,
		Flow:           flow,
		Depth:          depth,
		Offset:         offset,
		Metadata:       metadata,
		Message:        groups["message"],
		Revision:       groups["revision"],
	}, nil
}

func ParseSnortRulesFromFile(rulesFile string) ([]SnortRule, error) {
	file, err := os.Open(rulesFile)
	if err != nil {
		return nil, fmt.Errorf("error opening file: %v", err)
	}
	defer file.Close()

	var parsedRules []SnortRule
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		rule := strings.TrimSpace(scanner.Text())
		if rule == "" || strings.HasPrefix(rule, "#") {
			continue // Skip empty lines and comments
		}
		parsedRule, err := ParseSnortRule(rule)
		if err != nil {
			fmt.Printf("Error parsing rule: %v\n", err)
			continue
		}
		parsedRules = append(parsedRules, *parsedRule)
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("error reading file: %v", err)
	}

	return parsedRules, nil
}

func SaveRulesAsJSON(rules []SnortRule, outputFile string) error {
	jsonOutput, err := json.MarshalIndent(rules, "", "  ")
	if err != nil {
		return fmt.Errorf("error marshaling to JSON: %v", err)
	}

	err = os.WriteFile(outputFile, jsonOutput, 0644)
	if err != nil {
		return fmt.Errorf("error writing JSON to file: %v", err)
	}

	return nil
}

func ConvertSnortRulesToJSON(rulesFile, outputFile string) error {
	rules, err := ParseSnortRulesFromFile(rulesFile)
	if err != nil {
		return fmt.Errorf("failed to parse rules from file: %v", err)
	}

	err = SaveRulesAsJSON(rules, outputFile)
	if err != nil {
		return fmt.Errorf("failed to save rules as JSON: %v", err)
	}

	return nil
}
