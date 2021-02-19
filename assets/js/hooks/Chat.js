import {
    EmojiButton
} from '@joeattardi/emoji-button';
import BSN from "bootstrap.native";

export default {

    maybeScrollToBottom(el) {
        if (this.isUserNearBottom(el)) {
            this.scrollToBottom(el);
        }
    },
    scrollToBottom(el) {
        el.scrollTop = el.scrollHeight;
    },
    isUserNearBottom(el) {
        const threshold = document.body.scrollHeight / 2;
        const position = el.scrollTop + el.offsetHeight;
        const height = el.scrollHeight;
        return position > height - threshold;
    },

    emotes() {
        return JSON.parse(this.el.dataset.emotes);
    },
    injectEmojiWithSpaces(leading, emoji, trailing) {
        if (leading.charAt(leading.length - 1) !== " ") {
            leading = leading + " ";
        }
        if (trailing.charAt(0) !== " ") {
            trailing = " " + trailing;
        }
        return leading + emoji + trailing;
    },
    mounted() {
        const glimeshEmojis = this.emotes();

        const picker = new EmojiButton({
            theme: 'dark',
            position: 'top-start',
            autoHide: false,
            style: 'twemoji',
            emojiSize: '32px',
            custom: glimeshEmojis,
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

        picker.on('emoji', selection => {
            let value = '';
            if (selection.custom) {
                value = selection.name;
            } else {
                value = selection.emoji;
            }

            const [start, end] = [chat.selectionStart, chat.selectionEnd];
            chat.value = this.injectEmojiWithSpaces(
                chat.value.substring(0, start),
                value,
                chat.value.substring(end, chat.value.length)
            );
        });

        this.scrollToBottom(chatMessages);
        this.handleEvent("new_chat_message", (e) => {
            // Scroll if we need to
            this.maybeScrollToBottom(chatMessages);

            // Apply a BS init to just the new chat message
            BSN.initCallback(document.getElementById(e.message_id));
            
            //Timestamp handler
            if (e["show_timestamps"]) {
                let timestamp = document.getElementById("small-" + e["message_id"]);
                timestamp.classList.remove("d-none");
            }
        });

        /* 
        For populating the initial X messages with the current timestamp state.
        */
        this.handleEvent("update_previous_messages_with_timestamp_state", (e) => {
            let childSmalls = chatMessages.getElementsByTagName("small");
            for (let i = 0; i < childSmalls.length; i++) {
                let childSmall = childSmalls[i];
                if (e["show_timestamps"]) {
                    childSmall.classList.remove("d-none");
                } else {
                    childSmall.classList.add("d-none");
                }
            }
            this.maybeScrollToBottom(chatMessages);
        });

    }
};