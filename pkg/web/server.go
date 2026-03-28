package web

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/pogao/immutable-artifact-build/pkg/finder"
)

type Server struct {
	mux *http.ServeMux
}

type Payload struct {
	Value string `json:"value"`
}

func Start() error {
	srv := &Server{
		mux: http.NewServeMux(),
	}

	srv.mux.HandleFunc("/api", srv.apiHandler)

	err := http.ListenAndServe(":8080", srv.mux)
	if err != nil {
		return err
	}

	return nil
}

func (s *Server) apiHandler(w http.ResponseWriter, r *http.Request) {
	var data Payload

	err := json.NewDecoder(r.Body).Decode(&data)
	if err != nil {
		slog.Error("malformed request", err.Error())
		fmt.Fprintf(w, "Malformed request") //nolint
		return
	}

	res, err := finder.Search(data.Value)
	if err != nil {
		slog.Error("failed to process request", err.Error())
		fmt.Fprintf(w, "failed to process input") //nolint
		return
	}

	if res {
		fmt.Fprintf(w, "value contains a secret") //nolint
		return
	}

	fmt.Fprintf(w, "value does not contain a secret") //nolint
}
