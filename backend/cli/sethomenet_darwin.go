// +build linux darwin

package main

import (
	"bufio"
	"bytes"
	"fmt"
	"os/exec"
	"regexp"
	"strings"

	"github.com/google/gopacket/pcap"
)

// SetHomeNet collects both IPv4 and IPv6 addresses for the given interface on Linux/macOS.
// Each address is appended with a netmask (/32 for IPv4, /128 for IPv6) and stored in a list.
func SetHomeNet(iface string) error {
	// Execute the ifconfig command for the specified interface.
	cmd := exec.Command("ifconfig", iface)
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("error executing ifconfig command: %v", err)
	}

	scanner := bufio.NewScanner(bytes.NewReader(output))
	// For Linux and macOS, ifconfig output typically contains "inet " for IPv4 and "inet6 " for IPv6.
	ipv4Regex := regexp.MustCompile(`inet (\d+\.\d+\.\d+\.\d+)`)
	ipv6Regex := regexp.MustCompile(`inet6 ([0-9a-fA-F:]+)`)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Extract IPv4 addresses.
		if matches := ipv4Regex.FindStringSubmatch(line); len(matches) == 2 {
			ip := matches[1]
			homeNet = append(homeNet, fmt.Sprintf("%s/32", ip))
		}

		// Extract IPv6 addresses.
		if matches := ipv6Regex.FindStringSubmatch(line); len(matches) == 2 {
			ip := matches[1]
			// Exclude link-local addresses (which usually start with "fe80")
			if !strings.HasPrefix(strings.ToLower(ip), "fe80") {
				homeNet = append(homeNet, fmt.Sprintf("%s/128", ip))
			}
		}
	}

	if len(homeNet) == 0 {
		// Fallback: extract IP addresses using pcap.
		devices, err := pcap.FindAllDevs()
		if err != nil {
			return fmt.Errorf("error finding devices: %v", err)
		}
		for _, device := range devices {
			if device.Name == iface {
				for _, addr := range device.Addresses {
					ip := addr.IP.String()
					if addr.IP.To4() != nil {
						homeNet = append(homeNet, fmt.Sprintf("%s/32", ip))
					} else {
						homeNet = append(homeNet, fmt.Sprintf("%s/128", ip))
					}
				}
				break
			}
		}
	}

	if len(homeNet) == 0 {
		return fmt.Errorf("no valid IP addresses found on interface %s", iface)
	}

	fmt.Printf("The homeNet is: %v\n", homeNet)
	return nil
}
