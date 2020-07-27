// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"
import BSN from "bootstrap.native";


function loadLib(url) {
    return new Promise((resolve, reject) => {
        // adding the script tag to the head as suggested before
        let head = document.getElementsByTagName('head')[0];
        let script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = url;

        // then bind the event to the callback function
        // there are several events for cross browser compatibility
        script.onreadystatechange = resolve;
        script.onload = resolve;

        // fire the loading
        head.appendChild(script);
    });
}

function tryVideo(url) {
    if (document.getElementById('player')) {
        Promise.all([
            loadLib("https://cdnjs.cloudflare.com/ajax/libs/dashjs/2.9.3/dash.all.min.js"),
            loadLib("https://cdn.jsdelivr.net/npm/hls.js@latest"),
            loadLib("/ovenplayer/ovenplayer.js"),
        ]).then(data => {
            console.log('finished loading video player with ' + url);
            // OvenPlayer.debug(true);

            let player = OvenPlayer.create("player", {
                // autoStart: true,
                image: "/images/stream-not-started.jpg",
                sources: [
                    {
                        type: "webrtc",
                        file: "wss://edge.live.glimesh.tv:3334/app/stream",
                        label: "Warp 1"
                    },
                    {
                        type: "hls",
                        file: "https://edge.live.glimesh.tv/app/stream/playlist.m3u8",
                        label: "HLS"
                    },
                    {
                        type: "mpd",
                        file: "https://edge.live.glimesh.tv/app/stream/manifest.mpd",
                        label: "MPEG-DASH"
                    }
                ]
            });
            player.on("error", function (error) {
                console.log(error);
            });
            player.on('ready', function () {
                // player.play();
            });

            player.on('metaChanged', function (f) {
                console.log(f);
                player.play();
            });

            setTimeout(function () {
            }, 5000);
        });
    }
}

let Hooks = {};
Hooks.LoadVideo = {
    playbackUrl() {
        return this.el.dataset.playbackUrl
    },
    mounted() {
        tryVideo(this.playbackUrl())
    }
};
Hooks.PaymentSubscription = {
    customerId() { return this.el.dataset.stripe_customer_id },
    mounted() {
        let backend = this;

        console.log("mountie");
        var stripe = Stripe('');
        var elements = stripe.elements();

        var style = {
            base: {
                color: "#32325d",
                fontFamily: '"Helvetica Neue", Helvetica, sans-serif',
                fontSmoothing: "antialiased",
                fontSize: "16px",
                "::placeholder": {
                    color: "#aab7c4"
                }
            },
            invalid: {
                color: "#fa755a",
                iconColor: "#fa755a"
            }
        };

        var card = elements.create("card", {
            style: style
        });
        card.mount("#card-element");

        var form = document.getElementById('subscription-form');

        form.addEventListener('submit', function (ev) {
            ev.preventDefault();
            // If a previous payment was attempted, get the latest invoice
            const latestInvoicePaymentIntentStatus = localStorage.getItem(
                'latestInvoicePaymentIntentStatus'
            );
            if (latestInvoicePaymentIntentStatus === 'requires_payment_method') {
                const invoiceId = localStorage.getItem('latestInvoiceId');
                const isPaymentRetry = true;
                // create new payment method & retry payment on invoice with new payment method
                createPaymentMethod({
                    card,
                    isPaymentRetry,
                    invoiceId,
                });
            } else {
                console.log(card)
                // create new payment method & create subscription
                createPaymentMethod({
                    card
                });
            }
        });

        function createSubscription({ customerId, paymentMethodId, priceId }) {
            backend.pushEvent("stripe-create-subscription", {
                customerId: customerId,
                paymentMethodId: paymentMethodId,
                priceId: priceId,
            }, function(done) {
                console.log("done")
            });
            //
            // return (
            //     fetch('/create-subscription', {
            //         method: 'post',
            //         headers: {
            //             'Content-type': 'application/json',
            //         },
            //         body: JSON.stringify({
            //             customerId: customerId,
            //             paymentMethodId: paymentMethodId,
            //             priceId: priceId,
            //         }),
            //     })
            //         .then((response) => {
            //             return response.json();
            //         })
            //         // If the card is declined, display an error to the user.
            //         .then((result) => {
            //             if (result.error) {
            //                 // The card had an error when trying to attach it to a customer.
            //                 throw result;
            //             }
            //             return result;
            //         })
            //         // Normalize the result to contain the object returned by Stripe.
            //         // Add the additional details we need.
            //         .then((result) => {
            //             return {
            //                 paymentMethodId: paymentMethodId,
            //                 priceId: priceId,
            //                 subscription: result,
            //             };
            //         })
            //         // Some payment methods require a customer to be on session
            //         // to complete the payment process. Check the status of the
            //         // payment intent to handle these actions.
            //         .then(handlePaymentThatRequiresCustomerAction)
            //         // If attaching this card to a Customer object succeeds,
            //         // but attempts to charge the customer fail, you
            //         // get a requires_payment_method error.
            //         .then(handleRequiresPaymentMethod)
            //         // No more actions required. Provision your service for the user.
            //         .then(onSubscriptionComplete)
            //         .catch((error) => {
            //             // An error has happened. Display the failure to the user here.
            //             // We utilize the HTML element we created.
            //             showCardError(error);
            //         })
            // );
        }


        function createPaymentMethod({ card, isPaymentRetry, invoiceId }) {
            console.log(card);

            // Set up payment method for recurring usage
            let billingName = "Luke Strickland";
            stripe
                .createPaymentMethod({
                    type: 'card',
                    card: card,
                    billing_details: {
                        name: billingName,
                    },
                })
                .then((result) => {
                    if (result.error) {
                        displayError(result);
                    } else {
                        if (isPaymentRetry) {
                            // Update the payment method and retry invoice payment
                            retryInvoiceWithNewPaymentMethod({
                                customerId: backend.customerId(),
                                paymentMethodId: result.paymentMethod.id,
                                invoiceId: invoiceId,
                                priceId: "price_1H8TwGBLNaYgaiU5uwYJO2Vb",
                            });
                        } else {
                            // Create the subscription
                            createSubscription({
                                customerId: backend.customerId(),
                                paymentMethodId: result.paymentMethod.id,
                                priceId: "price_1H8TwGBLNaYgaiU5uwYJO2Vb",
                            });
                        }
                    }
                });
        }

        function displayError(err) {
            console.error(err);
        }


        card.on('change', showCardError);

        function showCardError(event) {
            let displayError = document.getElementById('card-errors');
            if (event.error) {
                displayError.textContent = event.error.message;
            } else {
                displayError.textContent = '';
            }
        }
    }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start());
window.addEventListener("phx:page-loading-stop", info => {
    console.log("phx:page-loading-stop");
    BSN.initCallback(document.body);
    NProgress.done();

    // Close the nav bar on navigate
    if (document.getElementById("primaryNav")) {
        document.getElementById("primaryNav").classList.remove('show');
    }
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug();
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

