extends Node2D
var strokes:Array=[]
var font=preload("res://assets/fonts/NotoSansKR-game.ttf")
func _draw():
	draw_rect(Rect2(0,0,1024,512),Color("f4f4ed"))
	for stroke in strokes:
		var pts=PackedVector2Array()
		for p in stroke.points:pts.append(Vector2(p[0]*1024,p[1]*512))
		if stroke.get("kind","")=="text":
			draw_string(font,pts[0]+Vector2(0,float(stroke.get("fontSize",28))),stroke.text,HORIZONTAL_ALIGNMENT_LEFT,1000-pts[0].x,int(stroke.get("fontSize",28)),Color(stroke.color))
		elif pts.size()>1:draw_polyline(pts,Color(stroke.color),float(stroke.width),true)
