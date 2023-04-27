
export default {
    mounted() {
        hcaptcha.render(this.el, {
            "sitekey": this.el.dataset.sitekey,
            "theme": "dark"
        });
    },
    updated() {
    },
    destroyed() {
    }
};
