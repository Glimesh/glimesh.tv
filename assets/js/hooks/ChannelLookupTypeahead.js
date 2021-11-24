export default {
    mounted() {
        this.el.addEventListener("click", e => {
            let userId = this.el.getAttribute('data-id');
            let userName = this.el.getAttribute('data-name');
            let fieldName = this.el.getAttribute('data-fieldname');
            let channelId = this.el.getAttribute('data-channel-id');
            this.pushEvent(fieldName + "_selection_made", {"user_id": userId, "username": userName, "channel_id": channelId});
        });
    }
}