# 新手上路--创建第一个Dune数据看板

## 教程简介

我们的教程偏重实战，结合日常链上数据分析的场景与需求来编写。本文将结合Uniswap协议的一个已解析表来带领大家做一个简单的数据看板。

本教程为入门级，主要面向希望学习数据分析的新手用户。我们假定您之前并无编写SQL查询的经验，有SQL经验但不熟悉Dune平台的用户也可快速浏览本教程。

本教程主要包括以下内容：Dune平台简介，SQL查询快速入门、编写查询并创建可视化图表、使用查询图表创建数据看板。

## Dune 平台简介

### Dune平台是什么
[Dune](https://dune.com/)是一个强大的区块链数据分析平台，以SQL数据库的方式提供原始区块链数据和已解析的数据。通过使用SQL查询，我们可以从Dune的数据库中快速搜索和提取各种区块链信息，然后将其转换为人类可读的表格和可视化图表。

### Dune的数据看板和查询

数据看板（Dashboard）是Dune上内容的载体，由各种小部件（Widget）组成。这些小部件可以是从Query查询结果生成的可视化图表或文本框，你还可以在文本框中嵌入图像、链接等。

查询（Query）是Dune数据面板的主要数据来源。我们通过编写SQL语句，执行查询并在结果集上生成可视化图表，再将图表添加到对应的数据看板中。

使用Dune处理数据的一般过程可以概括为：编写SQL查询显示数据 -》可视化查询结果 -》在数据看板中组装可视化图表 -》调整美化数据看板。

关于Dune平台的使用，可以查看其[官方文档](https://dune.com/docs/)。Dune最新文档的中文版本目前正在翻译整理中，你可以在这里找到V1版本的[Dune中文文档](https://docs.dune.com/v/chinese/)。

## SQL查询基础知识

在开始编写我们的数据看板所需的第一个SQL查询之前，我们需要先了解一些必备的SQL查询基础知识。

### 数据库基础

#### 数据库（Database）

**数据库**是结构化信息或数据的有序集合，是按照数据结构来组织、存储和管理数据的仓库。Dune平台目前提供了多个数据库，分别支持来自不同区块链的数据。

#### 模式（Schema）

同一个数据库中，可以定义多个模式。我们暂时可以将模式简单理解为数据表的拥有者（Owner）。不同的模式下可以存在相同名称的数据表。

#### 数据表（Table）

数据表是由表名、表中的字段和表的记录三个部分组成的。数据表是我们编写SQL查询访问的主要对象。Dune将来自不同区块链的数据分别存贮到不同模式下的多个数据表中供我们查询使用。

使用数据表编写查询时，我们用`schema_name.table_name`的格式来指定查询要使用的数据表名称。例如`ethereum.transactions`表示`ethereum`模式下的`transactions`表，即以太坊的交易表。

同一个模式下的数据表名称必须唯一，但是相同名称的数据表可以同时存在于多个不同的模式下。例如V2中同时存在`ethereum.transactions`和`bnb.transactions`表。

#### 数据列（Column）

数据列也称为字段（Field），有时也简称为“列”，是数据表存贮数据的基本单位。每一个数据表都包含一个或多个列，分别存贮不同类型的数据。

#### 数据行（Row）

数据行也称为记录（Record）。每一个记录包括数据表定义的多个列的数据。我们编写SQL查询的执行结果就是一个或多个记录。查询输出的记录集通常也被称为结果集（Results）。

### 本教程使用的数据库和数据表

本教程使用Dune平台的“Dune Engine V2 (Beta)”数据库，通常被称为V2 Engine或者简称V2。与此对照，Dune平台支持的其他数据库也被统称为V1。

我们使用以太坊区块链上流行的DeFi协议Uniswap V3的流动资金池作为案例. 对应的数据表为`uniswap_v3_ethereum.Factory_evt_PoolCreated`（已创建的流动资金池表）。同时，部分查询也用到了`token.erc20`（ERC20代币表）。

已创建的流动资金池表`uniswap_v3_ethereum.Factory_evt_PoolCreated`的结构如下：

| **列名**                 | **数据类型**   | **说明**                                    |
| ----------------------- | ------------- | ------------------------------------------ |
| contract\_address       | string        | 合约地址                                    |
| evt\_block\_number      | long          | 区块编号                                    |
| evt\_block\_time        | timestamp     | 区块被开采的时间                             |
| evt\_index              | integer       | 事件的索引编号                               |
| evt\_tx\_hash           | string        | 事件归属交易的唯一哈希值                      |
| fee                     | integer       | 流动资金池的收费费率（百万分之N）               |
| pool                    | string        | 流动资金池的地址                             |
| tickSpacing             | integer       | 刻度间距                                    |
| token0                  | string        | 资金池中的第一个ERC20代币地址                  |
| token1                  | string        | 资金池中的第二个ERC20代币地址                  |

ERC20代币表`token.erc20`的结构如下：

| **列名**                 | **数据类型**   | **说明**                                    |
| ----------------------- | ------------- | ------------------------------------------ |
| blockchain              | string        | 代币归属的区块链名称                           |
| contract\_address       | string        | 代币的合约地址                                |
| decimals                | integer       | 代币支持的小数位数                             |
| symbol                  | string        | 代币的符号                                    |

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

通过使用汇总函数Count()，我们可以统计当前已创建的全部资金池的数量。

```SQL
select count(*) as pool_count
from uniswap_v3_ethereum.Factory_evt_PoolCreated
```

我们建议你复制上面的代码，创建新的查询，并按说明添加可视化图表。当然你也可以直接Fork下面列出的参考查询。Fork查询的便利之处是可以了解更多可视化图表的细节。

Dune上的参考查询链接：[https://dune.com/queries/1454941](https://dune.com/queries/1454941)

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
