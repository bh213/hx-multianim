package bh.ui;

import bh.ui.UIMultiAnimCheckbox;
import bh.multianim.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement;

@:nullSafety
class UIMultiAnimRadioButtons implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementListValue
		implements UIElementSubElements {
	public var disabled(default, set):Bool = false;

	final checkboxes:Array<UIStandardMultiCheckbox> = [];
	final items:Array<UIElementListItem>;
	final builder:MultiAnimBuilder;
	final singleRadioButtonBuilderName:String;
	var selectedIndex:Int;
	final builderResult:BuilderResult;
	var allowUnselected = false;

	public function new(builder:MultiAnimBuilder, radioButtonsBuildName, singleRadioButtonBuilderName, items, selectedIndex) {
		this.builder = builder;
		this.items = items;
		this.singleRadioButtonBuilderName = singleRadioButtonBuilderName;
		this.selectedIndex = selectedIndex;
		this.builderResult = builder.buildWithParameters(radioButtonsBuildName, ["count" => items.length], {callback: builderCallback});
		setSelectedIndex(selectedIndex);
	}

	public function set_disabled(value:Bool):Bool {
		Lambda.iter(checkboxes, x -> x.disabled = value);
		return value;
	}

	function builderCallback(request:CallbackRequest):CallbackResult {
		switch request {
			case NameWithIndex(name, index):
				return CBRString(items[index].name);
			case PlaceholderWithIndex(name, index):
				if (name == "checkbox") {
					var c = UIStandardMultiCheckbox.create(builder, singleRadioButtonBuilderName, false);
					this.checkboxes[index] = c;
					c.onInternalToggle = onSingleToggle.bind(index);
					return CBRObject(c.getObject());
				} else
					throw 'invalid callback ${request}';

			default:
				throw 'unsupported callback ${request}';
		}
	}

	public dynamic function onSingleToggle(index:Int, checked:Bool, controllable) {
		if (checked)
			this.setSelectedIndex(index);
		triggerItemChanged(index, controllable);
	}

	public function onEvent(eventWrapper:UIElementEventWrapper) {}

	public static function create(builder:MultiAnimBuilder, radioButtonsBuildName:String, singleRadioButtonBuilderName:String, items:Array<UIElementListItem>,
			selectedIndex:Int) {
		return new UIMultiAnimRadioButtons(builder, radioButtonsBuildName, singleRadioButtonBuilderName, items, selectedIndex);
	}

	public function getObject():Object {
		return builderResult.object;
	}

	public function containsPoint(pos:Point):Bool {
		return false;
	}

	public function clear() {}

	public function setSelectedIndex(idx:Int) {
		this.selectedIndex = idx;
		for (index => checkbox in checkboxes) {
			if (idx == index) {
				checkbox.selected = true;
				checkbox.ignoreSelectEvents = !allowUnselected;
			} else {
				checkbox.selected = false;
				checkbox.ignoreSelectEvents = false;
			}
		}
	}

	function triggerItemChanged(newIndex:Int, controllable:Controllable) {
		onItemChanged(newIndex, items);
		controllable.pushEvent(UIChangeItem(newIndex, items), this);
	}

	public dynamic function onItemChanged(newIndex:Int, items:Array<UIElementListItem>) {}

	public function getSelectedIndex():Int {
		return selectedIndex;
	}

	public function getList():Array<UIElementListItem> {
		return items;
	}

	public function getSubElements(type:SubElementsType):Array<UIElement> {
		return switch type {
			case SETReceiveUpdates: cast checkboxes;
			case SETReceiveEvents: cast checkboxes;
		}
	}
}
