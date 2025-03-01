package terminal

import (
	"bufio"
	"log"
	"net/http"
	"os/exec"
	"runtime"

	"github.com/gorilla/websocket"
)

// WebSocket upgrader
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

// getShellCommand returns the appropriate shell command based on OS
func getShellCommand() *exec.Cmd {
	if runtime.GOOS == "windows" {
		return exec.Command("cmd")
	}
	return exec.Command("bash")
}

// handleTerminalConnection manages WebSocket communication with the shell
func handleTerminalConnection(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket Upgrade Error:", err)
		return
	}
	defer conn.Close()

	log.Println("WebSocket connection established")

	// Start shell process
	cmd := getShellCommand()
	stdin, _ := cmd.StdinPipe()
	stdout, _ := cmd.StdoutPipe()
	cmd.Start()

	log.Println("Shell process started")

	// Read shell output and send to WebSocket
	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			msg := scanner.Text()
			log.Println("Shell output:", msg) // Log shell output
			if err := conn.WriteMessage(websocket.TextMessage, []byte(msg)); err != nil {
				log.Println("WebSocket Write Error:", err)
				return
			}
		}
	}()

	// Read WebSocket input and send to shell
	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			log.Println("WebSocket Read Error:", err)
			break
		}
		log.Println("WebSocket input received:", string(msg)) // Log WebSocket input
		stdin.Write(append(msg, '\n'))
	}

	log.Println("WebSocket connection closed")
}

// SetupRoutes initializes the API routes

	func SetupRoutes() {
		log.Println("API routes initialized")
		http.HandleFunc("/ws", handleTerminalConnection)
	}