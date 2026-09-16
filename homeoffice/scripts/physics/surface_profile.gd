extends RefCounted
## Gameplay contact profiles in SI units. Calibrate with tests/v3-physics-lab.gd.
static func material(surface:String) -> PhysicsMaterial:
	var p=PhysicsMaterial.new()
	var values={"wood":[.72,.02],"court":[.74,.04],"backboard":[.48,.10],"rim":[.38,.08],"tile":[.56,.02]}.get(surface,[.65,.02])
	p.friction=values[0];p.bounce=values[1];return p
