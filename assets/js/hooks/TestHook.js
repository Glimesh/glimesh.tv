
export default {
    updated() {
        console.log("updated testhook");
    },
    mounted() {
        console.log("mounted testhook")
        let parent = this;

        this.el.addEventListener("input", function(e) {
            parent.pushEvent("user_typing", {value: e.target.value})
        })
    }
};