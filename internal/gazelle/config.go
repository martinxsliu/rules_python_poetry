package gazelle

import (
	"flag"
	"log"
	"strings"

	"github.com/bazelbuild/bazel-gazelle/config"
	gzflag "github.com/bazelbuild/bazel-gazelle/flag"
	"github.com/bazelbuild/bazel-gazelle/rule"
	"github.com/martinxsliu/rules_python_poetry/internal/gazelle/stdlib"
	"github.com/martinxsliu/rules_python_poetry/internal/gazelle/version"
)

type packageMode int

const (
	packageModeModule packageMode = iota
	packageModePackage
)

type pyConfig struct {
	pyVersion                version.Version
	libMode, testMode        packageMode
	testRule                 string
	thirdPartyImportPrefixes map[string]string // Maps an import importPath prefix to a 3rd party package name.
	extraPipArgs             []string
}

// RegisterFlags registers command-line flags used by the extension. This
// method is called once with the root configuration when Gazelle
// starts. RegisterFlags may set an initial values in Config.Exts. When flags
// are set, they should modify these values.
func (pythonLang) RegisterFlags(fs *flag.FlagSet, cmd string, c *config.Config) {
	// Set default config.
	pc := &pyConfig{
		pyVersion:                stdlib.Latest,
		testRule:                 pythonTestRule,
		thirdPartyImportPrefixes: make(map[string]string),
	}
	c.Exts[pythonLangName] = pc

	switch cmd {
	case "update-repos":
		fs.Var(&gzflag.MultiFlag{Values: &pc.extraPipArgs},
			"extra_pip_args",
			"Sets the extra_pip_args attribute for the generated pip_repository rule(s).")
	}
}

// CheckFlags validates the configuration after command line flags are parsed.
// This is called once with the root configuration when Gazelle starts.
// CheckFlags may set default values in flags or make implied changes.
func (pythonLang) CheckFlags(fs *flag.FlagSet, c *config.Config) error { return nil }

// KnownDirectives returns a list of directive keys that this Configurer can
// interpret. Gazelle prints errors for directives that are not recognized by
// any Configurer.
func (pythonLang) KnownDirectives() []string {
	return []string{
		"python_lib_mode",
		"python_test_mode",
		"python_test_rule",
		"python_third_party_import",
		"python_version",
	}
}

// Configure modifies the configuration using directives and other information
// extracted from a build file. Configure is called in each directory.
//
// c is the configuration for the current directory. It starts out as a copy
// of the configuration for the parent directory.
//
// rel is the slash-separated relative importPath from the repository root to
// the current directory. It is "" for the root directory itself.
//
// f is the build file for the current directory or nil if there is no
// existing build file.
func (pythonLang) Configure(c *config.Config, rel string, f *rule.File) {
	pc := cloneConfig(c)
	if f == nil {
		return
	}
	for _, directive := range f.Directives {
		switch directive.Key {
		case "python_lib_mode":
			switch directive.Value {
			case "module":
				pc.libMode = packageModeModule
			case "package":
				pc.libMode = packageModePackage
			}
		case "python_test_mode":
			switch directive.Value {
			case "module":
				pc.testMode = packageModeModule
			case "package":
				pc.testMode = packageModePackage
			}
		case "python_test_rule":
			if directive.Value == pythonPytestRule {
				pc.testRule = pythonPytestRule
			}
		case "python_third_party_import":
			parts := strings.Split(directive.Value, " ")
			if len(parts) < 2 {
				log.Print("Expected two arguments for python_third_party_import directive")
				continue
			}
			pc.thirdPartyImportPrefixes[parts[0]] = parts[1]
		case "python_version":
			v, err := version.Parse(directive.Value)
			if err != nil {
				log.Print(err)
				continue
			}
			pc.pyVersion = v
		}
	}
}

func getConfig(c *config.Config) *pyConfig {
	pc := c.Exts[pythonLangName]
	if pc == nil {
		return nil
	}
	return pc.(*pyConfig)
}

func cloneConfig(c *config.Config) *pyConfig {
	pc := &pyConfig{}
	*pc = *getConfig(c)
	clonedMap := make(map[string]string)
	for k, v := range pc.thirdPartyImportPrefixes {
		clonedMap[k] = v
	}
	pc.thirdPartyImportPrefixes = clonedMap
	c.Exts[pythonLangName] = pc
	return pc
}
