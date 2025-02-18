// +build windows

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


func SetHomeNet(iface string) error {
	// Execute the ipconfig command to fetch IPv6 addresses.
	cmd := exec.Command("ipconfig")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("error executing ipconfig command: %v", err)
	}

	// Attempt to extract a stable IPv6 address from ipconfig output.
	candidateIPv6s := []string{}
	scanner := bufio.NewScanner(bytes.NewReader(output))
	// Regex to capture the IPv6 address from lines starting with "IPv6 Address"
	ipv6Regex := regexp.MustCompile(`IPv6 Address[.\s]*:[\s]*([0-9a-fA-F:]+)`)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		// Skip lines indicating temporary or link-local addresses.
		if strings.Contains(line, "Temporary") || strings.Contains(line, "Link-local") {
			continue
		}
		matches := ipv6Regex.FindStringSubmatch(line)
		if len(matches) == 2 {
			ip := matches[1]
			// Exclude any address that starts with fe80 (link-local).
			if strings.HasPrefix(strings.ToLower(ip), "fe80") {
				continue
			}
			candidateIPv6s = append(candidateIPv6s, ip)
		}
	}

	if len(candidateIPv6s) > 0 {
		homeNet = fmt.Sprintf("%s/128", candidateIPv6s[0])
		fmt.Printf("The homenet is: %s\n", homeNet)
		return nil
	}

	// If no suitable IPv6 address is found, fallback to extracting an IPv4 address
	// using pcap to obtain the device list.
	devices, err := pcap.FindAllDevs()
	if err != nil {
		return fmt.Errorf("error finding devices: %v", err)
	}
	for _, device := range devices {
		if device.Name == iface {
			for _, addr := range device.Addresses {
				if ip4 := addr.IP.To4(); ip4 != nil {
					// Force the netmask to /32 for host-based NIDS.
					homeNet = fmt.Sprintf("%s/32", ip4.String())
					fmt.Printf("The homenet is: %s\n", homeNet)
					return nil
				}
			}
			return fmt.Errorf("no IPv4 address found on interface %s", iface)
		}
	}

	return fmt.Errorf("interface %s not found", iface)
}
