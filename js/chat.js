document.addEventListener("DOMContentLoaded", function() {
    var sendButton = document.getElementById("send-button");
    messageInput.addEventListener("input", function() {
        if (messageInput.value.trim() !== "") {
            sendButton.classList.add("active");
        } else {
            sendButton.classList.remove("active");
        }
    });
});
exampleSocket = new WebSocket("ws://172.31.232.73:2345");
var messageInput = document.getElementById("message-input");
var sendButton = document.getElementById("send-button");

sendButton.addEventListener("click", function() {
    sendMessageEvent();
});

messageInput.addEventListener("keydown", function(event) {
    if (event.key === "Enter") {
        sendMessageEvent();
    }
});

exampleSocket.onopen = function (event) {
    ShowLastMessages();
};

exampleSocket.onmessage = function (event) {
    var data = JSON.parse(event.data);
    console.log(data);
    if (data.type === "message"){
        newMessage(data.data, data.username, data.timestamp, data.id, false);
    }
    if (data.type === "auth"){
        if (data.data === "success"){
            alert("Auth success");
            setMyUsername(data.username);
            updateMessageOwner(data.username);
            var loginButton = document.getElementById("login");
            loginButton.style.display = "none";
            messageInput.focus();
        } else {
            alert("Auth failed");
        }
    }
    if (data.type === "confirm"){
        replaceMessageId(data.tempId, data.id);
    }
    
}

function login(){
    authentificate();
}

async function ShowLastMessages(){
    var data = await fetch("/messages", { method: "GET" }).then(response => response.json());
    for (var i = data.length - 1; i >= 0; i--){
        newMessage(data[i].message, data[i].username, data[i].created_at, data[i].id, false);
    }
}

function setMyUsername(username){
    usernameField = document.getElementById("myUsername");
    usernameField.innerText = username;
}

function getMyUsername(){
    return document.getElementById("myUsername").textContent;
}

function updateMessageOwner(username){
    var messages = document.getElementsByClassName("msg-box");
    for (var i = 0; i < messages.length; i++){
        var message = messages[i];
        var messageUsername = message.getElementsByClassName("username")[0].textContent;
        if (messageUsername === username){
            message.parentElement.classList.add("msg-self");
            message.parentElement.classList.remove("msg-remote");
            message.classList.remove("waiting");
        }
    }
} 

function replaceMessageId(tempId, id) {
    var message = document.getElementById(tempId);
    message.classList.remove("waiting");
    message.id = id;
}

function authentificate() {
    var username = prompt("Enter your username");
    var password = prompt("Enter your password");
    hashedPassword = CryptoJS.SHA256(password);
    hashedPassword = [hashedPassword].join('');
    var obj = {
        type: "auth",
        data: {
            username: username,
            password: hashedPassword
        }
    };
    exampleSocket.send(JSON.stringify(obj));
}

function purifyString(string) {
    return string.replace(/<[^>]+>/g, '');
}

function sendMessageEvent() {
    var message = messageInput.value.trim();
    if (message === "") {
        messageInput.value = "";
        return;
    }
    var tempId = Math.random().toString(36).substr(2, 10);
    var obj = {
        type: "message",
        data: message,
        tempId: tempId
    };
    exampleSocket.send(JSON.stringify(obj));
    newMessage(message, getMyUsername(), new Date().toISOString(), tempId, true);
    messageInput.value = "";
}

function getTimeAgo(timestamp) {
    var currentDate = new Date();
    var previousDate = new Date(timestamp);
    var timeDifference = currentDate.getTime() - previousDate.getTime();
    var seconds = Math.floor(timeDifference / 1000);
    var minutes = Math.floor(seconds / 60);
    var hours = Math.floor(minutes / 60);
    var days = Math.floor(hours / 24);
    var months = Math.floor(days / 30);
    var years = Math.floor(months / 12);

    if (years > 0) {
        return years + " year" + (years > 1 ? "s" : "") + " ago";
    } else if (months > 0) {
        return months + " month" + (months > 1 ? "s" : "") + " ago";
    } else if (days > 0) {
        return days + " day" + (days > 1 ? "s" : "") + " ago";
    } else if (hours > 0) {
        return hours + " hour" + (hours > 1 ? "s" : "") + " ago";
    } else if (minutes > 0) {
        return minutes + " minute" + (minutes > 1 ? "s" : "") + " ago";
    } else {
        return seconds + " second" + (seconds > 1 ? "s" : "") + " ago";
    }
}

function newMessage(message, username, timestamp, id, mine=false) {
    var chat = document.getElementsByClassName("chat-window").item(0);
    var messageContainer = document.createElement("article");
    messageContainer.classList.add("msg-container");
    if (mine) {
        messageContainer.classList.add("msg-self");
    } else {
        messageContainer.classList.add("msg-remote");
    }
    var timeAgo = getTimeAgo(timestamp);
    timeAgo = getTimeAgo(timestamp);
    //<img class="user-img" src="" />
    messageContainer.innerHTML = `
        <div class="msg-box waiting" id="${id}">
            <div class="flr">
                <div class="messages">
                    <p class="msg">
                        ${purifyString(message)}
                    </p>
                </div>
                <span class="timestamp"><span class="username">${purifyString(username)}</span>&bull;<span class="posttime">${timeAgo}</span></span>
                <span class="created-at">${timestamp}</span>
            </div>
        </div>
    `;
    chat.append(messageContainer);
    if (chat.offsetHeight < chat.scrollHeight && chat.scrollTop + chat.offsetHeight + 150 > chat.scrollHeight){
        chat.scrollTop = chat.scrollHeight - chat.offsetHeight;
    }
}

setInterval(function() {
    var timestamps = document.getElementsByClassName("created-at");
    var ShowedTimes = document.getElementsByClassName("posttime");
    for (var i = 0; i < timestamps.length; i++) {
        var timestamp = timestamps[i].textContent;
        var timeAgo = getTimeAgo(timestamp);
        ShowedTimes[i].textContent = timeAgo;
    }
}, 1000);