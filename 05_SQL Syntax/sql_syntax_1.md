## 基础概念
**1、数据仓库是什么？**
说人话就是说就是出于数据统计的需要，把一些数据分门别类地存储起来,存储的载体是【数据表】。针对某一个或者一些主题的一系列【数据表】合在一起就是数据仓库。  
注意:
这里的数据可以是结果数据(比如Uniswap上线以来某个交易对每天的交易量统计)
也可以是过程数据(Uniswap上线以来某个交易对发生的每一条交易记录明细：谁发起的，用A换B，交易时间，tx_hash，交易数量….).   
**2、SQL是什么？**
假设你想吃脆香米巧克力，但是你这会儿出不了门，你就叫个跑腿说：我需要一盒巧克力，他的牌子是脆香米。跑腿去了趟超市把巧克力买来送到你家。
类比过来SQL就是你说的那句话，Dune Analytics就是个跑腿儿，他可以让你可以跟数据仓库对话，并且将数据仓库里的数据给你搬出来给你。SQL最基本的结构或者语法就3个模块，几乎所有的SQL都会包含这3个部分
**select**: 取哪个字段？
**from**：从哪个表里取？
**where**：限制条件是什么？    
**3、数据表长什么样？**  
你可以认为表就是一个一个的Excel 表，每一个Excel 表里存的不同的数据。以ethereum.transactions(以太坊上的transactions记录)为例
![query-page](images/raw_data.png)
先说下表里用比较多的几个字段
- **block_time**:交易被打包的时间
- **block_number**：交易被打包的区块高度
- **value**：转出了多少ETH(需要除以power(10,18)来换算精度)
- **from**：ETH从哪个钱包转出的
- **to**： ETH转到了哪个钱包
- **hash**：这个transaction的tx hash
- **success**：transaction是否成功
PS:可以随便抽1个hash粘贴到以太坊浏览器里会更容易理解这些字段的含义


## 常见语法以及使用案例
### 1.基础结构·运算符·排序
**案例1**:我想看看孙哥钱包(0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296)在2022年1月份以来的每一笔ETH的大额转出(>1000ETH)是在什么时候以及具体的转出数量
```sql
select --Select后跟着需要查询的字段，多个字段用空格隔开
    block_time 
    ,from
    ,to
    ,hash
    ,value /power(10,18) as value --通过将value除以/power(10,18)来换算精度，18是以太坊的精度
from ethereum.transactions --从 ethereum.transactions表中获取数据
where block_time > '2022-01-01'  --限制Transfer时间是在2022年1月1日之后
and from = lower('0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296') --限制孙哥的钱包，这里用lower()将字符串里的字母变成小写格式(dune数据库里存的模式是小写，直接从以太坊浏览器粘贴可能大些混着小写)
and value /power(10,18) >1000 --限制ETH Transfer量大于1000
order by block_time --基于blocktime做升序排列，如果想降序排列需要在末尾加desc
```
