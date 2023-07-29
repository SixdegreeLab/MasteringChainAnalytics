# Dune SQL 查询引擎入门

Dune 已经正式推出了其团队基于Trino（[https://trino.io/](https://trino.io/)）自研的查询引擎Dune SQL。本文介绍Dune SQL的一些常见查询语法、注意事项和细节。

注：由于Dune已经宣布2023年下半年起将全面过渡到Dune SQL查询引擎，所以本篇教程将原有的所有Query全部升级到了Dune SQL 版本。

## Dune SQL 语法概览

Dune SQL需要注意的书写语法要点有几个：
- Dune SQL 使用双引号来引用包含特殊字符或者本身是关键字的字段名或表名，如` "from", "to" `。
- Dune SQL的字符串类型和常用数值类型分别是`varchar`、`double`和`decimal(38, 0)`。
- Dune SQL 不支持隐式类型转换。比如，Dune SQL中，不能将`'2022-10-01'`直接与 block_time 进行比较，需要用 `date('2022-10-01')`等函数显式转换为日期后才能比较。不能直接将数值类型和字符串连接，要用`cast(number_value as varchar)`转换为字符串后才能连接。

Dune 文档提供了一份比较详细的语法对照表表，链接是：[Syntax Comparison](https://dune.com/docs/reference/dune-v2/query-engine/#syntax-comparison)，大家可以参考。下图列出了部分差异对照：

![image_01.png](img/image_01.png)


## Dune SQL 实例

### Dune SQL使用双引号引用特殊字段名和表名

Dune SQL使用双引号

```sql
select "from" as address, gas_price, gas_used
from ethereum.transactions
where success = true
limit 10
```

### 日期时间

Dune SQL 不支持字符串格式的日期值隐式转换为日期时间类型的值，必须使用显式转换。可以使用日期时间函数或者日期时间操作符。

1. 使用日期值

Dune SQL使用date()函数

```sql
select block_time, hash, "from" as address, "to" as contract_address
from ethereum.transactions
where block_time >= date('2022-12-18')
limit 10
```

2. 使用日期时间值

Dune SQL使用timestamp 操作符

```sql
select block_time, hash, "from" as address, "to" as contract_address
from ethereum.transactions
where block_time >= timestamp '2022-12-18 05:00:00'
limit 10
```

3. 使用interval

Dune SQL使用`interval '12' hour`

```sql
select block_time, hash, "from" as address, "to" as contract_address
from ethereum.transactions
where block_time >= now() - interval '12' hour
limit 10
```

### 地址和交易哈希

Dune SQL 查询中，地址和哈希值可以不放入单引号中直接使用，此时大小写不敏感，可以不显示转换为小写格式。

```sql
select block_time, hash, "from" as address, "to" as contract_address
from ethereum.transactions
where block_time >= date('2022-12-18') and block_time < date('2022-12-19')
    and (
        hash = 0x2a5ca5ff26e33bec43c7a0609670b7d7db6f7d74a14d163baf6de525a166ab10
        or "from" = 0x76BE685c0C8746BBafECD1a578fcaC680Db8242E
        )
```

### Dune SQL的字符串类型 varchar 和数值类型 double

Dune SQL中的字符串和常用数值类型是`varchar`和`double`。Dune SQL中的整数值默认是`bigint`类型，在做一些大数字的乘法时，容易产生溢出错误，此时可以强制转换为`double`类型或者`decimal(38, 0)`类型。Dune SQL中进行整数除法也不会隐式转换为浮点数再进行相除，而是直接返回一个整数，这点也需要注意。

1. 转换为字符串

Dune SQL

```sql
select block_time, hash, "from" as address, "to" as contract_address,
    cast(value / 1e9 as varchar) || ' ETH' as amount_value,
    format('%,.2f', value / 1e9) || ' ETH' as amount_value_format
from ethereum.transactions
where block_time >= date('2022-12-18') and block_time < date('2022-12-19')
    and (
        hash = 0x2a5ca5ff26e33bec43c7A0609670b7d7db6f7d74a14d163baf6de525a166ab10
        or "from" = 0x76BE685c0C8746BBafECD1a578fcaC680Db8242E
        )
```

检查上面的SQL输出，可以看到当将比较大或者比较小的数字直接cast()转换为字符串时，会被处理为科学计数法的输出格式，效果不太理想。使用`format()`则可以精确控制输出的字符串的格式，所以推荐用这种方式。

2. 转换为数值

注意，表`erc20_ethereum.evt_Transfer`中，`value`字段的类型是字符串。可以使用`cast()`函数将其转换为double 或者 decimal(38, 0) 数值类型。

```sql
select evt_block_time, evt_tx_hash, "from", "to", 
    cast(value as double) as amount,
    cast(value as decimal(38, 0)) as amount2
from erc20_ethereum.evt_Transfer
where evt_block_time >= date('2022-12-18') and evt_block_time < date('2022-12-19')
    and evt_tx_hash in (
        0x2a5ca5ff26e33bec43c7a0609670b7d7db6f7d74a14d163baf6de525a166ab10,
        0xb66447ec3fe29f709c43783621cbe4d878cda4856643d1dd162ce875651430fc
    )
```

### 强制类型转换

如前所述，Dune SQL不支持隐式类型转换，当我们需要将两种不同类型的值进行比较或者执行某些操作的时候，就需要确保它们是相同的（兼容的）数据类型，如果不是，则需要使用相关的函数或者操作符进行显式的类型转换。否则可能会遇到类型不匹配相关的错误。这里再举一个简单例子：

Dune SQL未做类型转换时，下面的SQL会报错：

```sql
select 1 as val
union all
select '2' as val
```

Dune SQL显式类型转换，可以执行

```sql
select 1 as val
union all
select cast('2' as int) as val
```

当我们遇到类似"Error: Line 47:1: column 1 in UNION query has incompatible types: integer, varchar(1) at line 47, position 1."这种错误时，就需要处理相应字段的类型兼容问题。

### 转换为double类型解决数值范围溢出错误

Dune SQL 支持整数类型 `int` 和 `bigint`，但是由于EVM等区块链不支持小数导致数值经常很大，比如当我们计算gas 费的时候，就可能遇到数值溢出的错误。下面的SQL，为了故意导致错误，我们将计算的gas fee乘以1000倍了：

```sql
select hash, gas_price * gas_used * 1000 as gas_fee
from ethereum.transactions 
where block_time >= date('2022-12-18') and block_time < date('2022-12-19')
order by gas_used desc
limit 10
```

执行上面的SQL将会遇到错误：
```
Error: Bigint multiplication overflow: 15112250000000000 * 1000.
```

为了避免类型溢出错误，我们可以将第一个参数显式转换为double类型。下面的SQL可以正确执行：

```sql
select hash, cast(gas_price as double) * gas_used * 1000 as gas_fee
from ethereum.transactions 
where block_time >= date('2022-12-18') and block_time < date('2022-12-19')
order by gas_used desc
limit 10
```

### 转换为double类型解决整数相除不能返回小数位的问题

同样，如果两个数值是bigint 类型，二者相除默认返回的也是整数类型，小数部分会被舍弃。如果希望返回小数部分，可以将被除数显式转换为double类型。

```sql
select hash, gas_used, gas_limit,
    gas_used / gas_limit as gas_used_percentage
from ethereum.transactions 
where block_time >= date('2022-12-18') and block_time < date('2022-12-19')
limit 10
```

执行上面的SQL，gas_used_percentage的值将会是0或者1，小数部分被舍弃取整，显然这不是我们想要的结果。将被除数gas_used显式转换为double类型，可以得到正确结果：

```sql
select hash, gas_used, gas_limit,
    cast(gas_used as double) / gas_limit as gas_used_percentage
from ethereum.transactions 
where block_time >= date('2022-12-18') and block_time < date('2022-12-19')
limit 10
```

### 从Hex十六进制转换到十进制

Dune SQL 定义了一组新的函数来处理将varbinary类型字符串转换到十进制数值的转换，字符串必须以`0x`前缀开始。

```sql
select bytearray_to_uint256('0x00000000000000000000000000000000000000000000005b5354f3463686164c') as amount_raw
```

详细帮助可以参考：[Byte Array to Numeric Functions](https://dune.com/docs/query/DuneSQL-reference/Functions-and-operators/varbinary/#byte-array-to-numeric-functions)


### 生成数值序列和日期序列

1. 数值序列

Dune SQL生成数值序列的语法：

```sql
select num from unnest(sequence(1, 10)) as t(num)
-- select num from unnest(sequence(1, 10, 2)) as t(num) -- step 2
```

2. 日期序列

Duen SQL使用`unnest()`搭配`sequence()`来生成日期序列值并转换为多行记录。

Dune SQL生成日期序列的语法：

```sql
select block_date from unnest(sequence(date('2022-01-01'), date('2022-01-31'))) as s(block_date)
-- select block_date from unnest(sequence(date('2022-01-01'), date('2022-01-31'), interval '7' day)) as s(block_date)
```

### 数组查询

1. Dune SQL 使用`cardinality()`查询数组大小。

Dune SQL语法：

```sql
select evt_block_time, evt_tx_hash, profileIds
from lens_polygon.LensHub_evt_Followed
where cardinality(profileIds) = 2
limit 10
```

2. Dune SQL 数组的索引从 1 开始计数

Dune SQL访问数组元素：

```sql
select evt_block_time, evt_tx_hash, profileIds,
    profileIds[1] as id1, profileIds[2] as id2
from lens_polygon.LensHub_evt_Followed
where cardinality(profileIds) = 2
limit 10
```

3. 将数组元素拆分到多行记录。

Dune SQL拆分数组元素到多行：

```sql
select evt_block_time, evt_tx_hash, profileIds,	tbl.profile_id
from lens_polygon.LensHub_evt_Followed
cross join unnest(profileIds) as tbl(profile_id)
where cardinality(profileIds) = 3
limit 20
```

4. 同时将多个数组字段拆分到多行记录。

要同时将多个数组字段拆分到多行（前提是它们必须具有相同的长度），Dune SQL中可以在`unnest()`函数中包括多个字段，同时输出多个对应字段。

Dune SQL拆分多个数组元素到多行：

```sql
SELECT evt_block_time, evt_tx_hash, ids, "values", tbl.id, tbl.val
FROM erc1155_polygon.evt_TransferBatch
cross join unnest(ids, "values") as tbl(id, val)
WHERE evt_tx_hash = 0x19972e0ac41a70752643b9f4cb453e846fd5e0a4f7a3205b8ce1a35dacd3100b
AND evt_block_time >= date('2022-12-14')
```

## 从Spark SQL迁移查询到Dune SQL 示例

将已经存在的Spark SQL引擎编写的query迁移到Dune SQL的过程是非常便利的。你可以直接进入Query的Edit界面，从左边的数据集下拉列表中切换到“1. v2 Dune SQL”，同时对Query的内容做相应的调整，涉及的主要修改已经在本文前面各节分别进行了介绍。这里举一个实际的例子：

Spark SQL 版本：[https://dune.com/queries/1773896](https://dune.com/queries/1773896)
Dune SQL 版本：[https://dune.com/queries/1000162](https://dune.com/queries/1000162)

迁移时修改内容对照：

![image_02.png](img/image_02.png)


## 其他

Dune SQL 还有一个潜在的高级功能，就是允许针对一个已保存的查询进行查询（Query of Query）。这个功能有很多的想象空间，可简化查询逻辑，优化缓存使用等。比如，你可以将一个复杂的查询的基础部分保存为一个query，然后基于此query来进一步的汇总统计。这个功能貌似有时还不太稳定。不过大家可以试试。

```sql
-- original query: https://dune.com/queries/1752041
select * from query_1752041
where user_status = 'Retained'
```

```sql
-- original query: https://dune.com/queries/1752041
select * from query_1752041
where user_status = 'Churned'
```

## 参考链接

1. [Syntax and operator differences](https://dune.com/docs/reference/dune-v2/query-engine/#syntax-and-operator-differences)
2. [Trino Functions and operators](https://trino.io/docs/current/functions.html)


## SixdegreeLab介绍

SixdegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixdegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
