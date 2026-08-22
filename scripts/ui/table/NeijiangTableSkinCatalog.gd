class_name NeijiangTableSkinCatalog
extends RefCounted

# The default is intentionally a quiet short-nap cloth.  Decorative jacquard
# remains available as an optional skin, but must not be the first impression.
const DEFAULT_SKIN_ID := "warm_caban_velvet"
const TEXTURE_ROOT := "res://res/art/materials/table_skins"

const SKINS: Array[Dictionary] = [
	{
		"id": "deep_emerald_crepe",
		"name": "深翡翠绉绒",
		"subtitle": "细密短绒·推荐",
		"source": "crepe_georgette",
		# 保留 Poly Haven 绉纱的真实翡翠底色与 1:1 细纤维尺度。
		# 这套 PBR 底图本身已有完整色彩，因此用克制的柔光而不是乘色补偿。
		"albedo_tint": Color("D9C4D1"),
		"uv_scale": Vector3(1.0, 1.0, 1.0),
		"normal_scale": 0.20,
		"roughness": 0.90,
		"anisotropy": 0.14,
		"light_color": Color("F6E8CF"),
		"rake_energy": 0.55,
		"overhead_energy": 0.35,
		"bounce_energy": 0.52,
	},
	{
		"id": "emerald_linen",
		"name": "翡翠精纺",
		"subtitle": "天然经纬·沉稳",
		"source": "rough_linen",
		"albedo_tint": Color("5A7466"),
		"uv_scale": Vector3(8.5, 8.5, 1.0),
		"normal_scale": 0.08,
		"roughness": 0.94,
		"anisotropy": 0.08,
		"light_color": Color("F4E5CE"),
		"rake_energy": 0.88,
		"overhead_energy": 0.94,
		"bounce_energy": 0.92,
	},
	{
		"id": "warm_caban_velvet",
		"name": "墨绿暖绒",
		"subtitle": "厚实柔和·经典",
		"source": "caban",
		"albedo_tint": Color("64796A"),
		"uv_scale": Vector3(8.0, 8.0, 1.0),
		"normal_scale": 0.07,
		"roughness": 0.96,
		"anisotropy": 0.11,
		"light_color": Color("F8E2C2"),
		"rake_energy": 0.86,
		"overhead_energy": 0.90,
		"bounce_energy": 0.88,
	},
	{
		"id": "black_gold_jacquard",
		"name": "黑金暗纹",
		"subtitle": "低调提花·夜宴",
		"source": "quatrefoil_jacquard_fabric",
		"albedo_tint": Color("5C6D63"),
		"uv_scale": Vector3(4.0, 4.0, 1.0),
		"normal_scale": 0.06,
		"roughness": 0.92,
		"anisotropy": 0.10,
		"light_color": Color("F7DDB8"),
		"rake_energy": 1.04,
		"overhead_energy": 1.08,
		"bounce_energy": 0.82,
	},
	{
		"id": "champagne_satin",
		"name": "香槟缎面",
		"subtitle": "暖金柔光·典藏",
		"source": "crepe_satin",
		"albedo_tint": Color("8C8068"),
		"uv_scale": Vector3(7.0, 7.0, 1.0),
		"normal_scale": 0.05,
		"roughness": 0.78,
		"anisotropy": 0.24,
		"light_color": Color("FFF0D2"),
		"rake_energy": 0.76,
		"overhead_energy": 0.82,
		"bounce_energy": 0.72,
	},
	{
		"id": "teal_teddy_check",
		"name": "青黛格绒",
		"subtitle": "柔软格纹·趣味",
		"source": "curly_teddy_checkered",
		"albedo_tint": Color("56717B"),
		"uv_scale": Vector3(3.4, 3.4, 1.0),
		"normal_scale": 0.05,
		"roughness": 0.98,
		"anisotropy": 0.06,
		"light_color": Color("E7E2D1"),
		"rake_energy": 0.82,
		"overhead_energy": 0.88,
		"bounce_energy": 0.86,
	},
]


static func all_skins() -> Array[Dictionary]:
	return SKINS.duplicate(true)


static func get_skin(skin_id: String) -> Dictionary:
	for skin in SKINS:
		if str(skin.get("id", "")) == skin_id:
			return skin.duplicate(true)
	for skin in SKINS:
		if str(skin.get("id", "")) == DEFAULT_SKIN_ID:
			return skin.duplicate(true)
	return SKINS[0].duplicate(true)


static func has_skin(skin_id: String) -> bool:
	for skin in SKINS:
		if str(skin.get("id", "")) == skin_id:
			return true
	return false


static func texture_path(skin_id: String, filename: String) -> String:
	var resolved_id := skin_id if has_skin(skin_id) else DEFAULT_SKIN_ID
	return "%s/%s/%s" % [TEXTURE_ROOT, resolved_id, filename]
