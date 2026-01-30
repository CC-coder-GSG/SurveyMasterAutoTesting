import math

def calculate_two_points(start, end):   # 计算两点测量理论结果
    dn = end["n"] - start["n"]
    de = end["e"] - start["e"]
    dz = end["z"] - start["z"]

    horizontal = math.sqrt(dn**2 + de**2)   # 计算水平距离
    slope_dist = math.sqrt(horizontal**2 + dz**2)   # 斜距

    percent = abs(dz) / horizontal * 100 if horizontal != 0 else 0  # 计算百分比
    ratio = slope_dist / horizontal if horizontal != 0 else 0   # 计算斜率比

    angle = math.degrees(math.atan2(de, dn))    # 角度
    if angle < 0:
        angle += 360

    return {
        "azimuth": round(angle, 4),   # 方位
        "horizontal": round(horizontal, 4),   # 水平距离
        "slope_dist": round(slope_dist, 4),   # 斜距
        "vertical": round(dz, 4),   # 垂直距离
        "dh": round(dz, 4),   # 垂直距离
        "slope_ratio": round(ratio, 4),   # 斜率比
        "slope_percent": round(percent, 2),   # 百分比
        "north_offset": round(dn, 4),   # 北偏移
        "east_offset": round(de, 4)    # 东偏移
    }
