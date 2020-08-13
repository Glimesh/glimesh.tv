import { EmojiButton } from '@joeattardi/emoji-button';

export default {
    mounted() {

        const picker = new EmojiButton({
            theme: 'dark',
            position: 'top-start',
            autoHide: false,
        });
        const trigger = document.querySelector('.emoji-activator');
        const chat = document.getElementById('chat_message_message');
        picker.on('emoji', selection => {
            const [start, end] = [chat.selectionStart, chat.selectionEnd];
            chat.value = chat.value.substring(0, start) + selection.emoji + chat.value.substring(end, chat.value.length);
        });

        trigger.addEventListener('click', () => picker.togglePicker(trigger));

    }
};