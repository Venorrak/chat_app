const emailRegex = new RegExp("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
async function createAccount(){
    event.preventDefault();
    var username = document.getElementById("username").value;
    var email = document.getElementById("email").value;
    var passwordField = document.getElementById("password");
    if (username === "" || email === "" || passwordField.value === ""){
    alert("Please fill in all fields");
    return;
    }
    if (!emailRegex.test(email)){
    alert("Invalid email");
    return;
    }
    var hashedPassword = CryptoJS.SHA256(passwordField.value);
    hashedPassword = [hashedPassword].join('');
    var obj = {
    username: username,
    email: email,
    password: hashedPassword
    }
    console.log(obj);
    var answer = await fetch ('/signup', {
    method: "POST",
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify(obj)
    })
    if (answer.status == 200) {
    alert("Account created");
    window.location.href = "/";
    } else {
    alert("Account creation failed : " + answer.error);
    }
}