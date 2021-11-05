import { Terminal } from "xterm/lib/xterm.js"

let XtermHook = {
  mounted() {
    this.term = new Terminal();
    this.term.open(this.el);

    this.handleEvent("sandbox", ({ tty_data }) => {
      this.term.write(tty_data)
    });

  }
}
export { XtermHook }