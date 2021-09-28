// More API functions here:
// https://github.com/googlecreativelab/teachablemachine-community/tree/master/libraries/image

// the link to your model provided by Teachable Machine export panel
const URL = "assets/my_model/";
var runningCamera = false;

let model, webcam, labelContainer, maxPredictions;

// Load the image model and setup the webcam
async function init(containerId, _deviceId) {
    if (runningCamera) {
        return
    }
    const modelURL = URL + "model.json";
    const metadataURL = URL + "metadata.json";
    const container = document.getElementById(containerId)
    // load the model and metadata
    // Refer to tmImage.loadFromFiles() in the API to support files from a file picker
    // or files from your local hard drive
    // Note: the pose library adds "tmImage" object to your window (window.tmImage)
    model = await tmImage.load(modelURL, metadataURL);
    maxPredictions = model.getTotalClasses();

    // Convenience function to setup a webcam
    const flip = false; // whether to flip the webcam
    webcam = new tmImage.Webcam(container.offsetWidth, container.offsetHeight - 10, flip); // width, height, flip
    await webcam.setup({deviceId:{exact: _deviceId}}); // request access to the webcam
    await webcam.play();
    window.requestAnimationFrame(loop);

    // append elements to the DOM
    container.appendChild(webcam.canvas);
    //container.removeChild(container.childNodes[0]);
    runningCamera = true;
}

async function loop() {
    webcam.update(); // update the webcam frame
    if (Alpine.store('camera').makePrediction) {
        await predict();
    }
    window.requestAnimationFrame(loop);
}

// run the webcam image through the image model
async function predict() {
    // predict can take in an image, video or canvas html element
    const prediction = await model.predict(webcam.canvas);
    for (let i = 0; i < maxPredictions; i++) {
        const classPrediction =
            prediction[i].className + ": " + prediction[i].probability.toFixed(2);
        if (prediction[i].probability > 0.8) {
            console.log(classPrediction); 
            speak( prediction[i].className)
            Alpine.store('camera').makePrediction = false;
        }
    }
}