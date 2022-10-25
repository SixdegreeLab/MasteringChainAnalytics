# 新手上路--创建第一个Dune看板

## 教程简介

### 教程定位

我们的教程注重实战，充分结合日常链上数据分析的场景与需求来编写。本文将结合Uniswap协议的一个已解析表来带领大家做一个简单的数据看板。

### 教程面向用户群体

本教程为入门级，主要想学习数据分析的新手小白、假定您之前并无编写SQL查询的经验。有SQL经验但不熟悉Dune平台的用户也可快速浏览。

### 教程的主要内容

本教程主要包括以下内容：Dune平台简介，SQL查询快速入门、编写查询并创建可视化图表、使用查询图表创建数据看板。


### 本教程使用的数据简介

Uniswap V3 的流动资金池. 基本只围绕 Dune Engine V2 （Beta）中的流动资金池表（uniswap_v3_ethereum.Factory_evt_PoolCreated）表来展开。


## Dune 平台简介

### Dune平台是什么

### Dune的数据看板和查询

数据看板（Dashboard）和查询（Query）

### 如何使用Dune平台

## 关系型数据库基础知识

### 数据库、模式、表、字段

### 本教程用到的数据表
Uniswap 流动资金池：uniswap_v3_ethereum.Factory_evt_PoolCreated。

## SQL查询快速入门

SQL语句类型包括新增（Insert）、删除（Delete）、修改（Update）、查找（Select）。链上数据分析绝大多数时候只需关注查找也就是Select语句，后续我们会交替使用查询、Query、Select等词汇，如无特别说明，都是指使用Select 语句编写Query进行查询。

### 编写第一个查询

SQL中的Hello World！从Uniswap 流动资金池查询返回所有记录的全部字段。

```SQL
select * from uniswap_v3_ethereum.Factory_call_createPool
```

### Select 查询语句基本语法介绍
```SQL
select 字段列表
from 数据表
where 筛选条件
order by 排序字段
limit 返回记录数量限制
```

使用Limit子句限制返回的记录数量：
```SQL
select *
from uniswap_v3_ethereum.Factory_evt_PoolCreated
limit 10
```

### Select 查询常用的一些函数和关键词

#### As定义别名
可以通过使用“as”子句给表、字段定义别名。别名对于表名（或字段名）较长、包含特殊字符或关键字等情况，或者需要对输出字段名称做格式化时，非常实用。别名经常用于计算字段、多表关联、子查询等场景中。

```SQL
select p.pool as `资金池地址`, p.token0 as `代币A`, p.token1 as `代币B`
from uniswap_v3_ethereum.Factory_evt_PoolCreated as p
limit 10
```

#### Distinct筛选唯一值

```SQL
select distinct fee
from uniswap_v3_ethereum.Factory_evt_PoolCreated
```

Date_Trunc
Now
Interval
Concat, ||
::data_type
power, pow, 1e6

### Select 查询语句进阶语法介绍

#### 汇总函数
Count，Sum，Avg，Min，Max
Group By
Having

#### 子查询

#### 多表关联

#### 集合
Union

#### Case 语句

#### CTE 简单示例
公共表表达式，即CTE（Common Table Expression），是一种在SQL语句内执行（且仅执行一次）子查询的好方法。数据库将执行所有的WITH字句，并允许你在整个查询的后续任意位置使用其结果。

#### 简单的窗口函数
Sum() Over (Order by block_date) As 


## 创建数据看板

### 背景知识

Uniswap V3 流动资金池简介

### 数据看板的内容

我们的第一个Dune数据看板将包括以下查询内容。每个查询会输出1个或多个可视化图表。
- 查询流动资金池总数
- 不同收费等级的流动资金池数量
- 按周汇总的新建流动资金池总数
- 最近30天的每日新建流动资金池总数
- 按周汇总的新建流动资金池总数-按收费等级分组
- 按代币类型统计各种代币的资金池数量
- 最新的100个流动资金池记录

### 查询1: 查询流动资金池总数
演示Count(*)
```SQL
select count(*) as pool_count
from uniswap_v3_ethereum.Factory_evt_PoolCreated
```

### 创建数据看板并添加图表

#### 创建看板

#### 添加查询图表

#### 添加文本组件

### 查询2：不同收费等级的流动资金池数量

根据我们需要的结果数据的格式，有不同的方式来统计。如果想使用计数器（Counter）类型的可视化图表，可以把相关统计数字在同一行中返回。如果想用一个扇形图（Pie Chart）来显示结果，则可以选择使用Group By分组，将结果数据以多行方式返回。

**使用Filter子句：**
```SQL
select count(*) filter (where fee = 100) as pool_count_100,
    count(*) filter (where fee = 500) as pool_count_500,
    count(*) filter (where fee = 3000) as pool_count_3000,
    count(*) filter (where fee = 10000) as pool_count_10000
from uniswap_v3_ethereum.Factory_evt_PoolCreated
```

**使用Group By子句：**
```SQL
select fee,
    count(*) as pool_count
from uniswap_v3_ethereum.Factory_evt_PoolCreated
group by 1
```

收费等级“fee”是数值形式，代表百万分之N的收费费率。比如，3000，代表3000/1000000，即“0.30%”。用`fee`的值除以10000 （1e4）即可得到用百分比表示的费率。
将数值转换为百分比表示的费率更加直观。我们可以使用修改上面的查询来做到这一点：
```SQL
select concat((fee / 1e4)::string, '%') as fee_tier,
    count(*) as pool_count
from uniswap_v3_ethereum.Factory_evt_PoolCreated
group by 1
```
其中，`concat((fee / 1e4)::string, '%') as fee_tier`部分的作用是将费率转换为百分比表示的值，再连接上“%”符号，使用别名`fee_tier`输出。

### 查询3：按周汇总的新建流动资金池总数

要实现汇总每周新建的流动资金池数量的统计，我们可以先在一个子查询中使用date_trunc()函数将资金池的创建日期转换为每周的开始日期（星期一），然后再用Group By进行汇总统计。

```SQL
select block_date, count(pool) as pool_count
from (
    select date_trunc('week', evt_block_time) as block_date, evt_tx_hash, pool
    from uniswap_v3_ethereum.Factory_evt_PoolCreated
)
group by 1
order by 1
```

### 查询4：最近30天的每日新建流动资金池总数

类似的，要实现汇总每天新建的流动资金池数量的统计，我们可以先在一个子查询中使用date_trunc()函数将资金池的创建日期转换为天（不含时分秒值），然后再用Group By进行汇总统计。这里我们使用公共表表达式（CTE）的方式来查询。与使用子查询相比，CTE能让查询逻辑更加直观易懂、定义后可以多次重用以提升效率、也更方便调试。后续的查询都会倾向于使用CTE方式。

```SQL
with pool_details as (
    select date_trunc('day', evt_block_time) as block_date, evt_tx_hash, pool
    from uniswap_v3_ethereum.Factory_evt_PoolCreated
    where evt_block_time >= now() - interval '29 days'
)

select block_date, count(pool) as pool_count
from pool_details
group by 1
order by 1
```

### 查询5：按周汇总的新建流动资金池总数-按收费等级分组

我们可以进一步细分分组统计的维度，按收费等级来汇总统计每周新建的流动资金池数量。这样我们可以对比不同收费等级在不同时间段的流行程度。
这个例子中我们将演示Group by多级分组，可视化图表数据的柱状图（Bar Chart）、分组、叠加等功能。

```SQL
with pool_details as (
    select date_trunc('week', evt_block_time) as block_date, fee, evt_tx_hash, pool
    from uniswap_v3_ethereum.Factory_evt_PoolCreated
)

select block_date,
    concat((fee / 1e4)::string, '%') as fee_tier,
    count(pool) as pool_count
from pool_details
group by 1, 2
order by 1, 2
```

### 查询6：按代币（Token）类型统计各种代币的资金池数量

如果想分析哪些ERC20代币在Uniswap资金池中更流行，我们可以按代币类型来做分组统计。

每一个Uniswap流动资金池都由两个ERC20代币组成（token0和token1），根据其地址哈希值的字母顺序，同一种ERC20代币可能保存在token0中，也可能保存在token1中。所以，在下面的查询中，我们通过使用集合（Union）来得到完整的资金池详细信息列表。

资金池中保存的是ERC20代币的合约地址，直接显示不够直观。Dune社区用户提交的魔法书生成的抽象数据表`tokens.erc20`保存了ERC20代币的基本信息。通过关联这个表，我们可以取到代币的符号（Symbol），小数位数（Decimals）等。这里我们只需使用代币符号。

Uniswap V3 一共有8000多个资金池，涉及6000多种不同的ERC20代币，我们只关注资金池最多的100个代币的数据。

下面的查询演示以下概念：多个CTE，Union，Join，Limit等。

```SQL
with pool_details as (
    select token0 as token_address,
        evt_tx_hash, pool
    from uniswap_v3_ethereum.Factory_evt_PoolCreated

    union all

    select token1 as token_address,
        evt_tx_hash, pool
    from uniswap_v3_ethereum.Factory_evt_PoolCreated
),

token_pool_summary as (
    select token_address,
        count(pool) as pool_count
    from pool_details
    group by 1
    order by 2 desc
    limit 100
)

select t.symbol, p.token_address, p.pool_count
from token_pool_summary p
inner join tokens.erc20 t on p.token_address = t.contract_address and t.blockchain = 'ethereum'
order by 3 desc
```

### 查询7：最新的100个流动资金池记录

当某个项目方发行了新的ERC20代币并支持上市流通时，Uniswap用户可能会在第一时间创建相应的流动资金池，以允许其他用户进行兑换。比如，XEN代币就是近期的一个比较轰动的案例。

我们可以通过查询最新创建的资金池来跟踪新的趋势。下面的查询同样关联`tokens.erc20`表获，通过不同的别名多次关联相同的表来获取不同代币的符号。本查询还演示了输出可视化表格，连接字符串生成超链接等功能。

```SQL
with last_crated_pools as (
    select p.evt_block_time,
        t0.symbol as token0_symbol,
        p.token0,
        t1.symbol as token1_symbol,
        p.token1,
        p.fee,
        p.pool,
        p.evt_tx_hash
    from uniswap_v3_ethereum.Factory_evt_PoolCreated p
    inner join tokens.erc20 t0 on p.token0 = t0.contract_address and t0.blockchain = 'ethereum'
    inner join tokens.erc20 t1 on p.token1 = t1.contract_address and t1.blockchain = 'ethereum'
    order by p.evt_block_time desc
    limit 100
)

select evt_block_time,
    token0_symbol || '-' || token1_symbol || ' ' || (fee / 1e4)::string || '%' as pool_name,
    '<a href=https://etherscan.io/address/' || pool || ' target=_blank>' || pool || '</a>' as pool_link,
    token0,
    token1,
    fee,
    evt_tx_hash
from last_crated_pools
order by evt_block_time desc
```


## 总结

## SixDegreeLab 介绍


脚注
