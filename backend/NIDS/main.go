package main

import (
	"NIDS/NIDS/core"
	"NIDS/NIDS/listnetworkinterfaces"
	"NIDS/NIDS/rulesparser"
	"NIDS/NIDS/sethomenet"
	"fmt"
	"log"

	"github.com/spf13/cobra"
)



func main() {


	// Setup logging
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds)

	// Initialize the IP blocker
	core.InitIPBlocker()

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
			iface, _ := cmd.Flags().GetString("interface")
			if iface == "" {
				fmt.Println("Error: No interface specified")
				return
			}

			// Set HomeNet based on the interface
			if err := sethomenet.SetHomeNet(iface); err != nil {
				log.Fatalf("HomeNet IP not successfully set: %v", err)
			}

			// Call CaptureAndLogAllFields with the provided interface
			if err := core.CaptureAndLogAllFields(iface, false, ""); err != nil {
				log.Fatalf("Error capturing packets: %v", err)
			}
		},
	}
	captureCmd.Flags().StringP("interface", "i", "", "Network interface to capture packets from (e.g., eth0, wlan0)")

	// Define the match command
	var matchCmd = &cobra.Command{
		Use:   "match",
		Short: "Match packets against rules",
		Long:  "Capture network packets from the specified interface and match them against the provided rules file.",
		Run: func(cmd *cobra.Command, args []string) {
			iface, _ := cmd.Flags().GetString("interface")
			rulesFilePath, _ := cmd.Flags().GetString("rulesFile")
			if iface == "" {
				fmt.Println("Error: No interface specified")
				return
			}
			if rulesFilePath == "" {
				fmt.Println("Error: No rules file specified")
				return
			}

			// Set HomeNet based on the specified interface
			if err := sethomenet.SetHomeNet(iface); err != nil {
				log.Fatalf("HomeNet IP not successfully set: %v", err)
			}

			// Perform matching using the provided rules file
			if err := core.CaptureAndLogAllFields(iface, true, rulesFilePath); err != nil {
				log.Fatalf("Error matching packets: %v", err)
			}
		},
	}
	matchCmd.Flags().StringP("interface", "i", "", "Network interface to capture packets from (e.g., eth0, wlan0)")
	matchCmd.Flags().StringP("rulesFile", "r", "", "Path to the rules file for matching")

	// Define the list interfaces command
	var listInterfacesCmd = &cobra.Command{
		Use:   "list-interfaces",
		Short: "List all available network interfaces",
		Long:  "List all network interfaces on the system and their details.",
		Run: func(cmd *cobra.Command, args []string) {
			if err := listnetworkinterfaces.ListNetworkInterfaces(); err != nil {
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
			rulesFile, _ := cmd.Flags().GetString("rulesFile")
			outputFile, _ := cmd.Flags().GetString("outputFile")

			if err := rulesparser.ConvertSnortRulesToJSON(rulesFile, outputFile); err != nil {
				log.Fatalf("Error converting rules: %v", err)
			}
		},
	}
	convertCmd.Flags().StringP("rulesFile", "r", "", "Path to the Snort rules file")
	convertCmd.Flags().StringP("outputFile", "o", "", "Path (file or directory) to save the output JSON file")

	// Define IP Blocker commands

	// List blocked IPs command
	var listBlockedIPsCmd = &cobra.Command{
		Use:   "list-blocked-ips",
		Short: "List all currently blocked IPs",
		Long:  "Display a list of all currently blocked IP addresses.",
		Run: func(cmd *cobra.Command, args []string) {
			blockedIPs := core.GetBlockedIPs()
			if len(blockedIPs) == 0 {
				fmt.Println("No IPs are currently blocked")
				return
			}
			
			fmt.Println("Currently blocked IP addresses:")
			fmt.Println("------------------------------")
			for _, ip := range blockedIPs {
				fmt.Println(ip)
			}
			fmt.Printf("\nTotal: %d blocked IP(s)\n", len(blockedIPs))
		},
	}

	// Block IP command
	var blockIPCmd = &cobra.Command{
		Use:   "block-ip",
		Short: "Block an IP address",
		Long:  "Block an IP address permanently.",
		Run: func(cmd *cobra.Command, args []string) {
			ip, _ := cmd.Flags().GetString("ip")
			
			if ip == "" {
				fmt.Println("Error: No IP address specified")
				return
			}
			
			if core.IpBlocker != nil {
				core.IpBlocker.BlockIP(ip)
				fmt.Printf("IP %s has been permanently blocked\n", ip)
			} else {
				fmt.Println("Error: IP blocker not initialized")
			}
		},
	}
	blockIPCmd.Flags().StringP("ip", "i", "", "IP address to block")

	// Unblock IP command
	var unblockIPCmd = &cobra.Command{
		Use:   "unblock-ip",
		Short: "Unblock an IP address",
		Long:  "Remove the block on a previously blocked IP address.",
		Run: func(cmd *cobra.Command, args []string) {
			ip, _ := cmd.Flags().GetString("ip")
			if ip == "" {
				fmt.Println("Error: No IP address specified")
				return
			}
			
			core.ManualUnblockIP(ip)
			fmt.Printf("IP %s has been unblocked\n", ip)
		},
	}
	unblockIPCmd.Flags().StringP("ip", "i", "", "IP address to unblock")

	// Whitelist commands can be implemented in a future update
	// For now, create a simple placeholder command
	var whitelistIPCmd = &cobra.Command{
		Use:   "whitelist",
		Short: "Add an IP to the whitelist",
		Long:  "Add an IP address to the whitelist to prevent it from being blocked.",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Whitelist functionality will be implemented in a future update")
		},
	}
	whitelistIPCmd.Flags().StringP("ip", "i", "", "IP address to whitelist")

	// Create an IP management command group and add its subcommands
	var ipManagementCmd = &cobra.Command{
		Use:   "ip",
		Short: "IP address management commands",
		Long:  "Commands for managing IP addresses, including blocking, unblocking, and whitelisting.",
	}
	ipManagementCmd.AddCommand(listBlockedIPsCmd, blockIPCmd, unblockIPCmd, whitelistIPCmd)

	// Add all commands to the root command
	rootCmd.AddCommand(captureCmd, matchCmd, listInterfacesCmd, convertCmd, ipManagementCmd)

	// Execute the root command
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		log.Fatal(err)
	}
}
