import random   # 引入随机数生成器

def generate_point(name_prefix="P"):    # 随机生成点
    return {
        "name": f"{name_prefix}{random.randint(1,9999)}",
        "n": round(random.uniform(-5000000, 5000000), 4),
        "e": round(random.uniform(-500000, 500000), 4),
        "z": round(random.uniform(-9000, 9000), 4),
    }

def generate_two_points():     # 随机生成两点
    return {
        "start": generate_point("S"),
        "end": generate_point("E")
    }

