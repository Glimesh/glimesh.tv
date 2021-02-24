import Tagify from '@yaireo/tagify';

export default {
    mounted() {
        let tagify = this.tagify();
        let parent = this;
        tagify.on("add", function(e) {
            parent.filterTags(e.detail.tagify.value);
        });
        tagify.on("remove", function(e) {
            parent.filterTags(e.detail.tagify.value);
        });
    },
    filterTags(tags) {
        this.pushEvent("filter_tags", tags)
    },
    tagify() {
        let tags = JSON.parse(this.el.dataset.tags);

        return new Tagify(this.el, {
            whitelist: tags,
            enforceWhitelist: true,
            editTags: false,
            templates: {
                tag: function(tagData) {
                    try{
                        return `<tag title='${tagData.value}' contenteditable='false' spellcheck="false" class='tagify__tag ${tagData.class ? tagData.class : ""}' ${this.getAttributes(tagData)}>
                                    <x title='remove tag' class='tagify__tag__removeBtn'></x>
                                    <div>
                                        <span class='tagify__tag-text'>${tagData.value}</span>
                                    </div>
                                </tag>`
                    } catch(err){
                        console.error("Error rendering tag", tagData)
                    }
            
                },
                dropdownItem : function(tagData){
                    try {
                        return `<div class='tagify__dropdown__item ${tagData.class ? tagData.class : ""}' tagifySuggestionIdx="${tagData.tagifySuggestionIdx}">
                                        <span>${tagData.label}</span>
                                    </div>`
                    } catch(err){
                        console.error("Error rendering dropdown tag", tagData)
                    }
                }
            },
            dropdown: {
                enabled: 0,
                classname: "tagify-dropdown",
                highlightFirst: true
            }
        });

    }
};