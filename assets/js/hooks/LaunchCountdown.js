let countdownTimer;

export default {

    copyValue() {
        return this.el.dataset.copyValue;
    },
    copiedText() {
        return this.el.dataset.copiedText;
    },
    copiedErrorText() {
        return this.el.dataset.copiedErrorText;
    },

    mounted() {
        let timerDom = this.el;
       
        // Countdown
        // Set the date we're counting down to
        // Remember that javascript is stupid and 2 == March
        var countDownDate = new Date(Date.UTC(2021, 2, 2, 16, 0, 0, 0)).getTime();

        function padToTwo(value) {
            var s = "0" + value;
            return s.substr(s.length - 2);
        }

        function setTimeRemaining() {
            // Get todays date and time
            var now = new Date().getTime();
            // Find the distance between now an the count down date
            var distance = countDownDate - now;
            // Time calculations for days, hours, minutes and seconds
            var days = Math.floor(distance / (1000 * 60 * 60 * 24));
            var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
            var seconds = Math.floor((distance % (1000 * 60)) / 1000);
            // Output the result in an element with id="demo"
            timerDom.innerHTML = '<div class="days"><span class="text">Days</span> <span class="count">' + padToTwo(days) + '</span></div>\n' +
                '<div class="spacer">:</div>\n' +
                '<div class="hours"><span class="text">Hours</span><span class="count">' + padToTwo(hours) + '</span></div>\n' +
                '<div class="spacer">:</div>\n' +
                '<div class="min"><span class="text">Minutes</span><span class="count">' + padToTwo(minutes) + '</span></div>\n' +
                '<div class="spacer">:</div>\n' +
                '<div class="sec"><span class="text">Seconds</span><span class="count">' + padToTwo(seconds) + '</span></div>\n';
            // If the count down is over, write some text
            if (distance < 0) {
                clearInterval(countdownTimer);
                timerDom.innerHTML = "EXPIRED";
            }
        }

        countdownTimer = setInterval(setTimeRemaining, 1000)
    }
};
