package listnetworkinterfaces

import (
	"fmt"

	"github.com/google/gopacket/pcap"
)

// NetworkInterface represents a network interface with its details
type NetworkInterface struct {
	Name        string
	Description string
	IPAddress   string
}

// ListNetworkInterfaces lists all available network interfaces and returns them as a slice of NetworkInterface
func ListNetworkInterfacesUI() ([]NetworkInterface, error) {
	interfaces, err := pcap.FindAllDevs()
	if err != nil {
		return nil, fmt.Errorf("failed to find network interfaces: %v", err)
	}

	var networkInterfaces []NetworkInterface

	for _, iface := range interfaces {
		if len(iface.Addresses) == 0 {
			networkInterfaces = append(networkInterfaces, NetworkInterface{
				Name:        iface.Name,
				Description: iface.Description,
				IPAddress:   "No IP Address",
			})
		} else {
			for _, addr := range iface.Addresses {
				networkInterfaces = append(networkInterfaces, NetworkInterface{
					Name:        iface.Name,
					Description: iface.Description,
					IPAddress:   addr.IP.String(),
				})
			}
		}
	}

	return networkInterfaces, nil
}