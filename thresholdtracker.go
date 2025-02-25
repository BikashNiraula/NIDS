package main

import (
	"log"
	"sync"
	"time"
)

// ThresholdAlert records that an alert was generated for a given rule and source IP.
type ThresholdAlert struct {
	RuleID    string
	SrcIP     string
	Timestamp time.Time
}

// ThresholdTracker tracks matching events per rule per source IP and records alerts.
type ThresholdTracker struct {
	mu     sync.Mutex
	// events: key = ruleSID + "_" + srcIP, value = timestamps for each matching event.
	events map[string][]time.Time
	// alerts: key = ruleSID + "_" + srcIP, value = information about when an alert was generated.
	alerts map[string]ThresholdAlert
}

// NewThresholdTracker creates a new ThresholdTracker.
func NewThresholdTracker() *ThresholdTracker {
	return &ThresholdTracker{
		events: make(map[string][]time.Time),
		alerts: make(map[string]ThresholdAlert),
	}
}

// RecordEvent records an event for a given rule (by ruleID) and source IP,
// using the provided threshold parameters. It returns true when the threshold is reached
// (and an alert should be generated) and also logs the rule SID and source IP for which the alert fired.
func (tt *ThresholdTracker) RecordEvent(ruleID, srcIP string, countThreshold, secondsThreshold int) bool {
	tt.mu.Lock()
	defer tt.mu.Unlock()

	key := ruleID + "_" + srcIP
	now := time.Now()

	// Retrieve existing events for this key.
	timestamps := tt.events[key]
	// Purge events older than the threshold window.
	cutoff := now.Add(-time.Duration(secondsThreshold) * time.Second)
	var recent []time.Time
	for _, t := range timestamps {
		if t.After(cutoff) {
			recent = append(recent, t)
		}
	}

	// Append the current event.
	recent = append(recent, now)
	tt.events[key] = recent

	log.Printf("DEBUG: Rule %s for source %s has %d events (threshold %d in %d sec)", ruleID, srcIP, len(recent), countThreshold, secondsThreshold)

	// Check if the threshold has been reached (or exceeded).
	if len(recent) >= countThreshold {
		// If we already generated an alert for this key within the threshold window, do not alert again.
		if alert, exists := tt.alerts[key]; exists {
			if now.Sub(alert.Timestamp) < time.Duration(secondsThreshold)*time.Second {
				// Already alerted for this key in the current window.
				return false
			}
		}
		// Record a new alert.
		tt.alerts[key] = ThresholdAlert{
			RuleID:    ruleID,
			SrcIP:     srcIP,
			Timestamp: now,
		}
		log.Printf("DEBUG: Threshold reached for rule %s on source %s - ALERT GENERATED", ruleID, srcIP)
		// Optionally, clear the events for this key to avoid immediate re-alerting.
		tt.events[key] = []time.Time{}
		return true
	}
	return false
}

// Cleanup iterates over all tracked events and alerts, purging those older than the threshold window.
// This ensures that stale events and alerts do not accumulate indefinitely.
func (tt *ThresholdTracker) Cleanup(secondsThreshold int) {
	tt.mu.Lock()
	defer tt.mu.Unlock()

	now := time.Now()
	cutoff := now.Add(-time.Duration(secondsThreshold) * time.Second)

	// Clean up events.
	for key, timestamps := range tt.events {
		var recent []time.Time
		for _, t := range timestamps {
			if t.After(cutoff) {
				recent = append(recent, t)
			}
		}
		if len(recent) == 0 {
			log.Printf("DEBUG: Removing key %s from threshold tracker events (no recent events)", key)
			delete(tt.events, key)
		} else {
			if len(recent) != len(timestamps) {
				log.Printf("DEBUG: Cleaned up key %s, %d events remaining", key, len(recent))
			}
			tt.events[key] = recent
		}
	}

	// Clean up alerts.
	for key, alert := range tt.alerts {
		if alert.Timestamp.Before(cutoff) {
			log.Printf("DEBUG: Removing alert for key %s from threshold tracker alerts (expired)", key)
			delete(tt.alerts, key)
		}
	}
}
