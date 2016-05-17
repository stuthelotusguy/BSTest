
var parseXml;

if (typeof window.DOMParser != "undefined") {
    parseXml = function (xmlStr) {
        return (new window.DOMParser()).parseFromString(xmlStr, "text/xml");
    };
} else if (typeof window.ActiveXObject != "undefined" &&
        new window.ActiveXObject("Microsoft.XMLDOM")) {
    parseXml = function (xmlStr) {
        var xmlDoc = new window.ActiveXObject("Microsoft.XMLDOM");
        xmlDoc.async = "false";
        xmlDoc.loadXML(xmlStr);
        return xmlDoc;
    };
} else {
    throw new Error("No XML parser found");
}

var position;
var target;
var tween, tweenBack;

var stage = new PIXI.Container();
var renderer = PIXI.autoDetectRenderer(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.view);
setup();

window.onresize = function (event) {
    scaleToFit();
}

function scaleToFit() {
    var w = window.innerWidth;
    var h = window.innerHeight;    //this part resizes the canvas but keeps ratio the same    
    renderer.view.style.width = w + "px";
    renderer.view.style.height = h + "px";
    //this part adjusts the ratio:
    renderer.resize(w, h);
    stage.scale.x = w / 1920;
    stage.scale.y = h / 1080;
}

var firstime = true;

function LoadXMLData(node, topnode) {
    for (var i = 0; i < node.childNodes.length; i++) {
        child = node.childNodes[i];
        var type = child.nodeName;
        if (type == "g") {
            attr = child.attributes;
            //group = new PIXI.Container()
            group = new PIXI.Sprite();

            group.width = 1280;
            group.height = 720;

            group.pivot.x = attr.ax.nodeValue;
            group.pivot.y = attr.ay.nodeValue;

            group.anchor.x = -attr.ax.nodeValue / group.width;
            group.anchor.y = -attr.ay.nodeValue / group.height;

            group.pivot.x = attr.ax.nodeValue / group.width;
            group.pivot.y = attr.ay.nodeValue / group.height;

            var ax = attr.ax.nodeValue;
            var ay = attr.ay.nodeValue;

            ax /= 1280;
            ay /= 720;

            group.position.x = attr.x.nodeValue;
            group.position.y = attr.y.nodeValue;

            group.scale.x = attr.sx.nodeValue;
            group.scale.y = attr.sy.nodeValue;

            topnode.addChild(group);
            LoadXMLData(child, group);
        } else if (type == "i") {
            attr = child.attributes;
            image = new PIXI.Sprite.fromImage(attr.url.nodeValue, true, 1.0);
            image.texture.baseTexture.scaleMode = PIXI.SCALE_MODES.LINEAR;

            image.id = attr.id;
            image.width = attr.w.nodeValue;
            image.height = attr.h.nodeValue;

            //image.anchor.x = -attr.ax.nodeValue / image.width;
            //image.anchor.y = -attr.ay.nodeValue / image.height;

            image.pivot.x = attr.ax.nodeValue / image.width;
            image.pivot.y = attr.ay.nodeValue / image.height;

            image.position.x = attr.x.nodeValue;
            image.position.y = attr.y.nodeValue;

            image.scale.x = attr.sx.nodeValue;
            image.scale.y = attr.sy.nodeValue;

            image.alpha = attr.t.nodeValue;

            image.interactive = true;
            // use the mousedown and touchstart
            image.mousedown = image.touchstart = function (data) {
                this.selecting = true;
            };

            // set the events for when the mouse is released or a touch is released
            image.mouseup = image.mouseupoutside = image.touchend = image.touchendoutside = function (data) {
                if (this.selecting) {
                    console.log("Selected: ", this.id);
                }
                this.selecting = false;
                // set the interaction data to null
                this.data = null;
            };

            // set the callbacks for when the mouse or a touch moves
            image.mousemove = image.touchmove = function (data) {
            }
            topnode.addChild(image);

            firstime = false;

            //PIXI.spine();

        } else if (type == "s") {
            attr = child.attributes;
            var graphics = new PIXI.Graphics();

            var color = parseInt(attr.c.nodeValue);
            alpha = color & 0xFF;
            color = color >> 8;
            drawcolor = color;
            drawcolor |= alpha << 24;

            graphics.beginFill(drawcolor);

            // set the line style to have a width of 1 and set the color
            graphics.lineStyle(1, drawcolor);

            // draw a rectangle
            graphics.drawRect(attr.x.nodeValue, attr.y.nodeValue, attr.w.nodeValue * attr.sx.nodeValue, attr.h.nodeValue * attr.sy.nodeValue);

            topnode.addChild(graphics);
        } else if (type == "t") {
            attr = child.attributes;
            var style =
            {
            };
            var pt = attr.fz.nodeValue * 0.64; //Get point from pixel?
            if (attr.fs.nodeValue == "Regular") {
                style.font = pt + "pt" + " " + attr.ff.nodeValue;
            } else {
                style.font = attr.fs.nodeValue + " " + pt + "pt" + " " + attr.ff.nodeValue;
            }
            var color = parseInt(attr.c.nodeValue);
            color = color & 0xFF0000;
            alpha = color & 0xFF;
            style.fill = 0x00ffffff & attr.c.nodeValue;
            style.fill |= alpha << 24;
            /*style.stroke = '#4a1850';
            style.strokeThickness = 5;
            style.dropShadow = true;
            style.dropShadowColor = '#000000';
            style.dropShadowAngle = Math.PI / 6;
            style.dropShadowDistance = 6;
            style.wordWrap = true;
            style.wordWrapWidth = attr.w.nodeValue;
            */
            var richText = new PIXI.Text(attr.ft.nodeValue, style);
            richText.id = attr.ft.nodeValue;
            richText.x = attr.x.nodeValue;
            richText.y = attr.y.nodeValue;
            topnode.addChild(richText);

            position = { x: richText.x, y: richText.y, rotation: 0 };
            target = richText;
            var x = parseFloat(richText.x);
            var y = parseFloat(richText.y);

                tween = new TWEEN.Tween(position)
					.to({ x: x + 100, y: y + 100, rotation: 359 }, 2000)
                    .easing(TWEEN.Easing.Linear.None)
					.onUpdate(update);

                tweenBack = new TWEEN.Tween(position)
					.to({ x: x, y: y, rotation: 0 }, 3000)
					.easing(TWEEN.Easing.Linear.None)
					.onUpdate(update);

                tween.chain(tweenBack);
                tweenBack.chain(tween);

                tween.start();
        }
    }
}

function setup() {

    var host = "ws://localhost:54323"
    //var host = "107.170.5.4"; // Digital Ocean "LabMediaServer" in New York
    //var host = "37.139.6.121"; // Digital Ocean "LabMediaServer" in Amsterdam
    //var host = "128.199.195.154"; // Digital Ocean "LabMediaServer" in Singapore
    //var host = "10.0.0.111"; // MattC's PC
    //var host = "ws://10.0.0.100"; // Stu's PC 
    //var host = "10.0.0.112"; // Stu's Linux VM

    openSocket(host);

    //window.resizeBy(1920, 1080);

    //ServerMessage(host, "Server/Lander.xml");
}

function openSocket(host) {

    var wsImpl = window.WebSocket || window.MozWebSocket;

    // create a new websocket and connect
    window.ws = new wsImpl(host);

    // when the connection is established, this method is called
    ws.onopen = OnServerConnect;

    // when the connection is closed, this method is called
    ws.onclose = OnServerDisconnect;

    // Log errors
    window.ws.onerror = OnServerError;

    // when data is comming from the server, this metod is called
    window.ws.onmessage = OnServerMessage;
}

function OnServerConnect() {
    console.log('WebSocket Connected. Sending \'start\'');
    window.ws.send("start");
}

function OnServerDisconnect() {
    console.log('WebSocket Disconnected');
}

function OnServerError(error) {
    console.log('WebSocket Error ' + error);
}

function OnServerMessage(evt) {
    console.log('receive server rendering instruction. parsing...');
    //console.log(evt.data);
    
    var xml = jQuery.parseXML(evt.data)
    if (xml)
    {
        // Remove all children before Loading
        stage.removeChildren();

        var root = xml.childNodes[0];
        LoadXMLData(root, stage);

        renderer.render(stage);
        console.log("rendered");
        animate();
    }
    else
    {
        console.log("Could not parse rendering instructions")
    }
}

function ServerMessage(host, msg) {
    var x = new XMLHttpRequest();
    x.open("GET", "http://" + host + "/" + msg, true);
    x.onreadystatechange = function () {
        if (x.readyState == 4 && x.status == 200) {
            var doc = x.responseText;
            //var xml = parseXml(doc);
            //var xml = parseXml(TestXML);

            var xml = jQuery.parseXML(doc)

            var root = xml.childNodes[0];
            LoadXMLData(root, stage);

            renderer.render(stage);
            console.log("rendered");
            animate();
        }
    };
    x.send(null);
}

function update() {

    target.x = position.x;
    target.y = position.y;
    target.style.webkitTransform = 'rotate(' + Math.floor(position.rotation) + 'deg)';
    target.style.MozTransform = 'rotate(' + Math.floor(position.rotation) + 'deg)';

}

function animate(time) {

    requestAnimationFrame(animate);
    renderer.render(stage);

    TWEEN.update(time);

}

