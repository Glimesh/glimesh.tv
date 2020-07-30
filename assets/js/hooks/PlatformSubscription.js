export default {
    stripe: null,

    onSubscriptionComplete(result) {
        // Payment was successful.
        if (result.subscription.status === 'active') {
            // Change your UI to show a success message to your customer.
            // Call your backend to grant access to your service based on
            // `result.subscription.items.data[0].price.product` the customer subscribed to.
        }
    },

    handlePaymentThatRequiresCustomerAction({
                                                subscription,
                                                invoice,
                                                priceId,
                                                paymentMethodId,
                                                isRetry,
                                            }) {
        if (subscription && subscription.status === 'active') {
            // Subscription is active, no customer actions required.
            return {subscription, priceId, paymentMethodId};
        }

        // If it's a first payment attempt, the payment intent is on the subscription latest invoice.
        // If it's a retry, the payment intent will be on the invoice itself.
        let paymentIntent = invoice ? invoice.payment_intent : subscription.latest_invoice.payment_intent;

        if (
            paymentIntent.status === 'requires_action' ||
            (isRetry === true && paymentIntent.status === 'requires_payment_method')
        ) {
            return this.stripe
                .confirmCardPayment(paymentIntent.client_secret, {
                    payment_method: paymentMethodId,
                })
                .then((result) => {
                    if (result.error) {
                        // Start code flow to handle updating the payment details.
                        // Display error message in your UI.
                        // The card was declined (i.e. insufficient funds, card has expired, etc).
                        throw result;
                    } else {
                        if (result.paymentIntent.status === 'succeeded') {
                            // Show a success message to your customer.
                            // There's a risk of the customer closing the window before the callback.
                            // We recommend setting up webhook endpoints later in this guide.
                            return {
                                priceId: priceId,
                                subscription: subscription,
                                invoice: invoice,
                                paymentMethodId: paymentMethodId,
                            };
                        }
                    }
                })
                .catch((error) => {
                    displayError(error);
                });
        } else {
            // No customer action needed.
            return {subscription, priceId, paymentMethodId};
        }
    },

    handleRequiresPaymentMethod({
                                    subscription,
                                    paymentMethodId,
                                    priceId,
                                }) {
        if (subscription.status === 'active') {
            // subscription is active, no customer actions required.
            return {subscription, priceId, paymentMethodId};
        } else if (
            subscription.latest_invoice.payment_intent.status ===
            'requires_payment_method'
        ) {
            // Using localStorage to manage the state of the retry here,
            // feel free to replace with what you prefer.
            // Store the latest invoice ID and status.
            localStorage.setItem('latestInvoiceId', subscription.latest_invoice.id);
            localStorage.setItem(
                'latestInvoicePaymentIntentStatus',
                subscription.latest_invoice.payment_intent.status
            );
            throw {error: {message: 'Your card was declined.'}};
        } else {
            return {subscription, priceId, paymentMethodId};
        }
    },

    retryInvoiceWithNewPaymentMethod({
                                         customerId,
                                         paymentMethodId,
                                         invoiceId,
                                         priceId
                                     }) {
        return (
            fetch('/retry-invoice', {
                method: 'post',
                headers: {
                    'Content-type': 'application/json',
                },
                body: JSON.stringify({
                    customerId: customerId,
                    paymentMethodId: paymentMethodId,
                    invoiceId: invoiceId,
                }),
            })
                .then((response) => {
                    return response.json();
                })
                // If the card is declined, display an error to the user.
                .then((result) => {
                    if (result.error) {
                        // The card had an error when trying to attach it to a customer.
                        throw result;
                    }
                    return result;
                })
                // Normalize the result to contain the object returned by Stripe.
                // Add the additional details we need.
                .then((result) => {
                    return {
                        // Use the Stripe 'object' property on the
                        // returned result to understand what object is returned.
                        invoice: result,
                        paymentMethodId: paymentMethodId,
                        priceId: priceId,
                        isRetry: true,
                    };
                })
                // Some payment methods require a customer to be on session
                // to complete the payment process. Check the status of the
                // payment intent to handle these actions.
                .then(handlePaymentThatRequiresCustomerAction)
                // No more actions required. Provision your service for the user.
                .then(onSubscriptionComplete)
                .catch((error) => {
                    // An error has happened. Display the failure to the user here.
                    // We utilize the HTML element we created.
                    displayError(error);
                })
        );
    },

    createSubscription({customerId, paymentMethodId, priceId}) {
        this.pushEvent("stripe-create-subscription", {
            customerId: customerId,
            paymentMethodId: paymentMethodId,
            priceId: priceId,
        }, function(results) {
            console.log("something happened with the payment");
            console.log(results);
        });
    },

    createPaymentMethod({card, isPaymentRetry, invoiceId}) {
        let parent = this;
        console.log(card);

        // Set up payment method for recurring usage
        let billingName = "Luke Strickland";
        this.stripe
            .createPaymentMethod({
                type: 'card',
                card: card,
                billing_details: {
                    name: billingName,
                },
            })
            .then((result) => {
                if (result.error) {
                    parent.displayError(result);
                } else {
                    if (isPaymentRetry) {
                        // Update the payment method and retry invoice payment
                        parent.retryInvoiceWithNewPaymentMethod({
                            customerId: parent.customerId(),
                            paymentMethodId: result.paymentMethod.id,
                            invoiceId: invoiceId,
                            priceId: "price_1H8TwGBLNaYgaiU5uwYJO2Vb",
                        });
                    } else {
                        // Create the subscription
                        parent.createSubscription({
                            customerId: parent.customerId(),
                            paymentMethodId: result.paymentMethod.id,
                            priceId: "price_1H8TwGBLNaYgaiU5uwYJO2Vb",
                        });
                    }
                }
            });
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

        this.stripe =  Stripe(this.stripePublicKey());
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
                backend.createPaymentMethod({
                    card,
                    isPaymentRetry,
                    invoiceId,
                });
            } else {
                console.log(card)
                // create new payment method & create subscriptionplatform_subscriptions
                backend.createPaymentMethod({
                    card
                });
            }
        });


        card.on('change', backend.showCardError);
    }
};