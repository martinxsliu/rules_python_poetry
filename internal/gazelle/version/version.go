package version

import (
	"fmt"
	"strconv"
	"strings"
)

type Version struct {
	Major, Minor uint
}

func (v Version) GTE(other Version) bool {
	if v.Major != other.Major {
		return v.Major > other.Major
	}
	if v.Minor != other.Minor {
		return v.Minor > other.Minor
	}
	// same version
	return true
}

func Parse(v string) (Version, error) {
	var parsed Version
	parts := strings.Split(v, ".")
	for i, part := range parts {
		n, err := strconv.Atoi(part)
		if err != nil {
			return parsed, fmt.Errorf("failed to parse version: %s", v)
		}
		if n < 0 {
			return parsed, fmt.Errorf("failed to parse version: %s", v)
		}
		switch i {
		case 0:
			parsed.Major = uint(n)
		case 1:
			parsed.Minor = uint(n)
		default:
			break
		}
	}
	return parsed, nil
}
