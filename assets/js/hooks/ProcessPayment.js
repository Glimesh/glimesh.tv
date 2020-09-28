import BSN from "bootstrap.native";

export default {
    stripe: null,
    formDisabled: false,

    savingForm() {
        this.formDisabled = true;
        this.el.querySelector("button[type=submit]").disabled = true;
        this.el.classList.add("loading");
    },

    resetForm() {
        this.formDisabled = false;
        this.el.querySelector("button[type=submit]").disabled = false;
        this.el.classList.remove("loading");
    },

    onSubscriptionComplete(result) {
        // Don't really need to do anything here since it's all handled by the backend
        this.resetForm();
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
            this.pushEvent("subscriptions.subscribe", {
                customerId: customerId,
                paymentMethodId: paymentMethodId
            }, function (results) {
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

    productId() {
        return this.el.dataset.stripeProductId
    },
    priceId() {
        return this.el.dataset.stripePriceId
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

    updated() {
        console.log("updated")
    },

    mounted() {
        let backend = this;

        backend.stripe = Stripe(this.stripePublicKey());

        let form = document.getElementById('subscription-form');

        if (!this.stripePaymentMethod()) {
            // No default payment method
            // Let's figure out payment details
            let billingName = document.getElementById("paymentName");
            billingName.focus();

            var elements = this.stripe.elements();

            var style = {
                base: {
                    color: "#009688",
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
            if (document.getElementById("card-element")) {
                card.mount("#card-element");
            }
            card.on('change', backend.showCardError);
        }

        form.addEventListener('submit', function (ev) {
            ev.preventDefault();
            if (backend.formDisabled) {
                return;
            }
            backend.savingForm();

            if (backend.stripePaymentMethod()) {
                backend.createSubscription(backend.customerId(), backend.stripePaymentMethod(), backend.priceId())
                    .then(backend.onSubscriptionComplete.bind(backend));
            } else {
                // Create a payment method first if we don't have one...
                let billingName = document.getElementById("paymentName");

                backend.createPaymentMethod(card, billingName.value).then(function ({
                    paymentMethod
                }) {
                    backend.createSubscription(backend.customerId(), paymentMethod.id, backend.priceId())
                        .then(backend.onSubscriptionComplete.bind(backend));
                });
            }

        });

    }
};