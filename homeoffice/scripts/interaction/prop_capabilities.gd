extends RefCounted
const CARRY={"book":.4,"crate":2.4,"marker":.1,"laser":.1,"basketball":.62,"football":.43,"gun":.8,"shield":1.2,"plate":.4,"pan":.8,"ingredient":.3,"meal":.4,"chair":6.0,"table":16.0,"low_table":8.0,"floor_lamp":4.0}

static func can_carry(kind:String) -> bool:return CARRY.has(kind)
static func mass_for(kind:String) -> float:return float(CARRY.get(kind,1))
static func throw_speed(kind:String) -> float:return clampf(9.0/sqrt(mass_for(kind)),2.0,10.0)
