# MEV研究——以Uniswap V3为例

## 什么是MEV？

MEV（miner-extractable value）的概念最早出现在2019年的Flashboy 2.0一文中，指的是矿工通过包含、重新排序、插入或忽略交易可以获得的额外利润。随着近两年区块链的发展和链上研究活动的推进，MEV现在已经延伸到最大可提取价值（maximal extractable value）。

以太坊是链上活动最丰富、最活跃的主网，讨论以太坊上MEV诞生的几个前提：

1. 以太坊的Gas机制本质上是拍卖机制，价高者得，且设计交易是串行的。即谁出的gas高，矿工/验证者会先打包哪个交易进块，以此达到收益最大化。这是以太坊为人诟病的gas昂贵、拥堵的原因之一，也为MEV的出现带来可能：一旦发现有利可图的交易，可以通过贿赂矿工（提高gas）的方法率先执行。

2. 区块链内存池Mempool的设计。所有发送出去的交易都需要暂时进入内存池，而不是由矿工直接打包。内存池中充满了待处理的交易，并且是公开的，这意味着任何人都可以监控内存池中的每笔交易和调用的每个函数，这为攻击者提供了监视交易的条件。

3. 根据 [Etherscan](https://etherscan.io/blocks) 数据，目前以太坊的平均出块时间为 12s。较长的出块时间出于节点同步的安全性考虑，也为攻击者提供了执行时间。

这里有意思的问题是，Solana既没有mempool，出块速度又快，不应该没有MEV吗？实际上Solana也有超级节点产生MEV，在此先不做讨论，仅讨论以太坊上的MEV。

### MEV的分类

### MEV现状
我们可以通过一些直观的数据来观察MEV市场的现状


### MEV的未来

## 如何分析MEV

## 参考
1. Understanding the Full Picture of MEV https://huobi-ventures.medium.com/understanding-the-full-picture-of-mev-4151160b7583
2. Flashboy 2.0 https://arxiv.org/pdf/1904.05234.pdf

## SixDegreeLab介绍

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixDegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
