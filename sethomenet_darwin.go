// +build darwin

package main

import (
	"bufio"
	"bytes"
	"fmt"
	"net"
	"os/exec"
	"regexp"
	"strings"
)

// Optionally, declare homeNet as a package-level variable if it is used elsewhere.
//var homeNet string

func SetHomeNet(iface string) error {
	// Use the macOS command "ifconfig <iface>" to show network configuration.
	cmd := exec.Command("ifconfig", iface)

	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("error executing command: %v", err)
	}

	scanner := bufio.NewScanner(bytes.NewReader(output))
	var candidateIPv6s []string

	// Prepare a regex to capture IPv6 addresses.
	// On macOS, we expect lines like:
	//   inet6 2001:db8::1 prefixlen 64 ...
	ipv6Regex := regexp.MustCompile(`inet6\s+([0-9a-fA-F:]+)`)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Exclude addresses marked as temporary or deprecated.
		if strings.Contains(line, "temporary") || strings.Contains(line, "deprecated") {
			continue
		}

		matches := ipv6Regex.FindStringSubmatch(line)
		if len(matches) == 2 {
			ip := matches[1]
			// Exclude link-local addresses.
			if strings.HasPrefix(strings.ToLower(ip), "fe80") {
				continue
			}
			candidateIPv6s = append(candidateIPv6s, ip)
		}
	}

	// If a stable IPv6 address is found, use it.
	if len(candidateIPv6s) > 0 {
		homeNet = fmt.Sprintf("%s/128", candidateIPv6s[0])
		fmt.Printf("The homenet is: %s\n", homeNet)
		return nil
	}

	// No IPv6 found; fallback to IPv4.
	ifi, err := net.InterfaceByName(iface)
	if err != nil {
		return fmt.Errorf("error finding interface %s: %v", iface, err)
	}
	addrs, err := ifi.Addrs()
	if err != nil {
		return fmt.Errorf("error getting addresses for interface %s: %v", iface, err)
	}
	for _, addr := range addrs {
		var ip net.IP
		switch v := addr.(type) {
		case *net.IPNet:
			ip = v.IP
		case *net.IPAddr:
			ip = v.IP
		}
		if ip == nil {
			continue
		}
		if ip4 := ip.To4(); ip4 != nil {
			homeNet = fmt.Sprintf("%s/32", ip4.String())
			fmt.Printf("The homenet is: %s\n", homeNet)
			return nil
		}
	}

	return fmt.Errorf("no suitable IPv6 or IPv4 address found on interface %s", iface)
}
