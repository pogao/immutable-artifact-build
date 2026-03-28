package finder

import (
	"log/slog"

	"github.com/zricethezav/gitleaks/v8/detect"
)

func Search(value string) (bool, error) {
	detector, err := detect.NewDetectorDefaultConfig()
	if err != nil {
		slog.Error("failed to generate detector", "error", err.Error())
		return false, err
	}

	findings := detector.DetectString(value)
	if len(findings) > 0 {
		return true, nil
	}

	return false, nil
}
