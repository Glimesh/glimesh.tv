const Combobox = {
    mounted() {
        let searchInput = this.el.querySelector('[data-search-input]');
        let dropdown = this.el.querySelector('[data-dropdown]');

        searchInput.addEventListener('input', (event) => {
            dropdown.scrollTop = 0;
            this.pushEventTo(this.el, "search", { value: event.target.value });
        })

        searchInput.addEventListener('focus', (event) => {
            if (this.el.getAttribute("data-open") === "false") {
                searchInput.dispatchEvent(new Event('input', { 'bubbles': true }))
            }
        })

        searchInput.addEventListener('click', (event) => {
            if (this.el.getAttribute("data-open") === "false") {
                searchInput.dispatchEvent(new Event('input', { 'bubbles': true }))
            }
        })

        searchInput.addEventListener('keydown', (event) => {
            let key = event.key
            switch (key) {
                case "Tab":
                    if (this.el.dataset.open === "true") {
                        event.preventDefault()
                    }
                    break
                case "ArrowUp":
                    event.preventDefault()
                    if (this.el.getAttribute("data-open") === "false") {
                        this.liveSocket.execJS(this.el, this.el.getAttribute("data-on-open"))
                    } else {
                        this.liveSocket.execJS(this.el, this.el.getAttribute("data-on-up"))
                    }
                    break
                case "ArrowDown":
                    event.preventDefault()
                    if (this.el.getAttribute("data-open") === "false") {
                        this.liveSocket.execJS(this.el, this.el.getAttribute("data-on-open"))
                    } else {
                        this.liveSocket.execJS(this.el, this.el.getAttribute("data-on-down"))
                    }
                    break
                case "Enter":
                    event.preventDefault()
                    dropdown.querySelectorAll('li')[this.el.dataset.activeIndex].dispatchEvent(new Event('click', { 'bubbles': true }))
                    searchInput.blur()
                    break
            }
        })

        this.handleEvent(`combobox:selected:${this.el.id}`, () => {
            this.liveSocket.execJS(this.el, this.el.getAttribute("data-on-selected"))
        })
    }
}

export { Combobox }