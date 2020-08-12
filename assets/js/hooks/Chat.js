import { EmojiButton } from '@joeattardi/emoji-button';

export default {
    mounted() {

        const picker = new EmojiButton({
            theme: 'dark',
            position: 'top-start',
            style: 'twemoji',
        });
        const trigger = document.querySelector('.feather-message-square');
        const chat = document.getElementById('chat_message_message');

        picker.on('emoji', selection => {
            chat.value += selection.emoji;
        });

        trigger.addEventListener('click', () => picker.togglePicker(trigger));

    }
};