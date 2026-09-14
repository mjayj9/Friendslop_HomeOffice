extends Node2D
var strokes:Array=[]
func _draw():
	draw_rect(Rect2(0,0,1024,512),Color("f4f4ed"))
	for stroke in strokes:
		var pts=PackedVector2Array()
		for p in stroke.points:pts.append(Vector2(p[0]*1024,p[1]*512))
		if pts.size()>1:draw_polyline(pts,Color(stroke.color),float(stroke.width),true)
