package gazelle

import (
	"path/filepath"

	"github.com/bazelbuild/bazel-gazelle/language"
)

var repoImportFuncs = map[string]func(args language.ImportReposArgs) language.ImportReposResult{
	"poetry.lock": importReposFromPoetry,
}

// CanImport returns whether a given configuration file may be imported
// with this extension. Only one extension may import any given file.
// ImportRepos will not be called unless this returns true.
func (pythonLang) CanImport(path string) bool {
	return repoImportFuncs[filepath.Base(path)] != nil
}

// ImportRepos generates a list of repository rules by reading a
// configuration file from another build system.
func (pythonLang) ImportRepos(args language.ImportReposArgs) language.ImportReposResult {
	return repoImportFuncs[filepath.Base(args.Path)](args)
}

// UpdateRepos generates pip_repository rules corresponding to packages in
// args.Imports.
func (pythonLang) UpdateRepos(args language.UpdateReposArgs) language.UpdateReposResult {
	return language.UpdateReposResult{}
}
