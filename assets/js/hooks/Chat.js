import { EmojiButton } from '../emoji-picker/index'; // use own compiled until pr https://github.com/joeattardi/emoji-button/pull/106 is in emoji picker lib on npm
import twemoji from 'twemoji';

export default {
    mounted() {

        // Get chatWindow selection
        var chatWindow = document.getElementById("chat-column");
        if (chatWindow === null) chatWindow = document.querySelector('.pop-out-chat')

        // Force chat to be same height as player as vh breaks on different scaled monitors
        let chatScrollHeight = 0, chatFooterHeight = 0;
        const chatFooter = chatWindow.querySelector(".chat-footer");
        const chatScroll = chatWindow.querySelector(".chat-conversation-box");
        const videoWindow = document.getElementById("video-column") !== null ? document.getElementById("video-column").children[0] : null;

        const chatResizeFix = function () {
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
                chatResizeFixSlim()
            }
        }

        const chatResizeFixSlim = function () {
            chatScrollHeight = chatWindow.clientHeight - chatFooter.clientHeight;
            chatScroll.style.height = `${chatScrollHeight}px`;
            chatFooterHeight = chatFooter.clientHeight;
        }
        window.addEventListener('resize', chatResizeFix);

        window.dispatchEvent(new Event('resize'));

        // Remove messages if the list gets over 200 entries triggeres every ish second

        window.setInterval(() => {
            const messageList = Array.from(chatScroll.querySelectorAll(".bubble"));
            if (messageList.length > 200) {
                for (const node of messageList.slice(0, messageList.length - 200)) {
                    node.remove();
                }
            }
        }, 1000);

        // Popout handler
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

        // Emoji unparser
        function unparse(value) {
            var out = "";
            value.split("<").map(v => v.split(">")).flat().forEach(element => {
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

        // Emoji start
        // Emoji Picker Start
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

        trigger.addEventListener('click', () => picker.togglePicker(trigger));

        const pritty = document.getElementById('chat_message-pritty');
        let text = "";

        picker.on('emoji', selection => {
            var value = "";
            if (selection.custom) {
                value = pritty.innerHTML + selection.name;
            }
            else {
                value = pritty.innerHTML + selection.emoji;
            }
            text = unparse(value);
            value = twemoji.parse(text, function (iconId, options) {
                return 'https://twemoji.maxcdn.com/v/13.0.0/svg/' + iconId + '.svg';
            });
            custom.forEach(emoji => value = value.replaceAll(emoji.name, `<img class="emoji" draggable="false" src="${emoji.emoji}" alt="${emoji.name}">`));
            pritty.innerHTML = value;
        });

        pritty.oninput = (event) => {
            twemoji.replace(event.target.innerHTML, (match) => pritty.innerHTML.replace(match, twemoji.parse(match)));
            text = unparse(event.target.innerHTML);

            if (chatFooterHeight !== chatFooter.clientHeight) {
                chatResizeFixSlim()
            }
        }

        const form = document.getElementById('chat_message-form');
        const view = window.liveSocket.getViewByEl(document.getElementById("chat"));
        const chat = document.getElementById('chat_message_message');

        pritty.addEventListener('keydown', (e) => {
            if (e.key == "Enter") {
                chat.value = text;
                view.submitForm(form, form, "send");
                e.preventDefault();
            }
        })

        // Emoji Picker end

        // Twemoji parser for messages as elixir does not want to use the regex required for this parser
        const targetNode = document.getElementById("chat-messages")
        const modifyFunction = function (addedNodes) {
            for (const node of addedNodes) {
                if (!isNaN(node.id)) {
                    const message = node.querySelector(`.chat-message`);
                    if (message !== undefined) {
                        message.innerHTML = twemoji.parse(message.innerHTML, function (iconId, options) {
                            return 'https://twemoji.maxcdn.com/v/13.0.0/svg/' + iconId + '.svg';
                        });
                    }
                }
            }
            chatResizeFix();
        }
        modifyFunction(Array.from(targetNode.childNodes).filter(t => t.nodeType === 1 && t.classList.contains("bubble")));
        view.channel.on("diff", (event) => {
            setTimeout(() => {
                if (event["0"] === undefined) {
                    if (targetNode.getAttribute("phx-update")) {
                        if (event["1"]["0"] !== undefined)
                            for (const element of event["1"]["0"].d) {
                                modifyFunction([document.getElementById(element[0])])
                            }
                    }
                    else {
                        modifyFunction(Array.from(targetNode.childNodes).filter(t => t.nodeType === 1 && t.classList.contains("bubble")))
                    }
                }
                else {
                    if (event["0"] === "replace") modifyFunction(Array.from(targetNode.childNodes).filter(t => t.nodeType === 1 && t.classList.contains("bubble")))
                    else {
                        if (event["1"]["0"] !== undefined)
                            for (const element of event["1"]["0"].d) {
                                modifyFunction([document.getElementById(element[0])])
                            }
                    }
                }
            }, 1)
        });
        // Twemoji parser end

        // CSS custom saving start

        const varMap = { "chat-font-size": "--chat-size", "chat-emoji-size": "--emoji-size", "chat-avatar-size": "--avatar-size", "chat-text-color": "--chat-color", "chat-mention-color": "--chat-mention", "chat-default-color": "--chat-message-background", "chat-background": "--chat-background", "chat-edit-color": "--type-color" };

        const chatSettings = chatFooter.querySelector(".chat-settings");
        const comutedStyle = getComputedStyle(chatSettings);

        var storedVarValues = JSON.parse(window.localStorage.getItem("chat-style-values"));
        if (storedVarValues === null) {
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

        // CSS custom saving end
    }
};