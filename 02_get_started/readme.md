# 新手上路

## 0. 写在前面

我们的教程偏重实战，结合日常链上数据分析的场景与需求来编写。本文将为大家讲解开始创建数据看板之前需要熟悉的相关SQL基础知识。本教程为入门级，主要面向希望学习数据分析的新手用户。我们假定您之前并无编写SQL查询的经验，有SQL经验但不熟悉Dune平台的用户也可快速浏览本教程。本篇教程主要包括Dune平台简介、SQL查询快速入门等内容。在下一篇教程中，我们将一起编写查询并创建可视化图表、使用查询图表创建数据看板。我们相信，只要你有信心并跟随我们的教程动手实践，你也可以做出高质量的数据看板，迈出成为链上数据分析师的第一步。

## 1. Dune 平台简介

### Dune平台是什么
[Dune](https://dune.com/)是一个强大的区块链数据分析平台，以SQL数据库的方式提供原始区块链数据和已解析的数据。通过使用SQL查询，我们可以从Dune的数据库中快速搜索和提取各种区块链信息，然后将其转换为直观的可视化图表。以此来获得信息和见解。

### Dune的数据看板和查询

数据看板（Dashboard）是Dune上内容的载体，由各种小部件（Widget）组成。这些小部件可以是从Query查询结果生成的可视化图表或文本框，你还可以在文本框中嵌入图像、链接等。查询（Query）是Dune数据面板的主要数据来源。我们通过编写SQL语句，执行查询并在结果集上生成可视化图表，再将图表添加到对应的数据看板中。

使用Dune处理数据的一般过程可以概括为：编写SQL查询显示数据 -》可视化查询结果 -》在数据看板中组装可视化图表 -》调整美化数据看板。关于Dune平台的使用，可以查看其[官方文档](https://dune.com/docs/)。Dune最新文档的中文版本目前正在翻译整理中，你可以在这里找到V1版本的[Dune中文文档](https://docs.dune.com/v/chinese/)。

## 2. 数据库基础知识

在开始编写我们的数据看板所需的第一个SQL查询之前，我们需要先了解一些必备的SQL查询基础知识。

### 数据库的基本概念介绍

**数据库（Database）**：数据库是结构化信息或数据的有序集合，是按照数据结构来组织、存储和管理数据的仓库。Dune平台目前提供了多个数据库，分别支持来自不同区块链的数据。本教程使用Dune平台的“Dune Engine V2 (Beta)”数据库，通常被称为V2 Engine或者简称V2。与此对照，Dune平台支持的其他数据库也被统称为V1。

**模式（Schema）**：同一个数据库中，可以定义多个模式。我们暂时可以将模式简单理解为数据表的拥有者（Owner）。不同的模式下可以存在相同名称的数据表。

**数据表（Table）**：数据表是由表名、表中的字段和表的记录三个部分组成的。数据表是我们编写SQL查询访问的主要对象。Dune将来自不同区块链的数据分别存贮到不同模式下的多个数据表中供我们查询使用。使用数据表编写查询时，我们用`schema_name.table_name`的格式来指定查询要使用的数据表名称。例如`ethereum.transactions`表示`ethereum`模式下的`transactions`表，即以太坊的交易表。同一个模式下的数据表名称必须唯一，但是相同名称的数据表可以同时存在于多个不同的模式下。例如V2中同时存在`ethereum.transactions`和`bnb.transactions`表。

**数据列（Column）**：数据列也称为字段（Field），有时也简称为“列”，是数据表存贮数据的基本单位。每一个数据表都包含一个或多个列，分别存贮不同类型的数据。编写查询时，我们可以返回全部列或者只返回需要的数据列。通常，只返回需要的最少数据可以提升查询的效率。

**数据行（Row）**：数据行也称为记录（Record）。每一个记录包括数据表定义的多个列的数据。SQL查询执行得到的结果就是一个或多个记录。查询输出的记录集通常也被称为结果集（Results）。

### 本教程使用的数据表

在本节的SQL查询示例中，我们使用ERC20代币表`token.erc20`做例子。ERC20代币表是由Dune社区用户通过魔法书（Spellbook）方式生成的抽象数据表（Spells，也称为Abstractions）。除了生成方式不同，这种类型的数据表的使用方式跟其他表完全一样。ERC20代币表保存了Dune支持检索的不同区块链上面的兼容ERC20标准的主流代币的信息。对于每种代币，分别记录了其归属的区块链、代币合约地址、代币支持的小数位数和代币符号信息。

ERC20代币表`token.erc20`的结构如下：

| **列名**                 | **数据类型**   | **说明**                                    |
| ----------------------- | ------------- | ------------------------------------------ |
| blockchain              | string        | 代币归属的区块链名称                           |
| contract\_address       | string        | 代币的合约地址                                |
| decimals                | integer       | 代币支持的小数位数                             |
| symbol                  | string        | 代币的符号                                    |

## SQL查询快速入门

广义的SQL查询语句类型包括新增（Insert）、删除（Delete）、修改（Update）、查找（Select）等多个类型。狭义的SQL查询主要指使用Select语句进行数据检索。链上数据分析绝大多数时候只需使用Select语句就能完成工作，所以我们这里只介绍Select查询语句。后续内容中我们会交替使用查询、Query、Select等词汇，如无特别说明，都是指使用Select语句编写Query进行数据检索。

### 编写第一个查询

下面的SQL可以查询所有的ERC20代币信息：

```sql
select * from tokens.erc20
```

### Select 查询语句基本语法介绍

一个典型的SQL查询语句的结构如下所示：

```sql
select 字段列表
from 数据表
where 筛选条件
order by 排序字段
limit 返回记录数量
```

**字段列表**可以逐个列出查询需要返回的字段（数据列），多个字段之间用英文逗号分隔，比如可以这样指定查询返回的字段列表`contract_address, decimals, symbol`。也可以使用通配符`*`来表示返回数据表的全部字段。如果查询用到了多个表并且某个字段同时存在于这些表中，我们就需要用`table_name.field_name`的形式指定需要返回的字段属于哪一个表。

**数据表**以`schema_name.table_name`的格式来指定，例如`token.erc20`。我们可以用`as alias_name`的语法给表指定一个别名，例如：`from token.erc20 as t`。这样就可以同一个查询中用别名`t`来访问表`token.erc20`和其中的字段。

**筛选条件**用于按指定的条件筛选返回的数据。对于不同数据类型的字段，适用的筛选条件语法各有不同。字符串（`string`）类型的字段，可以用`=`，`like`等条件做筛选。日期时间（`datetime`）类型的字段可以用`>=`，`<=`，`between ... and ...`等条件做筛选。使用`like`条件时，可以用通配符`%`匹配一个或多个任意字符。多个筛选条件可以用`and`（表示必须同时满足）或`or`（表示满足任意一个条件即可）连接起来。

**排序字段**用于指定对查询结果集进行排序的判断依据，这里是一个或多个字段名称，加上可选的排序方向指示（`asc`表示升序，`desc`表示降序）。多个排序字段之间用英文逗号分隔。Order By排序子句还支持按照字段在Select子句中出现的位置来指定排序字段，比如`order by 1`表示按照Select子句中出现的第一个字段进行排序（默认升序）。

**返回记录数量**用于指定（限制）查询最多返回多少条满足条件的记录。区块链保存的是海量数据，通常我们需要添加返回记录数量限制来提高查询的效率。

下面我们举例说明如何使用查询的相关部分。注意，在SQL语句中，我们可以`--`添加单行注释说明。还可以使用`/*`开头和`*/`结尾将多行内容标记为注释说明。注释内容不会被执行。

**指定返回的字段列表：**

```sql
select blockchain, contract_address, decimals, symbol   -- 逐个指定需要返回的列
from tokens.erc20
```

**添加筛选条件：**

```sql
select blockchain, contract_address, decimals, symbol
from tokens.erc20
where blockchain = 'ethereum'   -- 只返回以太坊区块链的ERC20代币信息
```

**使用多个筛选条件：**

```sql
select blockchain, contract_address, decimals, symbol
from tokens.erc20
where blockchain = 'ethereum'   -- 返回以太坊区块链的ERC20代币信息
    and symbol like 'E%'    -- 代币符号以字母E开头
```

**指定排序字段：**

```sql
select blockchain, contract_address, decimals, symbol
from tokens.erc20
where blockchain = 'ethereum'   -- 返回以太坊区块链的ERC20代币信息
    and symbol like 'E%'    -- 代币符号以字母E开头
order by symbol asc -- 按代币符号升序排列
```

**指定多个排序字段：**

```sql
select blockchain, contract_address, decimals, symbol
from tokens.erc20
where blockchain = 'ethereum'   -- 返回以太坊区块链的ERC20代币信息
    and symbol like 'E%'    -- 代币符号以字母E开头
order by decimals desc, symbol asc  -- 先按代币支持的小数位数降序排列，再按代币符号升序排列
```

**使用Limit子句限制返回的最大记录数量：**

```sql
select *
from tokens.erc20
limit 10
```

### Select查询常用的一些函数和关键词

#### As定义别名

可以通过使用“as”子句给表、字段定义别名。别名对于表名（或字段名）较长、包含特殊字符或关键字等情况，或者需要对输出字段名称做格式化时，非常实用。别名经常用于计算字段、多表关联、子查询等场景中。

```sql
select t.contract_address as `代币合约地址`,
    t.decimals as `代币小数位数`,
    t.symbol as `代币符号`
from tokens.erc20 as t
limit 10
```
实际上为了书写更加简洁，定义别名时`as`关键词可以省略，可以直接将别名跟在表名或字段名后，用一个空格分隔。下面的查询，功能和上一个查询完全相同。

```sql
-- 定义别名时，as 关键词可以省略
select t.contract_address `代币合约地址`,
    t.decimals `代币小数位数`,
    t.symbol `代币符号`
from tokens.erc20 t
limit 10
```

#### Distinct筛选唯一值

通过使用`distinct`关键词，我们可以筛选出出现在Select子句列表中的字段的唯一值。当Select子句包含多个字段时，返回的是这些字段的唯一值当组合。

```sql
select distinct blockchain
from tokens.erc20
```

#### Now 获取当前系统日期时间

使用`now()`可以获得当前系统的日期时间值。我们还可以使用`current_date`来得到当前系统日期，注意这里不需要加括号。

```sql
select now(), current_date
```

#### Date_Trunc 截取日期

区块链中的日期时间字段通常是以“年-月-日 时:分:秒”的格式保存的。如果要按天、按周、按月等进行汇总统计，可以使用`date_trunc()`函数对日期先进行转换。例如：`date_trunc('day', block_time`将block_time的值转换为以“天”表示的日期值，`date_trunc('month', block_time`将block_time的值转换为以“月”表示的日期值。

```sql
select now(),
    date_trunc('day', now()) as today,
    date_trunc('month', now()) as current_month
```

#### Interval获取时间间隔

使用`interval '2 days'`这样的语法，我们可以指定一个时间间隔。支持多种不同的时间间隔表示方式，比如：`'12 hours'`，`'7 days'`，`'3 months'`, `'1 year'`等。时间间隔通常用来在某个日期时间值的基础上增加或减少指定的间隔以得到某个日期区间。

```sql
select now() as current_time, 
    (now() - interval '2 hours') as two_hours_ago, 
    (now() - interval '2 days') as two_days_ago,
    (current_date - interval '1 year') as one_year_ago
```

#### Concat连接字符串

我们可以使用`concat()`函数将多个字符串连接到一起的到一个新的值。还可以使用更简洁的连接操作符`||`。

```sql
select concat('Hello ', 'world!') as hello_world,
    'Hello' || ' ' || 'world' || '!' as hello_world_again
```

#### Cast转换字段数据类型

SQL查询种的某些操作要求相关的字段的数据类型一致，比如concat()函数就需要参数都是字符串`string`类型。如果需要将不同类型的数据连接起来，我们可以用`cast()`函数强制转换为需要的数据类型，比如：`cast(25 as string)`将数字25转换为字符串“25”。还可以使用`::data_type`操作符方式完成类型转换，比如：`'123'::numeric`将字符串转换为数值类型。

```sql
select (cast(25 as string) || ' users') as user_counts,
    ('123'::numeric + 55) as digital_count
```

#### Power求幂

区块链上的ERC20代币通常都支持很多位的小数位。以太坊的官方代币ETH支持18位小数，因为相关编程语言的限制，代币金额通常是以整数形式存贮的，使用时必须结合支持的小数位数进行换算才能得到正确的金额。使用`power()`函数，或者`pow()`可以进行求幂操作实现换算。在Dune V2中，可以用简洁的形式表示10的N次幂，例如`1e18`等价于`power(10, 18)`。

```sql
select 1.23 * power(10, 18) as raw_amount,
    1230000000000000000 / pow(10, 18) as original_amount,
    7890000 / 1e6 as usd_amount
```

### Select查询进阶

#### Group By分组与常用汇总函数

SQL中有一些常用的汇总函数，`count()`计数，`sum()`求和，`avg()`求平均值，`min()`求最小值，`max()`求最大值等。除了对表中所有数据汇总的情况外，汇总函数通常需要结合分组语句`group by`来使用，按照某个条件进行分组汇总统计。Group By分组子句的语法为`group by field_name`，还可以指定多个分组字段`group by field_name1. field_name2`。与Order By子句相似，也可以按字段在Select子句中出现的位置来指定分组字段，这样可以让我们的SQL更加简洁。例如`group by 1`表示按第一个字段分组，`group by 1, 2`表示同时按第一个和第二个字段分组。我们通过一些例子来说明常用汇总函数的用法。

**统计目前支持的各个区块链的ERC20代币类型数量：**

```sql
select blockchain, count(*) as token_count
from tokens.erc20
group by blockchain
```

**统计支持的所有区块链的代币类型总数量、平均值、最小值、最大值：**

```sql
-- 这里为了演示相关函数，使用了子查询
select count(*) as blockchain_count,
    sum(token_count) as total_token_count,
    avg(token_count) as average_token_count,
    min(token_count) as min_token_count,
    max(token_count) as max_token_count
from (
    select blockchain, count(*) as token_count
    from tokens.erc20
    group by blockchain
)
```

#### 子查询（Sub Query）

子查询（Sub Query）是嵌套在一个Query中的Query，子查询会返回一个完整的数据集供外层查询（也叫父查询、主查询）进一步查询使用。当我们需要必须从原始数据开始通过多个步骤的查询、关联、汇总操作才能得到理想的输出结果时，我们就可以使用子查询。将子查询放到括号之中并为其赋予一个别名后，就可以像使用其他数据表一样使用子查询了。

在前面的例子中就用到了子查询`from ( 子查询语句 )`，这里不再单独举例。

#### 多表关联（Join）

当我们需要从相关的多个表分别取数据，或者从同一个表分别取不同的数据并连接到一起时，就需要使用多表关联。多表关联的基本语法为：`from table_a inner join table_b on table_a.field_name = table_b.field_name`。其中`table_a`和`table_b`可以是不同的表，也可以是同一个表，可以有不同的别名。

下面的查询使用`tokens.erc20`与其自身关联，来筛选出同时存在于以太坊区块链和币安区块链上且代币符号相同的记录：

```sql
select a.symbol,
    a.decimals,
    a.blockchain as blockchain_a,
    a.contract_address as contract_address_a,
    b.blockchain as blockchain_b,
    b.contract_address as contract_address_b
from tokens.erc20 a
inner join tokens.erc20 b on a.symbol = b.symbol
where a.blockchain = 'ethereum'
    and b.blockchain = 'bnb'
```

#### 集合（Union）

当我们需要将来自不同数据表的记录合并到一起，或者将由同一个数据表取出的包含不同字段的结果集合并到一起时，可以使用`Union`或者`Union All`集合子句来实现。`Union`会自动去除合并后的集合里的重复记录，`Union All`则不会做去重处理。对于包括海量数据的链上数据库表，去重处理有可能相当耗时，所以建议尽可能使用`Union All`以提升查询效率。

因为暂时我们尽可能保持简单，下面演示集合的SQL语句可能显得意义不大。不过别担心，这里只是为了显示语法。后续我们在做数据看板的部分有更合适的例子：

```sql
select contract_address, symbol, decimals
from tokens.erc20
where blockchain = 'ethereum'

union all

select contract_address, symbol, decimals
from tokens.erc20
where blockchain = 'bnb'
```

#### Case 语句

使用Case语句，我们可以基于某个字段的值来生成另一种类型的值，通常是为了让结果更直观。举例来说，ERC20代币表有一个`decimals`字段，保存各种代币支持的小数位数。如果我们想按支持的小数位数把各种代币划分为高精度、中等精度和低精度、无精度等类型，则可以使用Case语句进行转换。

```sql
select (case when decimals >= 10 then 'High precision'
            when decimals >= 5 then 'Middle precision'
            when decimals >= 1 then 'Low precision'
            else 'No precision'
        end) as precision_type,
    count(*) as token_count
from tokens.erc20
group by 1
order by 2 desc
```

#### CTE公共表表达式
公共表表达式，即CTE（Common Table Expression），是一种在SQL语句内执行（且仅执行一次）子查询的好方法。数据库将执行所有的WITH子句，并允许你在整个查询的后续任意位置使用其结果。

CTE的定义方式为`with cte_name as ( sub_query )`，其中`sub_query`就是一个子查询语句。我们也可以在同一个Query中连续定义多个CTE，多个CTE之间用英文逗号分隔即可。按定义的先后顺序，后面的CTE可以访问使用前面的CTE。在后续数据看板部分的“查询6”中，你可以看到定义多个CTE的示例。将前面子查询的例子用CTE格式改写：

```sql
with blockchain_token_count as (
    select blockchain, count(*) as token_count
    from tokens.erc20
    group by blockchain
)

select count(*) as blockchain_count,
    sum(token_count) as total_token_count,
    avg(token_count) as average_token_count,
    min(token_count) as min_token_count,
    max(token_count) as max_token_count
from blockchain_token_count
```

## 总结

恭喜！你已经熟悉了创建第一个Dune数据看板所需要的全部知识点。在下一篇教程中，我们将一起创建一个Dune数据看板。

你还可以通过以下链接学习更多相关的内容：
- [Dune平台的官方文档](https://dune.com/docs/)（Dune）
- [Dune入门指南](https://mirror.xyz/0xa741296A1E9DDc3D6Cf431B73C6225cFb5F6693a/iVzr5bGcGKKCzuvl902P05xo7fxc2qWfqfIHwmCXDI4)（SixDegreeLab成员Louis Wang翻译）
- [Dune Analytics零基础极简入门指南](https://mirror.xyz/gm365.eth/OE_CGx6BjCd-eQ441139sjsa3kTyUsmKVTclgMv09hY)（Dune社区用户gm365撰写）

## SixDegreeLab介绍

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixDegreeLab的Dune主页](https://dune.com/sixdegree)。

本文由SixDegreeLab成员Spring Zhang（[@superamscom](https://twitter.com/superamscom)）撰稿。因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
