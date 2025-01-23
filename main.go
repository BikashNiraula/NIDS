package main

import (
	"fmt"
	"log"
	"NIDS/rulesparser"
	"github.com/google/gopacket"
	_ "github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	"github.com/spf13/cobra"
	"github.com/olekukonko/tablewriter"
	"os"
	"path/filepath"
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
			if err := convertRulesToJSON(rulesFile, outputFile); err != nil {
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

// CaptureAndLogAllFields captures network packets from the given interface
func CaptureAndLogAllFields(iface string) error {
	// Open the network interface
	handle, err := pcap.OpenLive(iface, 1600, true, pcap.BlockForever)
	if err != nil {
		return fmt.Errorf("failed to open interface: %v", err)
	}
	defer handle.Close()

	// Create a packet source to process packets
	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())

	// Start capturing packets
	fmt.Println("Listening for packets and extracting all fields...")
	for packet := range packetSource.Packets() {
		// Extract timestamp
		timestamp := packet.Metadata().Timestamp.Format("2006-01-02 15:04:05.000")

		// Extract protocol, source, destination, and payload
		var protocol, sourceIP, destinationIP, sourcePort, destinationPort string
		var payload []byte

		// Extract network layer (IP addresses)
		if networkLayer := packet.NetworkLayer(); networkLayer != nil {
			src, dst := networkLayer.NetworkFlow().Endpoints()
			sourceIP = src.String()
			destinationIP = dst.String()
		}

		// Extract transport layer (Ports)
		if transportLayer := packet.TransportLayer(); transportLayer != nil {
			protocol = transportLayer.LayerType().String()
			src, dst := transportLayer.TransportFlow().Endpoints()
			sourcePort = src.String()
			destinationPort = dst.String()
		}

		// Extract application layer (Payload)
		if applicationLayer := packet.ApplicationLayer(); applicationLayer != nil {
			payload = applicationLayer.Payload()
		}

		// Log the extracted fields, including the timestamp
		fmt.Printf(
			"Packet:\n  Timestamp: %s\n  Protocol: %s\n  Source IP: %s\n  Source Port: %s\n  Destination IP: %s\n  Destination Port: %s\n  Payload: %x\n\n",
			timestamp,
			protocol,
			sourceIP,
			sourcePort,
			destinationIP,
			destinationPort,
			payload,
		)
	}
	return nil
}

// convertRulesToJSON handles the logic for converting Snort rules to JSON
func convertRulesToJSON(rulesFile, outputFile string) error {
	// Ensure the rulesFile is provided
	if rulesFile == "" {
		return fmt.Errorf("please provide a rules file or directory using the --rulesFile flag")
	}

	// Check if rulesFile is a directory
	fileInfo, err := os.Stat(rulesFile)
	if err != nil {
		return fmt.Errorf("failed to access rulesFile: %v", err)
	}

	// If it's a directory, process all .rules files in the directory
	if fileInfo.IsDir() {
		// Ensure the outputFile is a valid directory
		if outputFile == "" {
			return fmt.Errorf("please provide an output directory using the --outputFile flag")
		}

		// Check if outputFile is a valid directory
		outputDirInfo, err := os.Stat(outputFile)
		if err != nil {
			return fmt.Errorf("error accessing output directory: %v", err)
		}
		if !outputDirInfo.IsDir() {
			return fmt.Errorf("provided output path is not a directory")
		}

		// Process all .rules files in the directory
		files, err := os.ReadDir(rulesFile)
		if err != nil {
			return fmt.Errorf("failed to read rules directory: %v", err)
		}

		// Loop through the files and process .rules files
		for _, file := range files {
			if filepath.Ext(file.Name()) == ".rules" {
				// Construct the full path of the rules file
				rulesFilePath := filepath.Join(rulesFile, file.Name())
				// Construct the corresponding output JSON file path
				outputJSONPath := filepath.Join(outputFile, file.Name()+".json")

				// Convert each .rules file to JSON
				if err := rulesparser.ConvertSnortRulesToJSON(rulesFilePath, outputJSONPath); err != nil {
					log.Printf("Error converting %s: %v", file.Name(), err)
				} else {
					fmt.Printf("Rules file %s successfully converted to %s\n", file.Name(), outputJSONPath)
				}
			}
		}
		return nil
	}

	// If it's a single file, process it as usual
	if outputFile == "" {
		// Ensure the default output directory exists
		defaultOutputDir := "./Rules/JsonRules"
		err := os.MkdirAll(defaultOutputDir, os.ModePerm)
		if err != nil {
			return fmt.Errorf("error creating output directory: %v", err)
		}
		// Use the rules file name with .json extension in the default directory
		outputFile = filepath.Join(defaultOutputDir, filepath.Base(rulesFile)+".json")
	}

	// If outputFile is a directory, append .json extension with the same filename
	if info, err := os.Stat(outputFile); err == nil && info.IsDir() {
		// If it's a directory, use the base name of the rulesFile and append .json
		outputFile = filepath.Join(outputFile, filepath.Base(rulesFile)+".json")
	}

	// Convert the single Snort rules file to JSON
	if err := rulesparser.ConvertSnortRulesToJSON(rulesFile, outputFile); err != nil {
		return fmt.Errorf("error converting rules file to JSON: %v", err)
	}

	fmt.Printf("Rules file successfully converted to JSON and saved to %s\n", outputFile)
	return nil
}