package main

import (
	"fmt"
	"net/http"
	"os"
)

const address = "0.0.0.0:8080"

func main() {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		version := os.Getenv("VERSION")
		fmt.Fprintln(w, version)
	})

	fmt.Printf("Listening on %s\n", address)
	http.ListenAndServe(address, nil)
}
