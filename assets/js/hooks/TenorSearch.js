import tippy, { roundArrow } from 'tippy.js';
import 'tippy.js/dist/svg-arrow.css';
import 'tippy.js/animations/scale-subtle.css';

export default {
    apiKey: "",
    tenorSearch: null,
    popover: null,
    currentSection: 'trending',
    popoverVisible: false,
    recentSelections: [],
    maxRecentSelections: 15,

    mounted() {
        let storedRecentSelections = localStorage.getItem('tenor-recent-selections');
        if(storedRecentSelections != null) {
            this.recentSelections = storedRecentSelections.split(',');
        } else {
            this.recentSelections = [];
        }

        this.pushEventTo(this.el, "tenorsettings", null, (reply, ref) => {
            apiKey = reply.apikey;

            tenorSearch = new Tenor({
                key: apiKey,
                filter: reply.content_filter
            });
        });

        let parent = this;
        popover = tippy(this.el, {
            allowHTML: true,
            trigger: "manual",
            interactive: true,
            arrow: roundArrow,
            zIndex: 600,
            animation: "scale",
            maxWidth: 400,
            onShown(instance) {         
                parent.popoverVisible = true;
                return true;
            },
            onHidden(instance) { 
                parent.popoverVisible = false;
                return true;
            }
        });

        this.el.addEventListener("click", (e) => {  
            if(parent.popoverVisible) {
                popover.hide();
            } else {
                switch(parent.currentSection) {
                    case 'trending':
                        this.showTrending(10);
                        break;
                    case 'featured':
                        this.showFeatured(10);
                        break;
                    case 'recent':
                        this.showRecent();
                        break;
                    default: break;
                }
                popover.show();
            }
        });

        var reactionGifParent = document.getElementById('reaction-gif-selector');
        reactionGifParent.addEventListener('click', (e) => {
            var dispatched = false;
            switch(e.target.id) {
                case 'reactiongifs-trending-section':
                    this.showTrending(10);
                    dispatched = true;
                    break;
                case 'reactiongifs-featured-section':
                    this.showFeatured(10);
                    dispatched = true;
                    break;
                case 'reactiongifs-recent-section':
                    this.showRecent();
                    dispatched = true;
                    break;
                case 'reactiongifs-category-back-button':
                    if(currentSection == 'featured') {
                        this.showFeatured(10);
                    } else if (currentSection == 'trending') {
                        this.showTrending(10);
                    }
                    dispatched = true;
                    break;
                case 'reactiongifs-search-button':
                case 'reactiongifs-search-button-icon':
                    var searchField = document.getElementById('reactiongifs-search-input');                    
                    this.showSearch(searchField.value, 20);
                    dispatched = true;
                    break;
                case 'reactiongifs-category-search-next-button':
                    this.showCategorySearch(e.target.dataset.path, 20, e.target.dataset.next);
                    dispatched = true;
                    break;
                case 'reactiongifs-search-next-button':
                    this.showSearch(e.target.dataset.term, 20, e.target.dataset.next);
                    dispatched = true;
                    break;
                default: break;
            }

            if(!dispatched) {
                var categoryDiv = e.target.closest('.reactiongifs-category-div');
                var itemSelectionDiv = e.target.closest('.reactiongifs-item-select-div');
                if(categoryDiv != null) {
                    this.showCategorySearch(categoryDiv.dataset.path, 20);
                } else if(itemSelectionDiv != null) {
                    if(!itemSelectionDiv.dataset.noRecentTrack) {
                        this.addRecentSelection(itemSelectionDiv);
                    }
                    this.sendChatMessage(itemSelectionDiv.dataset.id, itemSelectionDiv.dataset.url, itemSelectionDiv.dataset.smallUrl);
                    popover.hide();
                }
            }
            
            return false;
        });

        reactionGifParent.addEventListener("keypress", (e) => {
            switch(e.target.id) {
                case 'reactiongifs-search-input':
                    if(e.key === "Enter") {
                        this.showSearch(e.target.value, 20);
                        e.preventDefault();
                    }
                    break;
                default: break;
            }
        });
    },
    addRecentSelection(itemElement) {
        if(this.recentSelections.length > this.maxRecentSelections) {
            this.recentSelections.splice(0,1);
        }
        this.recentSelections.push(itemElement.dataset.id);
        localStorage.setItem('tenor-recent-selections', this.recentSelections);
    },
    showFeatured(limit = null) {
        currentSection = 'featured';
        tenorSearch.showFeaturedCategories().then(results => { 
            let content = "";
            let categories = results["tags"];
            if(limit) {
                categories.splice(limit);
            }
            content = this.buildCategoryItems(categories);
            this.showPopover(this.buildPopover(content));
        });
    },
    showTrending(limit = null) {
        currentSection = 'trending';
        tenorSearch.showTrendingCategories().then(results => { 
            let content = "";
            let categories = results["tags"];
            if(limit) {
                categories.splice(limit);
            }
            content = this.buildCategoryItems(categories);
            this.showPopover(this.buildPopover(content));
        });
    },
    showRecent() {
        currentSection = 'recent';
        tenorSearch.get(this.recentSelections).then(results => {
            let content = this.buildRecentSearchResults(results.data);
            this.showPopover(this.buildPopover(content));
        });
    },
    showCategorySearch(path, limit = null, next = null) {
        let resultLimit = limit || 20;
        tenorSearch.searchCategories(path, resultLimit, next).then(results => {
            let content = this.buildCategorySearchResults(path, results.data, results.next);
            this.showPopover(this.buildPopover(content));
        });
    },
    showSearch(term, limit = null, next = null) {
        let resultLimit = limit || 20;
        tenorSearch.search(term, resultLimit, next).then(results => {
            let content = this.buildSearchResults(term, results.data, results.next);
            this.showPopover(this.buildPopover(content));
        });
    },
    showPopover(content) {
        popover.setContent(content);
        document.getElementById('reactiongifs-search-input').focus();
    },
    sendChatMessage(id, url, smallImgUrl) {
        let chatMessage = `:tenor:${id}:${url}:${smallImgUrl}`;
        this.pushEventTo(this.el, "sendtenormessage", {chat_params: {message: chatMessage}});
        tenorSearch.trackShare(id);  // let tenor know someone shared a gif
    },
    buildCategoryItems(items) {
        let html = "";
        items.forEach(item => {
            html += `
            <div class="row col-12 my-2 reactiongifs-category-div" data-path="${item.path}">
                <div class="tenor-search-categoryitem" style="background-image: url(${item.image})">
                    <div class="tenor-search-categoryitem-overlay">
                        <h5 class="tenor-search-categoryitem-name">${item.name}</h5>
                    </div>
                </div>
            </div>
            `;
        });
        return html;
    },
    buildCategorySearchResults(path, items, next) {
        let html = `
            <div class="row col-12">
                <button id="reactiongifs-category-back-button" class="btn btn-primary btn-sm" type="button">
                    <i class="fas fa-chevron-left"></i>&nbsp;Back To Category List
                </button>
            </div>
        `;
        if(items.length > 0) {
            items.forEach(item => {
                html += `
                <div class="row col-12 my-2 reactiongifs-item-select-div" data-id="${item.id}" data-url="${item.media_formats.gif.url}" data-small-url="${item.media_formats.tinygif.url}">
                    <div class="d-flex justify-content-center m-auto tenor-results-item">
                        <img src="${item.media_formats.tinygif.url}" width=220>
                    </div>
                </div>
                `;
            });    
        } else {
            html += `
            <div class="row col-12 my-2">
                <div class="d-flex justify-content-center m-auto">
                    <h4>No results returned</h4>
                </div>
            </div>
            `;
        }
        html += `
            <div class="row col-12 d-flex justify-content-center m-auto">
                <button id="reactiongifs-category-search-next-button" class="btn btn-primary btn-lg" type="button" data-next="${next}" data-path="${path}">More Results</button>
            </div>
        `;
        return html;
    },
    buildSearchResults(term, items, next) {
        let html = `
            <div class="row col-12">
                <button id="reactiongifs-category-back-button" class="btn btn-primary btn-sm" type="button">
                    <i class="fas fa-chevron-left"></i>&nbsp;Back To Category List
                </button>
            </div>
        `;
        if(items.length > 0) {
            items.forEach(item => {
                html += `
                <div class="row col-12 my-2 reactiongifs-item-select-div" data-id="${item.id}" data-url="${item.media_formats.gif.url}" data-small-url="${item.media_formats.tinygif.url}">
                    <div class="d-flex justify-content-center m-auto tenor-results-item">
                        <img src="${item.media_formats.tinygif.url}" width=220>
                    </div>
                </div>
                `;
            });    
        } else {
            html += `
            <div class="row col-12 my-2">
                <div class="d-flex justify-content-center m-auto">
                    <h4>No results returned</h4>
                </div>
            </div>
            `;
        }
        html += `
            <div class="row col-12 d-flex justify-content-center m-auto">
                <button id="reactiongifs-search-next-button" class="btn btn-primary btn-lg" type="button" data-term="${term}" data-next="${next}">More Results</button>
            </div>
        `;
        return html;
    },
    buildRecentSearchResults(items) {
        let html = "";
        for(var i = items.length - 1; i >= 0; i--) {
            html += `
            <div class="row col-12 my-2 reactiongifs-item-select-div" data-id="${items[i].id}" data-url="${items[i].media_formats.gif.url}" data-small-url="${items[i].media_formats.tinygif.url}" data-no-recent-track="true">
                <div class="d-flex justify-content-center m-auto tenor-results-item">
                    <img src="${items[i].media_formats.tinygif.url}" width=220>
                </div>
            </div>
            `;
        }
        if(items.length <= 0) {
            html += `
            <div class="row col-12 my-2">
                <div class="d-flex justify-content-center m-auto">
                    <h4>No results found</h4>
                </div>
            </div>
            `;
        }
        return html;
    },
    buildPopover(content) {
        return `
        <div class="tenor-search-popup">
            <div class="my-2 ml-1 input-group">
                <input id="reactiongifs-search-input" type="text" class="form-control" name="tenorsearch" value="" placeholder="Search Tenor" autocomplete="off">
                <button id="reactiongifs-search-button" type="button" class="btn btn-primary mr-2" title="search">
                    <i id="reactiongifs-search-button-icon" class="fas fa-search"></i>
                </button>
            </div>
            <div class="row ml-3">
                <img class="d-inline-block" src="/images/PB_tenor_logo_blue_horizontal.png" width=150 height=20>
            </div>
            <hr>
            <ul class="ml-1 nav nav-pills">
                <li class="nav-item">
                    <a id="reactiongifs-trending-section" href="#" class="nav-link ${currentSection == 'trending' ? 'active' : ''}">Trending</a>
                </li>
                <li class="nav-item">
                    <a id="reactiongifs-featured-section" href="#" class="nav-link ${currentSection == 'featured' ? 'active' : ''}">Featured</a>
                </li>
                <li class="nav-item">
                    <a id="reactiongifs-recent-section" href="#" class="nav-link ${currentSection == 'recent' ? 'active' : ''}">Recent</a>
                </li>
            </ul>
            <div class="mx-1 my-1 tenor-search-content">
                ${content}
            </div>
        </div>
        `;
    }
}

class Tenor{
    baseEndpoint = "https://tenor.googleapis.com";
    searchEndpoint = `${this.baseEndpoint}/v2/search?`;
    featuredEndpoint = `${this.baseEndpoint}/v2/featured?`;
    categoriesEndpoint = `${this.baseEndpoint}/v2/categories?`;
    searchSuggestionsEndpoint = `${this.baseEndpoint}/v2/search_suggestions?`;
    autocompleteEndpoint = `${this.baseEndpoint}/v2/autocomplete?`;
    trendingTermsEndpoint = `${this.baseEndpoint}/v2/trending_terms?`;
    registerShareEndpoint = `${this.baseEndpoint}/v2/registershare?`;
    postsEndpoint = `${this.baseEndpoint}/v2/posts?`;
    lastSearchTerm = null;


    constructor(options) {
        this.key = options.key;
        this.filter = options.filter || "medium";
        this.locale = options.locale || "en_US";
        this.mediaFilter = options.mediaFilter || "gif,tinygif,nanogif";
    }

    search(term, limit, next = null) {
        this.lastSearchTerm = term;
        let resultLimit = limit || 10;
        let url = encodeURI(`${this.searchEndpoint}q=${term}&key=${this.key}&locale=${this.locale}&contentfilter=${this.filter}&media_filter=${this.mediaFilter}&limit=${resultLimit}`);
        let parent = this;
        if(next != null) {
            url += encodeURI(`&pos=${next}`);
        }

        return new Promise((resolve, reject) => {
            parent.call(url, (ret) => {
                let data = JSON.parse(ret);
                resolve({data: data["results"], next: data["next"]});
            });
        });
    }

    autocomplete(term, limit, next = null) {
        this.lastSearchTerm = term;
        let resultLimit = limit || 10;
        let url = encodeURI(`${this.autocompleteEndpoint}q=${term}&key=${this.key}&locale=${this.locale}&limit=${resultLimit}`);
        let parent = this;
        if(next != null) {
            url += encodeURI(`&pos=${next}`);
        }

        return new Promise((resolve, reject) => {
            parent.call(url, (ret) => {
                let data = JSON.parse(ret);
                resolve(data);
            });
        });
    }

    searchCategories(path, limit, next = null) {
        this.lastSearchTerm = null;
        let resultLimit = limit || 20;
        let url = encodeURI(`${this.baseEndpoint}${path}&media_filter=${this.mediaFilter}&limit=${resultLimit}&key=${apiKey}`);
        let parent = this;
        if(next != null) {
            url += encodeURI(`&pos=${next}`);
        }

        return new Promise((resolve, reject) => {
            parent.call(url, (ret) => {
                let data = JSON.parse(ret);
                resolve({data: data["results"], next: data["next"]});
            });
        });
    }

    showCategories(type) {
        this.lastSearchTerm = null;
        let categoryType = type || "featured";
        let url = encodeURI(`${this.categoriesEndpoint}type=${categoryType}&key=${this.key}&locale=${this.locale}&contentfilter=${this.filter}`);
        let parent = this;

        return new Promise((resolve, reject) => {
            parent.call(url, (ret) => {
                let data = JSON.parse(ret);
                resolve(data);
            });
        });
    }

    showFeaturedCategories() {
        return this.showCategories("featured");
    }

    showTrendingCategories() {
        return this.showCategories("trending");
    }

    get(ids) {
        this.lastSearchTerm = null;
        let parent = this;
        if(ids == null || ids.length < 1) {
            return;
        }
        let url = encodeURI(`${this.postsEndpoint}ids=${ids.join()}&key=${this.key}&media_filter=${this.mediaFilter}`);

        return new Promise((resolve, reject) => {
            parent.call(url, (ret) => {
                let data = JSON.parse(ret);
                resolve({data: data["results"], next: data["next"]});
            });
        });
    }

    trackShare(id) {
        let url = encodeURI(`${this.registerShareEndpoint}id=${id}&key=${this.key}&locale=${this.locale}`);
        if(this.lastSearchTerm != null) {
            url += encodeURI(`&q=${this.lastSearchTerm}`);
        }
        this.call(url, (ret) => {});
    }

    call(theUrl, callback) {
        // create the request object
        var xmlHttp = new XMLHttpRequest();

        // set the state change callback to capture when the response comes in
        xmlHttp.onreadystatechange = function()
        {
            if (xmlHttp.readyState == 4 && xmlHttp.status == 200)
            {
                callback(xmlHttp.responseText);
            }
        }

        // open as a GET call, pass in the url and set async = True
        xmlHttp.open("GET", theUrl, true);

        // call send with no params as they were passed in on the url string
        xmlHttp.send(null);

        return;
    }    
}