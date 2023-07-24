
# 16 Analysis of the Polygon Chain Overview

Dune platform has been developing rapidly and currently supports 10 mainstream blockchains, including Layer 1 public chains such as Ethereum, BNB, Polygon, Fantom, and Layer 2 blockchains such as Arbitrum and Optimism that are dedicated to expanding Ethereum. In this tutorial, we will explore how to start analyzing the overview of a blockchain, taking the Polygon blockchain as an example.

Polygon's motto is "Bringing Ethereum to Everyone." Polygon believes that everyone can use Web3. It is a decentralized Ethereum scaling platform that enables developers to build scalable and user-friendly DApps with low transaction fees without compromising security.

Dashboard for this tutorial: [Polygon Chain Overview](https://dune.com/sixdegree/polygon-chain-overview)<a id="jump_8"></a>

## Contents of the Blockchain Overview Analysis

Our goal is to comprehensively analyze the entire Polygon Chain to understand its current development status. The analysis includes:

* **Block Analysis**: Total number of blocks, blocks mined per minute, total gas consumption, average gas consumption, daily (monthly) trend of block generation quantity, etc.
* **Transaction and User Analysis**: Total transaction volume, total number of users, transaction quantity per block, comparison of successful and failed transactions, daily (monthly) trend of transaction quantity, daily (monthly) trend of active users, daily (monthly) trend of new users, comparison of new users and active users, etc.
* **Native Token MATIC Analysis**: Total circulation supply, holder analysis, top holders, price trend, etc.
* **Smart Contract Analysis**: Total deployed smart contracts, daily (monthly) trend of new contract deployments, comparison of transaction volume for the most popular smart contracts, and analysis of development trends.

## Block and Gas Consumption Analysis

### Total Number of Blocks and Gas Consumption

To understand the total number of blocks and gas consumption in the Polygon Chain, we can write a simple SQL to retrieve the following information: the total number of blocks, the timestamp of the genesis block, the average number of new blocks per minute, the total gas consumption, and the average gas consumption per block.

``` sql
select count(*) / 1e6 as blocks_count,
   min(time) as min_block_time,
   count(*) / ((to_unixtime(Now()) - to_unixtime(min(time))) / 60) as avg_block_per_minute,
   sum(gas_used * coalesce(base_fee_per_gas, 1)) / 1e18 as total_gas_used,
   avg(gas_used * coalesce(base_fee_per_gas, 1)) / 1e18 as average_gas_used
from polygon.blocks
```

SQL explanation:

1. By using the `to_unixtime()`, we can convert date and time to Unix Timestamp values, which allows us to calculate the number of seconds between two date and time values. We can then use this to calculate the average number of new blocks per minute. The corresponding function is `from_unixtime()`.
2. `gas_used` represents the amount of gas consumed, and `base_fee_per_gas` is the unit price per gas. Multiplying them together gives us the gas cost. The native token of Polygon, MATIC, has 18 decimal places, so dividing by 1e18 gives us the final MATIC amount.

The results of this query can be added as Counter-type visualizations and included in a dashboard. The display is as follows:

![image_01.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_01.png)

Query link:[https://dune.com/queries/1835390](https://dune.com/queries/1835390)<a id="jump_8"></a>

### Daily (Monthly) New Block Generation Trend and Gas Consumption

We can aggregate by date to calculate the daily number of generated blocks and the corresponding gas consumption. To track the change, we first define a CTE to perform daily data statistics. Then, based on this CTE, we use a window function such as avg`(blocks_count) over (order by rows between 6 preceding and current row)` to calculate the 7-day moving average. The SQL is as follows:

``` sql
with block_daily as (
    select date_trunc('day', time) as block_date,
        count(*) as blocks_count,
        sum(gas_used * coalesce(base_fee_per_gas, 1)) / 1e18 as gas_used
    from polygon.blocks
    group by 1
)

select block_date,
    blocks_count,
    gas_used,
    avg(blocks_count) over (order by block_date rows between 6 preceding and current row) as ma_7_days_blocks_count,
    avg(blocks_count) over (order by block_date rows between 29 preceding and current row) as ma_30_days_blocks_count,
    avg(gas_used) over (order by block_date rows between 6 preceding and current row) as ma_7_days_gas_used
from block_daily
order by block_date
```

Add two Bar Chart for the query, displaying "Daily Block Count, 7-day Moving Average, and 30-day Moving Average Block Count" and "Daily Gas Consumption Total and 7-day Moving Average" values. Add them to the dashboard.

Make a Fork of the above query, and modify it slightly to calculate the monthly statistics. Also, change the moving average to consider a period of 12 months. This will give us the monthly new block generation trend.

The visualizations of the two SQL queries added to the dashboard will have the following display. We can observe that the number of new blocks generated remains relatively stable, but the gas fees have significantly increased since 2022, with a brief decline in between and currently approaching the previous high.

![image_02.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_02.png)

Query Link:
* [https://dune.com/queries/1835421](https://dune.com/queries/1835421)<a id="jump_8"></a>
* [ttps://dune.com/queries/1835445](ttps://dune.com/queries/1835445)<a id="jump_8"></a>

## Transaction and User Analysis
### Total Transaction Volume and User Count

We want to calculate the total number of transactions and the total number of unique user addresses. A CTE can be difined to combine the sender addresses `from` and receiver addresses `to` using the UNION ALL, and then count the distinct addresses. It's important to note that we're not excluding contract addresses in this analysis. If you wish to exclude contract addresses, you can add a subquery to exclude those addresses found in the `polygon.creation_traces` table. Since the data volume is large, we'll represent the values in millions (M). Add a Counter visualization chart for each metric and include them in the dashboard.

``` sql
with transactions_detail as (
    select block_time,
        hash,
        "from" as address
    from polygon.transactions

    union all

    select block_time,
        hash,
        "to" as address
    from polygon.transactions
)

select count(distinct hash) / 1e6 as transactions_count,
    count(distinct address) / 1e6 as users_count
from transactions_detail
```

Query Link:
* [https://dune.com/queries/1836022](https://dune.com/queries/1836022)<a id="jump_8"></a>

### Daily (Monthly) Transaction and Active User Analysis

Similarly, by grouping the data by date, we can generate reports for daily transaction volume and the number of active users. By summarizing the data on a monthly basis, we can obtain monthly insights. Below is the SQL query for daily aggregation:

``` sql
with transactions_detail as (
    select block_time,
        hash,
        "from" as address
    from polygon.transactions

    union all

    select block_time,
        hash,
        "to" as address
    from polygon.transactions
)

select date_trunc('day', block_time) as block_date,
    count(distinct hash) as transactions_count,
    count(distinct address) as users_count
from transactions_detail
group by 1
order by 1
```

Add Bar Chart for both daily and monthly transaction data, displaying transaction count and active user count. You can use a secondary Y-axis for the active user count, and choose either Line or Area chart. The resulting visualization on the dashboard would be the following:

![image_03.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_03.png)

Query Link:
* [https://dune.com/queries/1835817](https://dune.com/queries/1835817)<a id="jump_8"></a>
* [ttps://dune.com/queries/1836624](ttps://dune.com/queries/1836624)<a id="jump_8"></a>

### Active User and New User Statistics Analysis

For a public blockchain, the growth trend of new users is a critical analysis that reflects the popularity of the chain. We can start by identifying the first transaction date for each address (`users_initial_transaction` CTE in the query below) and then use it to calculate the number of new users per day. By associating the daily active user data with the daily new user data, we can create a comparative chart. The number of active users for a given day can be obtained by subtracting the number of new users on that day from the daily active user count. Considering the possibility of no new users on certain dates, we use a LEFT JOIN and the `coalesce()` to handle potential null values. The SQL query is as follows:

``` sql
with users_details as (
    select block_time,
        "from" as address
    from polygon.transactions
    
    union all
    
    select block_time,
        "to" as address
    from polygon.transactions
),

users_initial_transaction as (
    select address,
        min(date_trunc('day', block_time)) as min_block_date
    from users_details
    group by 1
),

new_users_daily as (
    select min_block_date as block_date,
        count(address) as new_users_count
    from users_initial_transaction
    group by 1
),

active_users_daily as (
    select date_trunc('day', block_time) as block_date,
        count(distinct address) as active_users_count
    from users_details
    group by 1
)

select u.block_date,
    active_users_count,
    coalesce(new_users_count, 0) as new_users_count,
    active_users_count - coalesce(new_users_count, 0) as existing_users_count
from active_users_daily u
left join new_users_daily n on u.block_date = n.block_date
order by u.block_date
```

FORK this daily user statistics query, adjust the date to monthly statistics using `date_trunc('month', block_time)`. This will enable us to calculate the number of active users and new users per month.

For these two queries, we can add the following visualizations:

1. Bar Chart: Display the daily (or monthly) count of active users and new users. Since the proportion of new users is relatively low, set it to use the secondary Y-axis.
2. Area Chart: Compare the proportion of new users and existing users.

Adding these visualizations to the dashboard will result in the following display:

![image_04.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_04.png)

Query link:
* [https://dune.com/queries/1836744](https://dune.com/queries/1836744)<a id="jump_8"></a>
* [ttps://dune.com/queries/1836854](ttps://dune.com/queries/1836854)<a id="jump_8"></a>

## Native Token Analysis
### MATIC Price Trend

Dune's Spells `prices.usd` provides price of Polygon chain tokens, including the native token MATIC. Therefore, we can directly calculate the average price on a daily basis.

``` sql
select date_trunc('day', minute) as block_date,
    avg(price) as price
from prices.usd
where blockchain = 'polygon'
    and symbol = 'MATIC'
group by 1
order by 1
```

Since the query results are sorted in ascending order by date, the last record represents the average price for the most recent date, which can be considered as the "current price". We can generate a Counter chart for it, setting the "Row Number" value to "-1" to retrieve the value from the last row. Additionally, we can add a Line to display the daily average price for the MATIC token. After adding these charts to the dashboard, the display will be as shown below:

![image_05.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_05.png)

Query link:
* [https://dune.com/queries/1836933](https://dune.com/queries/1836933)<a id="jump_8"></a>

### Addresses with the highest holdings of the MATIC token

Addresses with the highest holdings of the MATIC token are of interest to us, as they often have the potential to influence the token's price movements. The following query retrieves the top 1000 addresses. MATIC is the native token of the Polygon chain, and the details of its transfers are stored in the `polygon.traces` table. Please note that we haven't differentiated between contract and non-contract addresses in this query. Due to the low transaction gas fees on Polygon, we have omitted the calculation of gas consumption for performance reasons.

``` sql
with polygon_transfer_raw as (
    select "from" as address, (-1) * cast(value as decimal) as amount
    from polygon.traces
    where call_type = 'call'
        and success = true
        and value > uint256 '0'
    
    union all
    
    select "to" as address, cast(value as decimal) as amount
    from polygon.traces
    where call_type = 'call'
        and success = true
        and value > uint256 '0'
)

select address,
    sum(amount) / 1e18 as amount
from polygon_transfer_raw
group by 1
order by 2 desc
limit 1000
```

Considerations in the above query: The `value` in the `polygon.traces` is of type `uint256`, which is a custom type in Dune SQL. If you directly compare it with the numerical value 0, you will encounter a type mismatch error that prevents comparison. Therefore, we use syntax like `uint256 '0'` to convert the value 0 into the same type for comparison. Alternatively, you can use type conversion functions like `cast(0 as uint256)`. You can also convert the `value` to double, decimal, bigint, or other types before comparison, but in such cases, be mindful of potential data overflow issues.

We can further analyze the distribution of MATIC token holdings among the top 1000 addresses based on the above query. We can fork the previous query and make slight modifications to achieve this.

``` sql
with polygon_transfer_raw as (
    -- same as above
),

polygon_top_holders as (
    select address,
        sum(amount) / 1e18 as amount
    from polygon_transfer_raw
    group by 1
    order by 2 desc
    limit 1000
)

select (case when amount >= 10000000 then '>= 10M'
             when amount >= 1000000 then '>= 1M'
             when amount >= 500000 then '>= 500K'
             when amount >= 100000 then '>= 100K'
             else '< 100K'
        end) as amount_segment,
    count(*) as holders_count
from polygon_top_holders
group by 1
order by 2 desc
```

Generate a Bar Chart and a Pie Chart for the above two queries respectively. Add them to the dashboard, and the display is as follows:

![image_06.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_06.png)

Query link:
* [https://dune.com/queries/1837749](https://dune.com/queries/1837749)<a id="jump_8"></a>
* [ttps://dune.com/queries/1837150](ttps://dune.com/queries/1837150)<a id="jump_8"></a>
* [ttps://dune.com/queries/1837781](ttps://dune.com/queries/1837781)<a id="jump_8"></a>

## Smart Contract Analysis
### Number of Created and Suicided Contracts

``` sql
select type,
    count(*) / 1e6 as transactions_count
from polygon.traces
where type in ('create', 'suicide')
    and block_time >= date('2023-01-01') -- Date conditions are added here for performance considerations
group by 1
order by 1
```

Since we have restricted the values of the `type` and specified the sorting order, we can ensure that two records are returned and their order is fixed. Therefore, we can generate Counter-type visualizations for the values in the first and second rows respectively.

Query link:
* [https://dune.com/queries/1837749](https://dune.com/queries/1837749)<a id="jump_8"></a>

### Daily (Monthly) Contract Created and Suicided Count

We can calculate the daily (monthly) count of newly created and suicided contracts by date. Considering the cumulative count is also valuable, we first use a CTE to calculate the daily count, and then use the window function `sum() over (partition by type order by block_date)` to calculate the cumulative count by date. The `partition by type` is used to specify separate aggregations based on the contract type.

``` sql
with polygon_contracts as (
    select date_trunc('day', block_time) as block_date,
        type,
        count(*) as transactions_count
    from polygon.traces
    where type in ('create', 'suicide')
    group by 1, 2
)

select block_date, 
    type,
    transactions_count,
    sum(transactions_count) over (partition by type order by block_date) as accumulate_transactions_count
from polygon_contracts
order by block_date
```

Similarly, we can adjust the date to monthly, and calculate the count of newly created and suicided contracts on a monthly basis.

The above queries generate Bar Chart and Area Chart respectively. After adding them to the dashboard, the resulting display is as follows:

![image_07.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_07.png)

Query link:
* [https://dune.com/queries/1837749](https://dune.com/queries/1837749)<a id="jump_8"></a>
* [ttps://dune.com/queries/1837144](ttps://dune.com/queries/1837150)<a id="jump_8"></a>
* [ttps://dune.com/queries/1837781](ttps://dune.com/queries/1837781)<a id="jump_8"></a>
### Transaction Count Statistics for Top Smart Contracts

The top smart contracts in each blockchain usually generate the majority of transaction counts. We can analyze the top 100 smart contracts with the highest transaction counts. In the output results, we have added a link field for convenience, allowing you to directly query the transaction list for each smart contract by clicking on the link.

``` sql
with contract_summary as (
    select "to" as contract_address,
        count(*) as transaction_count
    from polygon.transactions
    where success = true
    group by 1
    order by 2 desc
    limit 100
)

select contract_address,
    '<a href=https://polygonscan.com/address/' || cast(contract_address as varchar) || ' target=_blank>PolygonScan</a>' as link,
    transaction_count
from contract_summary
order by transaction_count desc
```

Generating a Bar Chart and a Table Chart for this query. Adding them to the dashboard, the display is as follows:

![image_08.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_08.png)

Query link:
* [https://dune.com/queries/1838001](https://dune.com/queries/1838001)<a id="jump_8"></a>

### Analysis of Daily Transaction Volume for the Most Active Smart Contracts

We can analyze the daily transaction volume for the top smart contracts with the highest cumulative transaction count. This can provide insights into the popularity and lifespan of different smart contracts in different stages. Given the large amount of data, we will only analyze the top 20 contracts.

``` sql
with top_contracts as (
    select "to" as contract_address,
        count(*) as transaction_count
    from polygon.transactions
    where success = true
    group by 1
    order by 2 desc
    limit 20
)

select date_trunc('day', block_time) as block_date, 
    contract_address,
    count(*) as transaction_count
from polygon.transactions t
inner join top_contracts c on t."to" = c.contract_address
group by 1, 2
order by 1, 2
```

We first query the top 20 smart contracts with the highest historical transaction volume. Then, we calculate the daily transaction volume for these smart contracts. We add three different types of visualizations for the query:

1. Bar Chart: Displays the daily transaction volume for different smart contracts, stacked together.
2. Area Chart: Displays the daily transaction volume for different smart contracts, stacked together. We set "Normalize to percentage" to adjust the chart to display in percentages.
3. Pie Chart: Compares the cumulative transaction volume percentages for these top 20 smart contracts.

After adding these charts to the dashboard, the result is shown in the following:

![image_09.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_09.png)

Query link:
* [https://dune.com/queries/1838060](https://dune.com/queries/1838060)<a id="jump_8"></a>

### The most active smart contracts in the last 30 days

In addition to analyzing all historical transaction data, we can also perform a simple analysis on the most active smart contracts in recent. For example, we can analyze the top 50 smart contracts that have been the most active in the last 30 days.

``` sql
select "to" as contract_address,
    '<a href=https://polygonscan.com/address/' || cast("to" as varchar) || ' target=_blank>PolygonScan</a>' as link,
    count(*) as transaction_count
from polygon.transactions
where block_time >= now() - interval '30' day
group by 1, 2
order by 3 desc
limit 50
```

As it is a recent active projects, it may have been newly deployed and launched. Therefore, we have added hyperlinks to the query and created a Table. The display is as follows:

![image_10.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/13_polygon/img/image_10.png)

Query link:
* [https://dune.com/queries/1838077](https://dune.com/queries/1838077)<a id="jump_8"></a>

## Summary

Above, we have conducted a preliminary analysis of the Polygon Chain from several aspects, including blocks, gas consumption, transactions, users, native tokens, and smart contracts. Through this dashboard, we can gain a general understanding of the Polygon chain. In particular, through the analysis of top smart contracts, we can identify popular projects. This allows us to choose specific projects of interest for further analysis.

So far, SixDegreeLab has completed overview analyses for multiple blockchains, which you can find here:

* [Blockchain Overview Series](https://dune.com/sixdegree/blockchain-overview-series)<a id="jump_8"></a>

## SixDegreeLab introduction

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)<a id="jump_8"></a>）is a professional on-chain data team dedicated to providing accurate on-chain data charts, analysis, and insights to users. Our mission is to popularize on-chain data analysis and foster a community of on-chain data analysts. Through community building, tutorial writing, and other initiatives, we aim to cultivate talents who can contribute valuable analytical content and drive the construction of a data layer for the blockchain community, nurturing talents for the future of blockchain data applications.

Feel free to visit [SixDegreeLab's Dune homepage](https://dune.com/sixdegree)<a id="jump_8"></a>.

Due to our limitations, mistakes may occur. If you come across any errors, kindly point them out, and we appreciate your feedback.

# 18 Uniswap Multi-Chain Data Comparative Analysis

Uniswap is one of the leading decentralized exchanges (DEX) in the DeFi space. The Uniswap smart contract was initially deployed on the Ethereum blockchain in 2018, and it has since expanded to other chains such as Arbitrum, Optimism, Polygon, and Celo in 2021 and 2022. It continues to gain momentum with a new proposal to deploy on the Binance Smart Chain (BNB). In this article, we will explore how to analyze the performance of Uniswap across multiple chains in 2022. Please note that Celo chain is not included in this analysis as it is not currently supported by Dune.

Dashboard for this tutorial: [Uniswap V3 Performance In 2022 Multichains](https://dune.com/sixdegree/uniswap-v3-performance-in-2022-multi-chains)<a id="jump_8"></a>

All queries in this tutorial are executed using the Dune SQL.

Interestingly, during the completion of this tutorial, the Uniswap Foundation launched a new round of bounty program, focusing on analyzing Uniswap's performance across multiple chains on January 25, 2023. This tutorial hopes to provide some insights and ideas, and participants can further expand on these queries to participate in the bounty program. We wish you the best of luck in earning the generous rewards. You can find more information about the Unigrants program and the [Bounty #21 - Uniswap Multichain](https://unigrants.notion.site/Bounty-21-Uniswap-Multichain-b1edc714fe1949779530e920701fd617)<a id="jump_8"></a> here.

## Key Content of Multi-Chain Data Analysis

As mentioned in the description of the "Bounty #21 - Uniswap Multichain" activity, when analyzing DeFi applications like Uniswap, the most common metrics we need to analyze include trading volume, trading value, user base, and Total Value Locked (TVL). Uniswap deploys smart contracts for numerous liquidity pools that facilitate trading pairs of different tokens. Liquidity providers (LPs) deposit funds into these pools to earn transaction fee rewards, while other users can exchange their tokens using these liquidity pools. Therefore, a more in-depth analysis can also include liquidity pool-related and LP-related metrics.

In this tutorial, we will primarily focus on the following topics:

* Overview of total trading activity (number of trades, trading volume, user count, TVL)
* Daily trading data comparison
* Daily new user comparison
* Yearly comparison of new liquidity pools created
* Daily comparison of new liquidity pools
* TVL comparison
* Daily TVL
* Liquidity pool with the highest TVL

The Dune community has created a comprehensive trade data Spells called "uniswap.trades", which aggregates transaction data from Uniswap-related smart contracts on the mentioned four blockchains. Most of our queries can directly utilize this table. However, there is currently no Spells available for liquidity pool-related data, so we will need to write queries to aggregate data from different blockchains for comparative analysis.

It is important to note that in this tutorial, we primarily focus on the data from 2022. Therefore, there are date filtering conditions in the related queries. If you want to analyze the entire historical data, simply remove these conditions.

## Summary of Overall Trading Activity

We can write a query directly against the "uniswap.trades" to summarize the total trading volume, number of trades, and count of unique user addresses.

``` sql
select blockchain,
    sum(amount_usd) as trade_amount,
    count(*) as transaction_count,
    count(distinct taker) as user_count
from uniswap.trades
where block_time >= date('2022-01-01')
    and block_time < date('2023-01-01')
group by 1
```

Considering that the result data can be quite large, we can put the above query into a CTE (Common Table Expression). When outputting from the CTE, we can convert the numbers into million or billion units and conveniently aggregate data from multiple chains together.

We will add 3 Counter charts for the total trading volume, number of trades, and user count. Additionally, we will add 3 Pie charts to display the percentage of trading volume, number of trades, and user count for each chain. Furthermore, we will include a Table chart to present detailed numbers. All these charts will be added to the dashboard, resulting in the following display:

![image_01.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_01.png)

Query link:
* [https://dune.com/queries/1859214](https://dune.com/queries/1859214)<a id="jump_8"></a>

## Daily Transaction Data Comparative Analysis

Similarly, using the `uniswap.trades magical` table, we can write a SQL query to calculate the daily transaction data. The SQL query is as follows:

``` sql
with transaction_summary as (
    select date_trunc('day', block_time) as block_date,
        blockchain,
        sum(amount_usd) as trade_amount,
        count(*) as transaction_count,
        count(distinct taker) as user_count
    from uniswap.trades
    where block_time >= date('2022-01-01')
        and block_time < date('2023-01-01')
    group by 1, 2
)

select block_date,
    blockchain,
    trade_amount,
    transaction_count,
    user_count,
    sum(trade_amount) over (partition by blockchain order by block_date) as accumulate_trade_amount,
    sum(transaction_count) over (partition by blockchain order by block_date) as accumulate_transaction_count,
    sum(user_count) over (partition by blockchain order by block_date) as accumulate_user_count
from transaction_summary
order by 1, 2
```

Here, we summarize all transaction data from 2022 based on date and blockchains. We also output the cumulative data based on the date. It's important to note that the cumulative user count in this aggregation is not an accurate representation of "cumulative unique user count" since the same user can make transactions on different dates. We will explain how to calculate the unique user count separately in later queries.

Since our goal is to analyze the data performance across different chains, we can focus on the specific values as well as their proportions. Proportional analysis allows us to visually observe the trends of different chains over time. With this in mind, we generate the following charts: Line Chart for daily transaction volume, Bar Chart for daily transaction count and daily unique user count, Area Chart for cumulative transaction volume, transaction count, and unique user count, and another Area Chart to display the percentage contribution of each daily transaction data. The resulting charts, when added to the dashboard, will appear as follows:

![image_02.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_02.png)

Query link:
* [https://dune.com/queries/1928680](https://dune.com/queries/1928680)<a id="jump_8"></a>

## Daily New User Analysis

To analyze the daily new users and make comparisons, we first need to calculate the initial transaction date for each user address. Then, we can calculate the number of new users for each day based on their initial transaction dates. In the following query, we use a CTE called `user_initial_trade` to calculate the initial transaction date for each user address (`taker`) without any date filtering conditions. Then, in the CTE `new_users_summary`, we calculate the number of new users for each day in 2022. Additionally, we summarize the daily active users in the CTE `active_users_summary`. In the final output, we subtract the number of new users from the number of daily active users to obtain the number of retained users per day. This allows us to generate visualizations comparing the proportions of new users and retained users.

``` sql
with user_initial_trade as (
    select blockchain,
        taker,
        min(block_time) as block_time
    from uniswap.trades
    group by 1, 2
),

new_users_summary as (
    select date_trunc('day', block_time) as block_date,
        blockchain,
        count(*) as new_user_count
    from user_initial_trade
    where block_time >= date('2022-01-01')
        and block_time < date('2023-01-01')
    group by 1, 2
),

active_users_summary as (
    select date_trunc('day', block_time) as block_date,
        blockchain,
        count(distinct taker) as active_user_count
    from uniswap.trades
    where block_time >= date('2022-01-01')
        and block_time < date('2023-01-01')
    group by 1, 2
)

select a.block_date,
    a.blockchain,
    a.active_user_count,
    n.new_user_count,
    coalesce(a.active_user_count, 0) - coalesce(n.new_user_count, 0) as retain_user_count,
    sum(new_user_count) over (partition by n.blockchain order by n.block_date) as accumulate_new_user_count
from active_users_summary a
inner join new_users_summary n on a.block_date = n.block_date and a.blockchain = n.blockchain
order by 1, 2
```

To generate different visualizations for these queries, displaying the daily number and proportion of new users, daily number and proportion of retained users, daily cumulative number of new users, and the proportion of new users for each chain in 2022, we can create the following charts:

![image_03.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_03.png)

Query link:
* [https://dune.com/queries/1928825](https://dune.com/queries/1928825)<a id="jump_8"></a>

The queries mentioned above include the comparison of daily new users and daily retained users, as well as their respective proportions. However, since the results are already grouped by blockchain, it is not possible to display both the daily number of new users and the daily number of retained users in the same chart. In this case, we can utilize the Query of Query in the Dune SQL to create a new query using the previous queries as the data source. By selecting a specific blockchain from the query results, we can display multiple metrics in a single chart, as we no longer need to group by blockchain.

``` sql
select block_date,
    active_user_count,
    new_user_count,
    retain_user_count
from query_1928825 -- This points to all returned data from query https://dune.com/queries/1928825
where blockchain = '{{blockchain}}'
order by block_date
```

Here we will define the blockchain to be filtered as a parameter of type List, which will include the names (in lowercase format) of the four supported blockchains as options. We will generate two charts for the query results, displaying the daily number of new users and their respective proportions. After adding the charts to the dashboard, the display will be as follows:

![image_04.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_04.png)

Query link:
* [https://dune.com/queries/1929142](https://dune.com/queries/1929142)<a id="jump_8"></a>

## Comparative Analysis of Annual New Liquidity Pools

Dune's current Spells do not provide data on liquidity pools, so we can write our own queries to aggregate the data. We welcome everyone to submit a PR to the Spellbook repository on Dune's GitHub to generate the corresponding Spells. Using the PoolCreated event to parse the data, we will gather data from the four blockchains together. Since Uniswap V2 is only deployed on the Ethereum chain, we have not included it in the scope of our analysis.

``` sql
with pool_created_detail as (
    select 'ethereum' as blockchain,
        evt_block_time,
        evt_tx_hash,
        pool,
        token0,
        token1
    from uniswap_v3_ethereum.Factory_evt_PoolCreated

    union all
    
    select 'arbitrum' as blockchain,
        evt_block_time,
        evt_tx_hash,
        pool,
        token0,
        token1
    from uniswap_v3_arbitrum.UniswapV3Factory_evt_PoolCreated

    union all
    
    select 'optimism' as blockchain,
        evt_block_time,
        evt_tx_hash,
        pool,
        token0,
        token1
    from uniswap_v3_optimism.Factory_evt_PoolCreated

    union all
    
    select 'polygon' as blockchain,
        evt_block_time,
        evt_tx_hash,
        pool,
        token0,
        token1
    from uniswap_v3_polygon.factory_polygon_evt_PoolCreated
)

select blockchain,
    count(distinct pool) as pool_count
from pool_created_detail
where evt_block_time >= date('2022-01-01')
    and evt_block_time < date('2023-01-01')
group by 1
```

We can generate a Pie Chart to compare the number and proportion of newly created liquidity pools on each chain in 2022. Additionally, we can create a Table chart to display detailed data. After adding these charts to the dashboard, the display will look as follows:

![image_05.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_05.png)

Query link:
* [https://dune.com/queries/1929177](https://dune.com/queries/1929177)<a id="jump_8"></a>

## Daily Comparison of New Liquidity Pools

Similarly, by adding a date to the grouping condition in the query, we can calculate the daily count of new liquidity pools on each chain.

``` sql
with pool_created_detail as (
    -- 此处SQL同上
),

daily_pool_summary as (
    select date_trunc('day', evt_block_time) as block_date,
        blockchain,
        count(distinct pool) as pool_count
    from pool_created_detail
    group by 1, 2
)

select block_date,
    blockchain,
    pool_count,
    sum(pool_count) over (partition by blockchain order by block_date) as accumulate_pool_count
from daily_pool_summary
where block_date >= date('2022-01-01')
    and block_date < date('2023-01-01')
order by block_date
```

We can generate a Bar Chart for the daily count of new liquidity pools and an Area Chart to display the daily count percentage. Additionally, we can create an Area Chart to showcase the cumulative count of newly created liquidity pools. The visualizations can be added to the dashboard for display, as shown in the following image:

![image_06.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_06.png)

Query link:
* [https://dune.com/queries/1929235](https://dune.com/queries/1929235)<a id="jump_8"></a>

## Total Value Locked (TVL) Comparison Analysis

Different tokens have different prices. When comparing TVL, we need to convert the locked amounts (quantities) of these tokens to USD values by associating them with the `prices.usd` Spells. Only then can we perform the aggregation. Each trading pair represents an independent liquidity pool with its own contract address. The TVL represents the total value, in USD, of all tokens held by these contract addresses. To calculate the current token balances in a pool, we can use the `evt_Transfer` table under the `erc20` Spells to track the inflows and outflows of each pool and derive the current balances. Each pool consists of two different tokens, so we also need to obtain the decimal places and corresponding prices of these tokens. Let's take a look at the query code:

``` sql
with pool_created_detail as (
    -- The SQL here is the same as above
),

token_transfer_detail as (
    select p.blockchain,
        t.contract_address,
        t.evt_block_time,
        t.evt_tx_hash,
        t."to" as pool,
        cast(t.value as double) as amount_original
    from erc20_arbitrum.evt_Transfer t
    inner join pool_created_detail p on t."to" = p.pool
    where p.blockchain = 'arbitrum'

    union all

    select p.blockchain,
        t.contract_address,
        t.evt_block_time,
        t.evt_tx_hash,
        t."from" as pool,
        -1 * cast(t.value as double) as amount_original
    from erc20_arbitrum.evt_Transfer t
    inner join pool_created_detail p on t."from" = p.pool
    where p.blockchain = 'arbitrum'

    union all
    
    select p.blockchain,
        t.contract_address,
        t.evt_block_time,
        t.evt_tx_hash,
        t."to" as pool,
        cast(t.value as double) as amount_original
    from erc20_ethereum.evt_Transfer t
    inner join pool_created_detail p on t."to" = p.pool
    where p.blockchain = 'ethereum'

    union all

    select p.blockchain,
        t.contract_address,
        t.evt_block_time,
        t.evt_tx_hash,
        t."from" as pool,
        -1 * cast(t.value as double) as amount_original
    from erc20_ethereum.evt_Transfer t
    inner join pool_created_detail p on t."from" = p.pool
    where p.blockchain = 'ethereum'

    union all
    
    select p.blockchain,
        t.contract_address,
        t.evt_block_time,
        t.evt_tx_hash,
        t."to" as pool,
        cast(t.value as double) as amount_original
    from erc20_optimism.evt_Transfer t
    inner join pool_created_detail p on t."to" = p.pool
    where p.blockchain = 'optimism'

    union all

    select p.blockchain,
        t.contract_address,
        t.evt_block_time,
        t.evt_tx_hash,
        t."from" as pool,
        -1 * cast(t.value as double) as amount_original
    from erc20_optimism.evt_Transfer t
    inner join pool_created_detail p on t."from" = p.pool
    where p.blockchain = 'optimism'

    union all
    
    select p.blockchain,
        t.contract_address,
        t.evt_block_time,
        t.evt_tx_hash,
        t."to" as pool,
        cast(t.value as double) as amount_original
    from erc20_polygon.evt_Transfer t
    inner join pool_created_detail p on t."to" = p.pool
    where p.blockchain = 'polygon'

    union all

    select p.blockchain,
        t.contract_address,
        t.evt_block_time,
        t.evt_tx_hash,
        t."from" as pool,
        -1 * cast(t.value as double) as amount_original
    from erc20_polygon.evt_Transfer t
    inner join pool_created_detail p on t."from" = p.pool
    where p.blockchain = 'polygon'
),

token_list as (
    select distinct contract_address
    from token_transfer_detail
),

latest_token_price as (
    select contract_address, symbol, decimals, price, minute
    from (
        select row_number() over (partition by contract_address order by minute desc) as row_num, *
        from prices.usd
        where contract_address in ( 
                select contract_address from token_list 
            )
            and minute >= now() - interval '1' day
        order by minute desc
    ) p
    where row_num = 1
),

token_transfer_detail_amount as (
    select blockchain,
        d.contract_address,
        evt_block_time,
        evt_tx_hash,
        pool,
        amount_original,
        amount_original / pow(10, decimals) * price as amount_usd
    from token_transfer_detail d
    inner join latest_token_price p on d.contract_address = p.contract_address
)

select blockchain,
    sum(amount_usd) as tvl,
    (sum(sum(amount_usd)) over ()) / 1e9 as total_tvl
from token_transfer_detail_amount
where abs(amount_usd) < 1e9 -- Exclude some outlier values from Optimism chain
group by 1
```

The explanation of the above query is as follows:

* CTE `pool_created_detail`: Retrieves data for all created liquidity pools across different chains.
* CTE `token_transfer_detail`: Filters out token transfer data for all Uniswap liquidity pools by joining the `evt_Transfer` table with `pool_created_detail`.
* CTE `token_list`: Filters out the list of tokens used in all trading pairs.
* CTE `latest_token_price`: Calculates the current prices of these tokens. Since the price data in `prices.usd` may have a time delay, we first retrieve data from the past 1 day and then use `row_number() over (partition by contract_address order by minute desc)` to calculate the row number and return only the rows with a row number of 1, which represents the latest price records for each token.
* CTE `token_transfer_detail_amount`: Joins `token_transfer_detail` with `latest_token_price` to calculate the USD value of token transfers.
* The final output query summarizes the current TVL for each blockchain and the total TVL across all chains.

Generates a Pie Chart and a Counter chart respectively. Adds them to the dashboard, resulting in the following display:

![image_07.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_07.png)

Query link:
* [https://dune.com/queries/1929279](https://dune.com/queries/1929279)<a id="jump_8"></a>

### Daily TVL (Total Value Locked) Comparative Analysis

When analyzing daily TVL amounts, we need to add a date grouping dimension. However, the result obtained at this point is the daily change in TVL, not the daily balance. We also need to accumulate the balances by date to obtain the correct daily balances.


``` sql
with pool_created_detail as (
    -- The SQL here is the same as above
),

token_transfer_detail as (
    -- The SQL here is the same as above
),

token_list as (
    -- The SQL here is the same as above
),

latest_token_price as (
    -- The SQL here is the same as above
),

token_transfer_detail_amount as (
    -- The SQL here is the same as above
),

tvl_daily as (
    select date_trunc('day', evt_block_time) as block_date,
        blockchain,
        sum(amount_usd) as tvl_change
    from token_transfer_detail_amount
    where abs(amount_usd) < 1e9 -- Exclude some outlier values from Optimism chain
    group by 1, 2
)

select block_date,
    blockchain,
    tvl_change,
    sum(tvl_change) over (partition by blockchain order by block_date) as tvl
from tvl_daily
where block_date >= date('2022-01-01')
    and block_date < date('2023-01-01')
order by 1, 2
```

We discovered that there are some abnormal data on the Optimism chain, so we added the condition abs(amount_usd) < 1e9 in the above query to exclude them. Generate an Area Chart for this query. Add it to the dashboard, and the display is as follows:

![image_08.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_08.png)

Query link:
* [https://dune.com/queries/1933439](https://dune.com/queries/1933439)<a id="jump_8"></a>

## Top Flow Pools by TVL

By aggregating the TVL (Total Value Locked) by the contract address of each flow pool, we can calculate the current TVL for each pool. However, if we want to compare the trade pairs more intuitively using the token symbols, we can join the tokens.erc20 Spells to generate the trade pairs. In Uniswap, the same trade pair can have multiple service fee rates (different pool addresses), so we need to aggregate them by the trade pair name. Here is the SQL to achieve this:


``` sql
with pool_created_detail as (
    -- The SQL here is the same as above
),

token_transfer_detail as (
    -- The SQL here is the same as above
),

token_list as (
    -- The SQL here is the same as above
),

latest_token_price as (
    -- The SQL here is the same as above
),

token_transfer_detail_amount as (
    -- The SQL here is the same as above
),

top_tvl_pools as (
    select pool,
        sum(amount_usd) as tvl
    from token_transfer_detail_amount
    where abs(amount_usd) < 1e9 -- Exclude some outlier values from Optimism chain
    group by 1
    order by 2 desc
    limit 200
)

select concat(tk0.symbol, '-', tk1.symbol) as pool_name,
    sum(t.tvl) as tvl
from top_tvl_pools t
inner join pool_created_detail p on t.pool = p.pool
inner join tokens.erc20 as tk0 on p.token0 = tk0.contract_address
inner join tokens.erc20 as tk1 on p.token1 = tk1.contract_address
group by 1
order by 2 desc
limit 100
```

We can generate a Bar Chart and a Table chart to display the data for the flow pools with the highest TVL (Total Value Locked).

![image_09.png](https://raw.githubusercontent.com/SixdegreeLab/MasteringChainAnalytics/main/15_uniswap_multichain/img/image_09.png)

Query link:
* [https://dune.com/queries/1933442](https://dune.com/queries/1933442)<a id="jump_8"></a>

## SixDegreeLab introduction

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)<a id="jump_8"></a>）is a professional on-chain data team dedicated to providing accurate on-chain data charts, analysis, and insights to users. Our mission is to popularize on-chain data analysis and foster a community of on-chain data analysts. Through community building, tutorial writing, and other initiatives, we aim to cultivate talents who can contribute valuable analytical content and drive the construction of a data layer for the blockchain community, nurturing talents for the future of blockchain data applications.

Feel free to visit [SixDegreeLab's Dune homepage](https://dune.com/sixdegree)<a id="jump_8"></a>.

Due to our limitations, mistakes may occur. If you come across any errors, kindly point them out, and we appreciate your feedback.

