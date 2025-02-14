package main

import(
	"encoding/json"
	"os"
	"strings"
)

// LoadRules loads and unmarshals a JSON file containing an array of SnortRule objects.
func LoadRules(filename string) ([]SnortRule, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	var rules []SnortRule
	if err := json.Unmarshal(data, &rules); err != nil {
		return nil, err
	}
	// Process the content field for each rule.
	for i, rule := range rules {
		if rule.Content != "" && strings.HasPrefix(rule.Content, "|") && strings.HasSuffix(rule.Content, "|") {
			// Remove spaces from inside the vertical bars.
			inner := rule.Content[1 : len(rule.Content)-1]
			clean := strings.ReplaceAll(inner, " ", "")
			rules[i].Content = "|" + clean + "|"
		}
	}
	return rules, nil
}
