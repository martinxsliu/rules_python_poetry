package gazelle

import (
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/martinxsliu/rules_python_poetry/internal/gazelle/stdlib"
)

const (
	importAll = "*"
)

type fileInfo struct {
	path    string
	name    string
	imports []importInfo
	isTest  bool
}

type importInfo struct {
	importPath  string
	fromImports []string
	filePath    string
}

func (info importInfo) IsFromImport() bool {
	return len(info.fromImports) > 0
}

func buildFileInfo(dir, rel, name string, pc *pyConfig) fileInfo {
	info := fileInfo{
		path:   filepath.Join(dir, name),
		name:   filepath.Base(name),
		isTest: strings.HasPrefix(name, "test_") || strings.HasSuffix(name, "_test.py") || strings.HasSuffix(name, "_tests.py"),
	}

	body, err := ioutil.ReadFile(info.path)
	if err != nil {
		log.Printf("%s: error reading file: %v", info.path, err)
		return info
	}

	allImports := findAllImports(string(body), rel)
	info.imports = filterNonStdlibImports(allImports, pc)

	return info
}

var (
	startFragment   = `(?m)^\s*`             // start of text or line
	endFragment     = `\s*(?:#.*)?$`         // end of text or line with optional comment
	pathFragment    = `\.{0,2}\w+(?:\.\w+)*` // e.g. foo.foo or .foo or ..foo
	asAliasFragment = `(?:\s+as\s+\w+)?`
	// e.g. foo.foo as f
	identFragment = fmt.Sprintf(`(?P<importPath>%s)%s`, pathFragment, asAliasFragment)
	// e.g. foo.foo as f, bar.bar as b
	identsFragment     = fmt.Sprintf(`(?P<idents>%s(?:\s*,\s*%s)*)`, identFragment, identFragment)
	importStmtFragment = fmt.Sprintf(`import\s+%s`, identsFragment)

	// whitespace with optional comment with a newline
	optNewlineFragment = `\s*(?:(?:#.*)?$\s*)?`
	// e.g. foo as f
	fromIdentFragment = fmt.Sprintf(`(?P<importPath>\w+)%s`, asAliasFragment)
	// e.g. foo as f, bar as b
	fromIdentsFragment = fmt.Sprintf(`(?P<fromIdents>%s(?:\s*,\s*%s)*)`, fromIdentFragment, fromIdentFragment)
	// e.g.
	//  (foo.foo as f, bar.bar as b)
	// or
	//  (
	//    foo.foo as f, # comment
	//    bar.bar as b,
	//  )
	fromIdentsParensFragment = fmt.Sprintf(
		`\(%s(?P<fromIdentsParens>%s(?:%s,%s%s)*)(?:%s,%s)?\)`,
		optNewlineFragment,
		fromIdentFragment,
		optNewlineFragment,
		optNewlineFragment,
		fromIdentFragment,
		optNewlineFragment,
		optNewlineFragment,
	)
	fromImportStmtFragment = fmt.Sprintf(
		`from\s+(?P<fromPath>%s)\s+import(?:\s+%s|\s*%s|\s*(?P<star>\*))`,
		pathFragment,
		fromIdentsFragment,
		fromIdentsParensFragment,
	)

	identRe        = regexp.MustCompile(identFragment)
	identRePathIdx = identRe.SubexpIndex("importPath")

	multilineIdentRe        = regexp.MustCompile(fmt.Sprintf(`(?m)%s%s%s`, optNewlineFragment, fromIdentFragment, optNewlineFragment))
	multilineIdentRePathIdx = multilineIdentRe.SubexpIndex("importPath")

	allRe = regexp.MustCompile(fmt.Sprintf(
		`%s(?:(?:%s)|(?:%s))%s`,
		startFragment,
		importStmtFragment,
		fromImportStmtFragment,
		endFragment,
	))
	allReIdentsIdx           = allRe.SubexpIndex("idents")
	allReFromPathIdx         = allRe.SubexpIndex("fromPath")
	allReFromIdentsIdx       = allRe.SubexpIndex("fromIdents")
	allReFromIdentsParensIdx = allRe.SubexpIndex("fromIdentsParens")
	allReStarIdx             = allRe.SubexpIndex("star")
)

func findAllImports(body, rel string) []importInfo {
	var imports []importInfo
	matches := allRe.FindAllStringSubmatch(body, -1)
	for _, match := range matches {
		if idents := match[allReIdentsIdx]; idents != "" {
			// e.g. import foo, foo.foo, foo as f
			// Go regexes does not capture repeating groups, but we know that packages
			// must be separated by commas (,) so we can split on that then apply regexes
			// to each split for the package name and alias.
			splits := strings.Split(idents, ",")
			for _, split := range splits {
				match := identRe.FindStringSubmatch(split)
				if match == nil {
					continue
				}

				importPath := match[identRePathIdx]
				imports = append(imports, importInfo{
					importPath: importPath,
					filePath:   buildFilePath(importPath, rel),
				})
			}
			continue
		}

		// e.g. from foo import foo
		importPath := match[allReFromPathIdx]
		imp := importInfo{
			importPath: importPath,
			filePath:   buildFilePath(importPath, rel),
		}
		switch {
		case match[allReFromIdentsIdx] != "":
			splits := strings.Split(match[allReFromIdentsIdx], ",")
			for _, split := range splits {
				match := identRe.FindStringSubmatch(split)
				if match == nil {
					continue
				}
				imp.fromImports = append(imp.fromImports, match[identRePathIdx])
			}
		case match[allReFromIdentsParensIdx] != "":
			splits := strings.Split(match[allReFromIdentsParensIdx], ",")
			for _, split := range splits {
				match := multilineIdentRe.FindStringSubmatch(split)
				if match == nil {
					continue
				}
				imp.fromImports = append(imp.fromImports, match[multilineIdentRePathIdx])
			}
		case match[allReStarIdx] != "":
			imp.fromImports = append(imp.fromImports, importAll)
		}
		imports = append(imports, imp)
	}
	return imports
}

func filterNonStdlibImports(imports []importInfo, pc *pyConfig) []importInfo {
	var nonStdlibImports []importInfo
	for _, imp := range imports {
		pathParts := strings.Split(imp.importPath, ".")
		if len(pathParts) == 0 {
			continue // this shouldn't happen.
		}

		versionRange, ok := stdlib.Packages[pathParts[0]]
		if ok && pc.pyVersion.GTE(versionRange.Min) && versionRange.Max.GTE(pc.pyVersion) {
			// Stdlib import, nothing to depend on.
			continue
		}

		nonStdlibImports = append(nonStdlibImports, imp)
	}
	return nonStdlibImports
}

func buildFilePath(importPath string, rel string) string {
	// Convert a relative import path into an absolute import path.
	pathParts := strings.Split(importPath, ".")
	if len(pathParts) == 0 {
		return "" // this shouldn't happen.
	}
	if pathParts[0] == "" {
		// Relative import, either `.foo` or `..foo`.
		if pathParts[1] == "" {
			pathParts[1] = ".."
		}
		pathParts = append([]string{rel}, pathParts[1:]...)
	}
	return filepath.Join(pathParts...)
}
