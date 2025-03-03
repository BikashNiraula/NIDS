package listnetworkinterfaces
import (
	// _ "NIDS/rulesparser"
	_ "encoding/json"
	"fmt"
	_ "log"
	_ "net"
	"os"
	_ "path/filepath"
	_ "strings"

	_ "github.com/google/gopacket"
	_ "github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	"github.com/olekukonko/tablewriter"
	_ "github.com/spf13/cobra"
)

// ListNetworkInterfaces lists all available network interfaces in a tabular format
func ListNetworkInterfaces() error {
	interfaces, err := pcap.FindAllDevs()
	if err != nil {
		return fmt.Errorf("failed to find network interfaces: %v", err)
	}

	// Create a new table for displaying network interfaces
	table := tablewriter.NewWriter(os.Stdout)
	table.SetHeader([]string{"Interface", "Description", "IP Address"})

	// Flag to track if there are interfaces with no IP address
	noIPFlag := false

	// Iterate over each interface and populate the table
	for _, iface := range interfaces {
		// Handle interfaces that have no IP addresses
		if len(iface.Addresses) == 0 {
			table.Append([]string{iface.Name, iface.Description, "No IP Address"})
			noIPFlag = true
		} else {
			// Iterate over the IP addresses associated with the interface
			for _, addr := range iface.Addresses {
				table.Append([]string{iface.Name, iface.Description, addr.IP.String()})
			}
		}
	}

	// If no IP addresses were found in any interfaces, display a message
	if noIPFlag {
		fmt.Println("Note: Some interfaces have no IP addresses associated.")
	}

	// Render the table
	table.Render()
	return nil
}