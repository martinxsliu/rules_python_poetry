package gazelle

import (
	"path/filepath"
	"strings"

	"github.com/bazelbuild/bazel-gazelle/language"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

// GenerateRules extracts build metadata from source files in a directory.
// GenerateRules is called in each directory where an update is requested
// in depth-first post-order.
//
// args contains the arguments for GenerateRules. This is passed as a
// struct to avoid breaking implementations in the future when new
// fields are added.
//
// A GenerateResult struct is returned. Optional fields may be added to this
// type in the future.
//
// Any non-fatal errors this function encounters should be logged using
// log.Print.
func (pythonLang) GenerateRules(args language.GenerateArgs) language.GenerateResult {
	pc := getConfig(args.Config)

	var binFiles, libFiles, testFiles []fileInfo
	for _, file := range args.RegularFiles {
		if !strings.HasSuffix(file, ".py") {
			continue
		}

		info := buildFileInfo(args.Dir, args.Rel, file, pc)
		switch {
		case file == "__main__.py":
			binFiles = append(binFiles, info)
		case info.isTest:
			testFiles = append(testFiles, info)
		default:
			libFiles = append(libFiles, info)
		}
	}

	binRules, binImports := generateRules(pythonBinRule, packageModeModule, args.Dir, binFiles)
	libRules, libImports := generateRules(pythonLibRule, pc.libMode, args.Dir, libFiles)
	testRules, testImports := generateRules(pc.testRule, pc.testMode, args.Dir, testFiles)

	gen := append(append(binRules, libRules...), testRules...)
	imports := append(append(binImports, libImports...), testImports...)

	return language.GenerateResult{
		Gen:     gen,
		Imports: imports,
		Empty:   generateEmpty(args.File, args.RegularFiles, pc),
	}
}

func generateRules(kind string, mode packageMode, dir string, files []fileInfo) ([]*rule.Rule, []interface{}) {
	if len(files) == 0 {
		return nil, nil
	}

	var rules []*rule.Rule
	var imports []interface{}
	switch mode {
	case packageModePackage:
		name := filepath.Base(dir)
		if isTestRule(kind) {
			name += "_test"
		}

		var srcs []string
		var imps []importInfo
		for _, file := range files {
			srcs = append(srcs, file.name)
			imps = append(imps, file.imports...)
		}

		r := rule.NewRule(kind, name)
		r.SetAttr("srcs", srcs)
		r.SetAttr("visibility", []string{"//visibility:public"})

		rules = append(rules, r)
		imports = append(imports, imps)
	default: // packageModePackage
		for _, file := range files {
			r := rule.NewRule(kind, ruleNameFromFile(file.path))
			r.SetAttr("srcs", []string{file.name})
			r.SetAttr("visibility", []string{"//visibility:public"})
			if kind == pythonBinRule {
				r.SetAttr("main", file.name)
			}

			rules = append(rules, r)
			imports = append(imports, file.imports)
		}
	}

	return rules, imports
}

func ruleNameFromFile(path string) string {
	name := filepath.Base(path)
	switch name {
	case "__main__.py":
		return "main"
	case "__init__.py":
		name = filepath.Base(filepath.Dir(path))
		if name == "main" {
			name += "_init"
		}
	}

	name = strings.ReplaceAll(name, "-", "_")
	name = strings.ReplaceAll(name, ".", "_")
	return strings.ToLower(name)
}

func generateEmpty(f *rule.File, regularFiles []string, pc *pyConfig) []*rule.Rule {
	if f == nil {
		// f will be nil iff there is no existing BUILD file.
		return nil
	}

	knownFiles := make(map[string]bool)
	for _, f := range regularFiles {
		knownFiles[f] = true
	}

	var empty []*rule.Rule
outer:
	for _, r := range f.Rules {
		kind := r.Kind()
		if kind != pythonBinRule && kind != pythonLibRule && !isTestRule(kind) {
			continue
		}

		if isTestRule(kind) && kind != pc.testRule {
			empty = append(empty, rule.NewRule(kind, r.Name()))
			continue
		}

		for _, src := range r.AttrStrings("srcs") {
			if knownFiles[src] {
				continue outer
			}
		}
		empty = append(empty, rule.NewRule(kind, r.Name()))
	}
	return empty
}
