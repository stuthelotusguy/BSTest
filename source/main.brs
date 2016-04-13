'********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
sub Main()
    showChannelSGScreen()
end sub

sub showChannelSGScreen()
    print "in showChannelSGScreen"
    m.screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    m.screen.setMessagePort(m.port)
    m.scene = m.screen.CreateScene("Roku_Youi_Scene")
    m.screen.show()

    msgPort = createobject("roMessagePort")
    udp = createobject("roDatagramSocket")
    udp.setMessagePort(msgPort) 'notifications for udp come to msgPort
    addr = createobject("roSocketAddress")
    addr.setPort(54321)
    udp.setAddress(addr) ' bind to all host addresses on port 54321
    addr.SetHostName("10.0.0.113")
    udp.setSendToAddress(addr) ' peer IP and port
    udp.notifyReadable(true)
    timeout = 1 * 10 * 1000 ' ten seconds in milliseconds
    uniqueDev = createobject("roDeviceInfo").GetDeviceUniqueId()
    message = "Datagram from " + uniqueDev
    udp.sendStr(message)
    continue = udp.eOK()
    While continue
        event = wait(timeout, msgPort)
        If type(event)="roSocketEvent"
            If event.getSocketID()=udp.getID()
                If udp.isReadable()
                    message = udp.receiveStr(1048000) ' max characters
                    print "Received message: '"; message; "'"
					  content = createObject("RoSGNode","Poster")
					  contentxml = createObject("roXMLElement")
					  contentxml.parse(message)
 
					  if contentxml.getName()="listcontent"
						print("getContent: listcontent found")
						for each item in contentxml.GetNamedElements("item")
						  attributes = item.getAttributes()
							listitem = content.createChild("Poster")
							listitem.translation=[Val(attributes.posx), Val(attributes.posy)]
							listitem.width = Val(attributes.width)
							listitem.height = Val(attributes.height)
							listitem.uri = attributes.uri
							print("getContent:")
							print(item.text)
						end for
					  end if
					  m.scene.replaceChild(content, 0)
                End If
            End If
        Else If event=invalid
            print "Timeout"
            udp.sendStr(message) ' periodic send
        End If
        if type(event) = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    End While
    udp.close() ' would happen automatically as udp goes out of scope
end sub

sub CreateSG(message as String)
  content = createObject("RoSGNode","Poster")
  contentxml = createObject("roXMLElement")
  contentxml.parse(message)
 
  if contentxml.getName()="listcontent"
    print("getContent: listcontent found")
    for each item in contentxml.GetNamedElements("item")
      attributes = item.getAttributes()
        listitem = content.createChild("Poster")
        listitem.translation=[Val(attributes.posx), Val(attributes.posy)]
        listitem.width = Val(attributes.width)
        listitem.height = Val(attributes.height)
        listitem.uri = attributes.uri
        print("getContent:")
        print(item.text)
    end for
  end if
  m.top.appendChild(content)
  screen.show()

end sub
