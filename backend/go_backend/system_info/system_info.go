package system_info

import (
	"encoding/json"
	"log"
	"net/http"
	"runtime"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/net"
)

// SystemStatus represents system metrics
type SystemStatus struct {
	OS         string  `json:"os"`
	CPUUsage   float64 `json:"cpuUsage"`
	Memory     float64 `json:"memoryUsage"`
	DiskUsage  float64 `json:"diskUsage"`
	NetworkIn  uint64  `json:"networkIn"`
	NetworkOut uint64  `json:"networkOut"`
}

// GetSystemStatus fetches system statistics
func GetSystemStatus() SystemStatus {
	os := runtime.GOOS

	// Get CPU usage
	cpuPercent, _ := cpu.Percent(0, false)

	// Get memory usage
	memoryInfo, _ := mem.VirtualMemory()

	// Get disk usage
	diskUsage, _ := disk.Usage("/")

	// Get network usage
	netIO, _ := net.IOCounters(true)
	var networkIn, networkOut uint64
	for _, io := range netIO {
		networkIn += io.BytesRecv
		networkOut += io.BytesSent
	}

	return SystemStatus{
		OS:         os,
		CPUUsage:   cpuPercent[0],
		Memory:     memoryInfo.UsedPercent,
		DiskUsage:  diskUsage.UsedPercent,
		NetworkIn:  networkIn,
		NetworkOut: networkOut,
	}
}

// Enable CORS
func enableCORS(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

// StatusHandler handles the system status endpoint
func StatusHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	status := GetSystemStatus()

	log.Printf("System Status Data: %+v\n", status)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}
