import { EmojiButton } from '../emoji-picker/index'; // use own compiled until pr https://github.com/joeattardi/emoji-button/pull/106 is in emoji picker lib on npm
import twemoji from 'twemoji';

export default {
    mounted() {

        const custom = [{
            name: ":glimangry",
            emoji: "/emotes/svg/glimangry.svg"
        }, {
            name: ":glimhype",
            emoji: "/emotes/svg/glimhype.svg"
        }, {
            name: ":glimlol",
            emoji: "/emotes/svg/glimlol.svg"
        }, {
            name: ":glimlove",
            emoji: "/emotes/svg/glimlove.svg"
        }, {
            name: ":glimsad",
            emoji: "/emotes/svg/glimsad.svg"
        }, {
            name: ":glimsleepy",
            emoji: "/emotes/svg/glimsleepy.svg"
        }, {
            name: ":glimsmile",
            emoji: "/emotes/svg/glimsmile.svg"
        }, {
            name: ":glimtongue",
            emoji: "/emotes/svg/glimtongue.svg"
        }, {
            name: ":glimuwu",
            emoji: "/emotes/svg/glimuwu.svg"
        }, {
            name: ":glimwink",
            emoji: "/emotes/svg/glimwink.svg"
        }, {
            name: ":glimwow",
            emoji: "/emotes/svg/glimwow.svg"
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
        var chatWindow = document.getElementById("chat-column");
        if (chatWindow === null) chatWindow = document.querySelector('.pop-out-chat')
        const popout = chatWindow.querySelector('.pop-out');

        if (window.location.href.split("/").length > 4) {
            popout.remove();
        }
        else {
            popout.style.display = "block";
            popout.addEventListener('click', (e) => {
                e.preventDefault();
                window.open(window.location.href + "/chat", "_blank", "location=no,menubar=no,toolbar=no");
            });
        }

        trigger.addEventListener('click', () => picker.togglePicker(trigger));

        const chat = document.getElementById('chat_message_message');
        const pritty = document.getElementById('chat_message-pritty');

        picker.on('emoji', selection => {
            var value = "";
            if (selection.custom) {
                value = pritty.innerHTML + selection.name;
            }
            else {
                value = pritty.innerHTML + selection.emoji;
            }
            value = twemoji.parse(value, function (iconId, options) {
                return 'https://twemoji.maxcdn.com/v/13.0.0/svg/' + iconId + '.svg';
            });
            custom.forEach(emoji => value = value.replaceAll(emoji.name, `<img class="emoji" draggable="false" src="${emoji.emoji}" alt="${emoji.name}">`));
            pritty.innerHTML = value;
        });

        const chatFooter = chatWindow.querySelector(".chat-footer");
        const chatScroll = chatWindow.querySelector(".chat-conversation-box");
        const videoWindow = document.getElementById("video-column") !== null ? document.getElementById("video-column").children[0] : null;
        let scrollY = 0;
        let chatScrollY = 0;
        let chatScrollSize = 0;
        let chatScrollHeight = 0;
        let text = "";
        let chatFooterHeight = 0;

        chatScroll.addEventListener('scroll', (e) => {
            chatScrollY = e.target.scrollTop;
            chatScrollSize = e.target.scrollHeight;
        });

        pritty.oninput = (event) => {
            twemoji.replace(event.target.innerHTML, (match) => pritty.innerHTML.replace(match, twemoji.parse(match)));
            text = unparse(event.target.innerHTML);

            if (chatFooterHeight !== chatFooter.clientHeight && videoWindow !== null) {
                chatScrollHeight = chatScroll.clientHeight - chatFooter.clientHeight;
                chatScroll.style.height = `${chatScrollHeight}px`;
                chatFooterHeight = chatFooter.clientHeight;
            }
            else {
                chatScrollHeight = chatWindow.clientHeight - chatFooter.clientHeight;
                chatScroll.style.height = `${chatScrollHeight}px`;
                chatFooterHeight = chatFooter.clientHeight;
            }
            window.scroll(0, scrollY);
        }

        const form = document.getElementById('chat_message-form');

        pritty.addEventListener('keydown', (e) => {
            if (e.key == "Enter") {
                chat.value = text;
                var view = window.liveSocket.getViewByEl(document.getElementById("chat"))
                view.submitForm(form, form, "send");
                e.preventDefault();
            }
        })

        function unparse(value) {
            var out = "";
            value.replace("<div><br></div>", "\n").split("<").map(v => v.split(">")).flat().forEach(element => {
                if (element.includes('img class="emoji" draggable="false" alt="')) {
                    var index = element.indexOf('"', element.indexOf("alt")) + 1;
                    out += element.substring(index, element.indexOf('"', index));
                }
                else {
                    out += element;
                }
            });
            return out.replace(/&nbsp;/g, " ");
        }

        const targetNode = document.getElementById("chat-messages")
        const config = { childList: true }
        const modifyFunction = function (addedNodes, _) {
            for (const node of addedNodes) {
                if (!isNaN(node.id)) {
                    const message = node.querySelector(`.chat-message`);
                    if (message !== undefined) {
                        console.log(message.innerHTML);
                        message.innerHTML = twemoji.parse(message.innerHTML, function (iconId, options) {
                            return 'https://twemoji.maxcdn.com/v/13.0.0/svg/' + iconId + '.svg';
                        });
                    }
                }
            }
            if (chatScrollSize - chatScrollHeight - chatScrollY < 10) {
                chatScroll.scroll(0, chatScroll.scrollHeight);
            }
            if (videoWindow !== null) {
                const height = videoWindow.clientHeight;
                chatWindow.style.height = `${height + 30}px`;
                chatScrollHeight = height - chatFooter.clientHeight;
                chatScroll.style.height = `${chatScrollHeight}px`;
                if (chatFooterHeight !== chatFooter.clientHeight) {
                    chatFooterHeight = chatFooter.clientHeight;
                }
            }
            else {
                chatScrollHeight = chatWindow.clientHeight - chatFooter.clientHeight;
                chatScroll.style.height = `${chatScrollHeight}px`;
                chatFooterHeight = chatFooter.clientHeight;
            }
            chatScrollSize = chatScroll.scrollHeight;
        }
        const mutationCallback = function (mutationsList, e) {
            for (const mutation of mutationsList) {
                modifyFunction(mutation.addedNodes, mutation.target);
            }
        }
        const observer = new MutationObserver(mutationCallback);
        observer.observe(targetNode, config);
        modifyFunction(Array.from(targetNode.childNodes).filter(t => t.nodeType === 1 && t.classList.contains("bubble")), targetNode);

        window.addEventListener('resize', () => {
            if (videoWindow !== null) {
                const height = videoWindow.clientHeight;
                chatWindow.style.height = `${height + 30}px`;
                chatScrollHeight = height - chatFooter.clientHeight;
                chatScroll.style.height = `${chatScrollHeight}px`;
                if (chatFooterHeight !== chatFooter.clientHeight) {
                    chatFooterHeight = chatFooter.clientHeight;
                }
            }
            else {
                chatScrollHeight = chatWindow.clientHeight - chatFooter.clientHeight;
                chatScroll.style.height = `${chatScrollHeight}px`;
                chatFooterHeight = chatFooter.clientHeight;
            }
        });

        window.addEventListener('scroll', (e) => {
            scrollY = window.scrollY;
        });

        window.dispatchEvent(new Event('resize'));

        window.setInterval(() => {
            const messageList = Array.from(chatScroll.querySelectorAll(".bubble"));
            if (messageList.length > 200) {
                for (const node of messageList.slice(0, messageList.length - 200)) {
                    node.remove();
                }
            }
        }, 1000);

        const varMap = { "chat-font-size": "--chat-size", "chat-emoji-size": "--emoji-size", "chat-avatar-size": "--avatar-size", "chat-text-color": "--chat-color", "chat-mention-color": "--chat-mention", "chat-default-color": "--chat-message-background", "chat-background": "--chat-background", "chat-edit-color": "--type-color" };

        const chatSettings = chatFooter.querySelector(".chat-settings");
        const comutedStyle = getComputedStyle(chatSettings);

        var storedVarValues = JSON.parse(window.localStorage.getItem("chat-style-values"));
        if(storedVarValues === null){
            storedVarValues = {};
        }

        for (const setting of chatSettings.querySelectorAll("input")) {
            const varId = varMap[setting.id];
            var varValue = comutedStyle.getPropertyValue(varId);
            if (storedVarValues[varId] !== undefined) {
                varValue = storedVarValues[varId];
            }
            setting.value = storedVarValues[varId] = varValue;
            chatWindow.style.setProperty(varId, setting.value);
            setting.addEventListener('keydown', (e) => {
                if (e.key == "Enter") {
                    chatWindow.style.setProperty(varId, setting.value);
                    storedVarValues[varId] = setting.value;
                    window.localStorage.setItem("chat-style-values", JSON.stringify(storedVarValues));
                    e.preventDefault();
                }
            });
            window.localStorage.setItem("chat-style-values", JSON.stringify(storedVarValues));
        }

        let settingsOpen = false;

        chatWindow.addEventListener('click', (e) => {
            if (e.path.some(f => f.classList !== undefined && (f.classList.contains("chat-settings") || f.classList.contains("settings")))) {
                if (!settingsOpen) {
                    chatSettings.style.display = "block";
                    settingsOpen = !settingsOpen;
                }
                else if (e.path.some(f => f.classList.contains("settings"))) {
                    chatSettings.style.display = "none";
                    settingsOpen = !settingsOpen;
                }
            }
            else if (settingsOpen) {
                chatSettings.style.display = "none";
                settingsOpen = !settingsOpen;
            }
        })
    }
};