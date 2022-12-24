export default {
    raidTime: 0,
    raidCounterId: "",
    raidTimeElement: null,
    interval: null,

    doTimer() {
        interval = setInterval(() => {
            raidTimeElement.innerText = `(${raidTime})`;
            if(raidTime < 1) {
                raidTime = 0;
                clearInterval(interval);
            } else {
                raidTime--;
            }
        }, 1000);
    },
    waitForElement(maxWait) {
        let parent = this;
        let wait = 0;
        elementWaitInterval = setInterval(() => {
            raidTimeElement = document.getElementById(raidCounterId);
            if(raidTimeElement != null) {
                clearInterval(elementWaitInterval);
                parent.doTimer();
            } else if(wait >= maxWait) {
                clearInterval(elementWaitInterval);
            } else {
                raidTime -= 2;
                wait += 2000;
            }
        }, 2000);
    },
    mounted() {
        raidCounterId = this.el.dataset.raidCounterId;
        let parent = this;

        this.handleEvent("start_raid_timer", (data) => {
            raidTime = data.time - 2;
            parent.waitForElement(40000);
        });
    }
};