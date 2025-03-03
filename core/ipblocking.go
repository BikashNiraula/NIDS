package core

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"
	"NIDS/loadrulefiles"
)


// IPBlocker handles the blocking and unblocking of IP addresses
type IPBlocker struct {
	blockedIPs      map[string]bool
	blockFilePath   string
	mutex           sync.RWMutex
	lastFileModTime time.Time
}

var IpBlocker *IPBlocker

// initIPBlocker initializes the IP blocker and starts the file monitor
func InitIPBlocker() {
	// Get the appropriate file path based on OS
	blockFilePath := getBlockFilePath()
	
	IpBlocker = &IPBlocker{
		blockedIPs:    make(map[string]bool),
		blockFilePath: blockFilePath,
	}
	
	// Ensure directory exists
	ensureDirectoryExists(filepath.Dir(blockFilePath))
	
	// Create the file if it doesn't exist
	if _, err := os.Stat(IpBlocker.blockFilePath); os.IsNotExist(err) {
		file, err := os.Create(IpBlocker.blockFilePath)
		if err != nil {
			log.Printf("Error creating blocked IPs file: %v", err)
		} else {
			file.Close()
		}
	}
	
	// Load initial blocked IPs
	IpBlocker.loadBlockedIPs()
	
	// Apply existing blocks to the system
	IpBlocker.applyExistingBlocks()
	
	// Start the file monitoring routine
	go IpBlocker.monitorBlockFile()
}

// getBlockFilePath returns the appropriate file path based on the OS
func getBlockFilePath() string {
	switch runtime.GOOS {
	case "windows":
		// Windows typically uses %APPDATA%
		appData := os.Getenv("APPDATA")
		if appData == "" {
			// Fallback if APPDATA is not available
			appData = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Roaming")
		}
		return filepath.Join(appData, "IPBlocker", "blocked_ips.txt")
	case "darwin":
		// macOS typically uses ~/Library/Application Support
		home, err := os.UserHomeDir()
		if err != nil {
			log.Printf("Error getting home directory: %v", err)
			return "blocked_ips.txt" // Fallback to current directory
		}
		return filepath.Join(home, "Library", "Application Support", "IPBlocker", "blocked_ips.txt")
	default:
		// Linux and other Unix-like systems typically use ~/.config
		home, err := os.UserHomeDir()
		if err != nil {
			log.Printf("Error getting home directory: %v", err)
			return "blocked_ips.txt" // Fallback to current directory
		}
		return filepath.Join(home, ".config", "ipblocker", "blocked_ips.txt")
	}
}

// ensureDirectoryExists creates a directory if it doesn't exist
func ensureDirectoryExists(dirPath string) {
	if _, err := os.Stat(dirPath); os.IsNotExist(err) {
		// Create directory with appropriate permissions
		var perm os.FileMode = 0755
		if runtime.GOOS == "windows" {
			// Windows doesn't use the same permission bits
			perm = 0777
		}
		
		if err := os.MkdirAll(dirPath, perm); err != nil {
			log.Printf("Error creating directory %s: %v", dirPath, err)
		}
	}
}

// IsBlocked checks if an IP is in the blocked list
func (b *IPBlocker) IsBlocked(ip string) bool {
	b.mutex.RLock()
	defer b.mutex.RUnlock()
	return b.blockedIPs[ip]
}

// BlockIP adds an IP to the blocked list, applies system-level blocking, and saves it to the file
func (b *IPBlocker) BlockIP(ip string) {
	// Check if already blocked
	b.mutex.RLock()
	isBlocked := b.blockedIPs[ip]
	b.mutex.RUnlock()
	
	if isBlocked {
		return // IP already blocked
	}
	
	// Apply system-level block
	if err := applySystemBlock(ip); err != nil {
		log.Printf("Error applying system block for IP %s: %v", ip, err)
		os.Exit(1);
		// Continue anyway to add to our list, even if system block failed
	}
	
	// Add to memory
	b.mutex.Lock()
	b.blockedIPs[ip] = true
	b.mutex.Unlock()
	
	// Add to file
	// Use OpenFile with OS-agnostic flags
	file, err := os.OpenFile(b.blockFilePath, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0644)
	if err != nil {
		log.Printf("Error opening blocked IPs file: %v", err)
		return
	}
	defer file.Close()
	
	// Use OS-agnostic line endings
	if _, err := file.WriteString(ip + "\n"); err != nil {
		log.Printf("Error writing IP to blocked file: %v", err)
	} else {
		log.Printf("IP %s has been blocked and added to %s", ip, b.blockFilePath)
	}
	
	// Update last modified time to avoid reloading due to our own changes
	if fileInfo, err := os.Stat(b.blockFilePath); err == nil {
		b.lastFileModTime = fileInfo.ModTime()
	}
}

// UnblockIP removes an IP from the blocked list, removes system-level block, and updates the file
func (b *IPBlocker) UnblockIP(ip string) {
	// Check if not blocked
	b.mutex.RLock()
	isBlocked := b.blockedIPs[ip]
	b.mutex.RUnlock()
	
	if !isBlocked {
		return // IP not blocked
	}
	
	// Remove system-level block
	if err := removeSystemBlock(ip); err != nil {
		log.Printf("Error removing system block for IP %s: %v", ip, err)
		// Continue anyway to remove from our list, even if system unblock failed
		os.Exit(1)
	}
	
	// Remove from memory
	b.mutex.Lock()
	delete(b.blockedIPs, ip)
	b.mutex.Unlock()
	
	// Rewrite the file without the unblocked IP
	b.rewriteBlockFile()
	
	log.Printf("IP %s has been unblocked", ip)
}

// loadBlockedIPs loads the list of blocked IPs from the file
func (b *IPBlocker) loadBlockedIPs() {
	file, err := os.Open(b.blockFilePath)
	if err != nil {
		log.Printf("Error opening blocked IPs file: %v", err)
		return
	}
	defer file.Close()
	
	// Get file modification time
	if fileInfo, err := file.Stat(); err == nil {
		b.lastFileModTime = fileInfo.ModTime()
	}
	
	// Read IPs from file
	b.mutex.Lock()
	defer b.mutex.Unlock()
	
	// Clear existing IPs
	b.blockedIPs = make(map[string]bool)
	
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		ip := strings.TrimSpace(scanner.Text())
		if ip != "" {
			b.blockedIPs[ip] = true
		}
	}
	
	if err := scanner.Err(); err != nil {
		log.Printf("Error reading blocked IPs file: %v", err)
	}
	
	log.Printf("Loaded %d blocked IPs from %s", len(b.blockedIPs), b.blockFilePath)
}

// applyExistingBlocks applies system-level blocks for all IPs in the list
func (b *IPBlocker) applyExistingBlocks() {
	b.mutex.RLock()
	defer b.mutex.RUnlock()
	
	// Apply blocks that aren't already applied
	count := 0
	for ip := range b.blockedIPs {
		if err := applySystemBlock(ip); err != nil {
			log.Printf("Error applying system block for IP %s: %v", ip, err)
		} else {
			count++
		}
	}
	
	if count > 0 {
		log.Printf("Applied system-level blocks for %d IPs", count)
	}
}

// rewriteBlockFile rewrites the block file with the current list of blocked IPs
func (b *IPBlocker) rewriteBlockFile() {
	// Ensure directory exists before creating file
	ensureDirectoryExists(filepath.Dir(b.blockFilePath))
	
	// Create with appropriate permissions
	var perm os.FileMode = 0644
	if runtime.GOOS == "windows" {
		// Windows doesn't use the same permission bits
		perm = 0666
	}
	
	file, err := os.OpenFile(b.blockFilePath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, perm)
	if err != nil {
		log.Printf("Error creating blocked IPs file: %v", err)
		return
	}
	defer file.Close()
	
	b.mutex.RLock()
	defer b.mutex.RUnlock()
	
	for ip := range b.blockedIPs {
		if _, err := file.WriteString(ip + "\n"); err != nil {
			log.Printf("Error writing IP to blocked file: %v", err)
		}
	}
	
	// Update last modified time
	if fileInfo, err := os.Stat(b.blockFilePath); err == nil {
		b.lastFileModTime = fileInfo.ModTime()
	}
}

// monitorBlockFile periodically checks if the block file has been modified
// and reloads it if necessary
func (b *IPBlocker) monitorBlockFile() {
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()
	
	for range ticker.C {
		fileInfo, err := os.Stat(b.blockFilePath)
		if err != nil {
			// Check if directory exists and recreate if needed
			if os.IsNotExist(err) {
				ensureDirectoryExists(filepath.Dir(b.blockFilePath))
				file, err := os.Create(b.blockFilePath)
				if err == nil {
					file.Close()
					log.Printf("Recreated missing blocked IPs file: %s", b.blockFilePath)
					continue
				}
			}
			log.Printf("Error checking blocked IPs file: %v", err)
			continue
		}
		
		// If file was modified externally, reload it and apply new blocks
		if fileInfo.ModTime().After(b.lastFileModTime) {
			log.Printf("Blocked IPs file has been modified, reloading...")
			
			// Save current IPs to determine what changed
			b.mutex.RLock()
			oldIPs := make(map[string]bool, len(b.blockedIPs))
			for ip := range b.blockedIPs {
				oldIPs[ip] = true
			}
			b.mutex.RUnlock()
			
			// Load new IPs
			b.loadBlockedIPs()
			
			// Find and apply new blocks
			b.mutex.RLock()
			for ip := range b.blockedIPs {
				if !oldIPs[ip] {
					// This is a new IP - apply system block
					if err := applySystemBlock(ip); err != nil {
						log.Printf("Error applying system block for newly added IP %s: %v", ip, err)
					}
				}
			}
			
			// Find and remove old blocks
			for ip := range oldIPs {
				if !b.blockedIPs[ip] {
					// This IP was removed - remove system block
					if err := removeSystemBlock(ip); err != nil {
						log.Printf("Error removing system block for removed IP %s: %v", ip, err)
					}
				}
			}
			b.mutex.RUnlock()
		}
	}
}

// applySystemBlock applies an IP block at the operating system level
func applySystemBlock(ip string) error {
	switch runtime.GOOS {
	case "windows":
		// Use Windows Firewall to block the IP
		cmd := exec.Command("netsh", "advfirewall", "firewall", "add", "rule",
			"name=IPBlocker-"+ip,
			"dir=in",
			"action=block",
			"remoteip="+ip)
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("windows firewall block failed: %v - %s", err, string(output))
		}
		
		// Also block outbound connections
		cmd = exec.Command("netsh", "advfirewall", "firewall", "add", "rule",
			"name=IPBlocker-Out-"+ip,
			"dir=out",
			"action=block",
			"remoteip="+ip)
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("windows firewall outbound block failed: %v - %s", err, string(output))
		}
		return nil
		
	case "darwin":
		// Use macOS PF firewall
		// First, ensure the anchor file exists
		pfConfigPath := "/etc/pf.anchors/com.ipblocker"
		if _, err := os.Stat(pfConfigPath); os.IsNotExist(err) {
			cmd := exec.Command("sudo", "touch", pfConfigPath)
			if output, err := cmd.CombinedOutput(); err != nil {
				return fmt.Errorf("failed to create PF anchor file: %v - %s", err, string(output))
			}
			
			// Add anchor to pf.conf if it doesn't exist
			cmd = exec.Command("sudo", "sh", "-c", "grep -q 'com.ipblocker' /etc/pf.conf || echo 'anchor \"com.ipblocker\"' >> /etc/pf.conf")
			if output, err := cmd.CombinedOutput(); err != nil {
				return fmt.Errorf("failed to add anchor to pf.conf: %v - %s", err, string(output))
			}
		}
		
		// Add the rule to the anchor file
		cmd := exec.Command("sudo", "sh", "-c", fmt.Sprintf("echo 'block drop from any to %s' >> %s", ip, pfConfigPath))
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("failed to add rule to PF anchor: %v - %s", err, string(output))
		}
		
		// Reload the firewall
		cmd = exec.Command("sudo", "pfctl", "-f", "/etc/pf.conf")
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("failed to reload PF: %v - %s", err, string(output))
		}
		
		// Enable PF if not already enabled
		cmd = exec.Command("sudo", "pfctl", "-e")
		cmd.CombinedOutput() // Ignore error as it might already be enabled
		
		return nil
		
	default:
		// Linux - use iptables
		// Block incoming connections
		cmd := exec.Command("sudo", "iptables", "-A", "INPUT", "-s", ip, "-j", "DROP")
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("iptables input block failed: %v - %s", err, string(output))
		}
		
		// Block outgoing connections
		cmd = exec.Command("sudo", "iptables", "-A", "OUTPUT", "-d", ip, "-j", "DROP")
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("iptables output block failed: %v - %s", err, string(output))
		}
		
		return nil
	}
}

// removeSystemBlock removes an IP block at the operating system level
func removeSystemBlock(ip string) error {
	switch runtime.GOOS {
	case "windows":
		// Remove Windows Firewall rules
		cmd := exec.Command("netsh", "advfirewall", "firewall", "delete", "rule",
			"name=IPBlocker-"+ip)
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("windows firewall rule removal failed: %v - %s", err, string(output))
		}
		
		cmd = exec.Command("netsh", "advfirewall", "firewall", "delete", "rule",
			"name=IPBlocker-Out-"+ip)
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("windows firewall outbound rule removal failed: %v - %s", err, string(output))
		}
		return nil
		
	case "darwin":
		// macOS - remove from PF anchor file and reload
		pfConfigPath := "/etc/pf.anchors/com.ipblocker"
		if _, err := os.Stat(pfConfigPath); err == nil {
			// Remove the rule from the anchor file
			cmd := exec.Command("sudo", "sh", "-c", 
				fmt.Sprintf("grep -v '%s' %s > /tmp/pf.tmp && sudo mv /tmp/pf.tmp %s", 
					ip, pfConfigPath, pfConfigPath))
			if output, err := cmd.CombinedOutput(); err != nil {
				return fmt.Errorf("failed to remove rule from PF anchor: %v - %s", err, string(output))
			}
			
			// Reload the firewall
			cmd = exec.Command("sudo", "pfctl", "-f", "/etc/pf.conf")
			if output, err := cmd.CombinedOutput(); err != nil {
				return fmt.Errorf("failed to reload PF: %v - %s", err, string(output))
			}
		}
		return nil
		
	default:
		// Linux - remove iptables rules
		cmd := exec.Command("sudo", "iptables", "-D", "INPUT", "-s", ip, "-j", "DROP")
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("iptables input rule removal failed: %v - %s", err, string(output))
		}
		
		cmd = exec.Command("sudo", "iptables", "-D", "OUTPUT", "-d", ip, "-j", "DROP")
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("iptables output rule removal failed: %v - %s", err, string(output))
		}
		
		return nil
	}
}

// BlockOnMatch checks if the rule action is "block" and blocks the source IP if so
func BlockOnMatch(pkt Packet, rule loadrulefiles.LoadedJsonRules) {
	if strings.ToLower(rule.Action) == "block" {
		if IpBlocker != nil {
			log.Printf("Blocking IP %s based on rule SID %s", pkt.SourceIP, rule.SID)
			IpBlocker.BlockIP(pkt.SourceIP)
		} else {
			log.Printf("IP blocker not initialized, cannot block IP %s", pkt.SourceIP)
		}
	}
}

// ManualUnblockIP provides a way to manually unblock an IP address
func ManualUnblockIP(ip string) {
	if IpBlocker != nil {
		IpBlocker.UnblockIP(ip)
	} else {
		log.Printf("IP blocker not initialized, cannot unblock IP %s", ip)
	}
}

// GetBlockedIPs returns the list of currently blocked IPs
func GetBlockedIPs() []string {
	if IpBlocker == nil {
		return []string{}
	}
	
	IpBlocker.mutex.RLock()
	defer IpBlocker.mutex.RUnlock()
	
	ips := make([]string, 0, len(IpBlocker.blockedIPs))
	for ip := range IpBlocker.blockedIPs {
		ips = append(ips, ip)
	}
	
	return ips
}
