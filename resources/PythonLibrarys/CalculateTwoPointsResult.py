import math

class CalculateTwoPointsExpected:
    def calculate_two_points(self, start, end):
        """
        计算两点之间的各种测量结果
        :param start: 起始点字典，包含'n', 'e', 'z'键
        :param end: 结束点字典，包含'n', 'e', 'z'键
        :return: 包含各种测量结果的字典
        """
        dn = end["n"] - start["n"]
        de = end["e"] - start["e"]
        dz = end["z"] - start["z"]

        horizontal = math.sqrt(dn**2 + de**2)    # 水平距离
        slope_dist = math.sqrt(horizontal**2 + dz**2)      # 斜距

        azimuth = math.degrees(math.atan2(de, dn))     # 方位角
        if azimuth < 0:
            azimuth += 360

        slope_percent = abs(dz) / horizontal * 100 if horizontal != 0 else 0    # 坡度百分比
        slope_ratio = f"1:{round(horizontal / abs(dz), 3)}" if dz != 0 else "∞"     # 坡度比例
        slope_angle = math.degrees(math.atan2(abs(dz), horizontal)) if horizontal != 0 else 90  # 坡度角度

        expected = {
            "azimuth": round(azimuth, 4),
            "horizontal": round(horizontal, 4),
            "slope_dist": round(slope_dist, 4),
            "vertical": round(abs(dz), 4),
            "dh": round(dz, 4),
            "slope_ratio": slope_ratio,
            "slope_percent": round(slope_percent, 2),
            "slope_angle": round(slope_angle, 4),
            "north_offset": round(dn, 4),
            "east_offset": round(de, 4)
        }
        
        return expected
    
# 添加一个顶层函数，使Robot Framework可以直接调用
def calculate_two_points(start, end):
    calculator = CalculateTwoPointsExpected()
    return calculator.calculate_two_points(start, end)