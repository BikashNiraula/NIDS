package rulesparser

import (

	"strings"
	"encoding/json"
	"fmt"
	"log"
	_ "net"
	 "os"
	"path/filepath"
	"bufio"

	_ "github.com/google/gopacket"
	_ "github.com/google/gopacket/layers"
	_ "github.com/google/gopacket/pcap"
	_ "github.com/olekukonko/tablewriter"
	_ "github.com/spf13/cobra"
)


// --------------------------
// Data Structures
// --------------------------

// SnortRule now includes many fields that might be present in a rule.
// Fields expected only once are stored as strings; fields that may appear multiple times (like flowbits, reference)
// are stored as slices. Metadata is parsed into a map.
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
	Flowbits  []string `json:"flowbits,omitempty"`
	Reference []string `json:"reference,omitempty"`

	// Metadata parsed into a key/value mapping.
	Metadata map[string]string `json:"metadata,omitempty"`
}

// --------------------------
// Parser Implementation
// --------------------------

// parser holds the input string and the current position.
type parser struct {
	input string
	pos   int
}

func newParser(input string) *parser {
	return &parser{input: input, pos: 0}
}

func (p *parser) peek() byte {
	if p.pos < len(p.input) {
		return p.input[p.pos]
	}
	return 0
}

func (p *parser) skipWhitespace() {
	for p.pos < len(p.input) && isWhitespace(p.input[p.pos]) {
		p.pos++
	}
}

// match returns true if the upcoming input begins with the literal.
func (p *parser) match(lit string) bool {
	return strings.HasPrefix(p.input[p.pos:], lit)
}

// expect consumes the given literal or returns an error.
func (p *parser) expect(lit string) error {
	p.skipWhitespace()
	if !p.match(lit) {
		return fmt.Errorf("expected %q at position %d", lit, p.pos)
	}
	p.pos += len(lit)
	return nil
}

// parseToken reads a token from the header (delimited by whitespace).
func (p *parser) parseToken() string {
	p.skipWhitespace()
	start := p.pos
	for p.pos < len(p.input) && !isWhitespace(p.input[p.pos]) {
		p.pos++
	}
	return p.input[start:p.pos]
}

// parseWord reads a word (for option keys): letters, digits, underscore.
func (p *parser) parseWord() string {
	start := p.pos
	for p.pos < len(p.input) && (isLetterOrDigit(p.input[p.pos]) || p.input[p.pos] == '_') {
		p.pos++
	}
	return p.input[start:p.pos]
}

// parseQuotedString parses a quoted string.
func (p *parser) parseQuotedString() (string, error) {
	if p.peek() != '"' && p.peek() != '\'' {
		return "", fmt.Errorf("expected quote at position %d", p.pos)
	}
	quote := p.input[p.pos]
	p.pos++ // consume opening quote
	start := p.pos
	for p.pos < len(p.input) && p.input[p.pos] != quote {
		p.pos++
	}
	if p.pos >= len(p.input) {
		return "", fmt.Errorf("unterminated quoted string starting at %d", start)
	}
	val := p.input[start:p.pos]
	p.pos++ // consume closing quote
	return val, nil
}

// option represents one key/value pair from the options.
type option struct {
	Key   string
	Value string
}

// parseOption parses one option (e.g. key: value).
func (p *parser) parseOption() (option, error) {
	p.skipWhitespace()
	key := p.parseWord()
	if key == "" {
		return option{}, fmt.Errorf("expected option key at position %d", p.pos)
	}
	p.skipWhitespace()
	if err := p.expect(":"); err != nil {
		return option{}, err
	}
	p.skipWhitespace()
	var val string
	if p.peek() == '"' || p.peek() == '\'' {
		v, err := p.parseQuotedString()
		if err != nil {
			return option{}, err
		}
		val = v
	} else {
		// Unquoted value: read until next semicolon or closing parenthesis.
		start := p.pos
		for p.pos < len(p.input) && p.input[p.pos] != ';' && p.input[p.pos] != ')' {
			p.pos++
		}
		val = strings.TrimSpace(p.input[start:p.pos])
	}
	return option{Key: key, Value: val}, nil
}

// parseOptionList parses a semicolon-separated list of options, returning a mapping of keys to slices of values.
func (p *parser) parseOptionList() (map[string][]string, error) {
	opts := make(map[string][]string)
	for {
		p.skipWhitespace()
		if p.peek() == ')' {
			break
		}
		opt, err := p.parseOption()
		if err != nil {
			return nil, err
		}
		opts[opt.Key] = append(opts[opt.Key], opt.Value)
		p.skipWhitespace()
		if p.peek() == ';' {
			p.pos++ // consume semicolon
		} else {
			break
		}
	}
	return opts, nil
}

// parseRule parses the complete Snort rule.
func (p *parser) parseRule() (*SnortRule, error) {
	// Parse header tokens.
	p.skipWhitespace()
	action := p.parseToken()
	if action == "" {
		return nil, fmt.Errorf("missing action")
	}
	p.skipWhitespace()
	protocol := p.parseToken()
	if protocol == "" {
		return nil, fmt.Errorf("missing protocol")
	}
	p.skipWhitespace()
	sourceIP := p.parseToken()
	if sourceIP == "" {
		return nil, fmt.Errorf("missing source IP")
	}
	p.skipWhitespace()
	sourcePort := p.parseToken()
	if sourcePort == "" {
		return nil, fmt.Errorf("missing source port")
	}
	p.skipWhitespace()
	// Expect arrow "->"
	if err := p.expect("->"); err != nil {
		return nil, err
	}
	p.skipWhitespace()
	destinationIP := p.parseToken()
	if destinationIP == "" {
		return nil, fmt.Errorf("missing destination IP")
	}
	p.skipWhitespace()
	destinationPort := p.parseToken()
	if destinationPort == "" {
		return nil, fmt.Errorf("missing destination port")
	}
	p.skipWhitespace()
	// Parse options: expect '(' then options then ')'
	if err := p.expect("("); err != nil {
		return nil, fmt.Errorf("expected '(' starting options: %v", err)
	}
	opts, err := p.parseOptionList()
	if err != nil {
		return nil, err
	}
	p.skipWhitespace()
	if err := p.expect(")"); err != nil {
		return nil, fmt.Errorf("expected ')' ending options: %v", err)
	}

	// Now, extract known keys.
	// For keys that occur only once, use the first element.
	extract := func(key string) string {
		if vals, ok := opts[key]; ok && len(vals) > 0 {
			return vals[0]
		}
		return ""
	}

	// For keys that can be multiple, take the whole slice.
	flowbits := opts["flowbits"]
	reference := opts["reference"]

	// For metadata, parse its first occurrence if present.
	metadata := make(map[string]string)
	if metaStr := extract("metadata"); metaStr != "" {
		// Split by commas then by whitespace.
		parts := strings.Split(metaStr, ",")
		for _, part := range parts {
			part = strings.TrimSpace(part)
			if part == "" {
				continue
			}
			kv := strings.SplitN(part, " ", 2)
			if len(kv) == 2 {
				metadata[kv[0]] = strings.TrimSpace(kv[1])
			}
		}
	}

	// 'sid' is required.
	sid := extract("sid")
	if strings.TrimSpace(sid) == "" {
		return nil, fmt.Errorf("missing required field: sid")
	}

	// Build the final SnortRule.
	rule := &SnortRule{
		Action:          action,
		Protocol:        protocol,
		SourceIP:        sourceIP,
		SourcePort:      sourcePort,
		DestinationIP:   destinationIP,
		DestinationPort: destinationPort,

		Message:   extract("msg"),
		Revision:  extract("rev"),
		GID:       extract("gid"),
		Classtype: extract("classtype"),
		Content:   extract("content"),
		Flow:      extract("flow"),
		Depth:     extract("depth"),
		Offset:    extract("offset"),
		Flags:     extract("flags"),
		Priority:  extract("priority"),

		Flowbits:  flowbits,
		Reference: reference,
		Metadata:  metadata,
		SID:        sid,
	}

	return rule, nil
}

// --------------------------
// Helper Functions
// --------------------------

// isWhitespace returns true if ch is a whitespace character.
func isWhitespace(ch byte) bool {
	return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

// isLetterOrDigit returns true if ch is a letter or digit.
func isLetterOrDigit(ch byte) bool {
	return (ch >= 'a' && ch <= 'z') ||
		(ch >= 'A' && ch <= 'Z') ||
		(ch >= '0' && ch <= '9')
}

// ParseSnortRule is the exported function that uses our recursive descent parser.
func ParseSnortRule(rule string) (*SnortRule, error) {
	p := newParser(rule)
	r, err := p.parseRule()
	if err != nil {
		return nil, fmt.Errorf("error parsing rule: %v", err)
	}
	return r, nil
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