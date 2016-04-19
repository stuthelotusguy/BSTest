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
    m.global.key = "none"

    m.scene = m.screen.CreateScene("Roku_Youi_Scene")
    m.screen.show()

    udp = createobject("roDatagramSocket")
    udp.setMessagePort(m.port) 'notifications for udp come to msgPort
    addr = createobject("roSocketAddress")
    addr.setPort(54321)
    udp.setAddress(addr) ' bind to all host addresses on port 54321
    addr.SetHostName("10.0.0.113")
    udp.setSendToAddress(addr) ' peer IP and port
    udp.notifyReadable(true)
    timeout = 1000 ' in milliseconds
    uniqueDev = createobject("roDeviceInfo").GetDeviceUniqueId()
    message = "Datagram from " + uniqueDev
    udp.sendStr(message)
    continue = udp.eOK()

    m.global.ObserveField("key","changetext")
    'm.global.setMessagePort(m.port)
    'm.global.control = "start"

    While continue
        event = wait(timeout, m.port)
        'event = m.port.GetMessage() ' get a message, if available

        print "key is :" + m.global.key

        if type(event) = "roUniversalControlEvent" then
            print "button pressed: ";event.GetInt()
        endif

        If type(event)="roSocketEvent"
            If event.getSocketID()=udp.getID()
                If udp.isReadable()
                    message = udp.receiveStr(1048000) ' max characters
                    'print "Received message: '"; message; "'"
                    content = createObject("RoSGNode","Poster") 'createObject("RoSGNode", "Roku_Youi_Scene")
                    content.id = "Youi"
                    content.focusable = true
                    contentxml = createObject("roXMLElement")
                    contentxml.parse(message)
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

                            'Create a root node for animation tests
                            'anim = content.createChild("Animation")
                            'anim.duration="3"
                            'anim.repeat="true" 
                            'anim.easeFunction="linear"
                            'fi = anim.createChild("FloatFieldInterpolator")
                            'fi.id = "myInterp"
                            'fi.key="[0.0, 0.50, 0.75, 1.0]"
                            'fi.keyValue="[0.0, 0.50, 0.75, 1.0]"
                            'fi.fieldToInterp = "Youi.opacity" 'content.id + ".opacity"

                            CreateSG(body, content)

                            print "creating scene"
                            m.scene.AppendChild(content)
                            content.setFocus(true)

                            'stop
                            'content.observeField("roSGNodeEvent", m.port)
                            anim = content.findNode("AnimationTestNode")
                            if(anim <> invalid) 
                                anim.control = "start"
                            end if

                        end if
                    End If
                End If
            End If
        Else If event <> invalid
            print "Event: " + type(event)
        End If
        if type(event) = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    End While

    udp.close() ' would happen automatically as udp goes out of scope

end sub

sub CreateSG(xml as Object, node as Object)
    namenum = 0

    for each elem in xml
        elemname = elem.GetName()
        if(elemname="g")
            attributes = elem.getAttributes()
            item = node.createChild("Group")
            item.id = attributes.id
            item.rotation = attributes.rz
            item.opacity = attributes.t
            item.scaleRotateCenter = [Val(attributes.ax), Val(attributes.ay)]
            item.translation = [Val(attributes.x), Val(attributes.y)]
            item.scale = [Val(attributes.sx), Val(attributes.sy)]
            PrintoutOfItem(item)
        else if(elemname="i")
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
            PrintoutOfItem(item)
        else if(elemname="t")
            attributes = elem.getAttributes()
            item = node.createChild("Label")
            item.color = attributes.c
            item.text = attributes.ft
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
            attributes = elem.getAttributes()
            item = node.createChild("Animation")
            print "Animation found. Not implemented yet"
        end if

        itembody = elem.GetBody()
        if (itembody <> invalid)
            CreateSG(itembody, item)
        endif

    end for
end sub

'gives the floating point value of an array from a parse based on the position. Currently supports only 2 dimensions'
'
' Example usage: scaleRotateCenter="[640.000000, 360.000000]"
'
'if(attributes.scaleRotateCenter <> invalid)
'    item.scaleRotateCenter = [StringToFloat(attributes.scaleRotateCenter, 1), StringToFloat(attributes.scaleRotateCenter, 2)]
'end if 
'
''
function StringToFloat(str as String, position as integer) as float
    len = Len(str)
    lenx = Instr(1, str, ",")
    if position = 1
        x = Val(Mid(str, 2, lenx - 2))
        return x
    else
        y = Val(Mid(str, lenx + 2, Len - Lenx - 2))
        return y
    end if
end function

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

function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false
  if press then
    if (key = "back") then
      handled = false
    else
      handled = true
    end if
  end if
  print "keys!"
  return handled
end function
