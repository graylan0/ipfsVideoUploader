var keychainAuthBtnDisabled = false

function loginBtnClicked() {
    // Show popup window of login options
    document.getElementById('loginPopup').style.display = "block"
}

window.onclick = (event) => {
    dismissPopup(event,'loginPopup')
}

window.ontouchstart = (event) => {
    dismissPopup(event,'loginPopup')
}

function dismissPopup(event,popupelement) {
    let popup = document.getElementById(popupelement)
    if (event.target == popup) {
        popup.style.display = "none"
    }
}

function keychainLogin() {
    if (keychainAuthBtnDisabled == true) {
        return
    }
    let keychainLoginBtn = document.getElementById('keychainAuthBtn')
    let username = document.getElementById('loginUsername').value.toLowerCase().replace('@','')
    if (!window.steem_keychain) {
        alert('Steem Keychain is not installed!')
        return
    }
    steem_keychain.requestHandshake(() => console.log('Handshake received!'))
    keychainLoginBtn.innerText = "Logging In..."
    keychainAuthBtnDisabled = true
    axios.get('/login?user=' + username).then((response) => {
        if (response.data.error != null) {
            alert(response.data.error)
            cancelLoginBtn()
            return
        }
        steem_keychain.requestVerifyKey(username,response.data.encrypted_memo,'Posting',(loginResponse) => {
            console.log(loginResponse)
            if (loginResponse.error != null) {
                alert(loginResponse.message)
                cancelLoginBtn()
                return
            }
            let encrypted_message = loginResponse.result.substr(1)   
            let contentType = {
                headers: {
                    "content-type": "text/plain",
                },
            }

            axios.post('/logincb',encrypted_message,contentType).then((cbResponse) => {
                if (cbResponse.data.error != null) {
                    alert(cbResponse.data.error)
                    cancelLoginBtn()
                } else {
                    window.location.href = '/upload?access_token=' + cbResponse.data.access_token + '&keychain=true'
                }
            }).catch((err) => {
                alert(err)
                cancelLoginBtn()
            })
        })
    }).catch((err) => {
        alert(err)
        cancelLoginBtn()
    })
}

function cancelLoginBtn() {
    let keychainLoginBtn = document.getElementById('keychainAuthBtn')
    keychainLoginBtn.innerText = "Login with Steem Keychain"
    keychainAuthBtnDisabled = false
}