package manim.lsp;

/**
 * Minimal LSP protocol types. Only what we need — no external dependencies.
 */

typedef LspPosition = {
	var line:Int;
	var character:Int;
}

typedef LspRange = {
	var start:LspPosition;
	var end:LspPosition;
}

typedef LspDiagnostic = {
	var range:LspRange;
	var severity:Int;
	var message:String;
	var ?source:String;
}

typedef LspCompletionItem = {
	var label:String;
	var kind:Int;
	var ?detail:String;
	var ?documentation:Dynamic; // String or {kind:"markdown", value:String}
	var ?insertText:String;
	var ?insertTextFormat:Int; // 1=PlainText, 2=Snippet
}

typedef LspSymbolInformation = {
	var name:String;
	var kind:Int;
	var range:LspRange;
	var selectionRange:LspRange;
	var ?detail:String;
	var ?children:Array<LspSymbolInformation>;
}

typedef LspHover = {
	var contents:Dynamic; // {kind:"markdown", value:String}
	var ?range:LspRange;
}

typedef LspLocation = {
	var uri:String;
	var range:LspRange;
}

// LSP Completion kinds
class CompletionKind {
	public static inline final Keyword = 14;
	public static inline final Property = 10;
	public static inline final EnumMember = 20;
	public static inline final Variable = 6;
	public static inline final Function = 3;
	public static inline final Constant = 21;
	public static inline final Snippet = 15;
	public static inline final Value = 12;
	public static inline final TypeParameter = 25;
	public static inline final Class = 7;
	public static inline final Struct = 22;
	public static inline final Module = 9;
	public static inline final Field = 5;
}

// LSP Symbol kinds
class SymbolKind {
	public static inline final File = 1;
	public static inline final Module = 2;
	public static inline final Namespace = 3;
	public static inline final Class = 5;
	public static inline final Method = 6;
	public static inline final Property = 7;
	public static inline final Field = 8;
	public static inline final Function = 12;
	public static inline final Variable = 13;
	public static inline final Enum = 10;
	public static inline final Constant = 14;
	public static inline final Struct = 23;
}

// LSP InsertTextFormat
class InsertTextFormat {
	public static inline final PlainText = 1;
	public static inline final Snippet = 2;
}

// LSP Diagnostic severity
class DiagnosticSeverity {
	public static inline final Error = 1;
	public static inline final Warning = 2;
	public static inline final Information = 3;
	public static inline final Hint = 4;
}
