import Tagify from '@yaireo/tagify';

export default {
    updated() {
        // Whenever the parent DOM changes, it's likely because a category ID 
        // change happened, which means we want to start over.
        this.mounted();
    },
    mounted() {
        let parent = this;
        let tagify = this.tagify();

        parent.handleEvent(this.el.dataset.suggestionsEvent, ({value, results}) => {
            tagify.settings.whitelist.splice(0, results.length, ...results);

            tagify.loading(false).dropdown.show.call(tagify, value);
        });

        tagify.on('input', function(e) {
            var value = e.detail.value;

            tagify.settings.whitelist.length = 0; // reset the whitelist
            tagify.loading(true).dropdown.hide.call(tagify);

            // Target the DOM selector ID to get to the child component
            parent.pushEventTo(`#${parent.el.id}`, "suggest", { value: value });
        });
    },
    tagify() {
        let categoryId = this.el.dataset.category;
        let allowedCreateRegex = new RegExp(this.el.dataset.createRegex);
        let allowEdit = (this.el.dataset.allowEdit == "true" ? true : false);
        let whitelist = [];
        if (this.el.value) {
            whitelist.push({value: this.el.value});
        }

        return new Tagify(this.el, {
            whitelist: whitelist,
            trim: true,
            enforceWhitelist: !allowEdit,
            editTags: allowEdit,
            maxTags: parseInt(this.el.dataset.maxOptions),
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
            validate: function( {value: input}) {
                let parsedWhitelist = this.whitelist.map(({value: v}) => v);
                if (parsedWhitelist.includes(input)) {
                    return true;
                }

                if (allowEdit && allowedCreateRegex.test(input) === false) {
                    return "Must be alphanumerical and may contain colon's, spaces, and dashes.";
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