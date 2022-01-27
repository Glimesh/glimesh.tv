export default {
    updated() {
        this.mounted();
    },
    mounted() {
        var target_input = this.el.dataset.fieldid;
        var target_input_element = document.getElementById(target_input);
        var tagify_instance = target_input_element.tagify;

        this.el.addEventListener("click", e => {
            let tagId = this.el.dataset.tagid;
            let tagName = this.el.dataset.tagname;
            let tagSlug = this.el.dataset.tagslug;
            let categoryId = this.el.dataset.categoryid;
            let operation = this.el.dataset.operation;
            if(operation === "replace") {
                tagify_instance.removeAllTags();
            }
            tagify_instance.addTags([{id: tagId, value: tagName, slug: tagSlug, label: tagName, categoryid: categoryId}]);
        });

    }
}