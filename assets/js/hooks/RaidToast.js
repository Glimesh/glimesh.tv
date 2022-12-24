import BSN from "bootstrap.native";

export default {
    raidTime: 0,
    raidCounterId: "",
    raidTimeElement: null,
    interval: null,

    mounted() {
        const toast = new BSN.Toast(this.el);
        raidTime = this.el.dataset.raidTime;
        raidCounterId = this.el.dataset.raidCounterId;
        raidTimeElement = document.getElementById(raidCounterId);
        let raidYesButton = document.getElementById('raid-yes-button');
        let raidNoButton = document.getElementById('raid-no-button');
        let parent = this;

        interval = setInterval(() => {
            raidTimeElement.innerText = `(${raidTime})`;
            if(raidTime < 1) {
                raidTime = 0;
                clearInterval(interval);
                toast.hide();
            } else {
                raidTime--;
            }
        }, 1000);
        toast.show();

        this.handleEvent("cancel_raid", () => {
            raidTime = 0;
            clearInterval(interval);
            toast.hide();
        });

        raidYesButton.addEventListener('click', function(e) {
            raidYesButton.disabled = true;
            raidNoButton.disabled = true;
        });

        raidNoButton.addEventListener('click', function(e) {
            raidTime = 0;
            clearInterval(interval);
            toast.hide();
            parent.pushEvent('decline-raid', {});
        });
    }
};