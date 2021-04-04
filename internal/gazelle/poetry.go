package gazelle

import (
	"fmt"
	"io/ioutil"
	"sort"
	"strings"

	"github.com/bazelbuild/bazel-gazelle/language"
	"github.com/bazelbuild/bazel-gazelle/rule"
	toml "github.com/pelletier/go-toml"
)

type poetryLock struct {
	Packages []poetryPackage `toml:"package"`
}

type poetryPackage struct {
	Name           string `toml:"name"`
	Version        string `toml:"version"`
	Description    string `toml:"description"`
	Category       string `toml:"category"`
	Optional       bool   `toml:"optional"`
	PythonVersions string `toml:"python-versions"`
}

func importReposFromPoetry(args language.ImportReposArgs) language.ImportReposResult {
	pc := getConfig(args.Config)

	data, err := ioutil.ReadFile(args.Path)
	if err != nil {
		return language.ImportReposResult{Error: err}
	}

	var lockFile poetryLock
	if err := toml.Unmarshal(data, &lockFile); err != nil {
		return language.ImportReposResult{Error: err}
	}

	var gen []*rule.Rule
	for _, pkg := range lockFile.Packages {
		r := rule.NewRule("pip_repository", repoName(pkg.Name))
		r.SetAttr("package", packageName(pkg.Name))
		r.SetAttr("requirement", "=="+pkg.Version)
		if len(pc.extraPipArgs) > 0 {
			r.SetAttr("extra_pip_args", pc.extraPipArgs)
		}
		gen = append(gen, r)
	}
	sort.SliceStable(gen, func(i, j int) bool {
		return gen[i].Name() < gen[j].Name()
	})

	return language.ImportReposResult{
		Gen: gen,
	}
}

func repoName(name string) string {
	name = strings.ReplaceAll(name, "-", "_")
	name = strings.ReplaceAll(name, ".", "_")
	name = strings.ToLower(name)
	return fmt.Sprintf("pypi__%s", name)
}

// From PEP 426:
//   All comparisons of distribution names MUST be case insensitive, and MUST
//   consider hyphens and underscores to be equivalent.
func packageName(name string) string {
	name = strings.ReplaceAll(name, "-", "_")
	name = strings.ToLower(name)
	return name
}
