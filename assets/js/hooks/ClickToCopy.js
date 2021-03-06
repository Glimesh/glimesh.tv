export default {

    copyValue() {
        return this.el.dataset.copyValue;
    },
    originalText() {
        return this.el.innerText;
    },
    copiedText() {
        return this.el.dataset.copiedText;
    },
    copiedErrorText() {
        return this.el.dataset.copiedErrorText;
    },

    mounted() {
        let parent = this;
        let originalText = this.originalText()

        if (navigator.clipboard === undefined) {
            this.el.remove();
            return;
        }
        
        this.el.addEventListener("click", function(event) {
            navigator.clipboard.writeText(parent.copyValue()).then(function () {
                parent.el.innerText = parent.copiedText();
                setTimeout(function () {
                    parent.el.innerText = originalText;
                }, 5000);
            }, function (err) {
                parent.el.innerText = parent.copiedErrorText();
            });
        });
    }
};