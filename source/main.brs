'********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
sub Main()
    showChannelSGScreen()
end sub

function GetTimestamp() as String
    ti = CreateObject ("roDateTime")
    return left(ti.ToISOString(), 19) + "." + right("000" + ti.getMilliseconds().toStr(), 3) + "Z: "
end function

function TryToConnect() as Boolean

    ClearExistingScreens()
    wait_connect = m.scene.findNode("wait_connect")
    if wait_connect <> invalid
        wait_connect.visible = 1
    end if

tryagain:
    if(m.buffer <> invalid)
        m.buffer = invalid
    end if
    m.buffer = CreateObject("roByteArray")
    m.buffer[65536] = 0 ' 64KB
    m.bufferSize = 0
    if(m.tcpServer <> invalid)
        m.tcpServer.close()
        for each id in m.connections
            m.connections[id].close()
        end for
        m.tcpServer = invalid
    end if
    if(m.tcpClient <> invalid)
        m.tcpClient.close()
        m.tcpClient = invalid
    end if
    m.connections = {}
    m.tcpServer = CreateObject("roStreamSocket")
    m.tcpServer.setMessagePort(m.port) 'notifications for tcp come to msgPort
    addr = createobject("roSocketAddress")
    addr.setPort(54321)
    m.tcpServer.setAddress(addr)
    m.tcpServer.notifyReadable(true)
    m.tcpServer.listen(4)
    continue = m.tcpServer.eOK()
    
    m.sendAddr = createobject("roSocketAddress")
    m.sendAddr.SetAddress("107.170.5.4:54322") ' Digital Ocean "LabMediaServer" (New York)
    'm.sendAddr.SetAddress("37.139.6.121:54322") ' Digital Ocean "Amsterdam"
    'm.sendAddr.SetAddress("10.1.0.110:54322") ' MattC's PC
    'm.sendAddr.SetAddress("10.0.0.100:54322") ' Stu's PC
    m.tcpClient =  CreateObject("roStreamSocket")
    m.tcpClient.setMessagePort(m.port) 'notifications for tcp come to msgPort
    m.tcpClient.setSendToAddress(m.sendAddr)
    m.tcpClient.notifyReadable(true)

    m.tcpClient.Connect()
    
    if not continue
        print "Error creating listen socket"
        sleep(1000)
        goto tryagain
    end if

    Sleep(250)

    byteSent = m.tcpClient.SendStr("getnav")
    if (byteSent > 0)
        print "TCP CLIENT - Sent 'getnav' request to " m.sendAddr.GetAddress()
    else
        print "TCP CLIENT - No connection to " m.sendAddr.GetAddress()
        sleep(1000)
        goto tryagain
    end if

    wait_connect = m.scene.findNode("wait_connect")
    if wait_connect <> invalid
        wait_connect.visible = 0
    end if
    return continue
end function

sub showChannelSGScreen()
    m.screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    m.screen.setMessagePort(m.port)

    m.scene = m.screen.CreateScene("Roku_Youi_Scene")
    m.screen.show()

    m.global = m.screen.getGlobalNode()
    m.global.id = "GlobalNode"
    m.global.addFields( {key : "none", keyEventCount : 0, firstPress : false} )
    m.global.addFields( {groups : 0, images : 0, solids : 0, text : 0, animations : 0, tracks : 0, keys : 0 } )
    m.global.key = "none"
    m.global.keyEventCount = 0
    m.global.firstPress = false

    m.global.ObserveField("key","changetext")
    'm.global.setMessagePort(m.port)
    'm.global.control = "start"

    timeout = 16 ' in milliseconds

    continue = TryToConnect()

    While continue
        event = m.port.waitMessage(timeout)
        'event = m.port.GetMessage() ' get a message, if available
        'print GetTimestamp() + " " + m.global.key
        if m.global.key <> "none"
            key = invalid
            if(m.global.keyEventCount > 0 and m.global.keyEventCount < 3) ' dont process the key for the next ~500ms after the first key press 
                m.global.keyEventCount = m.global.keyEventCount + 1
            else
                key = m.global.key
                if (m.global.keyEventCount = 0)
                    m.global.keyEventCount = 1
                end if
            end if
            if(key <> invalid)  'Roku 1 crashed with this error. Not seen otherwise.
                'print GetTimestamp() + "key is :" key
                if(m.currentNavigation = invalid)
                    m.currentNavigation = m.navigation[0]
                    if(m.currentNavigation.FocusInAnim <> invalid)
                        m.currentNavigation.FocusInAnim.control = "start"
                    end if
                else
                    for each keymap in m.currentNavigation.keymap
                        if keymap.key = key
                        
                            if (keymap.target <> invalid)
                        
                                if(m.currentNavigation.focusInAnim <> invalid)
                                    m.currentNavigation.focusInAnim.control = "finish"
                                end if
                                if(m.currentNavigation.focusOutAnim <> invalid)
                                    m.currentNavigation.focusOutAnim.control = "start"
                                end if

                                if (m.navListRoot <> invalid and key = "right")
                                    if (m.global.keyEventCount >= 3)
                                        if(m.currentNavigation.scrollLeftLinearAnim <> invalid and m.currentNavigation.scrollLeftLinearAnim.state = "stopped")
                                            m.currentNavigation.scrollLeftLinearAnim.control = "start"
                                        end if
                                    else
                                        if(m.currentNavigation.scrollLeftAnim <> invalid)
                                            m.currentNavigation.scrollLeftAnim.control = "start"
                                        end if
                                    end if
                                endif

                                ' Switch navigation node
                                m.currentNavigation = m.navigation[keymap.target]

                                if (m.navListRoot <> invalid and key = "left")
                                    if (m.global.keyEventCount >= 3)
                                        if(m.currentNavigation.scrollRightLinearAnim <> invalid  and m.currentNavigation.scrollRightLinearAnim.state = "stopped")
                                            m.currentNavigation.scrollRightLinearAnim.control = "start"
                                        end if
                                    else
                                        if(m.currentNavigation.scrollRightAnim <> invalid)
                                            m.currentNavigation.scrollRightAnim.control = "start"
                                        end if
                                    end if
                                endif

                                if(m.currentNavigation.focusInAnim <> invalid)
                                    m.currentNavigation.focusInAnim.control = "start"
                                end if
                            end if
                            
                            ' MattC Hack: crappy snappy page scroll
                            'if (m.navListRoot <> invalid)
                            '    if(key = "right")
                            '        m.countX = m.countX + 1
                            '        if (m.countX MOD 6 = 0)
                            '            m.navListRoot.translation = [m.navListRoot.translation[0] - 1080, m.navListRoot.translation[1]]
                            '        end if
                            '    else if(key = "left")
                            '        if (m.countX MOD 6 = 0)
                            '            m.navListRoot.translation = [m.navListRoot.translation[0] + 1080, m.navListRoot.translation[1]]
                            '        end if
                            '        m.countX = m.countX - 1
                            '    end if
                            'end if
                            
                            
                            goto keymapLoopBreak
                        end if
                    end for
keymapLoopBreak:
                    if(m.global.firstPress)
                        byteSent = m.tcpClient.SendStr(key)
                        m.global.firstPress = false
                        if (byteSent > 0)
                            print GetTimestamp() + "TCP CLIENT - Sent key '" key "' to " m.sendAddr.GetAddress()
                        else
                            print GetTimestamp() + "TCP CLIENT - No connection to " m.sendAddr.GetAddress() ". Switching screen locally."
                            if (key = "ok" or key = "back")
                                continue = TryToConnect()
                            end if
                        end if
                    end if
                end if
            end if
        end if

        if type(event) = "roUniversalControlEvent" then
            print "button pressed: ";event.GetInt()

        else if type(event)="roSocketEvent"
            changeID = event.getSocketID()
            if changeID = m.tcpClient.getID()
                closed = False
                if m.tcpClient.isReadable()
                    received = m.tcpClient.receive(m.buffer, m.bufferSize, 65536)
                    if (received > 0)
                        print "TCP CLIENT - received " received.toStr() + " bytes from " + m.sendAddr.getAddress()
                        m.bufferSize = m.bufferSize + received

                        if m.bufferSize > 0 and m.buffer[m.bufferSize-1] = 0 ' MattC Hack: we use the null char delimits the 'end of transmission' 
                            if (m.buffer[0] = 123) ' 123 is the '{' char, which is a JSON object
                                ParseBRSJSON()
                            else if (m.buffer[0] = 60) ' 60 os the '<' char, which is an XML object
                                ParseBRSXML()
                            else
                                ProcessCommand(m.buffer.ToAsciiString())
                            end if
                            m.bufferSize = 0 ' we consumed the m.buffer
                        end if
                    else
                        closed = true
                    end if
                end if
                if closed and not m.tcpClient.eOK()
                    print "TCP CLIENT - closing connection to " m.sendAddr.getAddress()
                    m.tcpClient.close()
                    continue = TryToConnect()
                end if
            else if changeID = m.tcpServer.getID() and m.tcpServer.isReadable()
                ' New
                newConnection = m.tcpServer.accept()
                if newConnection = Invalid
                    print "accept failed"
                else
                    print "accepted new connection ID" newConnection.getID()
                    newConnection.notifyReadable(true)
                    newConnection.setMessagePort(m.port)
                    m.connections[Stri(newConnection.getID())] = newConnection
                end if
            else
                ' Activity on an open connection
                connection = m.connections[Stri(changeID)]
                if connection <> invalid
                    closed = False
                    if connection.isReadable()
                        received = connection.receive(m.buffer, m.bufferSize, 65536)
                        print "received chunk :" received
                        m.bufferSize = m.bufferSize + received
                        if received = 0 'client closed
                            closed = true
                        end if
                    end if
                    if closed or not connection.eOK()
                        print "closing connection ID" changeID
                        connection.close()
                        m.connections.delete(Stri(changeID))
                        if (m.bufferSize > 0)
                            print "total byte received : " m.bufferSize
                            if (m.buffer[0] = 123) ' 123 is the '{' char
                                ParseBRSJSON()
                            else
                                ParseBRSXML()
                            endif
                            m.bufferSize = 0 ' we consumed the m.buffer
                        end if
                    end if
                end if
            end if
        else if type(event) = "roSGScreenEvent"
            if event.isScreenClosed() then return
        else if type(event) = "roVideoScreenEvent"
            if event.isScreenClosed()
                if m.tcpClient <> invalid
                    m.tcpClient.SendStr("back")
                end if
            end if
        end if
    end while

    m.tcpServer.close()
    for each id in m.connections
        m.connections[id].close()
    end for

end sub

sub ClearExistingScreens()
    if m.scene <> invalid
        count = m.scene.getChildCount()
        while count > 2 'Our "wait_connect and master node"
            print "removing scene" + StrI(count)
            print m.scene.getChild(count - 1).id
            m.scene.removeChildIndex(count - 1)
            count = m.scene.getChildCount()
        end while
    end if
    m.scene.getChild(1).visible = 1
end sub

sub ProcessCommand(command as String)

    m.video = invalid

    com =  left(command, 4)
    name = right(command, len(command) - 5)
    if com = "load"
        ClearExistingScreens()
        print "creating scene"

        m.lib = createObject("RoSGNode","ComponentLibrary")
        m.lib.id="BSTestLib"
        if left(name, 4) = "file"
            m.lib.uri=name
        else
            m.lib.uri="http://107.170.5.4/images/" + name
        end if
        print m.lib.loadStatus +" " + m.lib.uri
        while m.lib.loadStatus = "loading"
            print m.lib.loadStatus '+" " + m.lib.uri
        end while
            print m.lib.loadStatus

        content = CreateObject("roSGNode", "MainScreen")

        content.AppendChild(m.lib)

        if (name="Lander.pkg")
            ' MattC Hack: cache all of the navigation animation nodes for the screen.
            print GetTimestamp() + "Caching Lander.pkg Animation started..."
            for each nav in m.navigation
                anim = content.findNode(nav.focusIn)
                if(anim = invalid)
                    'print "animation " + nav.focusIn + " was not found."
                else
                    nav.focusInAnim = anim
                end if
                
                anim = content.findNode(nav.focusOut)
                if(anim = invalid)
                    'print "animation " + nav.focusOut + " was not found."
                else
                    nav.focusOutAnim = anim
                end if
                
                anim = content.findNode(nav.scrollLeft)
                if(anim = invalid)
                    'print "animation " + nav.scrollLeft + " was not found."
                else
                    nav.scrollLeftAnim = anim
                end if
                
                anim = content.findNode(nav.scrollRight)
                if(anim = invalid)
                    'print "animation " + nav.scrollRight + " was not found."
                else
                    nav.scrollRightAnim = anim
                end if
                
                anim = content.findNode(nav.scrollLeftLinear)
                if(anim = invalid)
                    'print "animation " + nav.scrollLeftLinear + " was not found."
                else
                    nav.scrollLeftLinearAnim = anim
                end if
                
                anim = content.findNode(nav.scrollRightLinear)
                if(anim = invalid)
                    'print "animation " + nav.scrollRightLinear + " was not found."
                else
                    nav.scrollRightLinearAnim = anim
                end if
                
            end for
            print GetTimestamp() + "Caching Lander.pkg Animation ended."
            
            ' MattC Hack: cache the list root for
            m.navListRoot = content.findNode("ListRoot_8")
            m.countX = 1 ' we start at 1 because the large BigBuckBunny is 2 posters wide.
        else
            for each nav in m.navigation
                nav.focusInAnim = invalid
                nav.focusOutAnim = invalid
            end for
            m.navListRoot = invalid
            m.currentNavigation = invalid
        end if
        
        m.scene.AppendChild(content)

        content.focusable = true
        content.setFocus(true)
        
    else if com = "play"
        if(left(name, 5) = "Focus")
            print "Ignoring '" + command + "' command"
        else
            print "playing '" + name + "'"
            anim = m.scene.findNode(name) 
            'stop
            if(anim <> invalid)
                anim.control = "start"
                dur = 100 + anim.duration * 1000
                'print dur
                'Sleep(dur * 3)
            else
                print "Not found"
            end if
        end if
    else if com = "pvid"
        print "playing video: " name
        videoclip = CreateObject("roAssociativeArray")
        videoclip.StreamBitrates = [0]
        videoclip.StreamUrls = name
        videoclip.StreamQualities = ["HD"]
        videoclip.StreamFormat = "hls"
        m.video = CreateObject("roVideoScreen")
        m.video.setMessagePort(m.port)
        m.video.SetContent(videoclip)
        m.video.show()
        
    end if
    
    if m.tcpClient <> invalid
        print GetTimestamp() + "Sending ACK"
        m.tcpClient.SendStr("ACK")
    end if

end sub

sub ParseBRSJSON()
    json = ParseJSON(m.buffer.ToAsciiString())
    if (json <> invalid)
        if(json.nav <> invalid)
            print "Navigation data parsed."
            m.navigation = json.nav
            m.tcpClient.SendStr("start") ' HACK MattC
        else
            print "Unknown json data"
        end if
    else
        print "Invalid json format."
    end if
end sub
  
sub ParseBRSXML()

    ClearExistingScreens()
    wait_connect = m.scene.findNode("wait_connect")
    if wait_connect <> invalid
        wait_connect.visible = 1
        wait_connect.setFocus(true)
    end if

    startTime = CreateObject("roDateTime")
    contentxml = createObject("roXMLElement")
    contentxml.parse(m.buffer.ToAsciiString())
    if contentxml.getName()="sc"
        content = createObject("RoSGNode","Poster")
        content.id = "Youi"
        content.focusable = true
        print "getContent: scene found"
        body = contentxml.GetBody()
        etype = lcase(type(body))
        if etype = "roxmllist"

            ClearExistingScreens()

            CreateSG(body, content)

            print "Loaded: "
            print "groups" m.global.groups 
            print "images" m.global.images 
            print "solids" m.global.solids 
            print "text" m.global.text 
            print "animations" m.global.animations 
            print "tracks" m.global.tracks 
            print "keys" m.global.keys

            m.global.groups  = 0
            m.global.images   = 0
            m.global.solids   = 0
            m.global.text   = 0
            m.global.animations  = 0 
            m.global.tracks   = 0
            m.global.keys  = 0
                                
            print "creating scene"
            m.scene.AppendChild(content)
            content.setFocus(true)

            'stop

            content.observeField("roSGNodeEvent", m.port)

            anim = content.findNode("Repeat_Logo_Animation_60")
            if(anim <> invalid)
                print "starting animation " anim.id
                intr = anim.getchild(0)
                print "Interpolating on " intr.fieldToInterp
                print "keys " intr.key
                print "keyvalue " intr.keyvalue
                parent = anim.getParent()
                while parent <> invalid
                    print "Parent " parent.id
                    parent = parent.getParent()
                end while
                anim.control = "start"
            end if
                                
        end if
    else
        print "getContent: scene NOT found. Must start with <sc>"
    end If
    endTime = CreateObject("roDateTime")
    totalTime = endTime.AsSeconds() - startTime.AsSeconds()
    print "Total time (in second):" totalTime
end sub

sub CreateSG(xml as Object, node as Object)
    namenum = 0

    for each elem in xml
        elemname = elem.GetName()
        if(elemname="g")
            m.global.groups = m.global.groups + 1
            attributes = elem.getAttributes()
            'if(left(attributes.id, 8) = "ListRoot")
            '    print "Found list node!"
            '    item = node.createChild("RowList")
	        '    item.numRows = 1
	        '    item.itemSize = [200, 200]
	        '    item.rowHeights = [200]
	        '    item.rowFocusAnimationStyle = "floatingFocus"
	        '    item.visible = true
            'else
                item = node.createChild("Group")
            'end if
            item.id = attributes.id
            item.rotation = attributes.rz
            item.opacity = attributes.t
            item.scaleRotateCenter = [Val(attributes.ax), Val(attributes.ay)]
            item.translation = [Val(attributes.x), Val(attributes.y)]
            item.scale = [Val(attributes.sx), Val(attributes.sy)]
            'item.visible = Val(attributes.v)
            PrintoutOfItem(item)
        else if(elemname="i")
            m.global.images = m.global.images + 1
            namenum = namenum + 1
            attributes = elem.getAttributes()
            item = node.createChild("Poster")
            item.rotation = attributes.rz
            item.opacity = attributes.t
            item.scaleRotateCenter = [Val(attributes.ax), Val(attributes.ay)]
            item.translation = [Val(attributes.x), Val(attributes.y)]
            item.scale = [Val(attributes.sx), Val(attributes.sy)]
            item.width = Val(attributes.w)
            item.height = Val(attributes.h)
            item.focusable = true
            item.loadDisplayMode = "scaleToFill"
            'item.visible = Val(attributes.v)
            item.uri = attributes.url
            if(attributes.url <> invalid)
                name = Left(attributes.url, 4)
                lname = lcase(name)
                if lname <> "http"
                    'BrS issue: Images do not seem to work from local files which means they must be hosted.'
                    'newuri = "pkg:/assets/drawable/default/" + attributes.url
                    newuri = "http://107.170.5.4/images/" + attributes.url
                    item.uri = newuri
                end if
            else
                'item.uri = "pkg:/assets/drawable/default/Placeholder16x9.png"
                item.uri = "http://107.170.5.4/images/Placeholder16x9.png"
            End if
            if(attributes.id <> invalid)
                item.id = attributes.id
            else
                numstring = StrI(namenum)
                item.id = "image" + numstring.trim()
                print "Null image name found, using " + item.id
            end if
            if (attributes.url = "Logo-Small-Outline.png")
                'Create for animation tests
                anim = item.createChild("Animation")
                anim.id = "AnimationTestNode"
                anim.duration="3"
                anim.repeat="true"
                anim.easeFunction="linear"
                fi = anim.createChild("FloatFieldInterpolator")
                fi.id = "myInterp"
                fi.key="[0.0, 0.50, 0.75, 1.0]"
                fi.keyValue="[0.0, 0.50, 0.75, 1.0]"
                fi.fieldToInterp = item.id + ".opacity"
                print "Animation is on " + fi.fieldToInterp
            end if
            PrintoutOfItem(item)
        else if(elemname="s")
            m.global.solids = m.global.solids + 1
            attributes = elem.getAttributes()
            item = node.createChild("Rectangle")
            item.color = attributes.c
            item.id = attributes.id
            item.rotation = attributes.rz
            item.opacity = attributes.t
            item.scaleRotateCenter = [Val(attributes.ax), Val(attributes.ay)]
            item.translation = [Val(attributes.x), Val(attributes.y)]
            item.scale = [Val(attributes.sx), Val(attributes.sy)]
            item.width = Val(attributes.w)
            item.height = Val(attributes.h)
            'item.visible = Val(attributes.v)
            PrintoutOfItem(item)
        else if(elemname="t")
            m.global.text = m.global.text + 1
            attributes = elem.getAttributes()
            item = node.createChild("Label")
            item.color = attributes.c
            item.text = attributes.ft
            'item.visible = Val(attributes.v)
            font  = CreateObject("roSGNode", "Font")

            'BrS issue: Fonts do not seem to work from a url which means they must be part of the pkg.'
            font.uri = "pkg:/fonts/yi_" + attributes.ff + "-" + attributes.fs + ".ttf"
            'font.uri = "http://107.170.5.4/fonts/yi_" + attributes.ff + "-" + attributes.fs + ".ttf"
            'print font.uri

            fontsize = Val(attributes.fz)
            font.size = fontsize
            item.font = font
            item.id = attributes.id
            if(attributes.fw <> invalid)
                wrap = Val(attributes.fw)
                item.wrap = wrap
            end if
            if(attributes.fe <> invalid)
                ellipsize = Val(attributes.fe)
                item.ellipsizeOnBoundary = ellipsize
            end if
            item.rotation = attributes.rz
            item.opacity = attributes.t
            item.scaleRotateCenter = [Val(attributes.ax), Val(attributes.ay)]
            item.translation = [Val(attributes.x), Val(attributes.y)]
            item.scale = [Val(attributes.sx), Val(attributes.sy)]
            if(attributes.w <> invalid)
                item.width = Val(attributes.w)
            end if
            if(attributes.h <> invalid)
                item.height = Val(attributes.h)
            end if
            if(attributes.tj <> invalid)
                item.horizAlign = attributes.tj
            end if
            item.vertAlign = "top"
            item.lineSpacing = -1
            PrintoutOfItem(item)
        else if(elemname="a")
            m.global.animations = m.global.animations + 1
            'goto nextIteration ' skipping animations for now due to EXTREMELY SLOW paring delays
            attributes = elem.getAttributes()
            item = node.createChild("Animation")
            item.id = attributes.id
            item.duration = attributes.d
            item.repeat = attributes.r
            item.easeFunction = "linear"
            PrintoutOfItem(item)
        else if(elemname="at")
            m.global.tracks = m.global.tracks + 1
            attributes = elem.getAttributes()
            if (attributes.t = "1")
                item = node.createChild("FloatFieldInterpolator")
            else if (attributes.t = "2")
                item = node.createChild("Vector2DFieldInterpolator")
            else
                print "Unknown Track type " + attributes.t
                goto nextIteration
            end if
            item.fieldToInterp = attributes.f
            PrintoutOfItem(item)
        else if(elemname="k")
            m.global.keys = m.global.keys + 1
            'goto nextIteration ' skipping animations for now due to EXTREMELY SLOW paring delays
            attributes = elem.getAttributes()

            key = CreateObject("roArray", 0, true) ' resizable key array
            keyValue = CreateObject("roArray", 0, true) ' resizable keyValue array

            key.Append(node.key)
            keyValue.Append(node.keyValue)

            key.Push(Val(attributes.t))
            if (attributes.y = invalid)
                keyValue.Push(Val(attributes.x))
            else
                keyValue.Push([Val(attributes.x), Val(attributes.y)])
            endif

            node.key = key
            node.keyValue = keyValue
        end if

        itembody = elem.GetBody()
        if (itembody <> invalid)
            CreateSG(itembody, item)
        endif

nextIteration:

    end for
end sub

sub PrintoutOfItem(node as Object)
    return

    if node.hasField("uri")
        print "Image:"
    else if node.hasField("text")
        print "Text:"
    else
        print "Solid:"
    end if

    print "id" node.id
    if node.hasField("color")
        print "color" node.color
    else
        print "uri: " node.uri
    end if
    print "scaleRotateCenter" node.scaleRotateCenter
    print "rotation" node.rotation
    print "opacity" node.opacity
    print "translation" node.translation
    print "scale" node.scale
    print "width" node.width
    print "height" node.height
end sub
