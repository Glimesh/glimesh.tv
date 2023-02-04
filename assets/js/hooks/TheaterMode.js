export default {
    toggle() {
        document.body.classList.toggle('theater-mode');
    },
    mounted() {
        this.el.addEventListener("click", e => {
            this.toggle();
        });

        document.addEventListener("keyup", e => {
            if(e.altKey && e.key === "t") {
                this.toggle();
            }
        });
    }
}