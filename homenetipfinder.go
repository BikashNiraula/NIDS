package main

import (
	"fmt"
	"github.com/google/gopacket/pcap"
)

// Global variable for home network CIDR (e.g. "192.168.101.6/24")
//var homeNet string

// SetHomeNet obtains the first IPv4 CIDR from the specified interface
// using the pcap.FindAllDevs() function and sets the global variable homeNet.
// func SetHomeNet(iface string) error {
// 	devices, err := pcap.FindAllDevs()
// 	if err != nil {
// 		return fmt.Errorf("error finding devices: %v", err)
// 	}

// 	for _, device := range devices {
// 		if device.Name == iface {
// 			for _, addr := range device.Addresses {
// 				if ip4 := addr.IP.To4(); ip4 != nil {
// 					// Determine the netmask size.
// 					maskSize, _ := addr.Netmask.Size()
// 					homeNet = fmt.Sprintf("%s/%d", ip4.String(), maskSize)
// 					return nil
// 				}
// 			}
// 			return fmt.Errorf("no IPv4 address found on interface %s", iface)
// 		}
// 	}
// 	return fmt.Errorf("interface %s not found", iface)
// }

// func main() {
// 	// Replace "eth0" with your interface name.
// 	iface := "\\Device\\NPF_{56610559-1305-4E78-8413-2864DE5D5E76}"
// 	if err := SetHomeNet(iface); err != nil {
// 		log.Fatalf("Failed to set homeNet: %v", err)
// 	}
// 	fmt.Println("homeNet set to", homeNet)
// 	os.Exit(0)
// }


// Global variable for home network CIDR (e.g. "192.168.101.6/32")
//var homeNet string

// SetHomeNet obtains the first IPv4 address from the specified interface
// using pcap.FindAllDevs() and sets the global variable homeNet with a /32 mask.
func SetHomeNet(iface string) error {
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
					return nil
				}
			}
			return fmt.Errorf("no IPv4 address found on interface %s", iface)
		}
	}
	return fmt.Errorf("interface %s not found", iface)
}

