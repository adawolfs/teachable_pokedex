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
    Alpine.store('cameraContext', {
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
            console.log('red');
        },
        blue(){
            console.log('blue');
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
    navigator.mediaDevices.enumerateDevices().then((devices) =>{
        console.log(devices);
        Alpine.store('devices', devices.filter(device => device.kind === 'videoinput'));
    });

    Alpine.store('controls', {
        a(){
            Alpine.store('cameraContext').a();
        }, 
        red(){
            Alpine.store('cameraContext').red();
        },
        blue(){
            console.log('blue');
        },
        up(){
            Alpine.store('cameraContext').up();
        },
        down(){
            Alpine.store('cameraContext').down();
        },
        left(){
            console.log('left');
        }, 
        right(){
            console.log('right');
        }
    })
})