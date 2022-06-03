import BSN from "bootstrap.native";

export default {
    mounted() {

        BSN.initCallback(this.el);
        console.log("Bootstrapize'd ", this.el, "!");

    }
};