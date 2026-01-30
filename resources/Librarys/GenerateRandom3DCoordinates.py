import random   # 引入随机数生成器
import math
from TwoPointsCalc import calculate_two_points    # 引入计算两点测量理论结果


def generate_random_point(name_prefix="P"):     # 生成随机点
    return {
        "name": f"{name_prefix}{random.randint(1,9999)}",
        "n": round(random.uniform(-5000000, 5000000), 4),
        "e": round(random.uniform(-500000, 500000), 4),
        "z": round(random.uniform(-9000, 9000), 4),
    }

def generate_two_points_case():  # 生成两点测量案例
    start = generate_random_point("S")
    end   = generate_random_point("E")

    expected = calculate_two_points(start, end) # 计算理论结果

    return {
        "start": start,
        "end": end,
        "expected": expected
    }
