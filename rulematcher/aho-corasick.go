package rulematcher

import (
	"container/list"
	"errors"
	"fmt"
	"strings"
)

type AhoCorasickNode struct {
	children   map[rune]*AhoCorasickNode
	failLink   *AhoCorasickNode
	patterns   []string
}

type AhoCorasick struct {
	root *AhoCorasickNode
}

// NewAhoCorasick initializes a new Aho-Corasick automaton
func NewAhoCorasick() *AhoCorasick {
	return &AhoCorasick{
		root: &AhoCorasickNode{children: make(map[rune]*AhoCorasickNode)},
	}
}

// AddPattern adds a pattern to the trie
func (ac *AhoCorasick) AddPattern(pattern string) {
	node := ac.root
	for _, char := range pattern {
		if _, exists := node.children[char]; !exists {
			node.children[char] = &AhoCorasickNode{children: make(map[rune]*AhoCorasickNode)}
		}
		node = node.children[char]
	}
	node.patterns = append(node.patterns, pattern)
}

// Build builds the failure links in the trie
func (ac *AhoCorasick) Build() {
	queue := list.New()
	for _, child := range ac.root.children {
		child.failLink = ac.root
		queue.PushBack(child)
	}

	for queue.Len() > 0 {
		node := queue.Remove(queue.Front()).(*AhoCorasickNode)

		for char, child := range node.children {
			failNode := node.failLink
			for failNode != nil && failNode.children[char] == nil {
				failNode = failNode.failLink
			}

			if failNode == nil {
				child.failLink = ac.root
			} else {
				child.failLink = failNode.children[char]
				child.patterns = append(child.patterns, failNode.children[char].patterns...)
			}

			queue.PushBack(child)
		}
	}
}

// Search finds all patterns in the input text
func (ac *AhoCorasick) Search(text string) ([]string, error) {
	if ac.root == nil {
		return nil, errors.New("Aho-Corasick automaton not built")
	}

	node := ac.root
	var matches []string
	for _, char := range text {
		for node != ac.root && node.children[char] == nil {
			node = node.failLink
		}
		if node.children[char] != nil {
			node = node.children[char]
		}
		for _, pattern := range node.patterns {
			matches = append(matches, pattern)
		}
	}

	return matches, nil
}

// PrintTrie is a debug function to visualize the Trie structure
func (ac *AhoCorasick) PrintTrie() {
	var printNode func(node *AhoCorasickNode, level int)
	printNode = func(node *AhoCorasickNode, level int) {
		for char, child := range node.children {
			fmt.Printf("%s%c -> ", strings.Repeat(" ", level*2), char)
			if len(child.patterns) > 0 {
				fmt.Printf("[%v]", child.patterns)
			}
			fmt.Println()
			printNode(child, level+1)
		}
	}

	printNode(ac.root, 0)
}


// Let's use this bad boy!
// ac := rulematcher.NewAhoCorasick()
// ac.AddPattern("attack")
// ac.AddPattern("hack")
// ac.AddPattern("malware")
// ac.Build()
// matches, _ := ac.Search("this is an attack with malware")
// fmt.Println("Matches:", matches)

// What do you think? Any tweaks or tests you want to add?
