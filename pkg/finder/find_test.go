package finder

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSearch(t *testing.T) {
	tt := []struct {
		name     string
		value    string
		expected bool
	}{
		{
			name:     "english sentence, not a secret",
			value:    "this is not a secret",
			expected: false,
		},
		{
			name:     "english sentence as well, not a secret",
			value:    "also not a secret",
			expected: false,
		},
		{
			name:     "aws access key",
			value:    "AKIAV27RE77X4G7HB2G6",
			expected: true,
		},
		{
			name:     "github token",
			value:    "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H0",
			expected: true,
		},
		{
			name:     "base64-style api key",
			value:    "api_key = cm9ndWUtYWdlbnQtc2VjcmV0LWtleS0xMjM0NQ==",
			expected: true,
		},
		{
			name:     "hex-style api key",
			value:    "api_key: 7a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p",
			expected: true,
		},
	}

	for _, tc := range tt {
		t.Run(tc.name, func(t *testing.T) {
			result, err := Search(tc.value)
			assert.Nil(t, err)
			assert.Equal(t, tc.expected, result)
		})
	}
}
