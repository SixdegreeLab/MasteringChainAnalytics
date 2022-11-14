# 数据分析中的常见查询（一）

在日常的数据分析中，我们经常会接到一些常见的需求，比如跟踪某个ERC20代币的价格变化、查询某个地址持有的各种ERC20代币余额等。在Dune平台的帮助文档里面，[一些有用的数据看板](https://dune.com/docs/reference/wizard-tools/helpful-dashboards/)和[实用查询](https://dune.com/docs/reference/wizard-tools/utility-queries/)部分分别给出了一些实例，大家可以参考。本篇教程中我们结合自己日常遇到的一些典型需求，整理一些查询案例给大家。

## 查询ERC20代币的价格

### 查询单个ERC20代币的最新价格

很多区块链项目都涉及ERC20代币，DeFi类的项目允许用户交换他们持有的ERC20代币，其他一些项目通过发行ERC20代币来募集资金或者通过分配计划、空投等方式回馈投资人、早期用户和项目方团队等。像[CoinGecko](https://www.coingecko.com/)这样的网站有提供各种ERC20代币的价格信息。Dune也将各区块链上常见的ERC20代币的价格信息整理到了`prices.usd`表和`prices.usd_latest`表中，方便数据分析师使用。[prices.usd](https://dune.com/docs/reference/tables/prices/)表记录了各种ERC20代币的每分钟价格信息。我们在分析ERC20代币相关的项目时，可以结合价格数据，将各种不同代币的金额转换为以美元表示的金额，就能进行汇总、对比等操作。

**获取单个ERC20代币的最新价格:**

`prices.usd`表中的价格是按分钟记录的，我们只需要根据代币的符号及其归属的区块链取最新的一条记录即可，如果有合约地址，也可以使用合约地址来查询。`usd_latest`表中则记录了每种代币的最新价格，每个代币只有一行记录。以下几种方式都可以查询单个代币（以WETH为例）的最新价格。因为价格信息按每分钟每个代币一条记录的方式保存，具体到每一个代币其记录数量也很庞大，我们通过限制读取最新的部分数据来提高查询的效率。由于偶尔可能会存在一定的延迟，下面的实例中我们从过去6小时的记录里面读取最新的一条，确保能取到价格。

**使用代币符号值读取`prices.usd`表的最新价格信息：**

```sql
select * from prices.usd
where symbol = 'WETH'
    and blockchain = 'ethereum'
    and minute >= now() - interval '6 hours'
order by minute desc
limit 1
```

**使用代币的合约地址读取`prices.usd`表的最新价格：**

```sql
select * from prices.usd
where contract_address = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'   -- WETH
    and minute >= now() - interval '6 hours'
order by minute desc
limit 1
```

**从`prices.usd_latest`表读取最新价格信息：**

```sql
select * from prices.usd_latest
where symbol = 'WETH'
    and blockchain = 'ethereum'
```

读取`prices.usd_latest`表的查询更加简洁。但是因为它实际上是`prices.usd`表的一个视图（参考源代码：https://github.com/duneanalytics/spellbook/blob/main/models/prices/prices_usd_latest.sql），相比来说查询执行的效率略低。


### 查询多个ERC20代币的最新价格

当我们需要同时读取多个Token的最新价格时，`prices.usd_latest`表的便利性就体现出来了。这里我们以同时查询WETH、WBTC和USDC的最新价格为例。


**从`prices.usd_latest`表读取多个代币的最新价格信息：**

```sql
select * from prices.usd_latest
where symbol in ('WETH', 'WBTC', 'USDC')
    and blockchain = 'ethereum'
```

**从`prices.usd`表读取多个代币的最新价格信息：**

```sql
select symbol, decimals, price, minute
from (
    select row_number() over (partition by symbol order by minute desc) as row_num, *
    from prices.usd
    where symbol in ('WETH', 'WBTC', 'USDC')
        and blockchain = 'ethereum'
        and minute >= now() - interval '6 hours'
    order by minute desc
) p
where row_num = 1
```

因为我们要同时读取多个代币的最新价格，就不能简单地使用`limit`子句限制结果数量来得到需要的结果。因为我们实际需要返回的是每个不同的代币分别按`minute`字段降序排序后取第一条记录。上面的查询中，我们使用了`row_number() over (partition by symbol order by minute desc) as row_num`来生成一个新的列，这个列的值按照`symbol`分组并按`minute`字段降序排序来生成，即每个不同的代币都会生成自己的1，2，3，4...这样的行号序列值。我们将其放到一个子查询中，外层查询中筛选`where row_num = 1`的记录，就是每个代币最新的记录。这种方法看起来稍显复杂，但是实际应用中经常需要用到类似的查询，通过`row_number()`函数生成新的列然后用于过滤数据。



多个

https://dune.com/queries/1180382

平均价格

https://dune.com/queries/1042456

使用 latest 表

### 查询单个ERC20代币的每日平均价格

单个


多个

## 从DeFi交易记录计算价格

dex.trades

## 从事件日志记录计算价格
https://dune.com/queries/1130354


### 如何提交你需要跟踪价格的Token？


## 查询ERC20代币的持有者和总供应量

持有人数

TOP 持有者

持有金额分布


## 查询原生代币的价格（ETH）

## 查询原生代币的持有者（ETH）

## 查询NFT的价格

最新价格

地板价

。。。

交易量

## 查询NFT的持有者


-- 以下放入第二部分

## 从事件日志原始表解析数据

## 从交易数据原始表解析数据

## 读取数组数据

## 读取JSON字符串数据

## 使用CTE自定义数据列表

## 清除异常值

least greatest



在Dune平台的Query编辑页面，我们可以通过左边栏来选择或搜索需要的数据表。这部分界面如下图所示：

![image_01.png](img/image_01.png)


图片中间的文本框可以用于搜索对应的数据模式(Schema)或数据表。比如，输入`erc721`将筛选出名称包含这个字符串的所有魔法表和已解析项目表。图片中上方的红框部分用于选择要使用的数据集，途中显示的“Dune Engine V2 (Spark SQL)”就是我们通常说的“V2 引擎”、“V2 Engine”或者“V2”，其他的则统称为“V1”。Dune V2 引擎基于Spark SQL（Databricks Spark），V1则是Postgresql，两种数据库引擎在SQL语法、支持的数据类型等方面有一些比较明显的区别。比如，在V1中，地址、交易哈希值这些是以`bytea`类型保存的，而在V2中，不存在`bytea`数据类型，地址、交易哈希值这些都是以小写字符串形势保存的。再如，V1中字符串对应的类型是`text`且不区分大小写，而在V2中字符串类型是`string`并且要区分大小写。

上图中下方的红框圈出的是前面所述Dune V2 引擎目前支持的几大类数据集。点击粗体分类标签文字即可进入下一级浏览该类数据集中的各种数据模式以及各模式下的数据表名称。点击分类标签进入下一级后，你还可以看到一个默认选项为“All Chains”的下拉列表，可以用来筛选你需要的区块链下的数据模式和数据表。当进入到数据表层级时，点击表名可以展开查看表中的字段列表。点击表名右边的“》”图标可以将表名（格式为`schema_name.table_name`插入到查询编辑器中光标所在位置。分级浏览的同时你也可以输入关键字在当前浏览的层级进一步搜索过滤。不同类型的数据表有不同的层次深度，下图为已解析数据表的浏览示例。

![image_03.png](img/image_03.png)

## 原始数据表




## SixDegreeLab介绍

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixDegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
