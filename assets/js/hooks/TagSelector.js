import Tagify from '@yaireo/tagify';

export default {
    updated() {
        console.log("Updated");
        let tagify = this.tagify();
        tagify.removeAllTags();
    },
    mounted() {
        this.tagify();
    },
    tagify() {
        let tags = JSON.parse(this.el.dataset.tags);
        let allowedRegex = /^[A-Za-z0-9: -]{2,18}$/;

        return new Tagify(this.el, {
            whitelist: tags,
            trim: true,
            maxTags: 10,
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
            validate: function({value: input}) {
                if ( ! allowedRegex.test(input)) {
                    return "Tags must be alphanumerical and may contain colon's, spaces, and dashes. Min length 2, Max length 18";
                }

                return true;
            },
            dropdown: {
                enabled: 0,
                classname: "tagify-dropdown",
                highlightFirst: true
            }
        });

    }
};