# 借贷协议数据分析

## 背景知识

去中心化金融（DeFi）是区块链的金融创新。通过各协议之间的可组合性、互操作性，DeFi乐高就此诞生。2020年6月，DeFi借贷协议Compound开启流动性挖矿，不仅拉开了DeFi Summer的序幕，也给DeFi借贷赛道注入新活力、新思路、新用户，借贷业务成为DeFi的三大核心之一。

### 借贷协议的意义

借贷协议是DeFi的银行。传统银行中，用户可以向银行存款收取利息，也可以向银行借款，最后连本带利一起归还。类似的，在DeFi的借贷协议中用户可以向协议存钱、借钱，不同的是没有了中心化的托管机构，而是用户和借贷协议的智能合约直接交互，靠代码的运行确保一切有条不紊地进行。CeFi中的借贷，贷款担保方式分为信用、保证以及抵押贷款。银行的风险偏好较低，抵押贷款在各类贷款中是占比最高的。得益于大数据信用体系建设，信用借贷越来越普遍，不过需要大量的审查、资质证明等。

![](img/bank.jpeg)

而DeFi中的借贷是匿名的，无需信任的。从模式上讲基本都处于抵押贷款方式，普遍采用的方式是超额抵押。也就是说，我抵押200块的资产，可以从借贷协议这借走不足200块的资金，这样就无需担心我借钱不还跑路，可以放心地借钱给我了。这种以币借币，甚至越借越少的行为看似非常愚蠢，但是实际上它解决的是市场切实存在的需求：

1. 交易活动的需求：包括套利、杠杆、做市等交易活动。例如做市商需要借资金来满足大量的交易；在DEX上买币只能做多，但是通过借币可以做空；通过抵押资产加杠杆，甚至可以通过循环贷不断增加杠杆（抵押ETH借USDC买ETH再抵押再借再买…）

2. 获得被动收入：闲置资金/屯币党在屯币的过程中可以通过借出资产获得额外收益

3. 代币激励：除了流动性挖矿，头部 DeFi 协议推出基于其原生代币的质押服务，代币持有者可质押获得更多原生代币。代币激励是面对借贷协议所有参与者的，借方可以通过交互获得代币奖励，通过交易获得的代币，偿还一部分债务

相比传统房车类型抵押贷款，需要人力验证资产所有人，还款违约还需要人力及时间进行资产拍卖。DeFi中的当铺模式只需要在抵押率过低停止抵押，对资产清算即可结束贷款合同。

### 借贷协议的运作模式

在区块链上抵押借贷，能借多少代币、什么时候清算，都是由智能合约中的一系列参数设定好的。

![](img/loan.png)

Max LTV（Loan to Value）：最大贷款价值比，决定借款发生时债务/ 抵押品价值的最大比例。

Liquidation threshold：清算门槛，是一个清算判定条件，债务/ 抵押品价值升至这个比例时发生清算。

Liquidation penalty：强平罚款，当清算发生时，以该资产为抵押品需要扣除的罚金比例。

比如，Aave V2中USDC 的Max LTV为87%，Liquidation threshold 为89%，Liquidation penalty 为4.5%，就代表每有1 USDC 的抵押品，最高可以借入0.87 美元其它代币，当借入的代币升值至0.89 美元时发生清算，顺利清算的情况下将被扣除4.5% 的罚金。

加密资产的价格浮动往往会比较剧烈，借贷协议采用的超额抵押方式有助于避免资不抵债的情况发生，如下图所示：不同的抵押率对应不同的费率和质押要求。

![](img/2.png)

当抵押资产或者借出资产发生大幅波动时到达一定程度时，借贷协议为了避免坏账要执行清算。
我们以AAVE为例，看借贷协议是如何进行清算的。
首先介绍一个概念叫健康因子（Health Factor），健康因子和账户的抵押物、借款金额有关，表达资不抵债的可能性。如何计算健康因子？

1、查看抵押物的清算线（LiquidationThreshold），比如此时USDC是0.89；

![](img/hf1.png)

2、健康因子 = 抵押金额 * 清算线/ 借出资产，以此刻为例，5794 * 0.89/ 4929 = 1.046；

![](img/hf2.png)

3、如果抵押物价格下跌，或者借出资产价格上涨，导致健康因子<1，则会执行清算Liquidation，具体清算过程如下：

![](img/hf3.png)

那么实际的不等式是：借出资产金额 <= 抵押金额 * LTV < 抵押金额 * 清算线。
清算时，超出清算线的部分会拿去拍卖，清算者（liquidators）购买抵押物，拍卖获得的资金用于归还负债，多出部分就作为清算者的奖赏。
清算过程依赖于预言机的喂价，目前AAVE取的是Chainlink。

有意思的是，虽然超额抵押的思路看起来非常靠谱，借贷协议应该没有坏账风险，但是实际上是这样吗？最近Eisenberg从AAVE V2借币做空CRV的事件中，就产生了约170 万美元的坏账。最主要的原因可能是该巨鲸的头寸过大，市场上并没有足够多的流动性让清算人买入。从下图可以看到，该巨鲸在Aave 中存入了5794 万USDC，借入了8342 万CRV。

![](img/crv1.jpg)

而从CoinGecko 和区块链浏览器中可以看出，CRV 代币的流通量只有6.37 亿，巨鲸借出的CRV 数量高于所有外部帐户持有者。例如，截至11 月25 日，Aave 的合约中只有4212 万CRV，持币量第8 的Binance 14 地址中也只有2021 万CRV。

![](img/crv2.png)

在DEX 中，Uniswap V3 的相关交易对中流动性最高的ETH/CRV 交易对中，流动性共176 万美元，只有148 万CRV。因此，市场上并没有足够的流动性供清算人买入，完成清算。每一次清算后，剩余的资金会补充到抵押品中，使剩余债务的清算价格上升。但是在清算过程中，CRV 的价格继续上涨，最终导致Aave 产生坏帐。

简单总结，大部分的借贷协议目前采用的方式是超额抵押，当价格波动时由健康因子监控是否需要清算，以及清算多少。这里我们只讲了最简单最基本的借贷业务，实际上各个协议之间也各有特色，如Compound是去中心化的点对点模式，资金池运用模式使池内资金达到了极高的利用值；AAVE首先提出了闪电贷，借款+操作+还款在一个区块内完成，原子性决定了这笔交易要么全部成功，要么全部失败；AAVE V3更提出了资产跨链流动的功能；而Euler，Kashi和Rari等借贷平台通过无许可的借贷池更好地满足长尾资产的需求。


## 重点关注指标
搞明白链上借贷协议的业务逻辑之后，就可以着手分析了，接下来我将列出一些常用于评估借贷协议的一些指标。需要注意的是，在智能合约中资金的流动虽然只有入、出两个方向，但是所代表的意义有所不同，需要结合智能合约、区块链浏览器来辅助判断。

### 1.总锁仓量 TVL（Total Value Locked）

即有多少金额锁定在借贷协议的智能合约中，TVL代表了协议的流动性。从[defillama](https://defillama.com/protocols/lending)数据来看，整体借贷市场TVL超过$10 B，前五的TVL总和约为$9.5 B，其中AAVE独占$3.9 B。

![](img/tvl.png)

以Arbitrum上的AAVE V3为例，做[TVL](https://dune.com/queries/1042816/1798270)的查询。

基本思路是：将AAVE智能合约中，定义为'Supply'的存入资金，减去定义为'Withdraw'的提取资金，就是锁定在合约中的总价值。打开[Arbscan](https://arbiscan.io/address/0x794a61358d6845594f94dc1db02a252b5b4814ad)找到一笔[AAVE的交易](https://arbiscan.io/tx/0x6b8069b62dc762e81b41651538d211f9a1a33009bcb41798e673d715867b2f29#eventlog)，点开log可以看到 topic0 = '0x2b627736bca15cd5381dcf80b0bf11fd197d01a037c52b927a881a10fb73ba61' 对应智能合约中'Supply'的行为。

![](img/arbscan1.png)

![](img/tvl2.png)

类似的，topic0 = '0x3115d1449a7b732c986cba18244e897a450f61e1bb8d589cd2e69e6c8924f9f7' 时对应'Withdraw'的行为（注，在Dune中topic1指的是etherscan中的topic0）。在Dune里，从Arbitrum的log表中选择发往AAVE V3合约的交易，根据topic定义“存入“和”提取“这两个动作（action_type）。存入为正提款为负，相加之后就是在合约内锁定的代币。用`bytearray_ltrim(topic1)`函数得到转账token的地址，用`bytearray_to_uint256(bytearray_substring(data, 1 + 32, 32))`函数得到转账token对应的数量（非usd计价金额）。

```sql
with aave_v3_transactions as (
    select 'Supply' as action_type,
        block_time,
        bytearray_ltrim(topic1) as token_address,
        bytearray_ltrim(topic2) as user_address,
        cast(bytearray_to_uint256(bytearray_substring(data, 1 + 32, 32)) as decimal(38, 0)) as raw_amount,
        tx_hash
    from arbitrum.logs
    where contract_address = 0x794a61358d6845594f94dc1db02a252b5b4814ad   -- Aave: Pool V3
        and topic0 = 0x2b627736bca15cd5381dcf80b0bf11fd197d01a037c52b927a881a10fb73ba61 -- Supply
        and block_time > date('2022-03-16') -- First transaction date
    
    union all
    
    select 'Withdraw' as action_type,
        block_time,
        bytearray_ltrim(topic1) as token_address,
        bytearray_ltrim(topic2) as user_address,
        -1 * cast(bytearray_to_uint256(bytearray_substring(data, 1 + 32, 32)) as decimal(38, 0)) as raw_amount,
        tx_hash
    from arbitrum.logs
    where contract_address = 0x794a61358d6845594f94dc1db02a252b5b4814ad   -- Aave: Pool V3
        and topic0 = 0x3115d1449a7b732c986cba18244e897a450f61e1bb8d589cd2e69e6c8924f9f7 -- Withdraw
        and block_time > date('2022-03-16') -- First transaction date
),

aave_v3_transactions_daily as (
    select date_trunc('day', block_time) as block_date,
        token_address,
        sum(raw_amount) as raw_amount_summary
    from aave_v3_transactions
    group by 1, 2
    order by 1, 2
)

select * from aave_v3_transactions_daily
```

到此我们得到了锁定在智能合约中的token数量，要得到美元计价的TVL，我们还需要将token和其价格匹配，这里我们手动选取了一些主流的币种：

```sql
token_mapping_to_ethereum(aave_token_address, ethereum_token_address, token_symbol) as (
    values
    (0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9, 0xdac17f958d2ee523a2206206994597c13d831ec7, 'USDT'),
    (0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f, 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599, 'WBTC'),
    (0xd22a58f79e9481d1a88e00c343885a588b34b68b, 0xdb25f211ab05b1c97d595516f45794528a807ad8, 'EURS'),
    (0xff970a61a04b1ca14834a43f5de4533ebddb5cc8, 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48, 'USDC'),
    (0xf97f4df75117a78c1a5a0dbb814af92458539fb4, 0x514910771af9ca656af840dff83e8264ecf986ca, 'LINK'),
    (0x82af49447d8a07e3bd95bd0d56f35241523fbab1, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 'WETH'),
    (0xda10009cbd5d07dd0cecc66161fc93d7c9000da1, 0x6b175474e89094c44da98b954eedeac495271d0f, 'DAI'),
    (0xba5ddd1f9d7f570dc94a51479a000e3bce967196, 0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9, 'AAVE')
),

latest_token_price as (
    select date_trunc('hour', minute) as price_date,
        contract_address,
        symbol,
        decimals,
        avg(price) as price
    from prices.usd
    where contract_address in (
        select ethereum_token_address
        from token_mapping_to_ethereum
    )
    and minute > now() - interval '1' day
    group by 1, 2, 3, 4
),

latest_token_price_row_num as (
    select  price_date,
        contract_address,
        symbol,
        decimals,
        price,
        row_number() over (partition by contract_address order by price_date desc) as row_num
    from latest_token_price
),

current_token_price as (
    select contract_address,
        symbol,
        decimals,
        price
    from latest_token_price_row_num
    where row_num = 1
),
```

用raw amount除以对应token的小数位（decimal）（例如ETH的decimal是18，USDT的是6），得到实际token有多少枚，再和对应价格相乘得到以usd为计价单位的金额，求和后得到总的TVL。

```sql
daily_liquidity_change as (
    select d.block_date,
        p.symbol,
        d.token_address,
        d.raw_amount_summary / power(10, coalesce(p.decimals, 0)) as original_amount,
        d.raw_amount_summary / power(10, coalesce(p.decimals, 0)) * coalesce(p.price, 1) as usd_amount
    from aave_v3_transactions_daily d
    inner join token_mapping_to_ethereum m on d.token_address = m.aave_token_address
    left join current_token_price p on m.ethereum_token_address = p.contract_address
    order by 1, 2
)

select sum(usd_amount) / 1e6 as total_value_locked_usd
from daily_liquidity_change
```
参考：https://dune.com/queries/1037796/1798021。

### 2.未偿贷款（Outstanding Loan）

即外借出去尚未归还的金额。与计算TVL时类似，参考区块链浏览器的数据，找出topic0（1）所对应的合约功能，用借出的（‘Borrow’）减去已偿还（‘Repay’）的。

参考：https://dune.com/queries/1037796/1798021

```sql
 select 'Borrow' as action_type,
    block_time,
    bytearray_ltrim(topic1) as token_address,
    bytearray_ltrim(topic2) as user_address,
    cast(bytearray_to_uint256(bytearray_substring(data, 1 + 32, 32)) as decimal(38, 0)) as raw_amount,
    tx_hash
from arbitrum.logs
where contract_address = 0x794a61358d6845594f94dc1db02a252b5b4814ad   -- Aave: Pool V3
    and topic0 = 0xb3d084820fb1a9decffb176436bd02558d15fac9b0ddfed8c465bc7359d7dce0 -- Borrow
    and block_time > date('2022-03-16') -- First transaction date

union all

select 'Repay' as action_type,
    block_time,
    bytearray_ltrim(topic1) as token_address,
    bytearray_ltrim(topic2) as user_address,
    -1 * cast(bytearray_to_uint256(bytearray_substring(data, 1 + 32, 32)) as decimal(38, 0)) as raw_amount,
    tx_hash
from arbitrum.logs
where contract_address = 0x794a61358d6845594f94dc1db02a252b5b4814ad   -- Aave: Pool V3
    and topic0 = 0xa534c8dbe71f871f9f3530e97a74601fea17b426cae02e1c5aee42c96c784051 -- Repay
    and block_time > date('2022-03-16') -- First transaction date

limit 100
```


### 3.资本效率（Utilization Ratio）

简单理解就是存入协议中的资金有多少被真正利用起来（借走）了，当前Arbitrum上AAVE V3的资本效率大约在30%，处于一个低杠杆水平，对比21年牛市时，资金利用率在40%-80%之间。有了前两段的基础，计算这部分并不困难，参考https://dune.com/queries/1037796/1798141。

![](img/ur.png)

![](img/ur.jpg)


### 4.详细分类

包括合约锁定资产构成和用户行为分布，参考：https://dune.com/queries/1026402/1771390。

![](img/4.1.png)

AAVE在Arbitrum上资金池中占比前三的是WETH（37.6%）、USDC（29.5%）和WBTC（22.6%）。目前还处于熊市，用户对杠杆需求不强烈，整体以存款吃息为主。

![](img/4.2.png)

### 5.基础指标 

一些基础的协议分析指标，如用户数，交易数，日均变化量情况，参考：https://dune.com/queries/1026141/1771147。

![](img/dunedata.png)

## 借贷的综合看板

1. Arbitrum上AAVE V3的综合dashboard。

https://dune.com/sixdegree/aave-on-arbitrum-overview

![](img/dashboard.png)

2. 将以太坊上三大经典借贷协议Maker，AAVE和Compound进行对比的dashboard。不过这个dashboard比较老，用的是Dune V1引擎，Dune即将下架V1，今后只使用V2，所以大家学习时借鉴思路即可。

https://dune.com/datanut/Compound-Maker-and-Aave-Deposits-Loans-LTV

![](img/dashboard2.png)

## 参考
1. https://foresightnews.pro/article/detail/17638
2. https://learnblockchain.cn/article/5036
3. https://twitter.com/0xhiger/status/1595076528697905157
4. https://www.blocktempo.com/why-do-defi-lending-protocols-generate-bad-debts/
5. https://www.panewslab.com/zh/articledetails/k1ep9df5.html
6. https://new.qq.com/rain/a/20201121A096UF00

## SixdegreeLab介绍

SixdegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixdegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
