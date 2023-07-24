
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

