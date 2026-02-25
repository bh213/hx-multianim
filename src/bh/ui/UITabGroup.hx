package bh.ui;

enum TabWireMode {
	Autowire;
	Manual;
}

class UITabGroup {
	var inputs:Array<{input:UIMultiAnimTextInput, tabIndex:Int}> = [];
	var nextAutoIndex:Int = 0;

	public var enterAdvances:Bool = false;

	public function new() {}

	public function add(input:UIMultiAnimTextInput, tabIndex:Int = -1) {
		final idx = if (tabIndex < 0) nextAutoIndex++ else tabIndex;
		for (entry in inputs) {
			if (entry.tabIndex == idx)
				throw 'UITabGroup: duplicate tabIndex $idx';
		}
		inputs.push({input: input, tabIndex: idx});
		inputs.sort((a, b) -> a.tabIndex - b.tabIndex);
	}

	public function remove(input:UIMultiAnimTextInput) {
		inputs = inputs.filter(e -> e.input != input);
	}

	public function clear() {
		inputs = [];
		nextAutoIndex = 0;
	}

	public function handleTab(shift:Bool):Bool {
		if (inputs.length == 0)
			return false;

		var currentIdx = -1;
		for (i in 0...inputs.length) {
			if (inputs[i].input.hasFocus()) {
				currentIdx = i;
				break;
			}
		}

		if (currentIdx < 0) {
			focusAt(0);
			return true;
		}

		var nextIdx = currentIdx;
		var attempts = 0;
		while (attempts < inputs.length) {
			if (shift) {
				nextIdx--;
				if (nextIdx < 0)
					nextIdx = inputs.length - 1;
			} else {
				nextIdx++;
				if (nextIdx >= inputs.length)
					nextIdx = 0;
			}
			attempts++;
			if (!inputs[nextIdx].input.disabled) {
				focusAt(nextIdx);
				return true;
			}
		}

		return false;
	}

	public function handleEnter():Bool {
		if (!enterAdvances || inputs.length == 0)
			return false;
		return handleTab(false);
	}

	public function advanceFrom(source:UIMultiAnimTextInput):Bool {
		if (!enterAdvances || inputs.length == 0)
			return false;

		var currentIdx = -1;
		for (i in 0...inputs.length) {
			if (inputs[i].input == source) {
				currentIdx = i;
				break;
			}
		}
		if (currentIdx < 0)
			return false;

		var nextIdx = currentIdx;
		var attempts = 0;
		while (attempts < inputs.length) {
			nextIdx++;
			if (nextIdx >= inputs.length)
				nextIdx = 0;
			attempts++;
			if (!inputs[nextIdx].input.disabled) {
				focusAt(nextIdx);
				return true;
			}
		}
		return false;
	}

	public function focusFirst() {
		for (i in 0...inputs.length) {
			if (!inputs[i].input.disabled) {
				focusAt(i);
				return;
			}
		}
	}

	public function focusByIndex(tabIndex:Int) {
		for (i in 0...inputs.length) {
			if (inputs[i].tabIndex == tabIndex) {
				focusAt(i);
				return;
			}
		}
	}

	function focusAt(idx:Int) {
		for (entry in inputs) {
			if (entry.input.hasFocus())
				entry.input.blur();
		}
		inputs[idx].input.focus();
	}
}
