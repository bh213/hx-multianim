package screens;

import bh.paths.AnimatedPath.AnimatedPathPositionMode;
import bh.base.MacroUtils;
import hxd.Res;
import h2d.Graphics;
import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder;
import bh.paths.*;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.*;
import bh.ui.screens.UIScreen;

private enum RadioAnimatedPathPositionMode {
	Absolute;
	RelativeToRef1;
	RelativeToRef2;
}

class PathsScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;
	var selectedPath:MultiAnimPaths.Path;
	var animatedPaths:Array<AnimatedPath> = [];
	var animObjs:Array<h2d.Object> = [];
	var graphics:h2d.Graphics = new h2d.Graphics();


	var currentPathIndex = 0;
	var startPoint:Null<bh.base.FPoint> = null;
	var endPoint:Null<bh.base.FPoint> = null;
	var angle:Float = 0;
	var animatedPathPositionMode:bh.paths.AnimatedPath.AnimatedPathPositionMode = Absolute;
	var paths:MultiAnimPaths;
	var cross1:h2d.Object;
	var cross2:h2d.Object;

	

	public function load() {
			this.builder = this.screenManager.buildFromResourceName("std.manim", false);
			var pathsBuilder = this.screenManager.buildFromResourceName("paths.manim", false);
			
			
			this.cross1 = pathsBuilder.buildWithParameters("cross1", []).object;
			this.cross2 = pathsBuilder.buildWithParameters("cross2", []).object;
			root.addChild(this.cross1);
			root.addChild(this.cross2);

			var animRes = pathsBuilder.buildWithParameters("anim", []);
			animObjs.push(animRes.object);

			var animRes = pathsBuilder.buildWithParameters("anim", []);
			animObjs.push(animRes.object);

			var animRes2 = pathsBuilder.buildWithParameters("animRect", []);
			animObjs.push(animRes2.object);
			
			
			

			
			this.paths = pathsBuilder.getPaths();
			
			final pathItems =  [
				{name: 'path1', data: 0},
				{name: 'path2', data: 1},
				{name: 'path3', data: 2},
				{name: 'pathX', data: 3},


			];

			addObjectToLayer(graphics, DefaultLayer);
			


			var points:Array<Null<bh.base.FPoint>> = [
				new bh.base.FPoint(0,0),
				new bh.base.FPoint(100,100),
				new bh.base.FPoint(200,100),
				new bh.base.FPoint(100,200),
				new bh.base.FPoint(400,200),
				new bh.base.FPoint(200,400),
				new bh.base.FPoint(777,777),
				null

			];
			final pointItems = [for(p in points) {name: p != null ? p.toString():null, data: p}];
			

			this.selectedPath = getPath(currentPathIndex);
			this.endPoint = pointItems[0].data;
			this.startPoint = pointItems[0].data;

			
			final positionModes = [
				{name: 'Absolute', data: RadioAnimatedPathPositionMode.Absolute},
				{name: 'Relative #ref1', data: RadioAnimatedPathPositionMode.RelativeToRef1},
				{name: 'Relative #ref2', data: RadioAnimatedPathPositionMode.RelativeToRef2},
			];

			onPathChanged();
			var res = bh.base.MacroUtils.macroBuildWithParameters(pathsBuilder, "ui", [], [
				angleSlider => addSlider(builder, 0),
				path=>addDropdownWithSingleBuilder(builder, "dropdown", "list-panel", "list-item-120", "scrollbar", "scrollbar", pathItems, 0),
				startPoint=>addDropdownWithSingleBuilder(builder, "dropdown", "list-panel", "list-item-120", "scrollbar", "scrollbar", pointItems, 0),	
				endPoint=>addDropdownWithSingleBuilder(builder, "dropdown", "list-panel", "list-item-120", "scrollbar", "scrollbar", pointItems, 0),
				animate=>addButtonWithSingleBuilder(builder, "button", "Animate"),
				//relativeCheckbox=>addCheckboxWithText(builder, "relative Anim Mode", false),
				positionMode=>addRadio(builder, positionModes, true, 0),
			
				// scroll1=>addScrollableList(builder, 100, 120, list4, -1),
				// checkboxWithLabel=>
				// dropdown1 => addDropdown(builder, list100, 0)
			]);
			addBuilderResult(res.builderResults);

			var ref1 = res.builderResults.getSingleItemByName("ref1").object;
			var ref2 = res.builderResults.getSingleItemByName("ref2").object;
			
			//var selectPath = addElementWithIterator(UIStandardMultiAnimDropdown.create(builder, "dropdown", "list-panel", "list-item-120", pathItems, 0), mainDropDownIterator);
			res.path.onItemChanged = (newIndex, items) -> {
				this.currentPathIndex = newIndex;
				onPathChanged();
			}

			res.startPoint.onItemChanged = (newIndex, items) -> {
				this.startPoint = items[newIndex].data;
				onPathChanged();
			}

			res.endPoint.onItemChanged = (newIndex, items) -> {
				this.endPoint = items[newIndex].data;
				onPathChanged();
			}

			res.animate.onClick = () -> {
					this.root.addChild(animObjs[0]);
					this.animatedPaths.push(pathsBuilder.createAnimatedPath("panim", selectedPath, 50, this.animatedPathPositionMode, HeapsObject(animObjs[0])));
			}		
			res.positionMode.onItemChanged = (newIndex, items) -> {
				var mode:RadioAnimatedPathPositionMode = items[newIndex].data;
				this.animatedPathPositionMode = switch mode {
					case Absolute: bh.paths.AnimatedPath.AnimatedPathPositionMode.Absolute;
					case RelativeToRef1: bh.paths.AnimatedPath.AnimatedPathPositionMode.RelativeTo(ref1.toh2dObject());
					case RelativeToRef2: bh.paths.AnimatedPath.AnimatedPathPositionMode.RelativeTo(ref2.toh2dObject());
				};

			}

			res.angleSlider.onChange = (value, wrapper) -> {
				this.angle = value;
				onPathChanged();
			}

			
	}
	
	function getPath(index:Int){
		return switch (index) {
			case 0: this.paths.getPath("line1",  this.startPoint, this.endPoint);
			case 1: this.paths.getPath("line2",  this.startPoint, this.endPoint);
			case 2: this.paths.getPath("line3",  this.startPoint, this.endPoint);
			case 3: this.paths.getPath("lineX",  this.startPoint, this.endPoint);
			default: throw "Unknown path index $index";
		}
		
	}
	function onPathChanged() {
		this.selectedPath = getPath(currentPathIndex);
		this.graphics.clear();

		this.graphics.lineStyle(3.0, 0xFFFFFFFF);	
		this.selectedPath.drawToGraphics(graphics);

		// graphics.x = startPoint == null ? 0 : startPoint.x;
		// graphics.y = startPoint == null ? 0 : startPoint.y;
		if (startPoint != null) {
			this.cross1.visible = true;
			this.cross1.setPosition(startPoint.x, startPoint.y);
		} else this.cross1.visible = false;

		if(endPoint != null) {
			this.cross2.visible = true;
			this.cross2.setPosition(endPoint.x, endPoint.y);
		} else this.cross2.visible = false;

	}

	public override function update(dt:Float) {
		super.update(dt);
		for (path in animatedPaths) {
			path.update(dt);
		}
		
		//if (anim != null) {
			//anim.update(dt);
			
			//var rate = anim.getAsRate();
			//var pt = this.lines[0].getPoint(rate);
			//animObj.setPosition(0,0);
			//animObj.setPosition(pt.x, pt.y);
	
		// }
	}
	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		
	}

	public override function onClear() {
		this.builder = null;
		this.animObjs = [];
		this.animatedPaths = [];
		
	}

}