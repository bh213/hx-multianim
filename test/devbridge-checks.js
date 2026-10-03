// The DevBridge op list that proves a transport works, shared by the two browser checks:
//   test/devbridge-page.md    — through window.hxDevBridge, from the Playwright MCP
//   test/devbridge-relay.mjs  — through the WebSocket relay
//
// This file is ONE expression: an async function (call, frameNow) => report.
//   call(method, params)  → Promise of the reply body {ok, result} | {ok: false, error, code}
//   frameNow()            → hxd.Timer.frameCount, or null when it cannot be read synchronously
// The report is {passed, failed: [{check, detail}], details}. Load it with (0, eval)(text).
(async (call, frameNow) => {
  const failed = [];
  const passed = [];
  const details = {};
  const check = (name, ok, detail) => {
    if (ok) passed.push(name);
    else failed.push({ check: name, detail });
  };
  const result = async (method, params = {}) => {
    const reply = await call(method, params);
    if (!reply || reply.ok !== true) throw new Error(`${method}: ${JSON.stringify(reply)}`);
    return reply.result;
  };
  const attempt = async (name, fn) => {
    try {
      await fn();
    } catch (e) {
      failed.push({ check: name, detail: String(e && e.message ? e.message : e) });
    }
  };

  await attempt("ping", async () => {
    const r = await result("ping");
    check("ping", r.ok === true && typeof r.uptime === "number", r);
  });

  await attempt("list_screens", async () => {
    const r = await result("list_screens");
    details.activeScreens = r.screens.filter((s) => s.active).map((s) => s.name);
    check("list_screens", r.screens.length > 0 && details.activeScreens.length > 0, r);
  });

  await attempt("scene_graph", async () => {
    const r = await result("scene_graph", { depth: 2 });
    check("scene_graph", r.type === "h2d.Scene" && Array.isArray(r.children), r.type);
  });

  await attempt("list_interactives", async () => {
    const r = await result("list_interactives");
    details.interactives = r.interactives.length;
    check("list_interactives", Array.isArray(r.interactives), r);
  });

  await attempt("set_parameter", async () => {
    const live = (await result("list_active_programmables")).programmables;
    const target = live.find((p) =>
      (p.parameterDefinitions || []).some((d) => d.type && d.type.type === "enum" && d.type.values.length > 1),
    );
    if (!target) {
      check("set_parameter", false, "no live programmable with an enum parameter on this screen");
      return;
    }
    const def = target.parameterDefinitions.find((d) => d.type && d.type.type === "enum" && d.type.values.length > 1);
    // findBuilderResult takes the first live instance of a name, so read back what it reads.
    const first = live.find((p) => p.name === target.name);
    const current = first.currentParameters ? String(first.currentParameters[def.name]) : def.type.values[0];
    const next = def.type.values.find((v) => v !== current);
    await result("set_parameter", { programmable: target.name, param: def.name, value: next });
    const after = (await result("get_parameters", { programmable: target.name })).parameters.find((p) => p.name === def.name);
    await result("set_parameter", { programmable: target.name, param: def.name, value: current });
    details.setParameter = `${target.name}.${def.name}: ${current} -> ${next} -> ${current}`;
    check("set_parameter", after && String(after.currentValue) === next, after);
  });

  await attempt("send_events", async () => {
    const r = await result("send_events", {
      auto_pause: true,
      events: [{ type: "move", x: 10, y: 10 }, { step: 1 }, { type: "move", x: 20, y: 20 }, { step: 1 }],
    });
    check("send_events", r.success === true && r.totalFramesStepped === 2 && r.paused === false, r);
  });

  await attempt("screenshot", async () => {
    const r = await result("screenshot");
    const bin = typeof atob === "function" ? atob(r.base64) : Buffer.from(r.base64, "base64").toString("latin1");
    const u32 = (o) =>
      ((bin.charCodeAt(o) << 24) | (bin.charCodeAt(o + 1) << 16) | (bin.charCodeAt(o + 2) << 8) | bin.charCodeAt(o + 3)) >>> 0;
    const isPng = bin.charCodeAt(0) === 0x89 && bin.slice(1, 4) === "PNG" && bin.slice(12, 16) === "IHDR";
    details.screenshot = { width: r.width, height: r.height, pngWidth: u32(16), pngHeight: u32(20), bytes: bin.length };
    check("screenshot", isPng && u32(16) === r.width && u32(20) === r.height && r.width > 0 && r.height > 0, details.screenshot);
  });

  await attempt("pause_step", async () => {
    const paused = await result("pause", { paused: true });
    const before = frameNow ? frameNow() : null;
    const steps = [];
    for (let i = 0; i < 3; i++) steps.push((await result("step")).framesAdvanced);
    const after = frameNow ? frameNow() : null;
    const resumed = await result("pause", { paused: false });
    details.pauseStep = { steps, framesCounted: before === null ? "n/a" : after - before };
    check(
      "pause_step",
      paused.paused === true && resumed.paused === false && steps.join() === "1,1,1" && (before === null || after - before === 3),
      details.pauseStep,
    );
  });

  await attempt("not_supported", async () => {
    const quit = await call("quit", {});
    const reload = await call("reload", { file: "none.manim" });
    check("not_supported", quit.code === "not_supported" && reload.code === "not_supported", { quit, reload });
  });

  await attempt("errors", async () => {
    const unknown = await call("no_such_method", {});
    check("errors", unknown.ok === false && unknown.code === "unknown_method", unknown);
  });

  return { passed, failed, details };
})
