export default {

    copyValue() {
        return this.el.dataset.copyValue;
    },
    copiedText() {
        return this.el.dataset.copiedText;
    },
    copiedErrorText() {
        return this.el.dataset.copiedErrorText;
    },

    mounted() {
        navigator.clipboard.writeText(this.copyValue()).then(function () {
            parent.el.innerText = parent.copiedText();
        }, function (err) {
            parent.el.innerText = parent.copiedErrorText();
        });
    }
};