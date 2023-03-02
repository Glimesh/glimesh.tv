export default {
    mounted() {
        this.el.addEventListener("click", e => {
            let shareText = this.el.dataset.shareText;
            let shareURL = this.el.dataset.shareUrl;
            let instanceSelector = this.el.dataset.instanceSelector;
            let instance = document.querySelector(instanceSelector).value;

            let url = instance + "share?text=" + shareText + "%0D%0A" + shareURL;
            window.open(url, '_blank');
        });
    }
}