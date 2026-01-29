import { forwardRef, useRef, useEffect } from 'react';
import Editor from '@monaco-editor/react';
import animGrammar from './anim.tmLanguage.json';
import manimGrammar from './manim.tmLanguage.json';

interface CodeEditorProps {
  value: string;
  onChange: (value: string) => void;
  language?: string;
  disabled?: boolean;
  placeholder?: string;
  onSave?: () => void;
  errorLine?: number;
  errorColumn?: number;
  errorStart?: number;
  errorEnd?: number;
}

// Convert TextMate grammar patterns to Monaco tokenizer rules
const convertTextMateToMonaco = (grammar: any) => {
  const tokenizer: any = {
    root: []
  };

  // Convert patterns to Monaco format
  if (grammar.patterns) {
    grammar.patterns.forEach((pattern: any) => {
      if (pattern.include) {
        // Handle includes
        const includeName = pattern.include.replace('#', '');
        if (grammar.repository && grammar.repository[includeName]) {
          const includePatterns = grammar.repository[includeName].patterns;
          includePatterns.forEach((includePattern: any) => {
            if (includePattern.match) {
              tokenizer.root.push([new RegExp(includePattern.match), includePattern.name || 'identifier']);
            }
          });
        }
      } else if (pattern.match) {
        tokenizer.root.push([new RegExp(pattern.match), pattern.name || 'identifier']);
      }
    });
  }

  // Add repository patterns
  if (grammar.repository) {
    Object.keys(grammar.repository).forEach(key => {
      const repo = grammar.repository[key];
      if (repo.patterns) {
        tokenizer[key] = repo.patterns.map((pattern: any) => {
          if (pattern.match) {
            return [new RegExp(pattern.match), pattern.name || 'identifier'];
          }
          return ['', ''];
        }).filter(([regex]: any) => regex !== '');
      }
    });
  }

  return tokenizer;
};

const CodeEditor = forwardRef<HTMLDivElement, CodeEditorProps>(
  ({ value, onChange, language = 'haxe-manim', disabled = false, placeholder, onSave, errorLine, errorColumn, errorStart, errorEnd }, ref) => {
    const editorRef = useRef<any>(null);
    const saveHandlerRef = useRef<() => void>();
    const errorDecorationRef = useRef<string[]>([]);

    // Store the save handler in a ref so it can be accessed by the event listener
    useEffect(() => {
      saveHandlerRef.current = onSave;
    }, [onSave]);

    // Handle error marking
    useEffect(() => {
      if (editorRef.current) {
        // Remove previous error decorations
        if (errorDecorationRef.current.length > 0) {
          editorRef.current.deltaDecorations(errorDecorationRef.current, []);
          errorDecorationRef.current = [];
        }

        // Only add new decorations if there's an error
        if (errorLine) {
          const decorations = [];

          // Add line decoration
          decorations.push({
            range: {
              startLineNumber: errorLine,
              startColumn: 1,
              endLineNumber: errorLine,
              endColumn: 1
            },
            options: {
              isWholeLine: true,
              className: 'error-line',
              glyphMarginClassName: 'error-glyph',
              linesDecorationsClassName: 'error-line-decoration'
            }
          });

          // Add character-level decoration if we have start and end positions
          if (errorStart !== undefined && errorEnd !== undefined) {
            const model = editorRef.current.getModel();
            if (model) {
              try {
                const startPos = model.getPositionAt(errorStart);
                const endPos = model.getPositionAt(errorEnd);
                
                decorations.push({
                  range: {
                    startLineNumber: startPos.lineNumber,
                    startColumn: startPos.column,
                    endLineNumber: endPos.lineNumber,
                    endColumn: endPos.column
                  },
                  options: {
                    className: 'error-token',
                    hoverMessage: { value: 'Parse error at this position' }
                  }
                });
              } catch (e) {
                console.log('Error calculating character position:', e);
              }
            }
          }

          errorDecorationRef.current = editorRef.current.deltaDecorations([], decorations);
        }
      }
    }, [errorLine, errorColumn, errorStart, errorEnd]);

    const handleEditorDidMount = (editor: any, monaco: any) => {
      editorRef.current = editor;
      
      // Register Haxe languages
      monaco.languages.register({ id: 'haxe-anim' });
      monaco.languages.register({ id: 'haxe-manim' });
      
      // Convert and set TextMate grammar for Haxe animation files
      const animTokenizer = convertTextMateToMonaco(animGrammar);
      monaco.languages.setMonarchTokensProvider('haxe-anim', {
        tokenizer: animTokenizer
      });
      
      // Convert and set TextMate grammar for Haxe manim files
      const manimTokenizer = convertTextMateToMonaco(manimGrammar);
      monaco.languages.setMonarchTokensProvider('haxe-manim', {
        tokenizer: manimTokenizer
      });

      // Register code snippets for manim language
      monaco.languages.registerCompletionItemProvider('haxe-manim', {
        provideCompletionItems: (model: any, position: any) => {
          const word = model.getWordUntilPosition(position);
          const range = {
            startLineNumber: position.lineNumber,
            endLineNumber: position.lineNumber,
            startColumn: word.startColumn,
            endColumn: word.endColumn
          };

          const snippets = [
            {
              label: 'programmable',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: '#${1:name} programmable(${2:param}:${3:type}=${4:default}) {\n  ${5:element}(${6:params}): ${7:0,0}\n}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Create a new programmable element',
              detail: 'Programmable template'
            },
            {
              label: 'bitmap',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'bitmap(${1:source}): ${2:0,0}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Display an image',
              detail: 'Bitmap element'
            },
            {
              label: 'text',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'text(${1:font}, "${2:text}", ${3:0xFFFFFF}): ${4:0,0}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Display text with font and color',
              detail: 'Text element'
            },
            {
              label: 'ninepatch',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'ninepatch(${1:sheet}, ${2:tile}, ${3:width}, ${4:height}): ${5:0,0}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: '9-patch scalable element',
              detail: 'Ninepatch element'
            },
            {
              label: 'button',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: '#${1:buttonName} programmable(state:[normal,hover,pressed]=normal) {\n  @(state=>normal) bitmap(${2:normalSprite}): 0,0\n  @(state=>hover) bitmap(${3:hoverSprite}): 0,0\n  @(state=>pressed) bitmap(${4:pressedSprite}): 0,0\n}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Create a button with hover/pressed states',
              detail: 'Button pattern'
            },
            {
              label: 'checkbox',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: '#${1:checkboxName} programmable(checked:bool=false) {\n  @(checked=>false) bitmap(${2:uncheckedSprite}): 0,0\n  @(checked=>true) bitmap(${3:checkedSprite}): 0,0\n}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Create a checkbox component',
              detail: 'Checkbox pattern'
            },
            {
              label: 'slider',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: '#${1:sliderName} programmable(value:int=50, min:int=0, max:int=100) {\n  ninepatch(${2:sheet}, ${3:trackTile}, 200, 10): 0,0\n  bitmap(${4:handleSprite}): $value*2,0\n}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Create a slider component',
              detail: 'Slider pattern'
            },
            {
              label: 'placeholder',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'placeholder(${1:32,32}, ${2:source}): ${3:0,0}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Dynamic placeholder element',
              detail: 'Placeholder element'
            },
            {
              label: 'reference',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'reference($${1:ref}): ${2:0,0}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Reference another programmable',
              detail: 'Reference element'
            },
            {
              label: 'layers',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'layers() {\n  ${1:element}: 0,0\n}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Z-ordering container',
              detail: 'Layers container'
            },
            {
              label: 'repeatable',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'repeatable($${1:var}, ${2:iterator}) {\n  ${3:element}: grid($${1:var}, 0)\n}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Loop elements',
              detail: 'Repeatable element'
            },
            {
              label: 'conditional',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: '@(${1:param}=>${2:value}) ${3:element}: ${4:0,0}',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Conditional element display',
              detail: 'Conditional'
            },
            {
              label: 'outline',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'outline(${1:color}, ${2:size})',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Add outline filter',
              detail: 'Outline filter'
            },
            {
              label: 'glow',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'glow(${1:color}, ${2:size}, ${3:strength})',
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: 'Add glow filter',
              detail: 'Glow filter'
            }
          ];

          return {
            suggestions: snippets.map(s => ({ ...s, range }))
          };
        }
      });

      // Add the save action with Ctrl+S keybinding
      editor.addAction({
        id: 'save-file',
        label: 'Save File',
        keybindings: [
          monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS
        ],
        run: () => {
          if (saveHandlerRef.current) {
            saveHandlerRef.current();
          }
        }
      });
      
      // Focus the editor
      editor.focus();
    };

    const handleEditorChange = (value: string | undefined) => {
      if (value !== undefined) {
        onChange(value);
      }
    };

    // Determine the language based on the content or file type
    const getLanguage = () => {
      if (language === 'typescript') {
        // Check if this looks like Haxe code
        if (value.includes('class') || value.includes('function') || value.includes('var')) {
          // You can add more sophisticated detection here
          return 'haxe-manim'; // Default to manim for now
        }
      }
      return language;
    };

    return (
      <div 
        ref={ref}
        className="w-full h-full min-h-[200px] border border-zinc-700 rounded overflow-hidden"
        style={{ minHeight: 200 }}
      >
        <style>{`
          .error-line {
            background-color: rgba(239, 68, 68, 0.1) !important;
            border-left: 3px solid #ef4444 !important;
          }
          .error-glyph {
            background-color: #ef4444 !important;
          }
          .error-line-decoration {
            background-color: #ef4444 !important;
          }
          .error-token {
            background-color: rgba(239, 68, 68, 0.4) !important;
            border-bottom: 2px solid #ef4444 !important;
            text-decoration: underline wavy #ef4444 !important;
          }
        `}</style>
        <Editor
          height="100%"
          language={language}
          value={value}
          onChange={handleEditorChange}
          onMount={handleEditorDidMount}
          options={{
            readOnly: disabled,
            minimap: { enabled: false },
            scrollBeyondLastLine: false,
            fontSize: 12,
            fontFamily: 'Consolas, Monaco, "Courier New", monospace',
            lineNumbers: 'on',
            roundedSelection: false,
            scrollbar: {
              vertical: 'visible',
              horizontal: 'visible',
              verticalScrollbarSize: 8,
              horizontalScrollbarSize: 8,
            },
            automaticLayout: true,
            wordWrap: 'on',
            theme: 'vs-dark',
            tabSize: 2,
            insertSpaces: true,
            detectIndentation: false,
            trimAutoWhitespace: true,
            largeFileOptimizations: false,
            placeholder: placeholder,
            // Haxe-specific options
            suggest: {
              showKeywords: true,
              showSnippets: true,
              showClasses: true,
              showFunctions: true,
              showVariables: true,
            },
            quickSuggestions: {
              other: true,
              comments: false,
              strings: false,
            },
          }}
          theme="vs-dark"
        />
      </div>
    );
  }
);

CodeEditor.displayName = 'CodeEditor';

export default CodeEditor; 