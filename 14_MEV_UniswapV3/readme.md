# MEV研究——以Uniswap V3为例

## 什么是MEV？

MEV（miner-extractable value）的概念最早出现在2019年的Flashboy 2.0一文中，指的是矿工通过包含、重新排序、插入或忽略交易可以获得的额外利润。随着近两年区块链的发展和链上研究活动的推进，MEV现在已经延伸到最可提取的价值。


我们认为链上攻击的本质原因在于区块链的设计。

1. 首先是区块链内存池的设计。所有发送出去的交易都需要暂时进入内存池，而不是由矿工直接打包。内存池中充满了待处理的交易，并且是公开的，这意味着任何人都可以监控内存池中的每笔交易和调用的每个函数。这为攻击者提供了监视交易的条件。

2. 二是区块链出块时间为攻击者提供了执行时间。根据 Etherscan 数据，目前以太坊的平均出块时间为 13s。

### MEV的历史

### MEV的分类

### MEV的未来

## 如何分析MEV

## 参考
1. Understanding the Full Picture of MEV https://huobi-ventures.medium.com/understanding-the-full-picture-of-mev-4151160b7583
2. Flashboy 2.0 https://arxiv.org/pdf/1904.05234.pdf

## SixDegreeLab介绍

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixDegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
