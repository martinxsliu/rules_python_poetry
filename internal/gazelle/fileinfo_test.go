package gazelle

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestImportInfos(t *testing.T) {
	for _, tc := range []struct {
		desc, body string
		want       []importInfo
	}{
		{
			desc: "empty",
			body: "",
			want: nil,
		},
		{
			desc: "basic import",
			body: "import foo",
			want: []importInfo{{
				importPath: "foo",
			}},
		},
		{
			desc: "basic nested import importPath",
			body: "import foo.foo",
			want: []importInfo{{
				importPath: "foo.foo",
			}},
		},
		{
			desc: "basic import with alias",
			body: "import foo as f",
			want: []importInfo{{
				importPath: "foo",
			}},
		},
		{
			desc: "basic import with comment",
			body: "import foo as f  # comment",
			want: []importInfo{{
				importPath: "foo",
			}},
		},
		{
			desc: "basic relative import",
			body: "import .foo as f",
			want: []importInfo{{
				importPath: ".foo",
			}},
		},
		{
			desc: "multiple relative import",
			body: "import .foo as f\nimport ..bar.bar",
			want: []importInfo{{
				importPath: ".foo",
			}, {
				importPath: "..bar.bar",
			}},
		},
		{
			desc: "multiple single line imports",
			body: "import foo.foo, bar as b, baz.baz as c",
			want: []importInfo{{
				importPath: "foo.foo",
			}, {
				importPath: "bar",
			}, {
				importPath: "baz.baz",
			}},
		},
		{
			desc: "multiple imports",
			body: "import foo.foo\nimport bar as b\nimport baz.baz as c",
			want: []importInfo{{
				importPath: "foo.foo",
			}, {
				importPath: "bar",
			}, {
				importPath: "baz.baz",
			}},
		},
		{
			desc: "imports with minimum whitespace",
			body: "import foo as f,bar#comment",
			want: []importInfo{{
				importPath: "foo",
			}, {
				importPath: "bar",
			}},
		},
		{
			desc: "imports with non standard whitespaces",
			body: "  import  foo  as  f  ,  bar as b  \n\timport\tbaz\tas\tc\nimport a,b#comment",
			want: []importInfo{{
				importPath: "foo",
			}, {
				importPath: "bar",
			}, {
				importPath: "baz",
			}, {
				importPath: "a",
			}, {
				importPath: "b",
			}},
		},
		{
			desc: "invalid import",
			body: "import foo-bar",
		},
		{
			desc: "basic from import all",
			body: "from foo import *",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"*"},
			}},
		},
		{
			desc: "basic nested from import all",
			body: "from foo.foo import *",
			want: []importInfo{{
				importPath:  "foo.foo",
				fromImports: []string{"*"},
			}},
		},
		{
			desc: "basic from import all no space",
			body: "from foo import*",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"*"},
			}},
		},
		{
			desc: "basic from import name",
			body: "from foo import foo",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo"},
			}},
		},
		{
			desc: "basic from import name with alias",
			body: "from foo import foo as f",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo"},
			}},
		},
		{
			desc: "basic from import names",
			body: "from foo import foo, bar, baz",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo", "bar", "baz"},
			}},
		},
		{
			desc: "basic from import with comment",
			body: "from foo import foo # comment",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo"},
			}},
		},
		{
			desc: "basic relative from import",
			body: "from .foo import foo as f\nfrom ..bar.bar import bar",
			want: []importInfo{{
				importPath:  ".foo",
				fromImports: []string{"foo"},
			}, {
				importPath:  "..bar.bar",
				fromImports: []string{"bar"},
			}},
		},
		{
			desc: "basic from import names with aliases",
			body: "from foo import foo as f, bar as b, baz as c",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo", "bar", "baz"},
			}},
		},
		{
			desc: "basic from import names in parens",
			body: "from foo import (foo, bar, baz)",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo", "bar", "baz"},
			}},
		},
		{
			desc: "basic from import names in multiline parens",
			body: "from foo import (\nfoo,\n)",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo"},
			}},
		},
		{
			desc: "multiple from imports",
			body: "from a import *\nfrom b import b\nfrom c import (c)\nfrom d import d # comment",
			want: []importInfo{{
				importPath:  "a",
				fromImports: []string{"*"},
			}, {
				importPath:  "b",
				fromImports: []string{"b"},
			}, {
				importPath:  "c",
				fromImports: []string{"c"},
			}, {
				importPath:  "d",
				fromImports: []string{"d"},
			}},
		},
		{
			desc: "multiple multiline from imports",
			body: "from foo import (\nfoo,\n)\nfrom bar import (\nbar,\n)",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo"},
			}, {
				importPath:  "bar",
				fromImports: []string{"bar"},
			}},
		},
		{
			desc: "from import with minimum whitespace",
			body: "from foo.foo import foo as f,bar#comment\nfrom bar import*\nfrom baz import(a)",
			want: []importInfo{{
				importPath:  "foo.foo",
				fromImports: []string{"foo", "bar"},
			}, {
				importPath:  "bar",
				fromImports: []string{"*"},
			}, {
				importPath:  "baz",
				fromImports: []string{"a"},
			}},
		},
		{
			desc: "from import with line breaks and comments",
			body: "from foo import (#a\nfoo#a\n,#a\nbar#a\n,#a\n)#a\n",
			want: []importInfo{{
				importPath:  "foo",
				fromImports: []string{"foo", "bar"},
			}},
		},
		{
			desc: "imports and from imports",
			body: "import foo\nfrom bar import bar",
			want: []importInfo{{
				importPath: "foo",
			}, {
				importPath:  "bar",
				fromImports: []string{"bar"},
			}},
		},
	} {
		t.Run(tc.desc, func(t *testing.T) {
			dir, err := ioutil.TempDir("", "")
			if err != nil {
				t.Fatal(err)
			}
			defer os.RemoveAll(dir)

			path := filepath.Join(dir, "test.py")
			if err := ioutil.WriteFile(path, []byte(tc.body), 0600); err != nil {
				t.Fatal(err)
			}

			got := buildFileInfo(dir, "test.py", &pyConfig{}).imports
			if !reflect.DeepEqual(got, tc.want) {
				t.Errorf("got: %#v\nwant: %#v", got, tc.want)
			}
		})
	}
}
