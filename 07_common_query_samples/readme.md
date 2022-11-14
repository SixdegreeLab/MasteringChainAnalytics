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

### 查询单个ERC20代币的每日平均价格

当我们需要查询某个ERC20代币每一天的平均价格时，只能使用`prices.usd`表来实现。通过设置要查询价格的日期范围（或者不加日期范围取全部日期的数据），按天汇总，使用`avg()`函数求得平均值，就可以得到按天的价格数据。SQL如下：

```sql
select date_trunc('day', minute) as block_date,
    avg(price) as price
from prices.usd
where symbol = 'WETH'
    and blockchain = 'ethereum'
    and minute >= '2022-01-01'
group by 1
order by 1
```

如果我们同时还需要返回其他字段，可以把它们加入SELECT列表并同时加入到GROUP BY里面。这是因为，当使用`group by`子句时，SELECT列表中出现的字段如果不是汇总函数就必须同时出现在GROUP BY子句中。SQL修改后如下：

```sql
select date_trunc('day', minute) as block_date,
    symbol,
    decimals,
    contract_address,
    avg(price) as price
from prices.usd
where symbol = 'WETH'
    and blockchain = 'ethereum'
    and minute >= '2022-01-01'
group by 1, 2, 3, 4
order by 1
```

### 查询多个ERC20代币的每日平均价格

类似地，我们可以同时查询一组ERC20代币每一天的平均价格，只需将要查询的代币的符号放入`in ()`条件子句里面即可。SQL如下：

```sql
select date_trunc('day', minute) as block_date,
    symbol,
    decimals,
    contract_address,
    avg(price) as price
from prices.usd
where symbol in ('WETH', 'WBTC', 'USDC')
    and blockchain = 'ethereum'
    and minute >= '2022-10-01'
group by 1, 2, 3, 4
order by 2, 1   -- Order by symbol first
```

## 从DeFi交易记录计算价格

Dune上的价格数据表`prices.usd`是通过spellbook来维护的，里面并没有包括所有支持的区块链上面的所有代币的价格信息。特别是当某个新的ERC20代币新发行上市，在DEX交易所进行流通（比如XEN），此时Dune的价格表并没有这个代币的数据。此时，我们可以读取DeFi项目中的交易数据，比如Uniswap中的Swap数据，将对应代币与USDC（或者WETH）之间的交换价格计算出来，再通过USDC或WETH的价格数据换算得到美元价格。示例查询如下：

```sql
with xen_price_in_usdc as (
    select date_trunc('hour', evt_block_time) as block_date,
        'XEN' as symbol,
        '0x06450dee7fd2fb8e39061434babcfc05599a6fb8' as contract_address, -- XEN
        18 as decimals,
        avg(amount1 / amount0) / pow(10, (6-18)) as price   --USDC: 6 decimals, XEN: 18 decimals
    from (
        select contract_address,
            abs(amount0) as amount0,
            abs(amount1) as amount1,
            evt_tx_hash,
            evt_block_time
        from uniswap_v3_ethereum.Pair_evt_Swap
        where contract_address = '0x353bb62ed786cdf7624bd4049859182f3c1e9e5d'   -- XEN-USDC 1.00% Pair
            and evt_block_time > '2022-10-07'
            and evt_block_time > now() - interval '30 days'
    ) s
    group by 1, 2, 3, 4
),

usdc_price as (
    select date_trunc('hour', minute) as block_date,
        avg(price) as price
    from prices.usd
    where contract_address = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'   -- USDC
        and minute > '2022-10-07'
        and minute > now() - interval '30 days'
    group by 1
)

select x.block_date,
    x.price * u.price as price_usd
from xen_price_in_usdc x
inner join usdc_price u on x.block_date = u.block_date
order by x.block_date
```

上面这个查询是我们在XEN Crypto项目的数据看板中的一个实际应用，参考链接如下：
数据看板：[XEN Crypto Overview](https://dune.com/sixdegree/xen-crypto-overview)
查询：[XEN - price trend](https://dune.com/queries/1382200)

另外，如果代币相关的交易记录已经集成到`dex.trades`表中，你也可以使用该表的数据来计算价格。将`amount_usd`与`token_bought_amount`或者`token_sold_amount`相除，得到对应代币的USD价格。

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



## SixDegreeLab介绍

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixDegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
