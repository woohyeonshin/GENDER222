# GENDER222

setTimeout(()=>{const r=[...document.querySelectorAll('[role="combobox"],[role="listbox"],[role="option"],select')].map(e=>[e.tagName,e.getAttribute('role'),e.getAttribute('aria-label'),e.id,e.getAttribute('data-test-id'),(e.innerText||'').slice(0,20)].join(' | ')).join('\n');copy(r);console.log(r)},6000)
