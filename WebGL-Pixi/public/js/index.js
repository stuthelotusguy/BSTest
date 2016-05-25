
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

/*
var position;
var target;
var tween, tweenBack;
*/

var stage = new PIXI.Container();
var activityIndicator = new PIXI.Container();
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
    stage.scale.x = w / 1280;
    stage.scale.y = h / 720;
}

var firstime = true;

function LoadXMLData(container, node, topnode) {

    if (container.animations == null)
    {
        container.animations = {};
    }

    if (container.sceneNodes == null)
    {
        container.sceneNodes = {};
    }

    for (var i = 0; i < node.childNodes.length; i++) {
        var child = node.childNodes[i];
        var type = child.nodeName;
        var attr = child.attributes;
        if (type == "g") {
            //group = new PIXI.Container()
            var group = new PIXI.Sprite();

            group.id = attr.id.nodeValue;
            group.width = 1280;
            group.height = 720;

            group.pivot.x = attr.ax.nodeValue;
            group.pivot.y = attr.ay.nodeValue;

            //group.anchor.x = -attr.ax.nodeValue / group.width;
            //group.anchor.y = -attr.ay.nodeValue / group.height;

            group.pivot.x = attr.ax.nodeValue / group.width;
            group.pivot.y = attr.ay.nodeValue / group.height;

            group.position.x = attr.x.nodeValue;
            group.position.y = attr.y.nodeValue;

            group.scale.x = attr.sx.nodeValue;
            group.scale.y = attr.sy.nodeValue;
            group.alpha = attr.t.nodeValue;

            container.sceneNodes[group.id] = group;

            if (attr.i != undefined) {
                if (attr.i.nodeValue == "1") {

                    group.interactive = true;
                    // use the mousedown and touchstart
                    group.mousedown = group.touchstart = function (data) {
                        this.selecting = true;
                    };

                    // set the events for when the mouse is released or a touch is released
                    group.mouseup = group.mouseupoutside = group.touchend = group.touchendoutside = function (data) {
                        if (this.selecting) {
                            console.log("Selected: ", this.id);
                        }
                        this.selecting = false;
                        // set the interaction data to null
                        this.data = null;
                        window.ws.send(this.id);
                    };

                    // set the callbacks for when the mouse or a touch moves
                    group.mousemove = group.touchmove = function (data) {
                    }
                }
            }

            topnode.addChild(group);

            LoadXMLData(container, child, group);
        } else if (type == "i") {
            var image = new PIXI.Sprite.fromImage(attr.url.nodeValue, true, 1.0);
            image.texture.baseTexture.scaleMode = PIXI.SCALE_MODES.LINEAR;

            image.id = attr.id.nodeValue;
            image.width = attr.w.nodeValue;
            image.height = attr.h.nodeValue;

            //image.anchor.x = -attr.ax.nodeValue / image.width;
            //image.anchor.y = -attr.ay.nodeValue / image.height;

            image.pivot.x = attr.ax.nodeValue / image.width;
            image.pivot.y = attr.ay.nodeValue / image.height;

            image.width = attr.w.nodeValue * attr.sx.nodeValue;
            image.height = attr.h.nodeValue * attr.sy.nodeValue;

            image.position.x = attr.x.nodeValue;
            image.position.y = attr.y.nodeValue;

            image.alpha = attr.t.nodeValue;

            if (attr.i != undefined) {
                if (attr.i.nodeValue == "1") {

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
                        //window.ws.send(this.id);                        
                    };

                    // set the callbacks for when the mouse or a touch moves
                    image.mousemove = image.touchmove = function (data) {
                    }
                }
            }

            container.sceneNodes[image.id] = image;
            topnode.addChild(image);

            firstime = false;

            //PIXI.spine();

        } else if (type == "s") {
            var graphics = new PIXI.Graphics();

            graphics.id = attr.id.nodeValue;

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

            container.sceneNodes[graphics.id] = graphics;

            graphics.alpha = attr.t.nodeValue;

            topnode.addChild(graphics);
        } else if (type == "t") {
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
            richText.id = attr.id.nodeValue;
            richText.x = attr.x.nodeValue;
            richText.y = attr.y.nodeValue;
            container.sceneNodes[richText.id] = richText;
            richText.alpha = attr.t.nodeValue;

            topnode.addChild(richText);

/*
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
                */
        }  else if (type == "a") {

            var animation = {
                id: attr.id.nodeValue,
                duration: parseFloat(attr.d.nodeValue) * 1000.0,
                repeat: attr.r.nodeValue == "1" ? true : false,
                tweens: []
            };

            console.log("loading '" + animation.id + "' animation");
            LoadXMLAnimationTracks(container, child, animation);
            container.animations[animation.id] = animation;
        }

    }
}

function LoadXMLAnimationTracks(container, node, animation) {
    for (var i = 0; i < node.childNodes.length; i++) {
        var child = node.childNodes[i];
        var type = child.nodeName;
        var attr = child.attributes;
        if (type == "at") {
            var dotPos = attr.f.nodeValue.lastIndexOf('.');
            var objectName = attr.f.nodeValue.substring(0, dotPos);
            var fieldName = attr.f.nodeValue.substring(dotPos+1);
            console.log("Loading '" + attr.f.nodeValue + "' track");
            var object = container.sceneNodes[objectName];
            if (object)
            {
                var keyframes = [];
                LoadXMLAnimationKeyframes(child, keyframes);

                if(keyframes.length > 0)
                {
                    var tweens = [];

                    for (var keyID = 1; keyID < keyframes.length; keyID++) {
                        if (fieldName == "scale") {
                            var from = {
                                slave: object, 
                                x: object.width * keyframes[keyID-1].x, 
                                y: object.height * keyframes[keyID-1].y, 
                                startX: object.width * keyframes[keyID-1].x, 
                                startY: object.height * keyframes[keyID-1].y
                            };
                            var to = {
                                x: object.width * keyframes[keyID].x, 
                                y: object.height * keyframes[keyID].y
                            }
                        }
                        else
                        {
                            var from = {
                                slave: object, 
                                x: keyframes[keyID-1].x, 
                                y: keyframes[keyID-1].y, 
                                startX: keyframes[keyID-1].x, 
                                startY: keyframes[keyID-1].y
                            };
                            var to = {
                                x: keyframes[keyID].x, 
                                y: keyframes[keyID].y
                            }
                        }

                        var duration = (animation.duration * keyframes[keyID].timePerc) - (animation.duration * keyframes[keyID-1].timePerc);
                        var tween = new TWEEN.Tween(from).to(to, duration);

                        tween.easing(TWEEN.Easing.Linear.None);

                        if (fieldName == "scaleRotateCenter") {
                            tween.onUpdate(function() {
                                this.slave.pivot.x = this.x / this.slave.width;
                                this.slave.pivot.y = this.y / this.slave.height;
                            });
                            tween.onComplete(function() {
                                this.x = this.startX;
                                this.y = this.startY;
                            });
                        } else if (fieldName == "translation") {
                            tween.onUpdate(function() {
                                this.slave.position.x = this.x;
                                this.slave.position.y = this.y;
                            });
                            tween.onComplete(function() {
                                this.x = this.startX;
                                this.y = this.startY;
                            });
                        } else if (fieldName == "scale") {
                            tween.onUpdate(function() {
                                this.slave.width = this.x;
                                this.slave.height = this.y;
                            });
                            tween.onComplete(function() {
                                this.x = this.startX;
                                this.y = this.startY;
                            });
                        } else if (fieldName == "rotation") {
                            tween.onUpdate(function() {
                                this.slave.rotation = this.x;
                            });
                            tween.onComplete(function() {
                                this.x = this.startX;
                            });
                        } else if (fieldName == "opacity") {
                            tween.onUpdate(function () {
                                this.slave.alpha = this.x;
                            });
                            tween.onComplete(function() {
                                this.x = this.startX;
                            });
                        }

                        tweens.push(tween);

                    }

                    // Chain multiple tweens together:  t1->...->tN
                    // Only applicable if we have more than one tween
                    if(tweens.length > 1)
                    {
                        for (var tweenID = 1; tweenID < tweens.length; tweenID++)
                        {
                            tweens[tweenID-1].chain(tweens[tweenID]);
                        }
                    }

                    // Repeat single or multiple tween: t1->t1 or t1->...->tN->t1
                    if(animation.repeat)
                    {
                        tweens[tweens.length-1].chain(tweens[0]);
                    }


                    // Because tweens are chained, we only need to add the first one.
                    animation.tweens.push(tweens[0]);
                }
                else
                {
                    console.log("ERROR! no keyframes found in track");
                }
            } else {
              console.log("ERROR! Could not find object named '" + objectName + "'");
            }
        }
    }
}

function LoadXMLAnimationKeyframes(node, keyframes) {
    for (var i = 0; i < node.childNodes.length; i++) {
        child = node.childNodes[i];
        var type = child.nodeName;
        var attr = child.attributes;
        if (type == "k") {
            var keyframe = {
                timePerc: parseFloat(attr.t.nodeValue),
                x: parseFloat(attr.x.nodeValue),
                y: attr.y ? parseFloat(attr.y.nodeValue) : 0.0
            }
            keyframes.push(keyframe);
        }
    }
}

function PlayAnimation(container, animationID) {
    if (container.animations[animationID])
    {
        var tweens = container.animations[animationID].tweens;
        for(var i = 0; i < tweens.length; ++i) {
            tweens[i].start();
        }
    }
    else
    {
        console.log("Unknown animation '" + animationID + "'");
    }
}

var host;
function setup() {

    OpenAndLoadXMLFile(activityIndicator, "views/ActivityIndicator.xml");

    host = "localhost";
    //host = "107.170.5.4"; // Digital Ocean "LabMediaServer" in New York
    //host = "37.139.6.121"; // Digital Ocean "LabMediaServer" in Amsterdam
    //host = "128.199.195.154"; // Digital Ocean "LabMediaServer" in Singapore
    //host = "10.0.0.111"; // MattC's PC
    //host = "10.0.0.101"; // Stu's PC 
    //host = "10.0.0.113"; // Stu's Linux VM

    /** 
     * Hack: 
     * OpenAndLoadXMLFile is asynchronous, which is why we're only starting
     * the animation asynchronously in 500ms. Otherwise, the animation would
     * not exist because it is not loaded in memory yet.
     */
    setTimeout(function() { 
        PlayAnimation(activityIndicator, "Loop_unknown_1");
        openWebSocket(host, 60000);
    }, 500);

    //window.resizeBy(1920, 1080);

}

function openWebSocket(host, port) {

    var wsImpl = window.WebSocket || window.MozWebSocket;

    // create a new websocket and connect
    window.ws = new wsImpl("ws://" + host + ':' + port);

    // when the connection is established, this method is called
    ws.onopen = OnServerConnect;

    // when the connection is closed, this method is called
    ws.onclose = OnServerDisconnect;

    // when data is comming from the server, this metod is called
    window.ws.onmessage = OnServerMessage;
}

function OnServerConnect() {
    console.log('WebSocket Connected. Sending \'start\' in just a sec...');
    PlayAnimation(activityIndicator, "Out_unknown_1");
    setTimeout(function() { 
        window.ws.send("start");
    }, 1000);
}

function OnServerDisconnect(evt) {
    console.log('WebSocket Disconnected (' + evt.code + ')');
    setTimeout(function() {
        activityIndicator.visible = true;
        openWebSocket(host, 60000);
    }, 5000);
}

function OnServerMessage(evt) {
    console.log('receive : ' + evt.data);

    if(evt.data.lastIndexOf("<?xml", 0) === 0)
    {
        var xml = jQuery.parseXML(evt.data)
        if (xml)
        {
            // Remove all children before Loading
            stage = new PIXI.Container();

            var root = xml.childNodes[0];
            scaleToFit();
            LoadXMLData(stage, root, stage);

            renderer.render(stage);
            console.log("rendered");
            animate();
        }
        else
        {
            console.log("Could not parse rendering instructions")
        }
    }
    else if (evt.data.lastIndexOf("load:", 0) === 0)
    {
        activityIndicator.visible = true;
        stage.removeChildren();
        stage = null;
        stage = new PIXI.Container();
        scaleToFit();
        OpenAndLoadXMLFile(stage, "views/" + evt.data.substring(5));
    }
    else if (evt.data.lastIndexOf("play:", 0) === 0)
    {
        if (activityIndicator.visible)
        {
            setTimeout(function() { 
                activityIndicator.visible = false;
                PlayAnimation(stage, evt.data.substring(5));
            }, 500);
        }
        else
        {
            PlayAnimation(stage, evt.data.substring(5));
        }
    }
}

function OpenAndLoadXMLFile(container, xmlFilePath) {
    console.log('Opening and loading ' + xmlFilePath)
    var req = new XMLHttpRequest();
    req.open("GET", xmlFilePath);
    req.setRequestHeader("Content-Type", "text/xml");
    req.onreadystatechange = function () {
        if (req.readyState == 4 && req.status == 200) {
            var doc = req.responseText;
            var xml = jQuery.parseXML(doc)
            var root = xml.childNodes[0];
            LoadXMLData(container, root, container);
            renderer.render(stage);
            console.log("rendered");
            animate();
        }
    };
    req.send(null);
}

/*
function update() {

    target.x = position.x;
    target.y = position.y;
    target.style.webkitTransform = 'rotate(' + Math.floor(position.rotation) + 'deg)';
    target.style.MozTransform = 'rotate(' + Math.floor(position.rotation) + 'deg)';

}
*/

function animate(time) {

    requestAnimationFrame(animate);
    renderer.render(stage);
    if (activityIndicator.visible)
    {
        renderer.render(activityIndicator);
    }

    TWEEN.update(time);
}

