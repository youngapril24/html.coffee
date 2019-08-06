import 'bulma/css/bulma.css';
import '@fortawesome/fontawesome-free';
import * as monaco from 'monaco-editor';
import 'monaco-editor/dev/vs/editor/editor.main.css'
import 'monaco-editor/esm/vs/editor/standalone/common/themes.js'

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

monaco.editor.create(document.getElementById('editor'), {
	value: [
		'<h1>안녕하세요</h1>',
		'<div>HTML 기초반에 오신 것을 <em>환영합니다.</em></div>',
		'<ul>',
		'  <li>HTML로 하는 일</li>',
		'  <li>HTML 언어 기초</li>',
		'</ul>'
	].join('\n'),
	language: 'html',
	minimap: { enabled: false },
	matchBrackets: false,
});
