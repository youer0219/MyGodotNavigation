# MyGodotNavigation
 各种gd实现的寻路


## 基于B站搬运视频的横板寻路

- 基于自定义路径点的横板寻路
- [原作者YouTube链接](https://www.youtube.com/@TheSolarString)
- [原项目GitHub链接](https://github.com/solarstrings/Godot4.x_Advanced2DPlatformerPathFinding)
- 我把他的C#脚本改成了GD脚本，其他素材基本来自该作者
- BUG记录：
	- 寻找下坠点时只考虑了一边（已修复）
	- 适配tilemaplayer后会出现错误跳跃的bug(临时修复)
		- 主要问题在于某两点（p1Map: (27, 10)、p2Map: (28, 14)）链接到一起,但是现有的跳跃方法会碰到天花板导致移动失败。
		- 为什么tilemap没有这个问题，tilemaplayer就会出现这个问题呢？
			- 这不是根本原因，因为之前的distance设置为4，layer的distance则回到了默认值5，所以表现不一样。
		- 所以核心问题在于 跳跃功能 的实现上。但目前暂时没有改进这个的想法。

![alt text](自定义节点横板寻路.png)

## 平面网格寻路

- 基于AstarGrid2D的平面网格寻路
- [原作者B站视频](https://www.bilibili.com/video/BV1PeYzefE7q/?spm_id_from=333.337.search-card.all.click&vd_source=912de37828db7e4feff5c9492864d51c)
- [原项目链接](https://merxon22.github.io/GodotArchive/zh/posts/navigation_tilemap/)

![alt text](平面寻路.png)

## 网格横板寻路

- 基于AstarGrid2D写横板寻路
	- 通过权重设置已实现路径寻找
	- 可能的问题：两个相近平台之间的寻路是直接联通而不是先下去再上来。这不是大的问题，具体表现还是取决于实体的实际性能
	- 初步设置player
		- 目标：实现横板的移动方式并以不同的跳跃能力来测试移动
		- 很粗糙的实现了移动效果。

![alt text](基于网格寻路的横板寻路.png)
