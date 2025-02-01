package main

import (
	"NIDS/rulesparser"
	_ "encoding/json"
	"fmt"
	"log"
	_ "net"
	_ "os"
	_ "path/filepath"
	_ "strings"

	_ "github.com/google/gopacket"
	_ "github.com/google/gopacket/layers"
	_ "github.com/google/gopacket/pcap"
	_ "github.com/olekukonko/tablewriter"
	"github.com/spf13/cobra"
)

func main() {
	// Create the root command
	var rootCmd = &cobra.Command{
		Use:   "nids",
		Short: "A command line tool for Network Intrusion Detection System",
		Long:  "This tool allows you to capture packets from a specified network interface and detect network intrusion",
	}

	// Define the capture command
	var captureCmd = &cobra.Command{
		Use:   "capture",
		Short: "Capture network packets",
		Long:  "Capture network packets from the specified interface and log details like protocol, IP addresses, and ports.",
		Run: func(cmd *cobra.Command, args []string) {
			// Get the network interface(iface) from the command arguments
			iface, _ := cmd.Flags().GetString("interface")
			if iface == "" {
				fmt.Println("Error: No interface specified")
				return
			}

			// Call CaptureAndLogAllFields with the provided interface
			err := CaptureAndLogAllFields(iface)
			if err != nil {
				log.Fatalf("Error capturing packets: %v", err)
			}
		},
	}


	// Define the list interfaces command
	var listInterfacesCmd = &cobra.Command{
		Use:   "list-interfaces",
		Short: "List all available network interfaces",
		Long:  "List all network interfaces on the system and their details.",
		Run: func(cmd *cobra.Command, args []string) {
			err := ListNetworkInterfaces()
			if err != nil {
				log.Fatalf("Error listing interfaces: %v", err)
			}
		},
	}

	// Define the convert command
	var convertCmd = &cobra.Command{
		Use:   "convert-snort",
		Short: "Convert Snort rules file to JSON",
		Long:  "Converts a Snort rules file to JSON format, which can be used for various tasks such as analysis or integration.",
		Run: func(cmd *cobra.Command, args []string) {
			// Retrieve the flags provided in the CLI
			rulesFile, _ := cmd.Flags().GetString("rulesFile")
			outputFile, _ := cmd.Flags().GetString("outputFile")

			// Call the conversion function with the provided flags
			if err := rulesparser.ConvertSnortRulesToJSON(rulesFile, outputFile); err != nil {
				log.Fatalf("Error: %v", err)
			}
		},
	}

	// Add flags to the convert command
	// Add the --interface flag to the capture command
	captureCmd.Flags().StringP("interface", "i", "", "Network interface to capture packets from (e.g., eth0, wlan0)")
	convertCmd.Flags().StringP("rulesFile", "r", "", "Path to the Snort rules file")
	convertCmd.Flags().StringP("outputFile", "o", "", "Path(can be filepath or directory) to save the output JSON file")

	

	// Add the list-interfaces command to the root command
	rootCmd.AddCommand(captureCmd)
	rootCmd.AddCommand(listInterfacesCmd)
	rootCmd.AddCommand(convertCmd)

	// Execute the command
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		log.Fatal(err)
	}
}
//-------------------------------------------------------------------------------------------
// package main

// import (
// 	"fmt"
// 	"log"
// 	"time"

// 	"github.com/google/gopacket"
// 	"github.com/google/gopacket/pcap"
// 	"NIDS/packetpreprocesser" //Update this with your actual module path
// )

// func main() {
// 	// Find a network device
// 	devices, err := pcap.FindAllDevs()
// 	if err != nil {
// 		log.Fatal("Error finding devices:", err)
// 	}
// 	if len(devices) == 0 {
// 		log.Fatal("No network devices found!")
// 	}
// 	device := "\\Device\\NPF_{56610559-1305-4E78-8413-2864DE5D5E76}" // Use the first available device

// 	// Open the device for packet capture
// 	handle, err := pcap.OpenLive(device, 1600, true, pcap.BlockForever)
// 	if err != nil {
// 		log.Fatal("Error opening device:", err)
// 	}
// 	defer handle.Close()

// 	// Apply a simple filter to capture only TCP packets
// 	if err := handle.SetBPFFilter("tcp"); err != nil {
// 		log.Fatal("Error applying BPF filter:", err)
// 	}

// 	fmt.Println("Listening on:", device)

// 	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())

// 	// Capture and process packets
// 	for packet := range packetSource.Packets() {
// 		meta := packetpreprocesser.DecodePacket(packet.Data())
// 		if meta != nil {
// 			fmt.Printf("\n[Packet Captured] %s\n", time.Now().Format(time.RFC3339))
// 			fmt.Printf("Src: %s:%d -> Dst: %s:%d\n", meta.SrcIP, meta.SrcPort, meta.DstIP, meta.DstPort)
// 			fmt.Printf("Protocol: %s | TCP Flags: %s\n", meta.Protocol, meta.TCPFlags)
// 			if meta.Payload != "" {
// 				fmt.Println("Payload:", meta.Payload)
// 			}
// 			packetpreprocesser.ExtractHTTP(meta)
// 			packetpreprocesser.ExtractDNS(meta)
// 		}
// 	}
// }
//--------------------------------------
// package main

// import (
// 	"fmt"
// 	"log"

// 	"github.com/google/gopacket"
// 	"github.com/google/gopacket/pcap"
// )

// func main() {
// 	// Open device for packet capture
// 	handle, err := pcap.OpenLive("\\Device\\NPF_{56610559-1305-4E78-8413-2864DE5D5E76}", 1600, true, pcap.BlockForever) // Change "eth0" to your network device
// 	if err != nil {
// 		log.Fatal(err)
// 	}
// 	defer handle.Close()

// 	// Capture packets
// 	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())

// 	// Loop over packets
// 	for packet := range packetSource.Packets() {
// 		fmt.Println(packet)
// 	}
// }
