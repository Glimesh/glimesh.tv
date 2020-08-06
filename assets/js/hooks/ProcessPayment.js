import BSN from "bootstrap.native";

export default {
    stripe: null,

    onSubscriptionComplete(result) {
        // Don't really need to do anything here since it's all handled by the backend
        console.log(result);
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


    createSubscription(customerId, paymentMethodId, priceId) {
        return new Promise((resolve, reject) => {
            this.pushEvent("subscriptions.channel.subscribe", {
                customerId: customerId,
                paymentMethodId: paymentMethodId,
                priceId: priceId,
            }, function(results) {
                resolve(results);
            });
        })
    },


    createPaymentMethod(card, billingName) {
        return this.stripe.createPaymentMethod({
            type: 'card',
            card: card,
            billing_details: {
                name: billingName,
            },
        })
    },


    stripePublicKey() {
        return this.el.dataset.stripePublicKey
    },
    customerId() {
        return this.el.dataset.stripeCustomerId
    },
    stripePaymentMethod() {
        return this.el.dataset.stripePaymentMethod
    },

    mounted() {
        let backend = this;

        backend.stripe = Stripe(this.stripePublicKey());

        let form = document.getElementById('subscription-form');

        if( ! this.stripePaymentMethod()) {
            // No default payment method
            // Let's figure out payment details
            let billingName = document.getElementById("paymentName");
            billingName.focus();

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
            if(document.getElementById("card-element")) {
                card.mount("#card-element");
            }
            card.on('change', backend.showCardError);
        }

        form.addEventListener('submit', function (ev) {
            ev.preventDefault();

            if (backend.stripePaymentMethod()) {
                backend.createSubscription(backend.customerId(), backend.stripePaymentMethod(), "price_1H8TwGBLNaYgaiU5uwYJO2Vb")
                    .then(backend.onSubscriptionComplete.bind(backend));
            } else {
                // Create a payment method first if we don't have one...
                backend.createPaymentMethod(card, billingName.value).then(function({paymentMethod}) {
                    backend.createSubscription(backend.customerId(), paymentMethod.id, "price_1H8TwGBLNaYgaiU5uwYJO2Vb")
                        .then(backend.onSubscriptionComplete.bind(backend));
                });
            }


        });

    }
};