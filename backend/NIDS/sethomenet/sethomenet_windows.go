// +build windows

package sethomenet

import (
	"bufio"
	"bytes"
	"fmt"
	"os/exec"
	"regexp"
	"strings"

	"github.com/google/gopacket/pcap"
)

// SetHomeNet collects both IPv4 and IPv6 addresses for the given interface.
// Each address is appended with a netmask (/32 for IPv4, /128 for IPv6) and stored in a list.


func SetHomeNet(iface string) error {
	// Execute the ipconfig command to fetch IP addresses.
	cmd := exec.Command("ipconfig")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("error executing ipconfig command: %v", err)
	}

	scanner := bufio.NewScanner(bytes.NewReader(output))
	ipv6Regex := regexp.MustCompile(`IPv6 Address[.\s]*:[\s]*([0-9a-fA-F:]+)`)
	ipv4Regex := regexp.MustCompile(`IPv4 Address[.\s]*:[\s]*([0-9\.]+)`)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Extract IPv6 addresses
		if matches := ipv6Regex.FindStringSubmatch(line); len(matches) == 2 {
			ip := matches[1]
			if !strings.HasPrefix(strings.ToLower(ip), "fe80") { // Exclude link-local addresses
				HomeNet = append(HomeNet, fmt.Sprintf("%s/128", ip))
			}
		}

		// Extract IPv4 addresses
		if matches := ipv4Regex.FindStringSubmatch(line); len(matches) == 2 {
			ip := matches[1]
			HomeNet = append(HomeNet, fmt.Sprintf("%s/32", ip))
		}
	}

	if len(HomeNet) == 0 {
		// Fallback to extracting IP addresses using pcap
		devices, err := pcap.FindAllDevs()
		if err != nil {
			return fmt.Errorf("error finding devices: %v", err)
		}
		for _, device := range devices {
			if device.Name == iface {
				for _, addr := range device.Addresses {
					ip := addr.IP.String()
					if addr.IP.To4() != nil {
						HomeNet = append(HomeNet, fmt.Sprintf("%s/32", ip))
					} else {
						HomeNet = append(HomeNet, fmt.Sprintf("%s/128", ip))
					}
				}
				break
			}
		}
	}

	if len(HomeNet) == 0 {
		return fmt.Errorf("no valid IP addresses found on interface %s", iface)
	}

	fmt.Printf("The homeNet is: %v\n", HomeNet)
	return nil
}
