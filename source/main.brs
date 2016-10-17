'********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
sub Main()
    showChannelSGScreen()
end sub

function TryToConnect() as Boolean

    ClearExistingScreens()
    
    continue = false

    while not continue
        if m.tcpClient.Connect()
            Sleep(250)
            byteSent = m.tcpClient.SendStr("start")
            if (byteSent > 0)
                print "TCP CLIENT - Sent 'start' request to " m.sendAddr.GetAddress()
                continue = true
            else
                print "TCP CLIENT - No connection to " m.sendAddr.GetAddress()
                sleep(1000)
            end if
        else
            print "TCP CLIENT - No connection to " m.sendAddr.GetAddress()
            sleep(1000)
        end if
    end while

    return continue
end function

sub showChannelSGScreen()
    m.screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    m.screen.setMessagePort(m.port)

    m.scene = m.screen.CreateScene("Roku_Youi_Scene")
    m.scene.backgroundColor="0xFFFFFFFF"
    m.scene.backgroundUri = ""
    m.screen.show()
    
    m.buffer = CreateObject("roByteArray")
    m.buffer[65536] = 0 ' 64KB
    m.bufferSize = 0

    m.sendAddr = createobject("roSocketAddress")
    'm.sendAddr.SetAddress("labmediaserver.crabdance.com:54322") ' Digital Ocean "LabMediaServer" (San Francisco)
    'm.sendAddr.SetAddress("internal-labmediaserver.crabdance.com:54322") ' Digital Ocean "internal-LabMediaServer" (New York)
    'm.sendAddr.SetAddress("37.139.6.121:54322") ' Digital Ocean "Amsterdam"
    m.sendAddr.SetAddress("192.168.2.85:54322") ' MattC's PC on Lan
    'm.sendAddr.SetAddress("10.1.0.118:54322") ' MattC's PC on Stu's wifi router
    'm.sendAddr.SetAddress("10.0.0.100:54322") ' Stu's PC

    m.tcpClient =  CreateObject("roStreamSocket")
    m.tcpClient.setMessagePort(m.port) 'notifications for tcp come to msgPort
    m.tcpClient.setSendToAddress(m.sendAddr)
    m.tcpClient.notifyReadable(true)

    m.global = m.screen.getGlobalNode()
    m.global.id = "GlobalNode"
    m.global.addFields( {key : "none", remoteIndex : -1} )

    m.global.ObserveField("key", m.port)
    m.global.ObserveField("remoteIndex", m.port)
    
    timeout = 16 ' in milliseconds

    continue = TryToConnect()

    While continue
        event = m.port.waitMessage(timeout)
        
        if type(event)="roSocketEvent"
            changeID = event.getSocketID()
            if changeID = m.tcpClient.getID()
                closed = False
                if m.tcpClient.isReadable()
                    received = m.tcpClient.receive(m.buffer, m.bufferSize, 65536)
                    if (received > 0)
                        print "TCP CLIENT - received " received.toStr() + " bytes from " + m.sendAddr.getAddress()
                        m.bufferSize = m.bufferSize + received

                        if m.bufferSize > 0 and m.buffer[m.bufferSize-1] = 0 ' MattC Hack: we use the null char delimits the 'end of transmission'
                            'print m.buffer.ToAsciiString() 
                            ProcessCommand(m.buffer.ToAsciiString())
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
            end if
        else if type(event) = "roSGScreenEvent"
            if event.isScreenClosed() then return
        else if type(event) = "roSGNodeEvent"
            if event.getNode() = "GlobalNode"
                if event.getField() = "remoteIndex"
                    if m.tcpClient <> invalid
                        m.tcpClient.SendStr("selected:" + m.global.remoteIndex.ToStr())
                        ' MATTC Reset remoteIndex so the same movie can be
                        ' selected again at a later time. 
                        m.global.unobserveField("remoteIndex")
                        m.global.remoteIndex = -1
                        m.global.observeField("remoteIndex", m.port)
                    end if
                else if event.getField() = "key"
                    if m.global.key <> "none"
                        byteSent = m.tcpClient.SendStr(m.global.key)
                        if (byteSent > 0)
                            print "TCP CLIENT - Sent key '" key "' to " m.sendAddr.GetAddress()
                        else
                            print "TCP CLIENT - No connection to " m.sendAddr.GetAddress() ". Switching screen locally."
                            if (key = "ok" or key = "back")
                                continue = TryToConnect()
                            end if
                        end if
                    end if
                end if
            end if
        end if
    end while
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
    m.scene.getChild(1).visible = 1 ' make our wait_connect visible
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
            m.lib.uri="https://internal-labmediaserver.crabdance.com/images/" + name
        end if
        print m.lib.loadStatus +" " + m.lib.uri
        while m.lib.loadStatus = "loading"
            print m.lib.loadStatus '+" " + m.lib.uri
        end while
            print m.lib.loadStatus

        content = CreateObject("roSGNode", "MainScreen")

        content.AppendChild(m.lib)

        m.scene.AppendChild(content)

        content.focusable = true
        content.setFocus(true)
        
        wait_connect = m.scene.findNode("wait_connect")
        if wait_connect <> invalid
            wait_connect.visible = 0
        end if

    else if com = "clrs" 'clear screens
    
        ClearExistingScreens()
        
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
            else
                print "Not found"
            end if
        end if
    else if com = "pvid"
        print "playing video: " name
        videoSurfaceView = m.scene.findNode("Video_Surface_View_3")
        if videoSurfaceView <> invalid
            videoContent = createObject("RoSGNode", "ContentNode")
            videoContent.url = name
            'videoContent.streamformat = "hls"
            videoContent.streamformat = "mp4"  'MATTC Todo
            
            videoSurfaceView.content = videoContent
            videoSurfaceView.control = "play"
        end if
        
    end if
    
    if m.tcpClient <> invalid
        print "Sending ACK"
        m.tcpClient.SendStr("ACK")
    end if

end sub
