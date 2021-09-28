(function() {
   
    const _lights_canvas = document.getElementById('lights');
    const _base_canvas = document.getElementById('base');
    const _controls_canvas = document.getElementById('controls');
    const _screen_canvas = document.getElementById('screen');
    const _screen_ctx = _screen_canvas.getContext('2d');
    const _screen_container = document.getElementsByClassName('screen')[0];
    // resize the canvas to fill browser window dynamically
    window.addEventListener('resize', resizeCanvas, false);
            
    function resizeCanvas() {
        _lights_canvas.width = 1000;
        _lights_canvas.height = 1500;
        _base_canvas.width = 1000;
        _base_canvas.height = 1500;

        _controls_canvas.width = 1000;
        _controls_canvas.height = 500;
        _screen_canvas.width = 1000;
        _screen_canvas.height = 1000;
                    
        /**
         * Your drawings need to be inside this function otherwise they will be reset when 
         * you resize the browser window and the canvas goes will be cleared.
         */
        drawStuff(); 
    }
    
    resizeCanvas();
            
    function drawStuff() {
        const rive_pokedex_ui = 'assets/rive/pokedex.riv';
        const lights = new rive.Rive({
            src: rive_pokedex_ui,
            canvas: document.getElementById('lights'),
            artboard: 'lights',
            autoplay: false,
        });
        const base = new rive.Rive({
            src: rive_pokedex_ui,
            canvas: document.getElementById('base'),
            artboard: 'base',
            autoplay: false,
        });
        const screen = new rive.Rive({
            src: rive_pokedex_ui,
            canvas: document.getElementById('screen'),
            artboard: 'screen',
            autoplay: false,
        });
        const controls = new rive.Rive({
            src: rive_pokedex_ui,
            canvas: document.getElementById('controls'),
            artboard: 'controls',
            autoplay: false,
        });
        lights.layout = new rive.Layout({fit: rive.Fit.FitWidth, alignment: rive.Alignment.TopCenter});
        base.layout = new rive.Layout({fit: rive.Fit.FitWidth, alignment: rive.Alignment.BottomCenter});
    }
})();