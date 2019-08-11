import 'bulma/css/bulma.css';
import '@fortawesome/fontawesome-free';
import * as monaco from 'monaco-editor';
import 'monaco-editor/dev/vs/editor/editor.main.css'
import 'monaco-editor/esm/vs/editor/standalone/common/themes.js'

declare var Elm: any;

(self as any)['MonacoEnvironment'] = {
    getWorkerUrl: function (moduleId: any, label: string) {
        if (label === 'json') {
            return './json.worker.bundle.js';
        }
        if (label === 'css') {
            return './css.worker.bundle.js';
        }
        if (label === 'html') {
            return './html.worker.bundle.js';
        }
        if (label === 'typescript' || label === 'html') {
            return './ts.worker.bundle.js';
        }
        return './editor.worker.bundle.js';
    }
}

customElements.define('code-editor', class MonacoEditorElement extends HTMLElement {
    _editor: monaco.editor.IStandaloneCodeEditor
    _editorValue: string

    constructor() {
        super();
    }

    set editorValue(v: string) {
        this._editorValue = v;
    }

    get editorValue() {
        return this._editorValue;
    }

    connectedCallback() {
        this._editor = monaco.editor.create(this, {
            value: this.editorValue,
            language: 'html',
            fontLigatures: true,
            fontSize: 14,
            renderLineHighlight: "none",
            minimap: { enabled: false },
            matchBrackets: false,
        });
        this._editor.onDidChangeModelContent(e => {
            console.log(this._editor.getValue());
            this._editorValue = this._editor.getValue();
            this.dispatchEvent(new CustomEvent("editorChanged"));
        });
    }
});

Elm.Main.init({
    node: document.getElementById("node"),
    flags: ""
});