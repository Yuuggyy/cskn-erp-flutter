(function() {
  _flutter.buildConfig = {
    "engineRevision": "5a2a6a42cce67f965cf540fcecf616faca624aa1",
    "builds": [
      {
        "compileTarget": "dart2wasm",
        "renderer": "canvaskit",
        "mainWasmPath": "main.dart.wasm",
        "jsSupportRuntimePath": "main.dart.mjs"
      }
    ]
  };

  window._diagLog = [];
  function dlog(msg) {
    window._diagLog.push(new Date().toISOString().substr(11,8) + ' ' + msg);
    console.log('[DIAG] ' + msg);
  }

  dlog('Bootstrap started');

  _flutter.loader.load({
    config: {
      canvasKitBaseUrl: "canvaskit/",
      useLocalCanvasKit: true
    },
    onEntrypointLoaded: async function(engineInitializer) {
      dlog('onEntrypointLoaded called');
      try {
        dlog('Initializing engine...');
        let appRunner = await engineInitializer.initializeEngine({
          assetBase: ""
        });
        dlog('Engine initialized, running app...');
        await appRunner.runApp();
        dlog('App running!', 'ok');
      } catch(e) {
        dlog('ERROR: ' + e.message);
        dlog('STACK: ' + e.stack);
        dlog('TYPE: ' + typeof e);
        dlog('STRING: ' + String(e));
        if (e instanceof WebAssembly.Exception) {
          dlog('WASM Exception!');
          try { dlog('WASM arg: ' + e.arg); } catch(_){}
          try { dlog('WASM name: ' + e.name); } catch(_){}
          try { dlog('WASM tag: ' + e.tag); } catch(_){}
        }
        // Show error on page
        const div = document.createElement('div');
        div.style.cssText = 'position:fixed;bottom:0;left:0;right:0;background:#ff5252;color:#fff;padding:10px;font-family:monospace;font-size:12px;z-index:9999;max-height:300px;overflow:auto';
        div.textContent = window._diagLog.join('\n');
        document.body.appendChild(div);
      }
    }
  }).catch(e => {
    dlog('LOADER ERROR: ' + e.message);
    const div = document.createElement('div');
    div.style.cssText = 'position:fixed;bottom:0;left:0;right:0;background:#ff5252;color:#fff;padding:10px;font-family:monospace;font-size:12px;z-index:9999';
    div.textContent = window._diagLog.join('\n');
    document.body.appendChild(div);
  });
})();
