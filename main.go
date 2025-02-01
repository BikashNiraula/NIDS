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