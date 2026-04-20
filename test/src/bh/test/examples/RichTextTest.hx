package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.multianim.TextMarkupConverter;

/**
 * Unit tests for TextMarkupConverter (convert, hasMarkup, extractStyleReferences, etc.)
 * and builder-level richText element construction (styles, images, markup, parameters).
 */
class RichTextTest extends BuilderTestBase {
	// ==================== convert() — basic tags ====================

	@Test
	public function testConvertSimpleStyleTag():Void {
		var result = TextMarkupConverter.convert("[damage]50[/]");
		Assert.equals("<damage>50</damage>", result);
	}

	@Test
	public function testConvertNestedTags():Void {
		var result = TextMarkupConverter.convert("[outer][inner]text[/][/]");
		Assert.equals("<outer><inner>text</inner></outer>", result);
	}

	@Test
	public function testConvertNoMarkup():Void {
		var result = TextMarkupConverter.convert("plain text");
		Assert.equals("plain text", result);
	}

	@Test
	public function testConvertEmptyString():Void {
		var result = TextMarkupConverter.convert("");
		Assert.equals("", result);
	}

	@Test
	public function testConvertNull():Void {
		var result = TextMarkupConverter.convert(null);
		Assert.isNull(result);
	}

	// ==================== convert() — [br] line break ====================

	@Test
	public function testConvertBrTag():Void {
		var result = TextMarkupConverter.convert("line1[br]line2");
		Assert.equals("line1<br/>line2", result);
	}

	@Test
	public function testConvertBrTagMultiple():Void {
		var result = TextMarkupConverter.convert("a[br]b[br]c");
		Assert.equals("a<br/>b<br/>c", result);
	}

	@Test
	public function testConvertBrTagWithStyles():Void {
		var result = TextMarkupConverter.convert("[damage]50[/][br]dealt");
		Assert.equals("<damage>50</damage><br/>dealt", result);
	}

	// ==================== convert() — special tags ====================

	@Test
	public function testConvertImgTag():Void {
		var result = TextMarkupConverter.convert("[img:sword]");
		Assert.equals('<img src="sword"/>', result);
	}

	@Test
	public function testConvertAlignTag():Void {
		var result = TextMarkupConverter.convert("[align:center]text[/]");
		Assert.equals('<p align="center">text</p>', result);
	}

	@Test
	public function testConvertLinkTag():Void {
		var result = TextMarkupConverter.convert("[link:help]click here[/]");
		Assert.equals('<a href="help">click here</a>', result);
	}

	// ==================== convert() — escape sequences ====================

	@Test
	public function testConvertEscapeBracket():Void {
		var result = TextMarkupConverter.convert("[[escaped]]");
		Assert.equals("[escaped]]", result);
	}

	@Test
	public function testConvertDoubleEscapeBracket():Void {
		var result = TextMarkupConverter.convert("[[text[[");
		Assert.equals("[text[", result);
	}

	// ==================== convert() — XML character escaping ====================

	@Test
	public function testConvertEscapesLessThan():Void {
		var result = TextMarkupConverter.convert("Hull<25%");
		Assert.equals("Hull&lt;25%", result);
	}

	@Test
	public function testConvertEscapesGreaterThan():Void {
		var result = TextMarkupConverter.convert("damage>100");
		Assert.equals("damage&gt;100", result);
	}

	@Test
	public function testConvertEscapesAmpersand():Void {
		var result = TextMarkupConverter.convert("fire & ice");
		Assert.equals("fire &amp; ice", result);
	}

	@Test
	public function testConvertEscapesXmlWithMarkup():Void {
		var result = TextMarkupConverter.convert("[damage]50>25[/]");
		Assert.equals("<damage>50&gt;25</damage>", result);
	}

	@Test
	public function testConvertEscapesMultipleXmlChars():Void {
		var result = TextMarkupConverter.convert("a<b & c>d");
		Assert.equals("a&lt;b &amp; c&gt;d", result);
	}

	@Test
	public function testConvertNoXmlCharsUnchanged():Void {
		var result = TextMarkupConverter.convert("plain text");
		Assert.equals("plain text", result);
	}

	// ==================== convert() — reserved HTML tags ====================

	@Test
	public function testConvertReservedBoldTag():Void {
		var result = TextMarkupConverter.convert("[b]bold[/]");
		Assert.equals("<_s_b>bold</_s_b>", result);
	}

	@Test
	public function testConvertReservedItalicTag():Void {
		var result = TextMarkupConverter.convert("[i]italic[/]");
		Assert.equals("<_s_i>italic</_s_i>", result);
	}

	@Test
	public function testConvertReservedFontTag():Void {
		var result = TextMarkupConverter.convert("[font]text[/]");
		Assert.equals("<_s_font>text</_s_font>", result);
	}

	// ==================== convert() — unrecognized tags ====================

	@Test
	public function testConvertUnrecognizedTag():Void {
		// Tags starting with digit are not valid style names
		var result = TextMarkupConverter.convert("[1]text[/]");
		// [1] is not a valid style name, so it's emitted literally
		Assert.isTrue(result.indexOf("[1]") >= 0);
	}

	@Test
	public function testConvertTagWithSpaces():Void {
		// Spaces in tag name make it invalid
		var result = TextMarkupConverter.convert("[text with spaces]hello[/]");
		Assert.isTrue(result.indexOf("[text with spaces]") >= 0);
	}

	// ==================== convert() — unclosed bracket ====================

	@Test
	public function testConvertUnclosedBracket():Void {
		var result = TextMarkupConverter.convert("[unclosed");
		Assert.equals("[unclosed", result);
	}

	// ==================== hasMarkup() ====================

	@Test
	public function testHasMarkupWithCloseTag():Void {
		Assert.isTrue(TextMarkupConverter.hasMarkup("[damage]50[/]"));
	}

	@Test
	public function testHasMarkupWithImgTag():Void {
		Assert.isTrue(TextMarkupConverter.hasMarkup("[img:sword]"));
	}

	@Test
	public function testHasMarkupWithAlignTag():Void {
		Assert.isTrue(TextMarkupConverter.hasMarkup("[align:center]text[/]"));
	}

	@Test
	public function testHasMarkupWithLinkTag():Void {
		Assert.isTrue(TextMarkupConverter.hasMarkup("[link:help]text[/]"));
	}

	@Test
	public function testHasMarkupWithBrTag():Void {
		Assert.isTrue(TextMarkupConverter.hasMarkup("line1[br]line2"));
	}

	@Test
	public function testHasMarkupPlainText():Void {
		Assert.isFalse(TextMarkupConverter.hasMarkup("just plain text"));
	}

	@Test
	public function testHasMarkupNoBrackets():Void {
		Assert.isFalse(TextMarkupConverter.hasMarkup("no brackets here"));
	}

	@Test
	public function testHasMarkupNull():Void {
		Assert.isFalse(TextMarkupConverter.hasMarkup(null));
	}

	@Test
	public function testHasMarkupBracketsButNoCloseTag():Void {
		// [note] without [/] is not markup (could be natural text)
		Assert.isFalse(TextMarkupConverter.hasMarkup("[note] just a note"));
	}

	@Test
	public function testHasMarkupEscapeSequence():Void {
		// [[ is escape, not markup
		Assert.isFalse(TextMarkupConverter.hasMarkup("[[not markup]]"));
	}

	// ==================== extractStyleReferences() ====================

	@Test
	public function testExtractStyleReferences():Void {
		var refs = TextMarkupConverter.extractStyleReferences("[damage]50[/] [heal]20[/]");
		Assert.equals(2, refs.length);
		Assert.equals("damage", refs[0]);
		Assert.equals("heal", refs[1]);
	}

	@Test
	public function testExtractStyleReferencesSkipsSpecialTags():Void {
		var refs = TextMarkupConverter.extractStyleReferences("[img:sword] [align:center] [link:help] [style]text[/]");
		Assert.equals(1, refs.length);
		Assert.equals("style", refs[0]);
	}

	@Test
	public function testExtractStyleReferencesSkipsBr():Void {
		var refs = TextMarkupConverter.extractStyleReferences("[damage]50[/][br]dealt");
		Assert.equals(1, refs.length);
		Assert.equals("damage", refs[0]);
	}

	@Test
	public function testExtractStyleReferencesEmpty():Void {
		var refs = TextMarkupConverter.extractStyleReferences("no markup");
		Assert.equals(0, refs.length);
	}

	@Test
	public function testExtractStyleReferencesNull():Void {
		var refs = TextMarkupConverter.extractStyleReferences(null);
		Assert.equals(0, refs.length);
	}

	@Test
	public function testExtractStyleReferencesSkipsCloseTag():Void {
		var refs = TextMarkupConverter.extractStyleReferences("[style]text[/]");
		Assert.equals(1, refs.length);
		Assert.equals("style", refs[0]);
	}

	// ==================== resolveColorToHex() ====================

	@Test
	public function testResolveColorRGB():Void {
		var result = TextMarkupConverter.resolveColorToHex("#F00");
		Assert.equals("#FF0000", result);
	}

	@Test
	public function testResolveColorRRGGBB():Void {
		var result = TextMarkupConverter.resolveColorToHex("#FF8800");
		Assert.equals("#FF8800", result);
	}

	@Test
	public function testResolveColorRRGGBBAA():Void {
		// Alpha is stripped
		var result = TextMarkupConverter.resolveColorToHex("#FF880088");
		Assert.equals("#FF8800", result);
	}

	@Test
	public function testResolveColorEmptyString():Void {
		var result = TextMarkupConverter.resolveColorToHex("");
		Assert.equals("#000000", result);
	}

	@Test
	public function testResolveColorNull():Void {
		var result = TextMarkupConverter.resolveColorToHex(null);
		Assert.equals("#000000", result);
	}

	@Test
	public function testResolveColorNamedRed():Void {
		var result = TextMarkupConverter.resolveColorToHex("red");
		Assert.equals("#FF0000", result);
	}

	@Test
	public function testResolveColorNamedWhite():Void {
		var result = TextMarkupConverter.resolveColorToHex("white");
		Assert.equals("#FFFFFF", result);
	}

	// ==================== escapeStyleName() ====================

	@Test
	public function testEscapeStyleNameNormal():Void {
		Assert.equals("damage", TextMarkupConverter.escapeStyleName("damage"));
	}

	@Test
	public function testEscapeStyleNameReservedB():Void {
		Assert.equals("_s_b", TextMarkupConverter.escapeStyleName("b"));
	}

	@Test
	public function testEscapeStyleNameReservedI():Void {
		Assert.equals("_s_i", TextMarkupConverter.escapeStyleName("i"));
	}

	@Test
	public function testEscapeStyleNameReservedU():Void {
		Assert.equals("_s_u", TextMarkupConverter.escapeStyleName("u"));
	}

	@Test
	public function testEscapeStyleNameReservedS():Void {
		Assert.equals("_s_s", TextMarkupConverter.escapeStyleName("s"));
	}

	@Test
	public function testEscapeStyleNameReservedBold():Void {
		Assert.equals("_s_bold", TextMarkupConverter.escapeStyleName("bold"));
	}

	@Test
	public function testEscapeStyleNameReservedItalic():Void {
		Assert.equals("_s_italic", TextMarkupConverter.escapeStyleName("italic"));
	}

	@Test
	public function testEscapeStyleNameReservedFont():Void {
		Assert.equals("_s_font", TextMarkupConverter.escapeStyleName("font"));
	}

	@Test
	public function testEscapeStyleNameNotReserved():Void {
		Assert.equals("myStyle", TextMarkupConverter.escapeStyleName("myStyle"));
	}

	// ==================== Builder-Level richText Tests ====================

	@Test
	public function testRichTextBuilds():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable() {
				richText(\"m3x6\", \"hello\", #FFFFFF): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testRichTextWithStyles():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable() {
				richText(\"m3x6\", \"[damage]50[/]\", #FFFFFF, styles: {damage: color(#FF0000)}): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testRichTextWithMarkup():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable() {
				richText(\"m3x6\", \"[heal]20[/] and [crit]50[/]\", #FFFFFF, styles: {heal: color(#00FF00), crit: color(#FF4444)}): 0, 0
			}
		", "test");
		Assert.notNull(result);
		var texts = BuilderTestBase.findAllTextDescendants(result.object);
		Assert.isTrue(texts.length > 0);
	}

	@Test
	public function testRichTextWithImages():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable() {
				richText(\"m3x6\", \"hello\", #FFFFFF, images: {sword: generated(color(8, 8, #FF0000))}): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testRichTextParamStyleColor():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable(hlColor:color=#FF0000) {
				richText(\"m3x6\", \"[hl]text[/]\", #FFFFFF, styles: {hl: color($hlColor)}): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		// setParameter should not throw
		result.setParameter("hlColor", 0x00FF00);
	}

	@Test
	public function testPlainTextRejectsStyles():Void {
		var err = BuilderTestBase.parseExpectingError("
			#test programmable() {
				text(\"m3x6\", \"hello\", #FFFFFF, styles: {damage: color(#FF0000)}): 0, 0
			}
		");
		Assert.notNull(err);
		Assert.isTrue(err.indexOf("richText") >= 0);
	}

	@Test
	public function testPlainTextBuilds():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable() {
				text(\"m3x6\", \"hello\", #FFFFFF): 0, 0
			}
		", "test");
		Assert.notNull(result);
		var texts = BuilderTestBase.findAllTextDescendants(result.object);
		Assert.isTrue(texts.length > 0);
	}

	@Test
	public function testRichTextMultipleStyles():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable() {
				richText(\"m3x6\", \"[a]x[/][b]y[/]\", #FFFFFF, styles: {a: color(#FF0000), b: color(#00FF00)}): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testRichTextEscapeBrackets():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable() {
				richText(\"m3x6\", \"[[escaped]]\", #FFFFFF): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testRichTextCondenseWhite():Void {
		var result = BuilderTestBase.buildFromSource("
			#test programmable() {
				richText(\"m3x6\", \"hello  world\", #FFFFFF, condenseWhite: true): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	// ==================== autoFitFill empty fonts fallback ====================

	@Test
	public function testAutoFitFillEmptyFontsKeepsOriginal():Void {
		// Regression: ProgrammableBuilder.autoFitFill used to fall back to
		// `fonts[fonts.length - 1]` when no candidate fit, which evaluated to
		// `fonts[-1]` (null) on an empty fonts array — clobbering the text's
		// original font with null and crashing downstream rendering.
		// Empty fonts array must now leave the original font intact.
		var origFont = hxd.res.DefaultFont.get();
		var t = new h2d.Text(origFont);
		t.text = "this is a long string that wont fit in 1px";

		// fitWidth tiny so the original font does NOT satisfy the constraint,
		// forcing the function past the early-return into the fallback branch.
		bh.multianim.ProgrammableBuilder.autoFitFill(t, [], 1.0, null);

		Assert.notNull(t.font, "font must not be null after empty-fonts fallback");
		Assert.equals(origFont, t.font, "font must remain the original when fonts array is empty");
	}
}
