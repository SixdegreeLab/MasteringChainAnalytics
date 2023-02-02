# 各类常见指标分析（一）

## 背景知识

在前面的教程中，我们学习了许多关于数据表和SQL查询语句的知识。准确规范地检索统计出所需数据是一名合格分析师的必备技能。与此同时，正确地认识和解读这些数据指标也是十分关键。只有对数据指标有足够深刻的理解，它才能对我们的决策提供强力的支持。

在看具体的指标之前，我们先思考一下，我们为什么需要数据指标呢？简单地说，指标就是能够反映一种现象的数字，比如某个NFT的地板价，某家DEX的日活跃交易数。指标可以直接反映我们研究对象的状况，为相应决策提供数据支撑，我们可以通过之前学习的数据表和SQL语句知识，构建、调用、分析这些指标，达到事半功倍的效果。如果没有指标，我们获取的信息就会显得很乱，我们能够知道的信息就会变少。

具体到区块链领域，虽然有些指标与金融市场的指标类似，但它也有相当一部分特有的指标，比如比特币市值占比（Bitcoin Dominance），交易所七日流入量（All Exchanges Inflow Mean-MA7）等。在本教程中，我们先来学习以下几个常见指标和它们的计算方法：

- 总锁仓量 Total Value Locked (TVL)
- 流通总量 Circulating Supply
- 总市值 Market Cap 
- 日/月活跃用户 Daily/Monthly Active User (DAU, MAU)


## 总锁仓量Total Value Locked (TVL)
我们来看我们今天学习的第一个指标- 总锁仓量Total Value Locked (TVL)。 它描述了一个协议中锁定的所有代币价值的总和，该协议可以是Dex,借贷平台,也可以是侧链，L2二层网络等等。TVL描述了该协议的流动性，同时也反映了其受欢迎程度以及用户的信心。

比如我们来看一下DEX的TVL排行：

![DEX TVL](https://user-images.githubusercontent.com/85688147/214268451-496d2dd7-e771-4034-b483-0e0c9bc873a6.png)

以及二层网络L2的TVL排行：

![L2TVL](https://user-images.githubusercontent.com/85688147/214268702-38008feb-5eaa-44a5-8cb5-c4f5260b224c.png)

排名靠前的均是热度比较高的协议。

TVL的计算逻辑比较简单，即统计出协议中所有代币的数目，再乘以每种代币的价格，最后求和得出。我们以zksync为例，为了计算它自2021.6.15以来的TVL，我们可以先统计出它在各个时间点上的所有ERC20代币的数量，以及代币在该时间点的价格，然后相乘。这里Dune提供了一个抽象表 `erc20."view_token_balances_daily"`，我们可以直接取到所有ERC20代币在各个日期的价值，因此可以略过计算步骤。因为ERC20代币众多，为了运算速度，我们限定只纳入代币总价值高于3000美元的进行统计：
```sql
with erc_zksync as(
    select day, token_symbol as label, amount, amount_usd as token_amount_usd, token_symbol as label1
    from erc20."view_token_balances_daily"
    where wallet_address = '\xaBEA9132b05A70803a4E85094fD0e1800777fBEF' and day > '2021-06-15'  and amount_usd > 3000
    order by 1
),
```
除了ERC20，我们还需要另外计算ETH的价值。该部分的计算没有直接的抽象表可以取用，我们要根据每天zksync的转入转出计算当日的ETH数目，然后再乘以当日ETH均价进行计算。
```sql
prices as (
    select  date_trunc('day', minute) as day, avg(price) as price ,symbol from prices."usd"
    where minute > '2021-06-15' and symbol ='WETH'
    group by 1,3 order by 1
),

eth_zksync as (
    select p.day, label, token_amount as amount, token_amount * price as token_amount_usd ,'ETH' as label1 from (
    select day, label, avg(token_amount) as token_amount from (
    select day, 'WETH' as label, 2976.81715478975235801+SUM(transfer) over (order by day) as token_amount from ( 
    select timeb as day , income+outcome as transfer from (
    (select date_trunc('day', evt_block_time) as timeb, sum(amount/1e18) as income 
      from zksync."ZkSync_evt_Deposit" where "tokenId" = 0 and evt_block_time > '2021-06-15' group by date_trunc('day', evt_block_time)
     ) bb
      left join
      (select date_trunc('day', evt_block_time) as timed, sum(-amount/1e18) as outcome 
       from zksync."ZkSync_evt_Withdrawal" where "tokenId" = 0 and evt_block_time > '2021-06-15' group by date_trunc('day', evt_block_time)
      ) dd
      on bb. timeb = dd. timed)
    ) as cc
    ) w group by 1,2 order by 1
    ) n
    left join 
    prices p 
    on n.day = p.day and n.label = p.symbol
),
```
最后我们把每日ERC20的价值和ETH的价值按照日期整合到一起，我们就获得了最后的结果表：
```sql

zksync_tvl as (
    select * from erc_zksync union all
    select * from eth_zksync)


select label1, day, sum(token_amount_usd)/1e6 as TVL_usd from zksync_tvl 
group by 1,2 
order by TVL_usd DESC
```

这样我们就能够把TVL的变化呈现出来：


![tvl](https://user-images.githubusercontent.com/85688147/214280256-5d9ee348-83c3-49e4-9688-86679e1f5afa.png)

## 流通总量 Circulating Supply
流通总量是当前市场中以及持币者掌握的流通的加密货币数量。它与总供应量(Total Supply)不同，它不会将无法交易流通的部分纳入统计，比如被锁定而无法交易的货币数量。由于这部分无法流通的加密货币通常并不会影响其价格，所以流通总量作为代币数量的度量较总供应量更为常用。对于不同的加密货币，其计算方式有所不同。比如一些线性释放的代币，他的供应量随时间增加。又如一些有通缩燃烧机制的代币，我们在计算流通总量的时候就要减去这一部分。这里我们以比特币为例，计算它的当前流通总量。
比特币的流通总量计算逻辑较为简单，从起始周期每个区块产出50枚，每210000个区块进入一个减半周期。基于此，我们可以计算出它当前的流通总量：

```sql
SELECT SUM(50/POWER(2, ROUND(height/210000))) as Supply                      
FROM bitcoin.blocks
```


## 总市值 Market Cap 
今天学习的第三个指标是总市值(Market Cap)。相信大家对这个指标并不陌生。在股票市场，总市值是指在某特定时间内总股本数乘以当时股价得出的股票总价值。相应的在区块链领域，它是一种加密货币的流通总量(Circulating Supply）乘以该加密货币的价格得出的该加密货币总价值。因此计算总市值的关键是计算出我们刚刚学习的指标-流通总量。当我们计算出了流通总量，再乘以该加密货币的当前价格，就能得出其总市值。
我们继续以比特币为例，在计算出其流通总量的基础上，我们再乘以它当前的价格即可获得它的总市值：

```sql
SELECT SUM(50/POWER(2, ROUND(height/210000))) as Supply,                                                                                                                  SUM(50/POWER(2, ROUND(height/210000)))* (SELECT price FROM prices.usd_latest WHERE symbol='BTC' AND contract_address IS NULL) /POWER(10, 9) AS "market cap"               
FROM bitcoin.blocks
```

我们最开始提到的比特币市值占比（Bitcoin Dominance），就是以此为分子，然后以所有加密货币市值之和为分母计算出来的。


## 日/月活跃用户 Daily/Monthly Active User
今天学习的最后一个指标是日/月活跃用户 (Daily/Monthly Active User,D/MAU)。相对于绝对交易数额，活跃用户的数目更能反应一个协议受欢迎程度。由于少数用户的大额交互就可以拉高交易数额，活跃的用户数可以更客观的描述该协议的热度。它的计算方式比较简单，我们只要找出与某个合约交易的钱包地址，并按天/月统计频数即可得出。
我们以最近比较热门的Lens为例：

```sql
with daily_count as (
    select date_trunc('day', block_time) as block_date,
        count(*) as transaction_count,
        count(distinct `from`) as user_count
    from polygon.transactions
    where `to` = '0xdb46d1dc155634fbc732f92e853b10b288ad5a1d'   -- LensHub
        and block_time >= '2022-05-16'  -- contract creation date
    group by 1
    order by 1
)

select block_date,
    transaction_count,
    user_count,
    sum(transaction_count) over (order by block_date) as accumulate_transaction_count,
    sum(user_count) over (order by block_date) as accumulate_user_count
from daily_count
order by block_date
```

我们使用distinct函数让每位用户每天只会被统计一次。在统计每日活跃人数的基础上，我们还使用 `sum` `over`函数，统计出了累计用户数。

![user](https://user-images.githubusercontent.com/85688147/214829368-a9524d70-6a8c-4b38-800c-4909f0de56ba.png)






## SixDegreeLab介绍

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixDegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。

