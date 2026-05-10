extends RefCounted

class_name NeijiangRuleNotes

# 内江麻将专属规则骨架说明：
# - 报叫 / 报杠白名单
# - 卡二条
# - 归
# - 两门牌下的查叫 / 退税
# 当前文件作为规则扩展占位，后续将把内江专属判定逐步从四川规则链中拆出。

func build_runtime_flags(rules_config) -> Dictionary:
	return {
		"is_neijiang": false if rules_config == null else bool(rules_config.is_neijiang_mode()),
		"enable_bao_jiao": false if rules_config == null else bool(rules_config.enable_bao_jiao),
		"enable_bao_gang": false if rules_config == null else bool(rules_config.enable_bao_gang),
		"enable_ka_er_tiao": false if rules_config == null else bool(rules_config.enable_ka_er_tiao),
		"enable_gui": false if rules_config == null else bool(rules_config.enable_gui),
	}
