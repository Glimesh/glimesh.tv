import BSN from "bootstrap.native";

export default {
    stripe: null,

    onSubscriptionComplete(result) {
        // Payment was successful.
        if (result.error) {
            // Show error to your customer (e.g., insufficient funds)
            this.displayError(result.error);
        } else {
            // The payment has been processed!
            if (result.paymentIntent.status === 'succeeded') {
                // Show a success message to your customer
                // There's a risk of the customer closing the window before callback
                // execution. Set up a webhook or plugin to listen for the
                // payment_intent.succeeded event that handles any business critical
                // post-payment actions.
                console.log("success");
                console.log(result);
            }
        }
    },

    displayError(err) {
        console.error(err);
    },


    showCardError(event) {
        let displayError = document.getElementById('card-errors');
        if (event.error) {
            displayError.textContent = event.error.message;
        } else {
            displayError.textContent = '';
        }
    },

    stripePublicKey() {
        return this.el.dataset.stripePublicKey
    },
    customerId() {
        return this.el.dataset.stripeCustomerId
    },
    mounted() {
        let backend = this;

        backend.stripe = Stripe(this.stripePublicKey());

        this.handleEvent("accept-payment-intent", function({client_secret}) {
            new BSN.Modal('#paymentModal', { backdrop: true }).show();
            document.getElementById("paymentModal").addEventListener("shown.bs.modal", function(ev) {
                document.getElementById("paymentName").focus();
            });

            let form = document.getElementById('subscription-form');

            form.addEventListener('submit', function (ev) {
                ev.preventDefault();
                backend.stripe.confirmCardPayment(client_secret, {
                    payment_method: {
                        card: card,
                        billing_details: {
                            name: document.getElementById("paymentName").value
                        }
                    }
                }).then(backend.onSubscriptionComplete);
            });
        });

        var elements = this.stripe.elements();

        var style = {
            base: {
                color: "#009688",
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
        card.on('change', backend.showCardError);
    }
};