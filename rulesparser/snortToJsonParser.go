package rulesparser

import (
	"bufio"
	"encoding/json"
	"regexp"
	"strings"
	_ "encoding/json"
	"fmt"
	"log"
	_ "net"
	"os"
	"path/filepath"
	_ "strings"

	_ "github.com/google/gopacket"
	_ "github.com/google/gopacket/layers"
	_ "github.com/google/gopacket/pcap"
	_ "github.com/olekukonko/tablewriter"
)

type Metadata struct {
	CreatedAt         string `json:"created_at,omitempty"`
	UpdatedAt         string `json:"updated_at,omitempty"`
	SignatureSeverity string `json:"signature_severity,omitempty"`
}

type SnortRule struct {
	ID              string   `json:"id"`
	Action          string   `json:"action"`
	Protocol        string   `json:"protocol"`
	SourceIP        string   `json:"source_ip"`
	SourcePort      string   `json:"source_port"`
	DestinationIP   string   `json:"destination_ip"`
	DestinationPort string   `json:"destination_port"`
	Classtype       string   `json:"classtype,omitempty"`
	Content         string   `json:"content,omitempty"`
	Flow            string   `json:"flow,omitempty"`
	Depth           string   `json:"depth,omitempty"`
	Offset          string   `json:"offset,omitempty"`
	Metadata        Metadata `json:"metadata,omitempty"`
	Message         string   `json:"message"`
	Revision        string   `json:"revision"`
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

	// Validate required fields
	if groups["action"] == "" || groups["protocol"] == "" || groups["source_ip"] == "" || groups["source_port"] == "" || groups["destination_ip"] == "" || groups["destination_port"] == "" {
		return nil, fmt.Errorf("missing required fields in rule")
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

		switch {
		case strings.HasPrefix(option, "msg:"):
			groups["message"] = strings.Trim(option[4:], "\" ")
		case strings.HasPrefix(option, "rev:"):
			groups["revision"] = strings.Trim(option[4:], " ")
		case strings.HasPrefix(option, "classtype:"):
			classtype = strings.Trim(option[10:], " ")
		case strings.HasPrefix(option, "content:"):
			content = strings.Trim(option[8:], "\" ")
		case strings.HasPrefix(option, "flow:"):
			flow = strings.Trim(option[5:], " ")
		case strings.HasPrefix(option, "depth:"):
			depth = strings.Trim(option[6:], " ")
		case strings.HasPrefix(option, "offset:"):
			offset = strings.Trim(option[7:], " ")
		case strings.HasPrefix(option, "metadata:"):
			metadataParts := strings.Split(option[9:], ",")
			for _, part := range metadataParts {
				kv := strings.SplitN(part, " ", 2)
				if len(kv) == 2 {
					key := strings.TrimSpace(kv[0])
					value := strings.TrimSpace(kv[1])
					switch key {
					case "created_at":
						metadata.CreatedAt = value
					case "updated_at":
						metadata.UpdatedAt = value
					case "signature_severity":
						metadata.SignatureSeverity = value
					default:
						// Ignore unknown metadata keys
						continue
					}
				}
			}
		default:
			keyValue := strings.SplitN(option, ":", 2)
			if len(keyValue) == 2 {
				conditions[strings.TrimSpace(keyValue[0])] = strings.TrimSpace(keyValue[1])
			}
		}
	}

	// Ensure ID is present
	if conditions["sid"] == "" {
		return nil, fmt.Errorf("missing required field: sid")
	}

	return &SnortRule{
		ID:              conditions["sid"],
		Action:          groups["action"],
		Protocol:        groups["protocol"],
		SourceIP:        groups["source_ip"],
		SourcePort:      groups["source_port"],
		DestinationIP:   groups["destination_ip"],
		DestinationPort: groups["destination_port"],
		Classtype:       classtype,
		Content:         content,
		Flow:            flow,
		Depth:           depth,
		Offset:          offset,
		Metadata:        metadata,
		Message:         groups["message"],
		Revision:        groups["revision"],
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
			log.Printf("Error parsing rule: %v\n", err)
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

func ConvertSingleSnortRulesFileToJSON(rulesFile, outputFile string) error {
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

// Handles the coversion of .rules file to 
func ConvertSnortRulesToJSON(rulesFile, outputFile string) error {
	// Ensure the rulesFile is provided
	if rulesFile == "" {
		return fmt.Errorf("please provide a rules file or directory using the --rulesFile flag")
	}

	// Check if rulesFile is a directory
	fileInfo, err := os.Stat(rulesFile)
	if err != nil {
		return fmt.Errorf("failed to access rulesFile: %v", err)
	}

	// If it's a directory, process all .rules files in the directory
	if fileInfo.IsDir() {
		// Ensure the outputFile is a valid directory
		if outputFile == "" {
			return fmt.Errorf("please provide an output directory using the --outputFile flag")
		}

		// Check if outputFile is a valid directory
		outputDirInfo, err := os.Stat(outputFile)
		if err != nil {
			return fmt.Errorf("error accessing output directory: %v", err)
		}
		if !outputDirInfo.IsDir() {
			return fmt.Errorf("provided output path is not a directory")
		}

		// Process all .rules files in the directory
		files, err := os.ReadDir(rulesFile)
		if err != nil {
			return fmt.Errorf("failed to read rules directory: %v", err)
		}

		// Loop through the files and process .rules files
		for _, file := range files {
			if filepath.Ext(file.Name()) == ".rules" {
				// Construct the full path of the rules file
				rulesFilePath := filepath.Join(rulesFile, file.Name())
				// Construct the corresponding output JSON file path
				outputJSONPath := filepath.Join(outputFile, file.Name()+".json")

				// Convert each .rules file to JSON
				if err := ConvertSingleSnortRulesFileToJSON(rulesFilePath, outputJSONPath); err != nil {
					log.Printf("Error converting %s: %v", file.Name(), err)
				} else {
					fmt.Printf("Rules file %s successfully converted to %s\n", file.Name(), outputJSONPath)
				}
			}
		}
		return nil
	}

	// If it's a single file, process it as usual
	if outputFile == "" {
		// Ensure the default output directory exists
		defaultOutputDir := "./Rules/JsonRules"
		err := os.MkdirAll(defaultOutputDir, os.ModePerm)
		if err != nil {
			return fmt.Errorf("error creating output directory: %v", err)
		}
		// Use the rules file name with .json extension in the default directory
		outputFile = filepath.Join(defaultOutputDir, filepath.Base(rulesFile)+".json")
	}

	// If outputFile is a directory, append .json extension with the same filename
	if info, err := os.Stat(outputFile); err == nil && info.IsDir() {
		// If it's a directory, use the base name of the rulesFile and append .json
		outputFile = filepath.Join(outputFile, filepath.Base(rulesFile)+".json")
	}

	// Convert the single Snort rules file to JSON
	if err := ConvertSingleSnortRulesFileToJSON(rulesFile, outputFile); err != nil {
		return fmt.Errorf("error converting rules file to JSON: %v", err)
	}

	fmt.Printf("Rules file successfully converted to JSON and saved to %s\n", outputFile)
	return nil
}