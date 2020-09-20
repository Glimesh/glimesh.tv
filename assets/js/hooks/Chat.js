import { EmojiButton } from '../emoji-picker/index'; // use own compiled until pr https://github.com/joeattardi/emoji-button/pull/106 is in emoji picker lib on npm
import twemoji from 'twemoji';

export default {
    mounted() {

        const custom = [{
            name: ":glimangry",
            emoji: "./emotes/svg/glimangry.svg"
        }, {
            name: ":glimhype",
            emoji: "./emotes/svg/glimhype.svg"
        }, {
            name: ":glimlol",
            emoji: "./emotes/svg/glimlol.svg"
        }, {
            name: ":glimlove",
            emoji: "./emotes/svg/glimlove.svg"
        }, {
            name: ":glimsad",
            emoji: "./emotes/svg/glimsad.svg"
        }, {
            name: ":glimsleepy",
            emoji: "./emotes/svg/glimsleepy.svg"
        }, {
            name: ":glimsmile",
            emoji: "./emotes/svg/glimsmile.svg"
        }, {
            name: ":glimtongue",
            emoji: "./emotes/svg/glimtongue.svg"
        }, {
            name: ":glimuwu",
            emoji: "./emotes/svg/glimuwu.svg"
        }, {
            name: ":glimwink",
            emoji: "./emotes/svg/glimwink.svg"
        }, {
            name: ":glimwow",
            emoji: "./emotes/svg/glimwow.svg"
        }]

        const picker = new EmojiButton({
            theme: 'dark',
            position: 'top-start',
            autoHide: false,
            style: 'twemoji',
            emojiSize: "32px",
            emojisPerRow: "10",
            custom: custom
        });

        const trigger = document.querySelector('.emoji-activator');

        trigger.addEventListener('click', () => picker.togglePicker(trigger));

        const chat = document.getElementById('chat_message_message');
        const pritty = document.getElementById('chat_message_pritty');

        picker.on('emoji', selection => {
            const [start, end] = [chat.selectionStart, chat.selectionEnd];
            if(selection.custom){
                chat.value = chat.value.substring(0, start) + selection.name + chat.value.substring(end, chat.value.length);
            }
            else{
                chat.value = chat.value.substring(0, start) + selection.emoji + chat.value.substring(end, chat.value.length);
            }
            var value = twemoji.parse(chat.value, function(iconId, options) {
                return 'https://twemoji.maxcdn.com/v/13.0.0/svg/' + iconId + '.svg';
            });
            custom.forEach(emoji => value = value.replaceAll(emoji.name, `<img class="emoji" draggable="false" src="${emoji.emoji}" alt="${emoji.name}">`));
            pritty.innerHTML = value;
        });

        pritty.oninput = (event) => {
            twemoji.replace(event.target.innerHTML, (match) => pritty.innerHTML.replace(match, twemoji.parse(match)));
            chat.value = unparse(event.target.innerHTML);
        }

        const form = document.getElementById('chat_message-form');

        pritty.addEventListener('keydown', (e) => {
            if(e.key == "Enter"){
                var view = window.liveSocket.getViewByEl(document.getElementById("chat"))
                view.submitForm(form, form, "send");
                e.preventDefault();
            }
        })

        function unparse(value){
            var out = "";
            value.replace("<div><br></div>", "\n").split("<").map(v => v.split(">")).flat().forEach(element => {
                if(element.includes('img class="emoji" draggable="false" alt="')){
                    var index = element.indexOf('"', element.indexOf("alt")) + 1;
                    out += element.substring(index, element.indexOf('"', index));
                }
                else{
                    out += element;
                }
            });
            return out.replace(/&nbsp;/g, " ");
        }

        const targetNode = document.getElementById("chat-messages")
        const config = { childList: true }
        const modifyFunction = function(addedNodes, target){
            console.log(target)
            for(const node of addedNodes){
                if(!isNaN(node.id)){
                    const message = Array.from(target.querySelectorAll(`.chat-message`)).find(t => t.parentElement.id == node.id);
                    message.innerHTML = twemoji.parse(message.innerHTML, function(iconId, options) {
                        return 'https://twemoji.maxcdn.com/v/13.0.0/svg/' + iconId + '.svg';
                    });
                }
            }
        }
        const mutationCallback = function(mutationsList, _){
            for(const mutation of mutationsList){
                modifyFunction(mutation.addedNodes, mutation.target);
            }
        }
        const observer = new MutationObserver(mutationCallback);
        observer.observe(targetNode, config);
        modifyFunction(Array.from(targetNode.childNodes).filter(t => t.nodeType === 1 && t.classList.contains("bubble")), targetNode);
    }
};