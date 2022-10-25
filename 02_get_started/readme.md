# 新手上路--创建第一个Dune看板

## 教程简介

### 教程定位

偏实战Practice 性质。

### 教程面向用户群体

新手小白、假定之前无SQL经验、有SQL经验的也可快速浏览。

### 教程的主要内容

Dune，SQL快速入门、编写查询、创建可视化图表、创建数据看板。


### 本教程使用的数据简介

Uniswap V3 的流动性池. 基本只围绕 Dune Engine V2 （Beta）中的 uniswap_v3_ethereum.Factory_evt_PoolCreated 表来展开。


## Dune 平台简介

### Dune平台是什么

### Dune的数据看板和查询

数据看板（Dashboard）和查询（Query）

### 如何使用Dune平台

## SQL查询快速入门

SQL语句类型包括新增（Insert）、删除（Delete）、修改（Update）、查找（Select）。链上数据分析绝大多数时候只需关注查找也就是Select语句，后续我们会交替使用查询、Query、Select等词汇，如无特别说明，都是指使用Select 语句编写Query进行查询。

### 编写第一个查询

SQL中的Hello World！

```SQL
select *
from uniswap_v3_ethereum.Factory_call_createPool
limit 10
```

### Select 查询语句基本语法介绍
Select
From
Where
Order By
Limit

### Select 查询常用的一些函数和关键词
As
Distinct
Date_Trunc
Now
Interval
Concat, ||

### Select 查询语句进阶语法介绍

#### 汇总函数
Count，Sum，Avg，Min，Max

#### 子查询

#### 多表关联

#### 联合

#### Case 语句

#### CTE 简单示例

#### 简单的窗口函数
Sum() Over (Order by block_date) As 


## 创建数据看板

### 背景知识

Uniswap V3 流动性池简介

### 数据看板的内容

查询流动性池总数
不同Fee Tier的流动性池数量
按周汇总的新建流动性池总数
最近30天的每日新建流动性池总数
按周汇总的新建流动性池总数-按Fee Tier分组
最近30天的每日新建流动性池总数-按Fee Tier分组
最新的100个流动性池记录

### 查询1: 查询流动性池总数
演示Count(*)

### 创建数据看板并添加图表

#### 创建看板

#### 添加查询图表

#### 添加文本组件

### 查询2：不同Fee Tier的流动性池数量
演示Group By

### 查询3：按周汇总的新建流动性池总数
演示子查询、date_trunc()

### 查询4：最近30天的每日新建流动性池总数
演示CTE

### 查询5：按周汇总的新建流动性池总数-按Fee Tier分组
演示Group by

### 查询6：最近30天的每日新建流动性池总数-按Fee Tier分组
演示CTE

### 查询7：最新的100个流动性池记录
演示JOIN语法，关联token表取Symbol
演示Contact，超链接


## 总结

脚注
