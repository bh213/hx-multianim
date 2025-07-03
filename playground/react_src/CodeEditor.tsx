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
  ({ value, onChange, language = 'text', disabled = false, placeholder, onSave, errorLine, errorColumn, errorStart, errorEnd }, ref) => {
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
          defaultLanguage={getLanguage()}
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