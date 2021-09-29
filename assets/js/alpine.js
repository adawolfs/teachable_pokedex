document.addEventListener('alpine:init',() => {
    Alpine.store('devices', []);
    Alpine.store('camera', {
        selected:0,
        makePrediction:false,
        isSelected(key){
            return key == this.selected 
        },
        busy:false
    })
    Alpine.store('vr', {
        selected:0,
        pokemon:['bulbasaur','charmander'],
        isSelected(key){
            return key == this.selected 
        },
        busy:false
    })
    Alpine.store('camera_actions', {
        a(){
            if(Alpine.store('camera').busy) {
                Alpine.store('camera').makePrediction = true;
            } else {
                device = Alpine.store('devices')[Alpine.store('camera').selected]
                init('black_screen',device.deviceId)
                Alpine.store('camera').busy = true
            }
        }, 
        red(){
            if(Alpine.store('camera').busy) {
                webcam.stop()
                container = document.getElementById('black_screen')
                container.removeChild(document.getElementById('camera'))
                Alpine.store('camera').busy = false
            }
        },
        blue(){
            Alpine.store('context', {
                actions: Alpine.store('vr_actions'),
                name: 'vr',
            })
        },
        up(){
            Alpine.store('camera').selected--
            if (Alpine.store('camera').selected < 0) {
                Alpine.store('camera').selected = Alpine.store('devices').length - 1
            }
        },
        down(){
            if (Alpine.store('camera').selected < Alpine.store('devices').length) {
                Alpine.store('camera').selected++
            }
            if (Alpine.store('camera').selected >= Alpine.store('devices').length) {
                Alpine.store('camera').selected = 0
            }
        },
        left(){
            console.log('left');
        }, 
        right(){
            console.log('right');
        }
    })
    Alpine.store('vr_actions', {
        a(){
            pokemon = Alpine.store('vr').pokemon[Alpine.store('vr').selected]
            window.location.href = `vr.html?pokemon=${pokemon}`
            console.log(pokemon)
        }, 
        red(){
            Alpine.store('currentContext').red();
        },
        blue(){
            console.log('blue');
        },
        up(){
            Alpine.store('vr').selected--
            if (Alpine.store('vr').selected < 0) {
                Alpine.store('vr').selected = Alpine.store('vr').pokemon.length - 1
            }
        },
        down(){
            if (Alpine.store('vr').selected < Alpine.store('vr').pokemon.length) {
                Alpine.store('vr').selected++
            }
            if (Alpine.store('vr').selected >= Alpine.store('vr').pokemon.length) {
                Alpine.store('vr').selected = 0
            }
        },
        left(){
            console.log('left');
        }, 
        right(){
            console.log('right');
        }
    })
    Alpine.store('context', {
        actions: Alpine.store('camera_actions'),
        name: 'camera',
    })
    navigator.mediaDevices.enumerateDevices().then((devices) =>{
        console.log(devices.filter(device => device.kind === 'videoinput'));
        Alpine.store('devices', devices.filter(device => device.kind === 'videoinput'));
    });

    Alpine.store('controls', {
        a(){
            playPressA()
            Alpine.store('context').actions.a();
        }, 
        red(){
            Alpine.store('context').actions.red();
        },
        blue(){
            Alpine.store('context').actions.blue();
        },
        up(){
            Alpine.store('context').actions.up();
        },
        down(){
            Alpine.store('context').actions.down();
        },
        left(){
            console.log('left');
        }, 
        right(){
            console.log('right');
        }
    })
})