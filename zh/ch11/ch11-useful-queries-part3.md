# 常见查询三：自定义数据、数字序列、数组、JSON等

在常见查询的前面两个部分，我们分别介绍了ERC20代币的价格查询、持有者、持有余额等常见的一些查询方法。在这一部分，我们再介绍一些其他方面的常用查询。

## 使用CTE自定义数据表

Dune V2目前还不支持用户自定义表和视图，对于一些来源外部数据源的数据或者手动整理的少量数据，我们可以考虑在查询内使用CTE来生成自定义数据列表。经过测试，对于只包括几个字段的情况，可以支持包含上千行数据的自定义CTE数据表，只要不超过Dune查询请求的最大数据量限制，就能成功执行。下面介绍两种自定义CTE数据表的方式：

第一种语法示例：
```sql
with raydium_lp_pairs(account_key, pair_name) as (
    values
    ('58oQChx4yWmvKdwLLZzBi4ChoCc2fqCUWBkwMihLYQo2', 'SOL/USDC'),
    ('7XawhbbxtsRcQA8KTkHT9f9nc6d69UwqCDh6U5EEbEmX', 'SOL/USDT'),
    ('AVs9TA4nWDzfPJE9gGVNJMVhcQy3V9PGazuz33BfG2RA', 'RAY/SOL'),
    ('6UmmUiYoBjSrhakAobJw8BvkmJtDVxaeBtbt7rxWo1mg', 'RAY/USDC'),
    ('DVa7Qmb5ct9RCpaU7UTpSaf3GVMYz17vNVU67XpdCRut', 'RAY/USDT'),
    ('GaqgfieVmnmY4ZsZHHA6L5RSVzCGL3sKx4UgHBaYNy8m', 'RAY/SRMSOL'),
    ('6a1CsrpeZubDjEJE9s1CMVheB6HWM5d7m1cj2jkhyXhj', 'STSOL/USDC'),
    ('43UHp4TuwQ7BYsaULN1qfpktmg7GWs9GpR8TDb8ovu9c', 'APEX4/USDC')
)

select * from raydium_lp_pairs
```

第二种语法示例：

```sql
with token_plan as (
    select token_name, hook_amount from (
        values
        ('Token Type','BEP-20 on BNB Chain'),
        ('Total Token Supply','500,000,000 HOOK'),
        ('Private Sale Allocation','100,000,000 HOOK'),
        ('Private Sale Token Price','0.06 USD to 0.12 USD / HOOK'),
        ('Private Sale Amount Raised','~ 6,000,000 USD'),
        ('Binance Launchpad Sale Allocation','25,000,000 HOOK'),
        ('Binance Launchpad Sale Price','0.10 USD / HOOK'),
        ('Binance Launchpad Amount to be Raised','2,500,000 USD'),
        ('Initial Circ. Supply When Listed on Binance','50,000,000 HOOK (10.00%)')
    ) as tbl(token_name, hook_amount)
)

select * from token_plan
```

当然，对于第二种语法，如果碰巧你只需要返回这部分自定义的数据，则可以省略CTE定义，直接使用其中的SELECT查询。

以上查询的示例链接：
- [https://dune.com/queries/781862](https://dune.com/queries/781862)
- [https://dune.com/queries/1650640](https://dune.com/queries/1650640)

由于前面提到的局限性，数据行太多时可能无法执行成功，而且你需要在每一个查询中复制同样的CTE代码，相对来说很不方便。对于数据量大、需要多次、长期使用等情况，还是应该考虑通过提交spellbook PR来生成魔法表。

## 从事件日志原始表解析数据

之前在讲解计算ERC20代币价格时，我们介绍过从事件日志原始表（logs）解析计算价格的例子。这里再举例说明一下其他需要直接从logs解析数据的情况。当遇到智能合约未被Dune解析，或者因为解析时使用的ABI数据不完整导致没有生成对应事件的解析表的情况，我们就可能需要直接从事件日志表解析查询数据。以Lens 协议为例，我们发现在Lens的智能合约源代码中（[Lens Core](https://github.com/lens-protocol/core)），几乎每个操作都有发生生成事件日志，但是Dune解析后的数据表里面仅有少数几个Event相关的表。进一步的研究发现时因为解析时使用的ABI缺少了这些事件的定义。我们当然可以重新生成或者找Lens团队获取完整的ABI，提交给Dune去再次解析。不过这里的重点是如何从未解析的日志里面提取数据。

在Lens智能合约的源代码里，我们看到了`FollowNFTTransferred`事件定义，[代码链接](https://github.com/lens-protocol/core/blob/main/contracts/libraries/Events.sol#L347)。代码里面也有`Followed`事件，但是因为其参数用到了数组，解析变得复杂，所以这里用前一个事件为例。从事件名称可以推断，当一个用户关注某个Lens Profile时，将会生成一个对应的关注NFT （FollowNFT）并把这个NFT转移到关注者的地址。那我们可以找到一个关注的交易记录，来看看里面的logs，示例交易：[https://polygonscan.com/tx/0x30311c3eb32300c8e7e173c20a6d9c279c99d19334be8684038757e92545f8cf](https://polygonscan.com/tx/0x30311c3eb32300c8e7e173c20a6d9c279c99d19334be8684038757e92545f8cf)。在浏览器打开这个交易记录页面并切换到“Logs”标签，我们可以看到一共有4个事件日志。对于一些事件，区块链浏览器可以显示原始的事件名称。我们查看的这个Lens交易没有显示原始的名称，那我们怎么确定哪一个是对应`FollowNFTTransferred`事件日志记录的呢？这里我们可以结合第三方的工具，通过生成事件定义的keccak256哈希值来比较。[Keccak-256](https://emn178.github.io/online-tools/keccak_256.html)这个页面可以在线生成Keccak-256哈希值。我们将源代码中`FollowNFTTransferred`事件的定义整理为精简模式（去除参数名称，去除空格），得到`FollowNFTTransferred(uint256,uint256,address,address,uint256)`，然后将其粘贴到Keccak-256工具页面，生成的哈希值为`4996ad2257e7db44908136c43128cc10ca988096f67dc6bb0bcee11d151368fb`。（最新的Dune解析表已经有Lens项目的完整事件表，这里仅作示例用途）

![image_08.png](img/image_08.png)

使用这个哈希值在Polygonscan的交易日志列表中搜索，即可找到匹配项。可以看到第一个日志记录正好就是我们要找的。

![image_09.png](img/image_09.png)

找到了对应的日志记录，剩下的就简单了。结合事件的定义，我们可以很容易的进行数据解析：

```sql
select block_time,
    tx_hash,
    bytearray_to_uint256(topic1) as profile_id, -- 关注的Profile ID
    bytearray_to_uint256(topic2) as follower_token_id, -- 关注者的NFT Token ID
    bytearray_ltrim(bytearray_substring(data, 1, 32)) as from_address2, -- NFT转出地址
    bytearray_ltrim(bytearray_substring(data, 1 + 32, 32)) as to_address2 -- NFT转入地址（也就是关注者的地址）
from polygon.logs
where contract_address = 0xdb46d1dc155634fbc732f92e853b10b288ad5a1d -- Lens合约地址
    and block_time >= date('2022-05-01') -- Lens合约部署在此日期之后，此条件用于改善查询速度
    and topic0 = 0x4996ad2257e7db44908136c43128cc10ca988096f67dc6bb0bcee11d151368fb   -- 事件主题 FollowNFTTransferred
limit 10
```

以上查询的示例链接：
- [https://dune.com/queries/1652759](https://dune.com/queries/1652759)
- [Keccak-256 Tool](https://emn178.github.io/online-tools/keccak_256.html)

## 使用数字序列简化查询

研究NFT项目时，我们可能需要分析某个时间段内某个NFT项目等所有交易的价格分布情况，也就是看下每一个价格区间内有多少笔交易记录。通常我们会设置最大成交价格和最小成交价格（通过输入或者从成交数据中查询并对异常值做适当处理），然后将这个范围内的价格划分为N个区间，再统计每个区间内的交易数量。下面是逻辑简单但是比较繁琐的查询示例：

```sql
-- nft持仓成本分布
-- 0x306b1ea3ecdf94ab739f1910bbda052ed4a9f949 beanz
-- 0xED5AF388653567Af2F388E6224dC7C4b3241C544 azuki
with contract_transfer as (
    select * 
    from nft.trades
    where nft_contract_address = 0xe361f10965542ee57D39043C9c3972B77841F581
        and tx_to != 0x0000000000000000000000000000000000000000
        and amount_original is not null
),

transfer_rn as (
    select row_number() over (partition by token_id order by block_time desc) as rn, *
    from contract_transfer
),

latest_transfer as (
    select * from transfer_rn
    where rn = 1 
),

min_max as (
    select (cast({{max_price}} as double) - cast({{min_price}} as double))/20.0 as bin
),

bucket_trade as (select *,
    case 
      when amount_original between {{min_price}}+0*bin and {{min_price}}+1*bin then 1*bin
      when amount_original between {{min_price}}+1*bin and {{min_price}}+2*bin then 2*bin
      when amount_original between {{min_price}}+2*bin and {{min_price}}+3*bin then 3*bin
      when amount_original between {{min_price}}+3*bin and {{min_price}}+4*bin then 4*bin
      when amount_original between {{min_price}}+4*bin and {{min_price}}+5*bin then 5*bin
      when amount_original between {{min_price}}+5*bin and {{min_price}}+6*bin then 6*bin
      when amount_original between {{min_price}}+6*bin and {{min_price}}+7*bin then 7*bin
      when amount_original between {{min_price}}+7*bin and {{min_price}}+8*bin then 8*bin
      when amount_original between {{min_price}}+8*bin and {{min_price}}+9*bin then 9*bin
      when amount_original between {{min_price}}+9*bin and {{min_price}}+10*bin then 10*bin
      when amount_original between {{min_price}}+10*bin and {{min_price}}+11*bin then 11*bin
      when amount_original between {{min_price}}+11*bin and {{min_price}}+12*bin then 12*bin
      when amount_original between {{min_price}}+12*bin and {{min_price}}+13*bin then 13*bin
      when amount_original between {{min_price}}+13*bin and {{min_price}}+14*bin then 14*bin
      when amount_original between {{min_price}}+14*bin and {{min_price}}+15*bin then 15*bin
      when amount_original between {{min_price}}+15*bin and {{min_price}}+16*bin then 16*bin
      when amount_original between {{min_price}}+16*bin and {{min_price}}+17*bin then 17*bin
      when amount_original between {{min_price}}+17*bin and {{min_price}}+18*bin then 18*bin
      when amount_original between {{min_price}}+18*bin and {{min_price}}+19*bin then 19*bin
      when amount_original between {{min_price}}+19*bin and {{min_price}}+20*bin then 20*bin
      ELSE 21*bin
    end as gap
  from latest_transfer,min_max
 )

select gap, count(*) as num
from bucket_trade
group by gap
order by gap 
```

这个例子中，我们定义了两个参数`min_price`和`max_price`，将他们的差值等分为20份作为分组价格区间，然后使用了一个冗长的CASE语句来统计每个区间内的交易数量。想象一下如果需要分成50组的情况。有没有更简单的方法呢？答案是有。先看代码：

```sql
with contract_transfer as (
    select * 
    from nft.trades
    where nft_contract_address = 0xe361f10965542ee57D39043C9c3972B77841F581
        and tx_to != 0x0000000000000000000000000000000000000000
        and amount_original is not null
),

transfer_rn as (
    select row_number() over (partition by token_id order by block_time desc) as rn, *
    from contract_transfer
),

latest_transfer as (
    select *
    from transfer_rn
    where rn = 1 
),

min_max as (
    select (cast({{max_price}} as double) - cast({{min_price}} as double))/20.0 as bin
),

-- 生成一个1到20数字的单列表
num_series as (
    select num from unnest(sequence(1, 20)) as tbl(num)
),

-- 生成分组价格区间的开始和结束价格
bin_gap as (
    select (num - 1) * bin as gap,
        (num - 1) * bin as price_lower,
        num * bin as price_upper
    from num_series
    join min_max on true
    
    union all
    
    -- 补充一个额外的区间覆盖其他数据
    select num * bin as gap,
        num * bin as price_lower,
        num * 1e4 * bin as price_upper
    from num_series
    join min_max on true
    where num = 20
),

bucket_trade as (
    select t.*,
        b.gap
      from latest_transfer t
      join bin_gap b on t.amount_original >= b.price_lower and t.amount_original < b.price_upper
 )

select gap, count(*) as num
from bucket_trade
group by gap
order by gap
```

在CTE`num_series`中，我们使用`unnest(sequence(1, 20)) as tbl(num)`来生成了一个从1到20点数字序列并且转换为20行，每行一个数字。然后在`bin_gap`中，我们通过JOIN两个CTE计算得到了每一个区间的低点价格值和高点价格值。使用`union all`集合添加了一个额外的高点价格值足够大的区间来覆盖其他交易记录。接下来`bucket_trade`就可以简化为只需要简单关联`bin_gap`并比较价格落入对应区间即可。整体上逻辑得到了简化而显得更加清晰易懂。

以上查询的示例链接：
- [https://dune.com/queries/1054461](https://dune.com/queries/1054461)
- [https://dune.com/queries/1654001](https://dune.com/queries/1654001)

## 读取数组Array和结构Struct字段中的数据

有的智能合约发出的事件日志使用数组类型的参数，此时Dune解析后生成的数据表也是使用数组来存贮的。Solana区块链的原始交易数据表更是大量使用了数组来存贮数据。也有些数据是保存在结构类型的，或者我们在提取数据时需要借用结构类型（下文有例子）。我们一起来看下如何访问保存着数组字段和结构字段中的数据。

```sql
select tokens, deltas, evt_tx_hash
from balancer_v2_arbitrum.Vault_evt_PoolBalanceChanged
where evt_tx_hash = 0x65a4f35d81fd789d93d79f351dc3f8c7ed220ab66cb928d2860329322ffff32c
```

上面查询返回的前两个字段都是数组类型（我处理了一下，显示如下图）：

![image_10.png](img/image_10.png)

我们可以使用`cross join unnest(tokens) as tbl1(token)`来将`tokens`数组字段拆分为多行：

```sql
select evt_tx_hash, deltas, token   -- 返回拆分后的字段
from balancer_v2_arbitrum.Vault_evt_PoolBalanceChanged
cross join unnest(tokens) as tbl1(token)   -- 拆分为多行，新字段命名为 token
where evt_tx_hash = 0x65a4f35d81fd789d93d79f351dc3f8c7ed220ab66cb928d2860329322ffff32c
```

同样我们可以对`deltas`字段进行拆分。但是因为每一个`cross join`都会将拆分得到的值分别附加到查询原来的结果集，如果同时对这两个字段执行操作，我们就会得到一个类似笛卡尔乘积的错误结果集。查询代码和输出结果如下图所示：

```sql
select evt_tx_hash, token, delta
from balancer_v2_arbitrum.Vault_evt_PoolBalanceChanged
cross join unnest(tokens) as tbl1(token)   -- 拆分为多行，新字段命名为 token
cross join unnest(deltas) as tbl2(delta)   -- 拆分为多行，新字段命名为 delta
where evt_tx_hash = 0x65a4f35d81fd789d93d79f351dc3f8c7ed220ab66cb928d2860329322ffff32c
```

![image_11.png](img/image_11.png)

要避免重复，正确的做法是在同一个`unnest()`函数里面同时对多个字段进行拆分，返回一个包括多个对应新字段的临时表。

```sql
select evt_tx_hash, token, delta
from balancer_v2_arbitrum.Vault_evt_PoolBalanceChanged
cross join unnest(tokens, deltas) as tbl(token, delta)   -- 拆分为多行，新字段命名为 token 和 delta
where evt_tx_hash = 0x65a4f35d81fd789d93d79f351dc3f8c7ed220ab66cb928d2860329322ffff32c
```

结果如下图所示：

![image_12.png](img/image_12.png)

以上查询的示例链接：
- [https://dune.com/queries/1654079](https://dune.com/queries/1654079)


## 读取JSON字符串数据

有的智能合约的解析表里，包含多个参数值的对象被序列化为json字符串格式保存，比如我们之前介绍过Lens的创建Profile事件。我们可以使用`:`来直接读取json字符串中的变量。例如：

```sql
select  json_value(vars, 'lax $.to') as user_address, -- 读取json字符串中的用户地址
     json_value(vars, 'lax $.handle') as handle_name, -- 读取json字符串中的用户昵称
    call_block_time,
    output_0 as profile_id,
    call_tx_hash
from lens_polygon.LensHub_call_createProfile
where call_success = true   
limit 100
```

另外的方式是使用`json_query()`或`json_extract()`函数来提取对应数据。当需要从JSON字符串中提取数组类型的值时，使用`json_extract()`函数才能支持类型转换。举例如下：

```sql
select
json_query(vars, 'lax $.follower') AS follower, -- single value
json_query(vars, 'lax $.profileIds') AS profileIds, -- still string
from_hex(cast(json_extract(vars,'$.follower') as varchar)) as follower2, -- cast to varbinary
cast(json_extract(vars,'$.profileIds') as array(integer)) as profileIds2, -- cast to array
vars
from lens_polygon.LensHub_call_followWithSig
where cardinality(output_0) > 1
limit 10
```

以上查询的示例链接：
- [https://dune.com/queries/1562662](https://dune.com/queries/1562662)
- [https://dune.com/queries/941978](https://dune.com/queries/941978)
- [https://dune.com/queries/1554454](https://dune.com/queries/1554454)

Dune SQL (Trino 引擎) JSON相关函数的详细帮助可以查看：https://trino.io/docs/current/functions/json.html 

## SixdegreeLab介绍

SixdegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixdegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
