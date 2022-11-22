# SQL基础（二）

在“SQL基础（一）”部分我们介绍了一些SQL的基础知识，包括SQL查询语句的基础结构语法说明、日期时间、分组聚合、子查询和关联查询等内容。接下来我们继续介绍一些常用的SQL基础知识点。

## 常用日期函数和日期时间间隔使用

区块链的数据都按交易发生的时间先后顺序被记录保存，日常数据分析中经常需要对一段时间范围内对数据进行统计。上一部分介绍过的`date_trunc()`函数用于按指定的间隔（天、周、小时等）截断日期值。除此之外还有一些常用的函数和常见用法。

### 1. Now()和Current_Date()函数
函数`now()`用于获取当前系统的日期和时间值。需要注意，其内部保存的是包括了时分秒值的，但是Dune的查询编辑器默认只显示到“时:分“。当我们要将日期字段跟价格表`prices.usd`中的`minute`字段进行关联时，必须先按分钟进行截取。否则可能关联不到正确的价格记录。

函数`current_date()`用于获取当前日期（不含时分秒部分）。当我们需要按日期、时间筛选数据时，常常需要结合使用它们其中之一，再结合相关日期时间函数来换算出需要的准确日期或者时间。函数`current_date()`相当于`date_trunc('day', now())`，即对`now()`函数的值按“天”进行截取。还可以省略`current_date()`的括号，直接写成`current_date`形式。

```sql
select now() -- 当前系统日期和时间
    ,current_date() -- 当前系统日期
    ,current_date   -- 可以省略括号
    ,date_trunc('day', now()) -- 与current_date相同
```

### 2. DateAdd()、Date_Add()、Date_Sub()和DateDiff()函数

函数`dateadd(unit, value, expr)`在一个日期表达式上添加一个的日期时间单位。这里的“日期时间单位”使用常量表示，常用的有HOUR、DAY、WEEK、MONTH等。其中的value值可以为负数，表示从后面的表达式减去对应的日期时间单位。也正是因为可以用负数表示减去一个日期时间间隔，所以不需要也确实没有`datesub()`函数。

函数`date_add(startDate, numDays)`在一个日期表达式上加上或者减去指定的天数，返回另外一个日期。参数`numDays`为正数表示返回`startDate`之后指定天数的日期，为负表示返回之前指定天数的日期。函数`date_sub(startDate, numDays)`作用类似，但表示的意思正好相反，即负数表示返回之后的日期，正数表示之前的日期。

函数`datediff(endDate, startDate)`返回两个日期表达式之间间隔的天数。如果`endDate`在`startDate`之后，返回正值，在之前则返回负值。

SQL示例如下：

```sql
select dateadd(MONTH, 2, current_date) -- 当前日期加2个月后的日期
    ,dateadd(HOUR, 12, now()) -- 当前日期时间加12小时
    ,dateadd(DAY, -2, current_date) -- 当前日期减去2天
    ,date_add(current_date, 2) -- 当前日期加上2天
    ,date_sub(current_date, -2) -- 当前日期减去-2天，相当于加上2天
    ,date_add(current_date, -5) -- 当前日期加上-5天，相当于减去5天
    ,date_sub(current_date, 5) -- 当前日期减去5天
    ,datediff('2022-11-22', '2022-11-25') -- 结束日期早于开始日期，返回负值
    ,datediff('2022-11-25', '2022-11-22') -- 结束日期晚于开始日期，返回正值
```

### 3. INTERVAL 类型

Interval是一种数据类型，以指定的日期时间单位表示某个时间间隔。以Interval 表示的时间间隔使用起来非常便利，避免被前面的几个名称相似、作用也类似的日期函数困扰。

```sql
select now() - interval '2 hours' -- 2个小时之前
    ,current_date - interval '7 days' -- 7天之前
    ,now() + interval '1 week' -- 一个星期之后的当前时刻
```

更多日期时间相关函数的说明，请参考[日期、时间和间隔函数](https://docs.databricks.com/sql/language-manual/sql-ref-functions-builtin.html#date-timestamp-and-interval-functions)

## 条件函数(case when,if)

## 字符串处理(普通函数，正则)

## 窗口函数(LEAD() | LAG() | RANK() | ROW_NUMBER())

## 聚合函数：collect_set 跟 collect_list




#### Dune Query URL  
[https://dune.com/queries/1525555](https://dune.com/queries/1525555)



