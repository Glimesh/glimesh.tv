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
        // 5 chat messages with padding
        const threshold = 404;
        const position = el.scrollTop + el.offsetHeight;
        const height = el.scrollHeight;
        const isNearBottom = position > height - threshold;
        // For when you need to debug chat scrolling
        // console.log(`scrollTop=${el.scrollTop} offsetHeight=${el.offsetHeight} threshold=${threshold} position=${position} height=${height} isNearBottom=${isNearBottom}`);
        return isNearBottom;
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

        /* 
        For populating the initial X messages with the current timestamp state.
        */
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
        })

    }
};
