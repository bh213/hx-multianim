package bh.ui;

import h2d.col.Point;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.ui.UIElement;

@:nullSafety
class UIInteractiveWrapper implements UIElement implements StandardUIElementEvents implements UIElementIdentifiable {
	public final interactive:MAObject;
	public final prefix:Null<String>;
	public final id:String;
	public final metadata:BuilderResolvedSettings;

	public function new(interactive:MAObject, prefix:Null<String>) {
		this.interactive = interactive;
		this.prefix = prefix;
		final extracted = extractInteractiveData(interactive, prefix);
		this.id = extracted.id;
		this.metadata = extracted.metadata;
	}

	static function extractInteractiveData(obj:MAObject, prefix:Null<String>):{id:String, metadata:BuilderResolvedSettings} {
		switch obj.multiAnimType {
			case MAInteractive(_, _, identifier, meta):
				return {id: prefix != null ? '$prefix.$identifier' : identifier, metadata: new BuilderResolvedSettings(meta)};
			default:
				throw "UIInteractiveWrapper requires MAInteractive";
		}
	}

	public function getObject():h2d.Object {
		return interactive;
	}

	public function containsPoint(pos:Point):Bool {
		return interactive.getBounds().contains(pos);
	}

	public function clear() {}

	public function onEvent(wrapper:UIElementEventWrapper) {
		switch wrapper.event {
			case OnRelease(_):
				wrapper.control.pushEvent(UIClick, this);
			case OnEnter:
				wrapper.control.pushEvent(UIEntering, this);
			case OnLeave:
				wrapper.control.pushEvent(UILeaving, this);
			default:
		}
	}
}
