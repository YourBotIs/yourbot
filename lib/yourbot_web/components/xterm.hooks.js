import { Terminal } from "xterm/lib/xterm.js"
import { FitAddon } from 'xterm-addon-fit';

let XtermHook = {
  disconnectd() {},
  reconnected() {
    this.mounted();
  },
  mounted() {
    this.term = new Terminal();
    this.fitAddon = new FitAddon();
    this.term.loadAddon(this.fitAddon);
    this.term.open(this.el);
    this.fitAddon.fit();

    this.handleEvent("sandbox", ({ tty_data }) => {
      this.term.write(tty_data)
    });

  }
}
export { XtermHook }