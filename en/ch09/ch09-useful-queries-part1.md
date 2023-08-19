# 09 Useful Queries (I): ERC20 token price queries

In daily data analysis, We usually encounter some common queries, such as tracking the price changes of an ERC20 token, querying the balance of various ERC20 tokens held by a certain address, etc. In the help documentation of the Dune platform, [some helpful data dashboards](https://dune.com/docs/reference/wizard-tools/helpful-dashboards/) and [utility queries](https://dune.com/docs/reference/wizard-tools/utility-queries/) sections give some examples, you can refer to them. In this tutorial, we combine some typical needs that we encounter in our daily life, and sort out some query cases for you.

## Query the latest price of a single ERC20 token

ERC20 tokens are used in a wide variety of blockchain applications. DeFi initiatives facilitate the trading of ERC20 tokens. Other projects reward their backers, early adopters, and development teams through distribution plans and airdrops in exchange for ERC20 tokens. Price data for several ERC20 tokens may be found on sites like [CoinGecko](https://www.coingecko.com/). The 'prices.usd' and 'prices.usd_latest' tables in Dune make it easy for data analysts to retrieve the current market value of the most popular ERC20 tokens on each blockchain. There is a table called [prices.usd](https://dune.com/docs/reference/tables/prices/) that keeps track of the minute-by-minute prices of different ERC20 tokens. To facilitate activities like summarization and comparison while researching ERC20 token-related projects, we may pool the pricing data to convert the quantity of different tokens into the amount stated in US dollars.

**Get the latest price of a single ERC20 token**

The prices in the `prices.usd` table are recorded on a minute-by-minute basis. The retrieval of the most recent record is contingent upon the token's symbol and the corresponding blockchain it is associated with. In the event that a contract address is available, it is also possible to use such contract address for querying purposes. The `usd_latest` database is designed to store the most recent price of each token. Each token is represented by a single row in the table. The below techniques may be used to get the most recent price of an individual token, using WETH as an illustrative instance. In order to enhance query performance, we restrict the retrieval of the most recent portion of the data, since the pricing information is stored in a single record per token each minute, resulting in a substantial number of records for each token. Intermittently, there may exist a specific temporal lag. In the present case, we retrieve the most recent data entry during the preceding six-hour timeframe to ascertain the obtainability of the pricing.

**Use the token value to read the latest price information in the `prices.usd` table:**

``` sql
select * from prices.usd
where symbol = 'WETH'
    and blockchain = 'ethereum'
    and minute >= now() - interval '6' hour
order by minute desc
limit 1
```

**Use the smart contract address of the token to read the latest price in the `prices.usd` table:**

``` sql
select * from prices.usd
where contract_address = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2   -- WETH
    and minute >= now() - interval '6' hour
order by minute desc
limit 1
```

**Read the latest price information from the tables of `prices.usd_latest`: **

``` sql
select * from prices.usd_latest
where symbol = 'WETH'
    and blockchain = 'ethereum'
```

The query is simpler to read from the `prices.usd_latest` table, but since it is actually a view of the `prices.usd` table, it is slightly less efficient to execute.
reference source code: [prices_usd _latest](https://github.com/dizunalytics/spellbook/blob/main/models/prices_usd.latest.sql)


## Check the latest prices of multiple ERC20 tokens

When we need to read the latest prices of multiple tokens at the same time, the convenience of the `prices.usd_latest` table is reflected. Here we take the latest price query of WETH, WBTC and USDC as an example.


**Read the latest price information for multiple tokens from the `prices.usd_latest` table:**

``` sql
select * from prices.usd_latest
where symbol in ('WETH', 'WBTC', 'USDC')
    and blockchain = 'ethereum'
```

**Read the latest price information for multiple tokens from the `prices.usd` table:**

``` sql
select symbol, decimals, price, minute
from (
    select row_number() over (partition by symbol order by minute desc) as row_num, *
    from prices.usd
    where symbol in ('WETH', 'WBTC', 'USDC')
        and blockchain = 'ethereum'
        and minute >= now() - interval '6' hour
    order by minute desc
) p
where row_num = 1
```

Because we want to read the latest prices of multiple tokens at the same time, we cannot simply use the `limit` clause to limit the number of results to get the desired results. What we actually need to return is to take the first record after each different token is sorted in descending order by the `minute` field. In the above query, we used `row_number() over (partition by symbol order by minute desc) as row_num` to generate a new column. The values in this column are grouped by `symbol` and sorted in descending order by the `minute` field - that is, each different token will generate its own row number sequence value such as 1, 2, 3, 4, etc. We put it into a subquery, and filter the record of `where row_num = 1` in the outer query, which is the latest record of each token. This method seems a little complicated, but similar queries are often used in practical applications, and new columns are generated through the `row_number()` function and then used to filter data.

## Query the daily average price of a single ERC20 token

When we need to query the average price of an ERC20 token every day, we can only use the `prices.usd` table. By setting the date range of the price to be queried (or taking the data of all dates without adding the date range), summarizing by day, and using the `avg()` function to obtain the average value, the price data by day can be obtained. The SQL statement is as follows:

``` sql
select date_trunc('day', minute) as block_date,
    avg(price) as price
from prices.usd
where symbol = 'WETH'
    and blockchain = 'ethereum'
    and minute >= date('2023-01-01')
group by 1
order by 1
```

If we need to return other fields at the same time, we can add them to the SELECT list and add them to the GROUP BY at the same time. This is because, when using the `group by` clause, fields that appear in the SELECT list must also appear in the GROUP BY clause if they are not aggregate functions. The modified SQL statement is as follows:

``` sql
select date_trunc('day', minute) as block_date,
    symbol,
    decimals,
    contract_address,
    avg(price) as price
from prices.usd
where symbol = 'WETH'
    and blockchain = 'ethereum'
    and minute >= date('2023-01-01')
group by 1, 2, 3, 4
order by 1
```

## Query the daily average price of multiple ERC20 tokens

Similarly, we can query the average price of a group of ERC20 tokens every day at the same time, just put the symbol of the token to be queried into the `in ()` conditional clause. The SQL statement is as follows:

``` sql
select date_trunc('day', minute) as block_date,
    symbol,
    decimals,
    contract_address,
    avg(price) as price
from prices.usd
where symbol in ('WETH', 'WBTC', 'USDC')
    and blockchain = 'ethereum'
    and minute >= date('2022-10-01')
group by 1, 2, 3, 4
order by 2, 1   -- Order by symbol first
```

## Calculate price from DeFi swap records

The price data table `prices.usd` on Dune is maintained through spellbook, which does not include price information for all tokens on all supported blockchains. Especially when a new ERC20 token is newly issued and listed on the DEX (such as XEN), Dune's price list will not automatically display this token's data. At this point, we can read the swap data in the DeFi project, such as the Swap data in Uniswap, calculate the exchange price between the corresponding token and USDC (or WETH), and then convert the USDC or WETH price data to get the US dollar price. A sample query is as follows:

``` sql
with xen_price_in_usdc as (
    select date_trunc('hour', evt_block_time) as block_date,
        'XEN' as symbol,
        '0x06450dee7fd2fb8e39061434babcfc05599a6fb8' as contract_address, -- XEN
        18 as decimals,
        avg(amount1 / amount0) / pow(10, (6-18)) as price   --USDC: 6 decimals, XEN: 18 decimals
    from (
        select contract_address,
            abs(amount0) as amount0,
            abs(amount1) as amount1,
            evt_tx_hash,
            evt_block_time
        from uniswap_v3_ethereum.Pair_evt_Swap
        where contract_address = '0x353bb62ed786cdf7624bd4049859182f3c1e9e5d'   -- XEN-USDC 1.00% Pair
            and evt_block_time > '2022-10-07'
            and evt_block_time > now() - interval '30 days'
    ) s
    group by 1, 2, 3, 4
),

usdc_price as (
    select date_trunc('hour', minute) as block_date,
        avg(price) as price
    from prices.usd
    where contract_address = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'   -- USDC
        and minute > '2022-10-07'
        and minute > now() - interval '30 days'
    group by 1
)

select x.block_date,
    x.price * u.price as price_usd
from xen_price_in_usdc x
inner join usdc_price u on x.block_date = u.block_date
order by x.block_date
```

The above query is a practical application in the data dashboard of the XEN Crypto project. The reference link is as follows:
- data dashboard: [XEN Crypto Overview](https://dune.com/sixdegree/xen-crypto-overview)
- Query: [XEN - price trend](https://dune.com/queries/1382200)

## Calculate price from DeFi transaction spells table

If the corresponding DeFi transaction data is already integrated into the `dex.trades` table, it will be easier to use this table to calculate the price. We can divide `amount_usd` by `token_bought_amount` or `token_sold_amount` to get the USD price of the corresponding token. Taking USDC-WETH 0.30% under Uniswap V3 as an example, the SQL statement to calculate the latest price of WETH is as follows:

``` sql
with trade_detail as (
    select block_time,
        tx_hash,
        amount_usd,
        token_bought_amount,
        token_bought_symbol,
        token_sold_amount,
        token_sold_symbol
    from dex.trades
    where project_contract_address = 0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8
        and block_date >= now() - interval '3' day
    order by block_time desc
    limit 1000
)

select avg(
    case when token_bought_symbol = 'WETH' then amount_usd / token_bought_amount
        else amount_usd / token_sold_amount
    end
    ) as price
from trade_detail
```

## Calculate the price of the native token (ETH)

Taking Ethereum as an example, its native token ETH is not an ERC20 token, so there is no price information of ETH itself in the `prices.usd` table. However, WETH tokens (Wrapped ETH) are equivalent to ETH, so we can directly use WETH price data.

## Use price data from other blockchains

There is also a trick that can work around when the token price data of the blockchain we want to analyze cannot be found in `prices.usd`. For example, the Avalanche-C chain also provides transactions of tokens such as USDC, WETH, WBTC, and AAVE, but they have different token addresses compared to the Ethereum chain. If `prices.usd` does not provide the price data of the Avalache-C chain (it should already be supported), we can customize a CTE to map the token addresses on different chains, and then query to obtain the price.

``` sql
with token_mapping_to_ethereum(aave_token_address, ethereum_token_address, token_symbol) as (
    values
    (0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9, 0xdac17f958d2ee523a2206206994597c13d831ec7, 'USDT'),
    (0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f, 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599, 'WBTC'),
    (0xd22a58f79e9481d1a88e00c343885a588b34b68b, 0xdb25f211ab05b1c97d595516f45794528a807ad8, 'EURS'),
    (0xff970a61a04b1ca14834a43f5de4533ebddb5cc8, 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48, 'USDC'),
    (0xf97f4df75117a78c1a5a0dbb814af92458539fb4, 0x514910771af9ca656af840dff83e8264ecf986ca, 'LINK'),
    (0x82af49447d8a07e3bd95bd0d56f35241523fbab1, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 'WETH'),
    (0xda10009cbd5d07dd0cecc66161fc93d7c9000da1, 0x6b175474e89094c44da98b954eedeac495271d0f, 'DAI'),
    (0xba5ddd1f9d7f570dc94a51479a000e3bce967196, 0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9, 'AAVE')
),

latest_token_price as (
    select date_trunc('hour', minute) as price_date,
        contract_address,
        symbol,
        decimals,
        avg(price) as price
    from prices.usd
    where contract_address in (
        select ethereum_token_address
        from token_mapping_to_ethereum
    )
    and minute > now() - interval '1' day
    group by 1, 2, 3, 4
),

latest_token_price_row_num as (
    select  price_date,
        contract_address,
        symbol,
        decimals,
        price,
        row_number() over (partition by contract_address order by price_date desc) as row_num
    from latest_token_price
),

current_token_price as (
    select contract_address,
        symbol,
        decimals,
        price
    from latest_token_price_row_num
    where row_num = 1
)

select * from current_token_price
```

Here's an example query: [https://dune.com/queries/1042456](https://dune.com/queries/1042456)


## Calculate price from logs

Tip: the content of this section is relatively complicated. If you find it difficult, you can skip it directly.

A special case is when analyzing a new DeFi project or a blockchain newly supported by Dune. At this point, there is no corresponding `prices.usd` data, the smart contract of the corresponding project has not been submitted for analysis, and the transaction records have not been integrated into the magic table like `dex.trades`. The only thing we can access is the raw data tables such as `transactions` and `logs`. Therefore, we can first find several transaction records, analyze the detailed information of the event log displayed on the blockchain, determine the data type and relative position contained in the `data` value of the event, and then manually analyze the data based on this information to convert the price.

For example, say we need to calculate the price of the $OP token on the Optimism chain, and assuming that all the aforementioned conditions are met, the price must be calculated from the original table of the transaction event log. We first find an exchange transaction record based on the clues provided by the project team (contract address, case hash, etc.): [https://optimistic.etherscan.io/tx/0x1df6dda6a4cffdbc9e477e6682b982ca096ea747019e1c0dacf4aceac3fc532f](https://optimistic.etherscan.io/tx/0x1df6dda6a4cffdbc9e477e6682b982ca096ea747019e1c0dacf4aceac3fc532f). This is a swap transaction, where the `topic1` value of the last `logs` log "0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822" corresponds to "Swap(address,uint256,uint256,uint256,uint256,address)" method. This can be further verified by querying the `decoding.evm_signatures` table (this is because Optimism is an EVM-compatible blockchain that uses the same related functions as Ethereum).

A screenshot of the logs on the blockchain browser is as follows:

![](img/ch09_image_01.png)

The screenshot of evm_signatures signature data query is as follows:

![](img/ch09_image_02.png)

When querying `evm_signatures` in the above figure, we did some processing so that the relevant columns of data are displayed from top to bottom. The corresponding SQL statement is:

``` sql
select 'ID:' as name, cast(id as varchar) as value
from decoding.evm_signatures
where id = 0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822
union all
select 'Signature:' as name, signature as value
from decoding.evm_signatures
where id = 0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822
union all
select 'ABI:' as name, abi as value
from decoding.evm_signatures
where id = 0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822
```

Combining the above relevant information, we can convert the price by analyzing the Swap records in the event log. In the query below, we take the latest 1000 transaction records to calculate the average price. Since the exchange is bidirectional, it may be exchanged from `token0` to `token1` or vice versa, we use a case statement to take out different values accordingly to calculate the transaction price.  In addition, we did not further obtain the price of USDC for conversion. After all, it is a stable currency and its price fluctuates less. When you need more accurate data, you can refer to the previous example to convert through USDC price information.

``` sql
with op_price as (
    select 0x4200000000000000000000000000000000000042 as token_address,
        'OP' as token_symbol,
        18 as decimals,
        avg(
            (case when amount0_in > 0 then amount1_out else amount1_in end) 
            / 
            (case when amount0_in > 0 then amount0_in else amount0_out end)
        ) as price
    from (
        select tx_hash,
            index,
            cast(bytearray_to_uint256(bytearray_substring(data, 1, 32)) as decimal(38, 0)) / 1e18 as amount0_in,
            cast(bytearray_to_uint256(bytearray_substring(data, 1 + 32, 32)) as decimal(38, 0)) / 1e6  as amount1_in,
            cast(bytearray_to_uint256(bytearray_substring(data, 1 + 32 * 2, 32)) as decimal(38, 0)) / 1e18  as amount0_out,
            cast(bytearray_to_uint256(bytearray_substring(data, 1 + 32 * 3, 32)) as decimal(38, 0)) / 1e6  as amount1_out
        from optimism.logs
        where block_time >= now() - interval '2' day
            and contract_address = 0x47029bc8f5cbe3b464004e87ef9c9419a48018cd -- OP - USDC Pair
            and topic0 = 0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822   -- Swap
        order by block_time desc
        limit 1000
    )
)

select * from op_price
```

Here is an actual case: [https://dune.com/queries/1130354](https://dune.com/queries/1130354)

## About Us

`Sixdegree` is a professional onchain data analysis team Our mission is to provide users with accurate onchain data charts, analysis, and insights. We are committed to popularizing onchain data analysis. By building a community and writing tutorials, among other initiatives, we train onchain data analysts, output valuable analysis content, promote the community to build the data layer of the blockchain, and cultivate talents for the broad future of blockchain data applications. Welcome to the community exchange!

- Website: [sixdegree.xyz](https://sixdegree.xyz)
- Email: [contact@sixdegree.xyz](mailto:contact@sixdegree.xyz)
- Twitter: [twitter.com/SixdegreeLab](https://twitter.com/SixdegreeLab)
- Dune: [dune.com/sixdegree](https://dune.com/sixdegree)
- Github: [https://github.com/SixdegreeLab](https://github.com/SixdegreeLab)

