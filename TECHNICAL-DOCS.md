Technical docs
--------------

This document is intended to provide a high-level overview of the technical aspects of the project. 



## UIElements

## Dropdown
dropdown control consists of closed-like button and scollable panel (called panel). dropdown control moves panel to different layer and keeps position in sync with PositionLinkObject.

## Elements handling by UIScreen
If elements are not showing or reacting to events check if they have been added to UIScreen's elements.



## Macros
```haxe
		var res = MacroUtils.macroBuildWithParameters(componentsBuilder, "ui", [], [
				checkbox1=>addCheckbox(builder,  true),
				checkbox2=>addCheckbox(builder,  true),
				checkbox3=>addCheckbox(builder,  true),
				checkbox4=>addCheckbox(builder,  true),
				checkbox5=>addCheckbox(builder,  true),
				scroll1=>addScrollableList(builder, 100, 120, list4, -1),
				scroll2=>addScrollableList(builder, 100, 120, list100, 10),
				scroll3=>addScrollableList(builder, 100, 120, list20, 3),
				scroll4=>addScrollableList(builder, 100, 120, list20disabled, 3),
				checkboxWithLabel=>addCheckboxWithText(builder, "my label", true),
				//function addDropdown(providedBuilder, items, settings:ResolvedSettings, initialIndex = 0) {
				dropdown1 => addDropdown(builder, list100, 0)
			]);
```

`macroBuildWithParameters` macro calls MultiAnimBuilder createWithParameters, allows settings to override control properties and adds objects and UIElements to s2d graphc and UIScreen elements.


