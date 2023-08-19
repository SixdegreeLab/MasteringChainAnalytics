# 19 Useful Metrics

## Background Knowledge

In the previous tutorials, we learned a lot about data tables and SQL query statements. Accurately and effectively retrieving as well as calculating the required data is an essential skill for a qualified analyst. At the same time, understanding and interpreting these data metrics are equally crucial. Only with a deep understanding of data metrics can they provide strong support for our decision-making.

Before delving into specific metrics, let's first consider why we need data metrics. In simple terms, metrics are numerical values that reflect certain phenomena, such as the floor price of a particular NFT or the daily active trades on a DEX. Metrics directly reflect the status of the objects we are studying and provide data support for corresponding decisions. By leveraging our knowledge of data tables and SQL queries, we can build, invoke, and analyze these metrics, making our analysis efforts more efficient. Without metrics, the information we obtain would be chaotic and the insights we can gain would be limited.

In the context of blockchain, although some metrics are similar to those in financial markets, there are also unique metrics specific to the blockchain space, such as Bitcoin Dominance and All Exchanges Inflow Mean-MA7. In this tutorial, we will start by learning about several common metrics and their calculation methods:

- Total Value Locked (TVL)
- Circulating Supply
- Market Cap
- Daily/Monthly Active Users (DAU/MAU)
- Daily/Monthly New Users

## Total Value Locked (TVL)

Let's start with the first metric we are going to learn today - Total Value Locked (TVL). It describes the total value of all locked tokens in a protocol, which can be a DEX, lending platform, or even a sidechain or L2 network. TVL reflects the liquidity and popularity of the protocol and indicates user confidence.

For example, let's take a look at the TVL ranking for DEXs:

![](img/ch19_image_01.png)

And the TVL ranking for Layer 2 networks:

![](img/ch19_image_02.png)

The top-ranked protocols are the ones with higher popularity.

The calculation logic for TVL is relatively straightforward. We need to count all relevant tokens in the protocol, multiply each token's quantity by its price, and finally sum up the results. Let's use the DEX project Auragi on the Arbitrum chain as an example to explain TVL calculation. The TVL of the DEX project is reflected through the balances in its liquidity pools. To calculate the TVL for each day, we need to first calculate the balance of relevant tokens in each pair for that day and their corresponding prices in USD.

To get the token balances for each pair, we first need to organize all transaction details:

``` sql
WITH token_pairs AS (
    SELECT 
        COALESCE(k1.symbol, 'AGI') || '-' || COALESCE(k2.symbol, 'AGI') AS pair_name,
        p.pair,
        p.evt_block_time,
        p.token0,
        p.token1,
        p.stable
    FROM auragi_arbitrum.PairFactory_evt_PairCreated p
    LEFT JOIN tokens.erc20 k1 ON p.token0 = k1.contract_address AND k1.blockchain = 'arbitrum'
    LEFT JOIN tokens.erc20 k2 ON p.token1 = k1.contract_address AND k2.blockchain = 'arbitrum'
),

token_transfer_detail AS (
    SELECT DATE_TRUNC('minute', evt_block_time) AS block_date,
        evt_tx_hash AS tx_hash,
        contract_address,
        "to" AS user_address,
        CAST(value AS DECIMAL(38, 0)) AS amount_raw
    FROM erc20_arbitrum.evt_Transfer
    WHERE "to" IN (SELECT pair FROM token_pairs)
        AND evt_block_time >= DATE('2023-04-04')

    UNION ALL
    
    SELECT DATE_TRUNC('minute', evt_block_time) AS block_date,
        evt_tx_hash AS tx_hash,
        contract_address,
        "from" AS user_address,
        -1 * CAST(value AS DECIMAL(38, 0)) AS amount_raw
    FROM erc20_arbitrum.evt_Transfer
    WHERE "from" IN (SELECT pair FROM token_pairs)
        AND evt_block_time >= DATE('2023-04-04')
),

token_price AS (
    SELECT DATE_TRUNC('minute', minute) AS block_date,
        contract_address,
        decimals,
        symbol,
        AVG(price) AS price
    FROM prices.usd
    WHERE blockchain = 'arbitrum'
        AND contract_address IN (SELECT DISTINCT contract_address FROM token_transfer_detail)
        AND minute >= DATE('2023-04-04')
    GROUP BY 1, 2, 3, 4
    
    UNION ALL
    
    -- AGI price from swap trade
    SELECT DATE_TRUNC('minute', block_time) AS block_date,
        0xFF191514A9baba76BfD19e3943a4d37E8ec9a111 AS contract_address,
        18 AS decimals,
        'AGI' AS symbol,
        AVG(CASE WHEN token_in_address = 0xFF191514A9baba76BfD19e3943a4d37E8ec9a111 THEN token_in_price ELSE token_out_price END) AS price
    FROM query_2337808
    GROUP BY 1, 2, 3, 4
)

SELECT p.symbol,
    d.block_date,
    d.tx_hash,
    d.user_address,
    d.contract_address,
    d.amount_raw,
    (d.amount_raw / POWER(10, p.decimals) * p.price) AS amount_usd
FROM token_transfer_detail d
INNER JOIN token_price p ON d.contract_address = p.contract_address AND d.block_date = p.block_date
```

The above query logic is as follows:

- First, in `token_pairs`, we obtain all pairs for this project.
- With the help of the `evt_Transfer` table, we extract the transaction details of each pair.
- In `token_price`, we calculate the current price of each token. As this is a relatively new token, Dune might not have its price data. Therefore, we use trade data to calculate the price. The detailed list of trade data is obtained through another query, which we reference using a Query of Query approach.
- Finally, we join the transaction details with the price information to calculate the USD amount for each transaction.

Based on the results of the transaction details query, we can now calculate the TVL for each day.

First, we generate a date-time series in `date_series`. Considering that this is a relatively new project, we calculate the TVL on an hourly basis. If the project has been online for a sufficient period, we recommend calculating it on a daily basis.

Next, in `pool_balance_change`, we combine the transaction details above to summarize the balance changes of each token per hour.

In `pool_balance_summary`, we sort the token balances by time and sum up the cumulative balances for each token. Here, we use the `lead()` function to calculate the next date with recorded balances for each token in each time period.

Finally, we join the date series with the cumulative balances for each hour, filling in the missing transaction data for each time period. Pay attention to the join condition here: `INNER JOIN date_series d ON p.block_date <= d.block_date AND d.block_date < p.next_date`. We use two conditions here: specifying that the cumulative balance date must be less than or equal to the date-time value of the date series and the date-time value of the series must be less than the date-time value of the next recorded balance. This is a common processing technique. Not all tokens have transactions in every time period, so when encountering a time period without transactions, we need to use the balance from the previous time period to represent the balance in the current time period. This should be relatively easy to understand because there were no new changes during the "current time period," so the balance naturally remains the same as the previous time period.

The query code is as follows:

``` sql
WITH date_series AS (
    SELECT block_date
    FROM UNNEST(SEQUENCE(TIMESTAMP '2023-04-01 00:00:00', localtimestamp, INTERVAL '1' hour)) AS tbl(block_date)
),

pool_balance_change AS (
    SELECT symbol,
        DATE_TRUNC('hour', block_date) AS block_date,
        SUM(amount_usd) AS amount
    FROM query_2339248
    GROUP BY 1, 2
),

pool_balance_summary AS (
    SELECT symbol,
        block_date,
        SUM(amount) OVER (PARTITION BY symbol ORDER BY block_date) AS balance_amount,
        LEAD(block_date, 1, current_date) OVER (PARTITION BY symbol ORDER BY block_date) AS next_date
    FROM pool_balance_change
    ORDER BY 1, 2
)

SELECT d.block_date,
    p.symbol,
    p.balance_amount
FROM pool_balance_summary p
INNER JOIN date_series d ON p.block_date <= d.block_date AND d.block_date < p.next_date
ORDER BY 1, 2
```

With this query, we can visualize the TVL changes:

![](img/ch19_image_03.png)

Links to the above queries:

- https://dune.com/queries/2339317
- https://dune.com/queries/2339248
- https://dune.com/queries/2337808

Another example for calculating TVL: https://dune.com/queries/1059644/1822157

## Circulating Supply

Circulating Supply represents the current quantity of a cryptocurrency that is circulating in the market and held by holders. It differs from Total Supply, which includes all tokens issued, even those that are locked and cannot be traded. Since these locked tokens usually do not impact the price, Circulating Supply is a more commonly used metric for token quantity. The calculation method for Circulating Supply can vary depending on the cryptocurrency. For example, for tokens with linear release schedules, their supply increases over time. Tokens with deflationary burning mechanisms may require a deduction for their Circulating Supply. Let's take Bitcoin as an example and calculate its current Circulating Supply.

The Circulating Supply of Bitcoin can be calculated based on the number of blocks and the block reward schedule:

``` sql
SELECT SUM(50/POWER(2, ROUND(height/210000))) AS Supply                      
FROM bitcoin.blocks
```

## Market Cap

The third metric we'll learn today is Market Cap. You are probably familiar with this metric. In the stock market, Market Cap refers to the total value of all outstanding shares of a stock at a specific time, which is calculated by multiplying the total number of shares by the stock's price. Similarly, in the blockchain space, it is calculated by multiplying the Circulating Supply of a cryptocurrency by its current price. Therefore, the key to calculating Market Cap is to obtain the metric we just learned - Circulating Supply. Once we have the Circulating Supply, we can multiply it by the current price of the cryptocurrency to get its Market Cap.

Let's continue using Bitcoin as an example. Based on the previously calculated Circulating Supply, we can now multiply it by Bitcoin's current price to obtain its Market Cap:

``` sql
SELECT SUM(50/POWER(2, ROUND(height/210000))) AS Supply, 
       SUM(50/POWER(2, ROUND(height/210000)) * p.price) / POWER(10, 9) AS "Market Cap"
FROM bitcoin.blocks
INNER JOIN (
    SELECT price FROM prices.usd_latest
    WHERE symbol='BTC'
        AND contract_address IS NULL
) p ON TRUE
```

The Bitcoin Dominance that we mentioned earlier is calculated as the Market Cap of Bitcoin divided by the sum of the Market Caps of all cryptocurrencies.

## Daily/Monthly Active Users (DAU/MAU)

The next metric we'll learn is Daily/Monthly Active Users (DAU/MAU). Compared to absolute trading volumes, the number of active users better reflects the popularity of a protocol. Large transactions from a small number of users can inflate the trading volumes, while the count of active users provides a more objective description of the protocol's popularity. The calculation is relatively simple; we just need to count the number of wallet addresses that interacted with a specific contract and then calculate the frequency per day or per month.

Let's take the recent popular protocol Lens as an example:

``` sql
WITH daily_count AS (
    SELECT DATE_TRUNC('day', block_time) AS block_date,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT "from") AS user_count
    FROM polygon.transactions
    WHERE "to" = 0xdb46d1dc155634fbc732f92e853b10b288ad5a1d   -- LensHub
        AND block_time >= DATE('2022-05-16')  -- contract creation date
    GROUP BY 1
    ORDER BY 1
)

SELECT block_date,
    transaction_count,
    user_count,
    SUM(transaction_count) OVER (ORDER BY block_date) AS accumulate_transaction_count,
    SUM(user_count) OVER (ORDER BY block_date) AS accumulate_user_count
FROM daily_count
ORDER BY block_date
```

We use the `DISTINCT` function to ensure that each user is counted only once per day. In addition to calculating the number of daily active users, we also use the `SUM` `OVER` function to calculate the cumulative user count. If you want to calculate the monthly active users (MAU), you can modify the query to use `DATE_TRUNC('month', block_time)` to group the counts by month.

![](img/ch19_image_04.png)



## Daily / Monthly New Users

In addition to monitoring active user data, the number of daily/monthly new users is also a very common analytical metric. Typically, to obtain accurate data on new users, we need to first calculate the date and time of the first transaction for each user address or the date and time of the first received/sent transfer record. Then, we can count the number of new users per day or per month based on this information. Here, we will use a query to calculate the number of daily new users on the Optimism chain as an example.

``` sql
with optimism_new_users as (
    SELECT "from" as address,
        min(block_time) as start_time
    FROM optimism.transactions
    GROUP BY 1
)

SELECT date_trunc('day', start_time) as block_date,
    count(n.address) as new_users_count
FROM optimism_new_users n
WHERE start_time >= date('2022-10-01')
GROUP BY 1
```

![](img/ch19_image_05.png)

Here is a practical example that combines the number of new users with specific NFT project user data statistics: [Example](https://dune.com/queries/1334302).

## About Us

`Sixdegree` is a professional onchain data analysis team Our mission is to provide users with accurate onchain data charts, analysis, and insights. We are committed to popularizing onchain data analysis. By building a community and writing tutorials, among other initiatives, we train onchain data analysts, output valuable analysis content, promote the community to build the data layer of the blockchain, and cultivate talents for the broad future of blockchain data applications. Welcome to the community exchange!

- Website: [sixdegree.xyz](https://sixdegree.xyz)
- Email: [contact@sixdegree.xyz](mailto:contact@sixdegree.xyz)
- Twitter: [twitter.com/SixdegreeLab](https://twitter.com/SixdegreeLab)
- Dune: [dune.com/sixdegree](https://dune.com/sixdegree)
- Github: [https://github.com/SixdegreeLab](https://github.com/SixdegreeLab)
