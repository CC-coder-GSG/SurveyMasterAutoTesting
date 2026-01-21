# SurveyMaster Auto Testing

测量大师自动化测试框架
Robot Framework UI automation project.

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![Robot Framework](https://img.shields.io/badge/Robot%20Framework-Checking-orange)
![Appium](https://img.shields.io/badge/Appium-Mobile-green)

## Run

pip install -r requirements.txt
python -m robot -d results tests

## 📖 项目简介
本项目是 **SurveyMaster (测量大师)** 软件的 UI 自动化测试框架。
主要用于对 `com.sinognss.sm.free` 应用进行回归测试、冒烟测试以及核心功能的自动化验证。

**核心技术栈：**
* **语言**: Python 3.x
* **框架**: Robot Framework
* **库**: AppiumLibrary

---

## ⚙️ 环境准备 (Prerequisites)

在运行本项目之前，请确保本地环境已安装以下工具：

1.  **Python 3.8+**: [下载地址](https://www.python.org/)
2.  **Node.js & npm** (用于安装 Appium Server)
3.  **Appium Server**:
    ```bash
    npm install -g appium
    ```
4.  **Android SDK**: 确保 `adb` 命令可用，并已配置 `ANDROID_HOME` 环境变量。
5.  **Java JDK 1.8+**: Appium 依赖项。

---

## 📂 项目结构 (Structure)

```text
SurveyMasterAutoTesting/
├── resources/           # 资源文件，存放基本关键字和定位器
│   ├── keywords/        # 关键字文件夹，用于存储封装好的关键字、定位器或页面操作步骤
│   │   ├──common/       # 原子层操作逻辑，包括点击、滑动以及测试开始、结束时处罚的基本事件
│   │   ├──flows/        # 将pages/文件夹的基础操作罗列成为完整的步骤形成的关键字，例如创建项目的完整捕捉
│   │   └──pages/        # 单个功能页面的基础操作，例如点击按钮，输入文本等
│   └── locators/android/    # 各个页面的定位器，每个页面单独进行罗列
│            
├── scripts/             # 启用appium服务的两个脚本
├── tests/               # 测试用例文件夹
|   ├──regression/       # 回归测试用例，所有用例只涉及业务层面的操作
|   ├──smoke/            # 冒烟测试用例
|   └──...               
├── .gitignore           
├── README.md        
└── requirements.txt     # 用于配置环境的说明文档