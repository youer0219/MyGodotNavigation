class_name PVZRAStarGrid2D
extends AStarGrid2D


# 配置横向优先级系数和纵向成本系数
var horizontal_scale: float = 0.95  # 横向成本降低5%
var vertical_scale: float = 1.0    # 纵向成本不变

func _compute_cost(from_id: Vector2i, to_id: Vector2i) -> float:
	# 计算横向和纵向的绝对差值
	var dx = abs(to_id.x - from_id.x)
	var dy = abs(to_id.y - from_id.y)
	
	# 基础成本：横向优先（更低的横向成本）
	var base_cost = dx * horizontal_scale + dy * vertical_scale
	
	# 获取目标点的权重缩放值
	var weight = get_point_weight_scale(to_id)
	
	# 最终成本 = 基础成本 × 权重
	return base_cost * weight

# 设置估算函数以匹配横向优先
func _estimate_cost(from_id: Vector2i, to_id: Vector2i) -> float:
	return abs(to_id.x - from_id.x) * horizontal_scale + abs(to_id.y - from_id.y) * vertical_scale
