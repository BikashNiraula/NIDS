// package terminal

// import (
// 	"bufio"
// 	"log"
// 	"net/http"
// 	"os/exec"
// 	"runtime"

// 	"github.com/gorilla/websocket"
// )

// // WebSocket upgrader
// var upgrader = websocket.Upgrader{
// 	CheckOrigin: func(r *http.Request) bool { return true },
// }

// // getShellCommand returns the appropriate shell command based on OS
// func getShellCommand() *exec.Cmd {
// 	if runtime.GOOS == "windows" {
// 		return exec.Command("cmd")
// 	}
// 	return exec.Command("bash")
// }

// // handleTerminalConnection manages WebSocket communication with the shell
// func handleTerminalConnection(w http.ResponseWriter, r *http.Request) {
// 	conn, err := upgrader.Upgrade(w, r, nil)
// 	if err != nil {
// 		log.Println("WebSocket Upgrade Error:", err)
// 		return
// 	}
// 	defer conn.Close()

// 	log.Println("WebSocket connection established")

// 	// Start shell process
// 	cmd := getShellCommand()
// 	stdin, _ := cmd.StdinPipe()
// 	stdout, _ := cmd.StdoutPipe()
// 	cmd.Start()

// 	log.Println("Shell process started")

// 	// Read shell output and send to WebSocket
// 	go func() {
// 		scanner := bufio.NewScanner(stdout)
// 		for scanner.Scan() {
// 			msg := scanner.Text()
// 			log.Println("Shell output:", msg) // Log shell output
// 			if err := conn.WriteMessage(websocket.TextMessage, []byte(msg)); err != nil {
// 				log.Println("WebSocket Write Error:", err)
// 				return
// 			}
// 		}
// 	}()

// 	// Read WebSocket input and send to shell
// 	for {
// 		_, msg, err := conn.ReadMessage()
// 		if err != nil {
// 			log.Println("WebSocket Read Error:", err)
// 			break
// 		}
// 		log.Println("WebSocket input received:", string(msg)) // Log WebSocket input
// 		stdin.Write(append(msg, '\n'))
// 	}

// 	log.Println("WebSocket connection closed")
// }

// // SetupRoutes initializes the API routes

//	func SetupRoutes() {
//		log.Println("API routes initialized")
//		http.HandleFunc("/ws/terminal", handleTerminalConnection)
//	}
package terminal

import (
	"bufio"
	"log"
	"net/http"
	"os/exec"
	"runtime"
	"sync"

	"github.com/gorilla/websocket"
)

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
	// Upgrade the connection to WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		http.Error(w, "Could not open WebSocket connection", http.StatusBadRequest)
		return
	}
	defer conn.Close()

	// Start shell process
	cmd := getShellCommand()
	stdin, err := cmd.StdinPipe()
	if err != nil {
		log.Printf("Failed to create stdin pipe: %v", err)
		return
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Printf("Failed to create stdout pipe: %v", err)
		return
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		log.Printf("Failed to create stderr pipe: %v", err)
		return
	}

	// Start the command
	if err := cmd.Start(); err != nil {
		log.Printf("Failed to start shell: %v", err)
		return
	}
	defer func() {
		stdin.Close()
		cmd.Process.Kill()
		cmd.Wait()
	}()

	// Synchronization
	var wg sync.WaitGroup
	wg.Add(2)

	// Read and send stdout
	go func() {
		defer wg.Done()
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			msg := scanner.Text()
			if err := conn.WriteMessage(websocket.TextMessage, []byte(msg+"\n")); err != nil {
				log.Printf("Failed to write stdout to WebSocket: %v", err)
				return
			}
		}
	}()

	// Read and send stderr
	go func() {
		defer wg.Done()
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			msg := scanner.Text()
			if err := conn.WriteMessage(websocket.TextMessage, []byte("ERROR: "+msg+"\n")); err != nil {
				log.Printf("Failed to write stderr to WebSocket: %v", err)
				return
			}
		}
	}()

	// Handle incoming WebSocket messages (commands)
	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			log.Printf("WebSocket read error: %v", err)
			break
		}

		// Write the command to stdin
		if _, err := stdin.Write(append(msg, '\n')); err != nil {
			log.Printf("Failed to write to stdin: %v", err)
			break
		}
	}

	// Wait for output goroutines to finish
	wg.Wait()
}

// SetupRoutes initializes the terminal WebSocket route
func SetupRoutes() {
	log.Println("Terminal WebSocket route initialized")
	http.HandleFunc("/ws/terminal", handleTerminalConnection)
}