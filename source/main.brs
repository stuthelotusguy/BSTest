'********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
sub Main()
    showChannelSGScreen()
end sub

sub showChannelSGScreen()
    m.screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    m.screen.setMessagePort(m.port)

    m.global = m.screen.getGlobalNode()
    m.global.id = "GlobalNode"
    m.global.addFields( {key : "none"} )
    m.global.addFields( {groups : 0, images : 0, solids : 0, text : 0, animations : 0, tracks : 0, keys : 0} )
    m.global.key = "none"

    m.scene = m.screen.CreateScene("Roku_Youi_Scene")
    m.screen.show()

    connections = {}
    buffer = CreateObject("roByteArray")
    buffer[524288] = 0 ' 512KB
    bufferSize = 0
    tcpServer = CreateObject("roStreamSocket")
    tcpServer.setMessagePort(m.port) 'notifications for tcp come to msgPort
    addr = createobject("roSocketAddress")
    addr.setPort(54321)
    tcpServer.setAddress(addr)
    tcpServer.notifyReadable(true)
    tcpServer.listen(4)
    continue = tcpServer.eOK()
    
    sendAddr = createobject("roSocketAddress")
    sendAddr.SetAddress("10.0.0.111:54322") ' MattC's PC
    'sendAddr.SetAddress("10.0.0.103:54322") ' Stu's PC
    tcpClient =  CreateObject("roStreamSocket")
    tcpClient.setMessagePort(m.port) 'notifications for tcp come to msgPort
    tcpClient.setSendToAddress(sendAddr)
    tcpClient.notifyReadable(true)

    tcpClient.Connect()
    
    if not continue
        print "Error creating listen socket"
    end if

    m.global.ObserveField("key","changetext")
    'm.global.setMessagePort(m.port)
    'm.global.control = "start"

    timeout = 16 ' in milliseconds
    pingpong = 1

    TestFunction(pingpong)

    While continue
        event = m.port.waitMessage(timeout)
        'event = m.port.GetMessage() ' get a message, if available

        if m.global.key <> "none"
            print "key is :" m.global.key

            if(m.global.key = "OK")
                m.global.key = "none"
                byteSent = tcpClient.SendStr(StrI(pingpong))
                if (byteSent > 0)
                    print "TCP CLIENT - Sent current screen ID to " sendAddr.GetAddress() " : " pingpong
                else
                    print "TCP CLIENT - No connection to " sendAddr.GetAddress() ". Switching screen locally."
                    pingpong ++
                    if(pingpong > 2)
                        pingpong = 1
                    end if
                    TestFunction(pingpong)
                end if
            end if
        end if

        if type(event) = "roUniversalControlEvent" then
            print "button pressed: ";event.GetInt()

        else if type(event)="roSocketEvent"
            changeID = event.getSocketID()
            if changeID = tcpClient.getID()
                closed = False
                if tcpClient.isReadable()
                    tcpClientRecvBuffer = CreateObject("roByteArray")
                    tcpClientRecvBuffer[65536] = 0 ' 64KB
                    received = tcpClient.receive(tcpClientRecvBuffer, 0, 65536)
                    if (received > 0)
                        print "TCP CLIENT - received " sendAddr.getAddress() " : " tcpClientRecvBuffer.ToAsciiString()
                        pingpong = Val(tcpClientRecvBuffer.ToAsciiString())
                        TestFunction(pingpong)
                    else
                        closed = True
                    end if
                end if
                if closed or not tcpClient.eOK()
                    print "TCP CLIENT - closing connection to " sendAddr.getAddress()
                    tcpClient.close()
                end if
            else if changedID = tcpServer.getID() and tcpServer.isReadable()
                ' New
                newConnection = tcpServer.accept()
                if newConnection = Invalid
                    print "accept failed"
                else
                    print "accepted new connection ID" newConnection.getID()
                    newConnection.notifyReadable(true)
                    newConnection.setMessagePort(m.port)
                    connections[Stri(newConnection.getID())] = newConnection
                end if
            else
                ' Activity on an open connection
                connection = connections[Stri(changedID)]
                closed = False
                if connection.isReadable()
                    received = connection.receive(buffer, bufferSize, 65536)
                    print "received chunk :" received
                    bufferSize += received
                    if received = 0 'client closed
                        closed = True
                    end if
                end if
                if closed or not connection.eOK()
                    print "closing connection ID" changedID
                    connection.close()
                    connections.delete(Stri(changedID))
                    if (bufferSize > 0)
                        print "total byte received : " bufferSize
                        startTime = CreateObject("roDateTime")
                        content = createObject("RoSGNode","Poster") 'createObject("RoSGNode", "Roku_Youi_Scene")
                        content.id = "Youi"
                        content.focusable = true
                        contentxml = createObject("roXMLElement")
                        contentxml.parse(buffer.ToAsciiString())
                        if contentxml.getName()="sc"
                            print("getContent: scene found")
                            body = contentxml.GetBody()
                            etype = lcase(type(body))
                            if etype = "roxmllist"

                                count = m.scene.getChildCount()
                                while count > 0
                                    print "removing scene" + StrI(count)
                                    print m.scene.getChild(count - 1).id
                                    m.scene.removeChildIndex(count - 1)
                                    count = m.scene.getChildCount()
                                end while

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
                        bufferSize = 0 ' we consumed the buffer
                    end if
                end if
            end if
        else if event <> invalid
            print "Event: " + type(event)
        else if type(event) = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while

    tcpServer.close()
    for each id in connections
        connections[id].close()
    end for

end sub

sub TestFunction(screen as Integer)

    if(screen = 1)
        anim =m.scene.findNode("Out_unknown_1") 
    else
        anim =m.scene.findNode("Out_unknown_1") 
    end if

    if(anim <> invalid)
        anim.control = "start"
    else
        print "Not found"
    end if

    Sleep(500)

    count = m.scene.getChildCount()
    while count > 0
        print "removing scene" + StrI(count)
        m.scene.removeChildIndex(count - 1)
        count = m.scene.getChildCount()
    end while

    print "creating scene"

    m.lib = createObject("RoSGNode","ComponentLibrary")
    m.lib.id="BSTestLib"
    if (screen = 1)
        m.lib.uri="http://107.170.5.4/images/Lander.pkg"
    else
        m.lib.uri="http://107.170.5.4/images/PDP.pkg"
    end if

   'm.lib.uri="http://107.170.5.4/images/POCSelect.pkg"



    while m.lib.loadStatus = "loading"
        print m.lib.loadStatus
    end while

    content = CreateObject("roSGNode", "MainScreen")

    content.AppendChild(m.lib)

    m.scene.AppendChild(content)

    content.focusable = true
    content.setFocus(true)

end sub

  
sub CreateSG(xml as Object, node as Object)
    namenum = 0

    for each elem in xml
        elemname = elem.GetName()
        if(elemname="g")
            m.global.groups ++
            attributes = elem.getAttributes()
            item = node.createChild("Group")
            item.id = attributes.id
            item.rotation = attributes.rz
            item.opacity = attributes.t
            item.scaleRotateCenter = [Val(attributes.ax), Val(attributes.ay)]
            item.translation = [Val(attributes.x), Val(attributes.y)]
            item.scale = [Val(attributes.sx), Val(attributes.sy)]
            'item.visible = Val(attributes.v)
            PrintoutOfItem(item)
        else if(elemname="i")
            m.global.images ++
            namenum += 1
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
            m.global.solids ++
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
            m.global.text ++
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
            PrintoutOfItem(item)
        else if(elemname="a")
            m.global.animations ++
            'goto nextIteration ' skipping animations for now due to EXTREMELY SLOW paring delays
            attributes = elem.getAttributes()
            item = node.createChild("Animation")
            item.id = attributes.id
            item.duration = attributes.d
            item.repeat = attributes.r
            item.easeFunction = "linear"
            PrintoutOfItem(item)
        else if(elemname="at")
            m.global.tracks ++
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
            m.global.keys ++
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
