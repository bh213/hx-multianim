package screens;

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


class ParticlesScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;

	public function load() {
			this.builder = this.screenManager.buildFromResourceName("std.manim", false);
			var particlesBuilder = this.screenManager.buildFromResourceName("particles.manim", false);

			var res = particlesBuilder.buildWithParameters("ui", []);


			var updatable = res.getUpdatable("particles1");

			var particles = particlesBuilder.createParticles("test1");
			// var particles = new bh.base.Particles();
			// var tile = this.screenManager.loader.loadSheet2("fx").get("particle/smoke-1");
			
			// var group = new bh.base.Particles.ParticleGroup("test", particles, [tile.tile]);

			// group.start();
			// particles.addGroup(group);


			updatable.setObject(particles);
			
			addBuilderResult(res);
			
	}
	
	public override function update(dt:Float) {
		super.update(dt);
		
	}
	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		
	}

}