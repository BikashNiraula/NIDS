package rulesparser

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// --------------------------
// Data Structures
// --------------------------

// ThresholdOption represents the parsed components of a threshold option.
type ThresholdOption struct {
	Type    string `json:"type,omitempty"`
	Count   string `json:"count,omitempty"`
	Seconds string `json:"seconds,omitempty"`
	Track   string `json:"track,omitempty"`
}

// SnortRule represents a complete Snort rule, including its header,
// explicitly parsed options, and any additional options.
type SnortRule struct {
	// Header fields
	Action          string `json:"action"`
	Protocol        string `json:"protocol"`
	SourceIP        string `json:"source_ip"`
	SourcePort      string `json:"source_port"`
	// Direction: either "->" or "<>"
	Direction       string `json:"direction"`
	DestinationIP   string `json:"destination_ip"`
	DestinationPort string `json:"destination_port"`

	// Unique identifier
	SID string `json:"sid"`

	// Common options (single occurrence)
	Message   string `json:"msg,omitempty"`
	Revision  string `json:"rev,omitempty"`
	GID       string `json:"gid,omitempty"`
	Classtype string `json:"classtype,omitempty"`
	Priority  string `json:"priority,omitempty"`
	Flow      string `json:"flow,omitempty"`
	Depth     string `json:"depth,omitempty"`
	Offset    string `json:"offset,omitempty"`
	Flags     string `json:"flags,omitempty"`

	// Additional detection options
	PCRE            string           `json:"pcre,omitempty"`
	Distance        string           `json:"distance,omitempty"`
	Within          string           `json:"within,omitempty"`
	Threshold       *ThresholdOption `json:"threshold,omitempty"`
	DetectionFilter string           `json:"detection_filter,omitempty"`

	// Options that can occur multiple times
	Content   []string `json:"content,omitempty"` // can be defined multiple times
	Flowbits  []string `json:"flowbits,omitempty"`
	Reference []string `json:"reference,omitempty"`

	// Metadata parsed into a key/value mapping.
	Metadata map[string]string `json:"metadata,omitempty"`

	// Any additional options that are not explicitly handled.
	OtherOptions map[string][]string `json:"other_options,omitempty"`
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
	// Stop at whitespace or '(' (beginning of options)
	for p.pos < len(p.input) && !isWhitespace(p.input[p.pos]) && p.input[p.pos] != '(' {
		p.pos++
	}
	return p.input[start:p.pos]
}

// parseWord reads a word (for option keys): letters, digits, underscore (and hyphen).
func (p *parser) parseWord() string {
	start := p.pos
	for p.pos < len(p.input) && (isLetterOrDigit(p.input[p.pos]) || p.input[p.pos] == '_' || p.input[p.pos] == '-') {
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

// parseOption parses one option which can be either a key:value pair or a flag (key with no colon).
func (p *parser) parseOption() (option, error) {
	p.skipWhitespace()
	key := p.parseWord()
	if key == "" {
		return option{}, fmt.Errorf("expected option key at position %d", p.pos)
	}
	p.skipWhitespace()
	var val string
	// If a colon follows, parse the value.
	if p.peek() == ':' {
		p.pos++ // consume colon
		p.skipWhitespace()
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
	} else {
		// No colon implies a flag option (e.g. "nocase")
		val = "true"
	}
	return option{Key: key, Value: val}, nil
}

// parseOptionList parses a semicolon-separated list of options into a mapping of keys to slices of values.
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

// parseThreshold converts a threshold string like
// "type both, count 5, seconds 60, track by_src"
// into a ThresholdOption struct.
func parseThreshold(thresholdStr string) (*ThresholdOption, error) {
	parts := strings.Split(thresholdStr, ",")
	thresh := &ThresholdOption{}
	for _, part := range parts {
		part = strings.TrimSpace(part)
		tokens := strings.Fields(part)
		if len(tokens) < 2 {
			return nil, fmt.Errorf("invalid threshold option: %s", part)
		}
		key := tokens[0]
		value := strings.Join(tokens[1:], " ")
		switch key {
		case "type":
			thresh.Type = value
		case "count":
			thresh.Count = value
		case "seconds":
			thresh.Seconds = value
		case "track":
			thresh.Track = value
		default:
			// Optionally log or handle unknown keys.
		}
	}
	return thresh, nil
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
	// Parse direction operator: either "->" or "<>"
	var direction string
	if p.match("->") {
		direction = "->"
		p.pos += 2
	} else if p.match("<>") {
		direction = "<>"
		p.pos += 2
	} else {
		return nil, fmt.Errorf("missing or invalid direction operator at position %d", p.pos)
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

	// Helper function: extract first occurrence of an option.
	extract := func(key string) string {
		if vals, ok := opts[key]; ok && len(vals) > 0 {
			return vals[0]
		}
		return ""
	}

	// For options that can occur multiple times.
	content := opts["content"]
	flowbits := opts["flowbits"]
	reference := opts["reference"]

	// Parse metadata into a key/value map if present.
	metadata := make(map[string]string)
	if metaStr := extract("metadata"); metaStr != "" {
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

	// Parse the threshold option into a structured format.
	var thresholdOption *ThresholdOption
	if rawThreshold := extract("threshold"); rawThreshold != "" {
		thresholdOption, err = parseThreshold(rawThreshold)
		if err != nil {
			return nil, fmt.Errorf("failed to parse threshold: %v", err)
		}
	}

	// Build the SnortRule object.
	rule := &SnortRule{
		Action:          action,
		Protocol:        protocol,
		SourceIP:        sourceIP,
		SourcePort:      sourcePort,
		Direction:       direction,
		DestinationIP:   destinationIP,
		DestinationPort: destinationPort,
		SID:             sid,

		Message:         extract("msg"),
		Revision:        extract("rev"),
		GID:             extract("gid"),
		Classtype:       extract("classtype"),
		Priority:        extract("priority"),
		Flow:            extract("flow"),
		Depth:           extract("depth"),
		Offset:          extract("offset"),
		Flags:           extract("flags"),

		PCRE:            extract("pcre"),
		Distance:        extract("distance"),
		Within:          extract("within"),
		Threshold:       thresholdOption,
		DetectionFilter: extract("detection_filter"),

		Content:         content,
		Flowbits:        flowbits,
		Reference:       reference,
		Metadata:        metadata,
	}

	// Remove known keys from opts and store any remaining options.
	knownKeys := []string{
		"msg", "rev", "gid", "classtype", "priority", "flow", "depth", "offset", "flags",
		"pcre", "distance", "within", "threshold", "detection_filter", "content", "flowbits",
		"reference", "metadata", "sid",
	}
	otherOpts := make(map[string][]string)
	for k, v := range opts {
		skip := false
		for _, known := range knownKeys {
			if k == known {
				skip = true
				break
			}
		}
		if !skip {
			otherOpts[k] = v
		}
	}
	if len(otherOpts) > 0 {
		rule.OtherOptions = otherOpts
	}

	return rule, nil
}

// --------------------------
// Helper Functions
// --------------------------

func isWhitespace(ch byte) bool {
	return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

func isLetterOrDigit(ch byte) bool {
	return (ch >= 'a' && ch <= 'z') ||
		(ch >= 'A' && ch <= 'Z') ||
		(ch >= '0' && ch <= '9')
}

// ParseSnortRule is the exported function to parse a single Snort rule string.
func ParseSnortRule(rule string) (*SnortRule, error) {
	p := newParser(rule)
	r, err := p.parseRule()
	if err != nil {
		return nil, fmt.Errorf("error parsing rule: %v", err)
	}
	return r, nil
}

// ParseSnortRulesFromFile reads a file containing Snort rules and parses them.
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
			continue // Skip empty lines and comments.
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

// SaveRulesAsJSON marshals the rules into JSON and writes to the specified file.
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

// ConvertSingleSnortRulesFileToJSON converts one .rules file to JSON.
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

// ConvertSnortRulesToJSON handles the conversion of a .rules file or a directory of .rules files to JSON.
func ConvertSnortRulesToJSON(rulesFile, outputFile string) error {
	if rulesFile == "" {
		return fmt.Errorf("please provide a rules file or directory using the --rulesFile flag")
	}

	fileInfo, err := os.Stat(rulesFile)
	if err != nil {
		return fmt.Errorf("failed to access rulesFile: %v", err)
	}

	if fileInfo.IsDir() {
		if outputFile == "" {
			return fmt.Errorf("please provide an output directory using the --outputFile flag")
		}
		outputDirInfo, err := os.Stat(outputFile)
		if err != nil {
			return fmt.Errorf("error accessing output directory: %v", err)
		}
		if !outputDirInfo.IsDir() {
			return fmt.Errorf("provided output path is not a directory")
		}

		files, err := os.ReadDir(rulesFile)
		if err != nil {
			return fmt.Errorf("failed to read rules directory: %v", err)
		}

		for _, file := range files {
			if filepath.Ext(file.Name()) == ".rules" {
				rulesFilePath := filepath.Join(rulesFile, file.Name())
				outputJSONPath := filepath.Join(outputFile, file.Name()+".json")
				if err := ConvertSingleSnortRulesFileToJSON(rulesFilePath, outputJSONPath); err != nil {
					log.Printf("Error converting %s: %v", file.Name(), err)
				} else {
					fmt.Printf("Rules file %s successfully converted to %s\n", file.Name(), outputJSONPath)
				}
			}
		}
		return nil
	}

	if outputFile == "" {
		defaultOutputDir := "./Rules/JsonRules"
		err := os.MkdirAll(defaultOutputDir, os.ModePerm)
		if err != nil {
			return fmt.Errorf("error creating output directory: %v", err)
		}
		outputFile = filepath.Join(defaultOutputDir, filepath.Base(rulesFile)+".json")
	}

	if info, err := os.Stat(outputFile); err == nil && info.IsDir() {
		outputFile = filepath.Join(outputFile, filepath.Base(rulesFile)+".json")
	}

	if err := ConvertSingleSnortRulesFileToJSON(rulesFile, outputFile); err != nil {
		return fmt.Errorf("error converting rules file to JSON: %v", err)
	}

	fmt.Printf("Rules file successfully converted to JSON and saved to %s\n", outputFile)
	return nil
}
