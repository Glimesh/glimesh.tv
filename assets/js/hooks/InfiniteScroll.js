
let scrollAt = () => {
    let scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
    let scrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight;
    let clientHeight = document.documentElement.clientHeight;

    return scrollTop / (scrollHeight - clientHeight) * 100;
}

export default {
    page() { 
        return this.el.dataset.page; 
    },
    mounted() {
        this.pending = this.page();
        window.addEventListener("scroll", e => {
            if(this.pending == this.page() && scrollAt() > 90){
                this.pending = this.page() + 1
                this.pushEvent("load-more", {})
            }
        });
    },
    reconnected() { 
        this.pending = this.page();
    },
    updated() { 
        this.pending = this.page();
    }
};