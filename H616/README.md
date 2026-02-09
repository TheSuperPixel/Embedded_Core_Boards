# H616核心板
## 简介
这是我在2025年3月的时候参考柚木鉉大佬的Yuzuki Chameleon H616卡片电脑绘制的全志H616开发板，核心板上带有一个无线网卡和EMMC，底板引出了一个USB OTG接口，一个SD卡接口，三个USB host接口一个HDMI接口还有一个网口。

![](./picture/cover.jpg)
## 使用方法
### H616核心板 文件夹
H616核心板的AD工程，已打板测试，可正常启动，通过串口进入Linux系统。需要在嘉立创使用JLC06161H-3313阻抗来打板。<br>
测试失败的外设：目前EMMC测试失败，导致系统只能从SD卡启动<br>
未测试的外设：板载无线网卡。因为当时2025年3月时我编译驱动一直报错，所以无法测试。

### H616底板 文件夹
H616底板的AD工程，已打板测试。当时是在捷配上面打板的，并向板厂指定了HDMI主要信号线差分100欧姆的阻抗、指定了HDMI其他信号线单端50欧姆的阻抗。如果要在嘉立创打板，需要重新修改线宽。<br>
测试通过的外设：USB OTG接口、SD卡接口、2个USB HOST接口、HDMI接口<br>
测试失败的外设：其中一个USB HOST接口<br>
未测试的外设：网口<br>


### 外壳 文件夹
存放着外壳亚克力设计文件

### 其他资料
存放着调试时记录的《H616调试笔记》

## 主要参考资料
1.Yuzuki Chameleon H616卡片电脑演示视频 https://www.bilibili.com/video/BV1KB4y1z79U<br>
2.Yuzuki Chameleon H616卡片电脑固件和文档资料 https://github.com/YuzukiHD/YuzukiChameleon<br>
3.Yuzuki Chameleon H616卡片电脑硬件资料 https://oshwhub.com/gloomyghost/yuzukih616<br>

