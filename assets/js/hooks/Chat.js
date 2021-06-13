import {
    EmojiButton
} from '@joeattardi/emoji-button';
import BSN from "bootstrap.native";

export default {

    maybeScrollToBottom(el) {
        if (this.isUserNearBottom(el)) {
            this.scrollToBottom(el);
            this.removeScrollNotice();
        } else {
            this.addScrollNotice();
        }
    },
    scrollToBottom(el) {
        el.scrollTop = el.scrollHeight;
    },
    isUserNearBottom(el) {
        // 5 chat messages with padding
        const threshold = 404;
        const position = el.scrollTop + el.offsetHeight;
        const height = el.scrollHeight;
        const isNearBottom = position > height - threshold;
        // For when you need to debug chat scrolling
        // console.log(`scrollTop=${el.scrollTop} offsetHeight=${el.offsetHeight} threshold=${threshold} position=${position} height=${height} isNearBottom=${isNearBottom}`);
        return isNearBottom;
    },

    addScrollNotice() {
        document.getElementById("more-chat-messages").classList.remove("d-none");
    },
    removeScrollNotice() {
        document.getElementById("more-chat-messages").classList.add("d-none");
    },

    theme() {
        return this.el.dataset.theme;
    },
    emotes() {
        return JSON.parse(this.el.dataset.emotes);
    },

    updated() {
        this.scrollToBottom(document.getElementById('chat-messages'));
    },
    reconnected() {
        this.scrollToBottom(document.getElementById('chat-messages'));
    },
    mounted() {
        const parent = this;
        const glimeshEmojis = this.emotes();

        const picker = new EmojiButton({
            theme: this.theme(),
            position: 'top-start',
            autoHide: false,
            style: 'twemoji',
            emojiSize: '32px',
            custom: glimeshEmojis,
            categories: [
                'custom',
                'smileys',
                'people',
                'animals',
                'food',
                'activities',
                'travel',
                'objects',
                'flags',
                'symbols',
            ],
            initialCategory: 'custom'
        });

        const trigger = document.querySelector('.emoji-activator');
        if (trigger) {
            trigger.addEventListener('click', (e) => {
                e.preventDefault();
                picker.togglePicker(trigger)
            });
        }

        const chat = document.getElementById('chat_message-form_message');
        const chatMessages = document.getElementById('chat-messages');

        // Whenever the user changes their browser size, re-scroll them to the bottom
        window.addEventListener('resize', () => this.scrollToBottom(chatMessages));

        picker.on('emoji', selection => {
            let value = '';
            if (selection.custom) {
                value = selection.name;
            } else {
                value = selection.emoji;
            }

            const [start, end] = [chat.selectionStart, chat.selectionEnd];
            chat.value = chat.value.substring(0, start) + value + chat.value.substring(end, chat.value.length);
        });

        this.scrollToBottom(chatMessages);
        this.handleEvent("new_chat_message", (e) => {
            // Scroll if we need to
            this.maybeScrollToBottom(chatMessages);

            let thisMessage = document.getElementById(e.message_id);
            // Apply a BS init to just the new chat message
            BSN.initCallback(thisMessage);
        });
        this.handleEvent("toggle_timestamps", (e) => {
            if (e["show_timestamps"]) {
                chatMessages.classList.add("show-timestamps");
            } else {
                chatMessages.classList.remove("show-timestamps");
            }
            this.maybeScrollToBottom(chatMessages);
        });
        this.handleEvent("toggle_mod_icons", (e) => {
            if (e["show_mod_icons"]) {
                chatMessages.classList.add("show-mod-icons");
            } else {
                chatMessages.classList.remove("show-mod-icons");
            }
            this.maybeScrollToBottom(chatMessages);
        });

        this.handleEvent("remove_timed_out_user_messages", (e) => {
            let offendingUserID = e["bad_user_id"];
            let offendingChatMessage = chatMessages.querySelectorAll(`[data-user-id=${CSS.escape(offendingUserID)}]`);
            // Have to hide them otherwise the tooltip gets stuck on removing the element
            offendingChatMessage.forEach(e => e.hidden = true);
        });

        this.handleEvent("remove_deleted_message", (e) => {
            document.getElementById(e["message_id"]).hidden = true;
        });

        // Scrolling voo-doo
        this.handleEvent("scroll_to_bottom", (e) => {
            parent.scrollToBottom(chatMessages);
        });
        chatMessages.onscroll = function () {
            if (chatMessages.scrollHeight - chatMessages.scrollTop === chatMessages.clientHeight) {
                parent.removeScrollNotice();
            }
        }

        let recentMessages = []; // Holds all user-sent messages
        let currentMessage = ""; // The current message the user is typing. Reset when sent.
        let currentIndex = -1; // The position the user is in of the array that holds the messages.

        document.getElementById("chat-form").onsubmit = function (e) {
            if (e.target[2].value !== "" && e.target[2].value.length <= 255) {
                recentMessages.unshift(e.target[2].value); // Pushes the message to the array
                currentIndex = -1; // Resets the position
                // If the message sent is what the user was typing (NOT a previous message) reset currentMessage
                if (e.target[2].value == currentMessage) {
                    currentMessage = ""
                }
            }
        }
        // Chat doesn't exist if they are not logged it, we check that before adding the listener
        if (chat) {
            chat.onkeyup = function (e) {
                if (e.code == "ArrowUp") {
                    // If no message is being typed and currentMessage was not sent
                    if (e.target.value == "" && currentMessage) {
                        e.target.value = currentMessage;
                        // Else we show the the previous message(s)
                    } else if (recentMessages.length !== 0 && recentMessages[currentIndex + 1]) {
                        e.target.value = recentMessages[currentIndex + 1];
                        currentIndex = currentIndex + 1
                    }
                } else if (e.code == "ArrowDown") {
                    // If there are more recent messages we show them
                    if (recentMessages.length !== 0 && recentMessages[currentIndex - 1]) {
                        e.target.value = recentMessages[currentIndex - 1];
                        currentIndex = currentIndex - 1;
                        // If we have no messages to show we set the value to current message
                    } else if (currentIndex - 1 == -1) {
                        e.target.value = currentMessage;
                        currentIndex = -1;
                    } else {
                        e.target.value = "" // Resets the box back to default
                    }
                }
            }
        }
        // On input we set the currentMessage to what is being typed. Not triggered when user puts previous messages in the input box
        document.getElementById("chat-form").oninput = function (e) {
            if (currentIndex == -1) {
                currentMessage = e.target.value;
            }
        };
    }
};
