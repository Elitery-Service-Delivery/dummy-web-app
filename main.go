package main

import (
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os/exec"
	"regexp"
	"strings"
	"sync"
	"time"
)

type CacheEntry struct {
	Output    string
	Timestamp time.Time
}

type Server struct {
	cache      *CacheEntry
	cacheMutex sync.RWMutex
}

func NewServer() *Server {
	return &Server{}
}

// convertANSIToHTML converts ANSI color codes to HTML spans with appropriate colors
func convertANSIToHTML(text string) string {
	// ANSI color code mapping to CSS colors
	colorMap := map[string]string{
		"30": "color: #000000",     // Black
		"31": "color: #ff0000",     // Red
		"32": "color: #00ff00",     // Green
		"33": "color: #ffff00",     // Yellow
		"34": "color: #0000ff",     // Blue
		"35": "color: #ff00ff",     // Magenta
		"36": "color: #00ffff",     // Cyan
		"37": "color: #ffffff",     // White
		"90": "color: #808080",     // Bright Black (Gray)
		"91": "color: #ff6666",     // Bright Red
		"92": "color: #66ff66",     // Bright Green
		"93": "color: #ffff66",     // Bright Yellow
		"94": "color: #6666ff",     // Bright Blue
		"95": "color: #ff66ff",     // Bright Magenta
		"96": "color: #66ffff",     // Bright Cyan
		"97": "color: #ffffff",     // Bright White
	}

	// Remove ANSI escape sequences and replace with HTML
	ansiRegex := regexp.MustCompile(`\x1b\[([0-9;]+)m`)
	
	result := ansiRegex.ReplaceAllStringFunc(text, func(match string) string {
		// Extract the color code
		re := regexp.MustCompile(`\x1b\[([0-9;]+)m`)
		matches := re.FindStringSubmatch(match)
		if len(matches) > 1 {
			codes := strings.Split(matches[1], ";")
			for _, code := range codes {
				if code == "0" || code == "" {
					return "</span>" // Reset
				}
				if style, exists := colorMap[code]; exists {
					return fmt.Sprintf(`<span style="%s">`, style)
				}
			}
		}
		return ""
	})

	// Clean up any remaining ANSI codes
	cleanRegex := regexp.MustCompile(`\x1b\[[0-9;]*m`)
	result = cleanRegex.ReplaceAllString(result, "")
	
	return result
}

func (s *Server) getFastfetchOutput() (string, error) {
	s.cacheMutex.RLock()
	if s.cache != nil && time.Since(s.cache.Timestamp) < time.Minute {
		output := s.cache.Output
		s.cacheMutex.RUnlock()
		return output, nil
	}
	s.cacheMutex.RUnlock()

	// Execute fastfetch command
	cmd := exec.Command("fastfetch")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to execute fastfetch: %v", err)
	}

	// Update cache
	s.cacheMutex.Lock()
	s.cache = &CacheEntry{
		Output:    string(output),
		Timestamp: time.Now(),
	}
	s.cacheMutex.Unlock()

	return string(output), nil
}

func (s *Server) rootHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	output, err := s.getFastfetchOutput()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error getting system info: %v", err), http.StatusInternalServerError)
		return
	}

	// Convert ANSI colors to HTML and escape HTML properly
	htmlOutput := convertANSIToHTML(output)

	// HTML template with proper terminal-like styling
	htmlTemplate := `<!DOCTYPE html>
<html>
<head>
    <title>System Information</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Courier New', 'DejaVu Sans Mono', 'Liberation Mono', monospace; 
            margin: 0; 
            padding: 20px; 
            background-color: #1e1e1e; 
            color: #ffffff;
            line-height: 1.2;
        }
        .container {
            max-width: 100%;
            margin: 0 auto;
        }
        h1 { 
            color: #00ff00; 
            font-size: 18px; 
            margin-bottom: 20px;
            font-weight: normal;
        }
        pre { 
            background-color: #000000; 
            color: #ffffff;
            padding: 20px; 
            border-radius: 8px; 
            overflow-x: auto; 
            white-space: pre;
            font-family: 'Courier New', 'DejaVu Sans Mono', 'Liberation Mono', monospace;
            font-size: 14px;
            line-height: 1.2;
            border: 1px solid #333;
            margin: 0;
        }
        /* Style for fastfetch colored output */
        .fastfetch-output {
            color: #ffffff;
            background-color: #000000;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>FastFetch System Information</h1>
        <pre class="fastfetch-output">{{.}}</pre>
    </div>
</body>
</html>`

	tmpl, err := template.New("index").Parse(htmlTemplate)
	if err != nil {
		http.Error(w, "Template error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	err = tmpl.Execute(w, template.HTML(htmlOutput))
	if err != nil {
		log.Printf("Template execution error: %v", err)
	}
}

func main() {
	server := NewServer()

	http.HandleFunc("/", server.rootHandler)

	port := ":3131"
	log.Printf("Starting server on port %s", port)
	log.Printf("Visit http://localhost%s to see system information", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}