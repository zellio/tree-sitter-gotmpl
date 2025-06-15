package tree_sitter_gotmpl_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_gotmpl "github.com/zellio/tree-sitter-gotmpl/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_gotmpl.Language())
	if language == nil {
		t.Errorf("Error loading Go Template grammar")
	}
}
