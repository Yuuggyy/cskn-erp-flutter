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

  _flutter.loader.load({
    config: {
      canvasKitBaseUrl: "canvaskit/",
      useLocalCanvasKit: true
    },
    onEntrypointLoaded: async function(engineInitializer) {
      let appRunner = await engineInitializer.initializeEngine({
        assetBase: ""
      });
      await appRunner.runApp();
    }
  });
})();
