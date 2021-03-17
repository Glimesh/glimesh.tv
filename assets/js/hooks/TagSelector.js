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
    maxTags() {
        if (this.el.dataset.maxTags) {
            return parseInt(this.el.dataset.maxTags);
        } else {
            return 10;
        }
    },
    tagify() {
        console.log(this.el.dataset)
        let tags = JSON.parse(this.el.dataset.tags);
        let categoryId = this.el.dataset.category;
        let optionMaxTags = this.maxTags()
        let allowedRegex = new RegExp(this.el.dataset.allowedRegex);
        // Allow existing weirdness to still exist
        let parsedWhitelist = tags.map((value) => value.value)

        return new Tagify(this.el, {
            whitelist: tags,
            trim: true,
            maxTags: optionMaxTags,
            originalInputValueFormat: (valuesArr) => {
                return JSON.stringify(
                    valuesArr.map(item => {
                        return {
                            category_id: categoryId,
                            value: item.value
                        }
                    })
                );
            },
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
                if (parsedWhitelist.includes(input)) {
                    return true;
                }

                if (!allowedRegex.test(input)) {
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