package gazelle

import (
	"github.com/bazelbuild/bazel-gazelle/config"
	"github.com/bazelbuild/bazel-gazelle/language"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

const (
	pythonLangName = "python"

	pythonBinRule     = "py_binary"
	pythonLibRule     = "py_library"
	pythonTestRule    = "py_test"
	pythonPytestRule  = "pytest_test"
	pipRepositoryRule = "pip_repository"
)

var _ language.Language = pythonLang{}
var _ language.RepoImporter = pythonLang{}
var _ language.RepoUpdater = pythonLang{}

type pythonLang struct{}

func NewLanguage() language.Language {
	return pythonLang{}
}

// Fix repairs deprecated usage of language-specific rules in f. This is
// called before the file is indexed. Unless c.ShouldFix is true, fixes
// that delete or rename rules should not be performed.
func (pythonLang) Fix(c *config.Config, f *rule.File) {}

func isTestRule(kind string) bool {
	return kind == pythonTestRule || kind == pythonPytestRule
}
