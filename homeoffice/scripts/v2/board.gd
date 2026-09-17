extends Node2D
var strokes:Array=[]
var font=preload("res://assets/fonts/NotoSansKR-game.ttf")
func _draw():
	draw_rect(Rect2(0,0,1024,512),Color("f4f4ed"))
	if strokes.is_empty():
		draw_line(Vector2(64,116),Vector2(960,116),Color("cbd4c9"),2)
		draw_string(font,Vector2(64,86),"생각을 함께 펼치는 곳",HORIZONTAL_ALIGNMENT_LEFT,896,32,Color("2b4844"))
		draw_string(font,Vector2(64,175),"마카를 집어 쓰거나 F로 보드 도구를 여세요.",HORIZONTAL_ALIGNMENT_LEFT,896,22,Color("526a65"))
		draw_string(font,Vector2(64,458),"COMMONS  /  WHITEBOARD",HORIZONTAL_ALIGNMENT_LEFT,896,20,Color("6a7e76"))
	for stroke in strokes:
		var pts=PackedVector2Array()
		for p in stroke.points:pts.append(Vector2(p[0]*1024,p[1]*512))
		if stroke.get("kind","")=="text":
			draw_string(font,pts[0]+Vector2(0,float(stroke.get("fontSize",28))),stroke.text,HORIZONTAL_ALIGNMENT_LEFT,1000-pts[0].x,int(stroke.get("fontSize",28)),Color(stroke.color))
		elif pts.size()>1:draw_polyline(pts,Color(stroke.color),float(stroke.width),true)
