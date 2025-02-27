package main

import (
	"log"
	"sync"
	"time"
)

// ThresholdAlert records that an alert was generated for a given rule and tracking key.
type ThresholdAlert struct {
	RuleID           string
	SrcIP            string // Represents the tracked component (src/dst) based on threshold config
	Timestamp        time.Time
	SecondsThreshold int
}

// ThresholdTracker tracks matching events per rule per tracking key and records alerts.
type ThresholdTracker struct {
	mu     sync.Mutex
	events map[string]*eventEntry // Maps composite key to event entry
	alerts map[string]ThresholdAlert
}

type eventEntry struct {
	timestamps       []time.Time
	secondsThreshold int
	countThreshold   int
}

// NewThresholdTracker creates a new ThresholdTracker.
func NewThresholdTracker() *ThresholdTracker {
	return &ThresholdTracker{
		events: make(map[string]*eventEntry),
		alerts: make(map[string]ThresholdAlert),
	}
}

// key generates a unique key based on rule ID and tracking component (srcIP for by_src).
func (tt *ThresholdTracker) key(ruleID, srcIP string) string {
	return ruleID + "_" + srcIP
}

// RecordEvent records an event for a given rule and tracking component using the rule's threshold parameters.
// Returns true if a new alert is generated.
func (tt *ThresholdTracker) RecordEvent(ruleID, srcIP string, countThreshold, secondsThreshold int) bool {
	tt.mu.Lock()
	defer tt.mu.Unlock()

	key := tt.key(ruleID, srcIP)
	now := time.Now()

	// Get or create event entry
	entry, exists := tt.events[key]
	if !exists {
		entry = &eventEntry{
			secondsThreshold: secondsThreshold,
			countThreshold:   countThreshold,
		}
		tt.events[key] = entry
	} else {
		// Update thresholds if changed (should typically be consistent for same rule)
		if entry.secondsThreshold != secondsThreshold || entry.countThreshold != countThreshold {
			entry.secondsThreshold = secondsThreshold
			entry.countThreshold = countThreshold
		}
	}

	// Purge old events
	cutoff := now.Add(-time.Duration(entry.secondsThreshold) * time.Second)
	var recent []time.Time
	for _, t := range entry.timestamps {
		if t.After(cutoff) {
			recent = append(recent, t)
		}
	}

	// Add current event
	recent = append(recent, now)
	entry.timestamps = recent

	log.Printf("DEBUG: Rule %s for %s has %d/%d events in %ds", 
		ruleID, srcIP, len(recent), entry.countThreshold, entry.secondsThreshold)

	// Check threshold
	if len(recent) >= entry.countThreshold {
		// Check existing alert
		if alert, exists := tt.alerts[key]; exists {
			if now.Sub(alert.Timestamp) < time.Duration(alert.SecondsThreshold)*time.Second {
				return false
			}
		}

		// Record new alert
		tt.alerts[key] = ThresholdAlert{
			RuleID:           ruleID,
			SrcIP:            srcIP,
			Timestamp:        now,
			SecondsThreshold: entry.secondsThreshold,
		}
		log.Printf("ALERT: Threshold reached for %s - %s", ruleID, srcIP)
		return true
	}
	return false
}

// Cleanup purges stale events and alerts based on their individual thresholds.
func (tt *ThresholdTracker) Cleanup() {
	tt.mu.Lock()
	defer tt.mu.Unlock()

	now := time.Now()

	// Cleanup events
	for key, entry := range tt.events {
		cutoff := now.Add(-time.Duration(entry.secondsThreshold) * time.Second)
		var recent []time.Time
		for _, t := range entry.timestamps {
			if t.After(cutoff) {
				recent = append(recent, t)
			}
		}
		if len(recent) == 0 {
			delete(tt.events, key)
		} else {
			entry.timestamps = recent
		}
	}

	// Cleanup alerts
	for key, alert := range tt.alerts {
		cutoff := now.Add(-time.Duration(alert.SecondsThreshold) * time.Second)
		if alert.Timestamp.Before(cutoff) {
			delete(tt.alerts, key)
		}
	}
}