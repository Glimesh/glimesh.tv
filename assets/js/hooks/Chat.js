import {
    EmojiButton
} from '@joeattardi/emoji-button';

export default {

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
        console.log(glimeshEmojis)

        const picker = new EmojiButton({
            theme: 'dark',
            position: 'top-start',
            autoHide: false,
            style: 'twemoji',
            emojiSize: '32px',
            custom: glimeshEmojis,
        });

        const trigger = document.querySelector('.emoji-activator');
        const chat = document.getElementById('chat_message_message');

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

        trigger.addEventListener('click', () => picker.togglePicker(trigger));

    }
};