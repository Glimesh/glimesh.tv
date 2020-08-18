import Choices from 'choices.js';

export default {
    mounted() {

        const choices = new Choices(this.el, {
            shouldSort: false,
            itemSelectText: "",
        })

    }
};