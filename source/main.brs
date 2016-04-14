'********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
sub Main()
    showChannelSGScreen()
end sub

sub showChannelSGScreen()
    m.screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    m.screen.setMessagePort(m.port)
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
    timeout = 1 * 10 * 1000 ' ten seconds in milliseconds
    uniqueDev = createobject("roDeviceInfo").GetDeviceUniqueId()
    message = "Datagram from " + uniqueDev
    udp.sendStr(message)
    continue = udp.eOK()
    While continue
		event = wait(timeout, m.port)
		'event = m.port.GetMessage() ' get a message, if available
		if type(event) = "roUniversalControlEvent" then
			print "button pressed: ";event.GetInt()
		endif
        If type(event)="roSocketEvent"
            If event.getSocketID()=udp.getID()
                If udp.isReadable()
                    message = udp.receiveStr(1048000) ' max characters
                    'print "Received message: '"; message; "'"
					content = createObject("RoSGNode","Poster")
					contentxml = createObject("roXMLElement")
					contentxml.parse(message) 
					if contentxml.getName()="sc"
						print("getContent: scene found")
						body = contentxml.GetBody()
						etype = lcase(type(body))
						if etype = "roxmllist"
						
							CreateSG(body, content)

							if(m.scene.getChildCount() > 0)
								print "replacing scene"
								m.scene.replaceChild(content, 0)
							else
								print "creating scene"
								m.scene.InsertChild(content, 0)
							End if
						end if
					End If
                End If
            End If
        Else ' If event=invalid
            'print "Timeout"
            'udp.sendStr(message) ' periodic send
			print type(event)
        End If
        if type(event) = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    End While
    udp.close() ' would happen automatically as udp goes out of scope
end sub

sub CreateSG(xml as Object, node as Object)
	for each elem in xml
		elemname = elem.GetName()
		if(elemname="Group")
			group = node.createChild("Group")
			groupbody = elem.GetBody()
			CreateSG(groupbody, group)
		endif
		if(elemname="i")
			attributes = elem.getAttributes()
			item = node.createChild("Poster")
			item.id = attributes.id
			item.id = attributes.id
			item.rotation = attributes.rz
			item.opacity = attributes.t
			item.scaleRotateCenter = [Val(attributes.ax), Val(attributes.ay)]
			item.translation = [Val(attributes.x), Val(attributes.y)]
			item.scale = [Val(attributes.sx), Val(attributes.sy)]
			item.width = Val(attributes.w)
			item.height = Val(attributes.h)
			item.uri = attributes.url
			if(attributes.url <> invalid)
				name = Left(attributes.url, 4)
				lname = lcase(name)
				if lname <> "http"
					newuri = "pkg:/assets/drawable/default/" + attributes.url
					item.uri = newuri
				end if
			else
				item.uri = "pkg:/assets/drawable/default/Card_04.jpg"
			End if
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
			font.uri = "pkg:/fonts/yi_" + attributes.ff + "-" + attributes.fs + ".ttf"
			fontsize = Val(attributes.fz)
			font.size = fontsize
			item.font = font
			item.id = attributes.id
			if(attributes.fw <> invalid)
				wrap = Val(attributes.fw)
				item.wrap = wrap = 1
			end if
			item.rotation = attributes.rz
			item.opacity = attributes.t
			item.scaleRotateCenter = [Val(attributes.ax), Val(attributes.ay)]
			item.translation = [Val(attributes.x), Val(attributes.y)]
			item.scale = [Val(attributes.sx), Val(attributes.sy)]
			item.width = Val(attributes.w) * 1.16
			item.height = Val(attributes.h) * 1.16
			item.horizAlign = "left"
			item.vertAlign = "center"
			PrintoutOfItem(item)
		end if

	end for
end sub

'gives the floating point value of an array from a parse based on the position. Currently supports only 2 dimensions'
'
' Example usage: scaleRotateCenter="[640.000000, 360.000000]"
'
'if(attributes.scaleRotateCenter <> invalid)
'	item.scaleRotateCenter = [StringToFloat(attributes.scaleRotateCenter, 1), StringToFloat(attributes.scaleRotateCenter, 2)]
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