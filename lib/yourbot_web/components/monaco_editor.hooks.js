import * as monaco from "monaco-editor";

window.MonacoEnvironment = {
  getWorkerUrl: function (moduleId, label) {
    if (label === "python") {
      return "/assets/python.js"
    }
    if (label === "lua") {
      return "/assets/lua.js"
    }
    if (label === "typescript" || label === "javascript") {
      return "/assets/ts.worker.js";
    }
    return "/assets/editor.worker.js";
  },
};

let MonacoEditor = {
  disconnected() {
    console.log("disconnect")
    this.editor.updateOptions({ readOnly: true })
  },
  reconnected(){
    console.log("reconnect")
    this.editor.updateOptions({ readOnly: false })
    this.mounted()
  },
  mounted() {
    monaco.editor.setTheme('vs-dark');
    this.editor = monaco.editor.create(this.el, {
      value: this.el.value || "# Select a bot to edit",
      language: "python",
      minimap: { enabled: false },
      automaticLayout: true,
      overviewRulerLanes: 0,
      hideCursorInOverviewRuler: true,
      scrollbar: {
          vertical: 'hidden'
      },
      overviewRulerBorder: false,
    });
    this.editor.onDidChangeModelContent((e) =>
      this.pushEvent("monaco_change", {
        value: this.editor.getValue()
      })
    );
    this.handleEvent("monaco_load", ({ value }) => {
      console.log("monaco_load");
      this.editor.setValue(value)
    });
  },
  updated() { }
}
export { MonacoEditor }