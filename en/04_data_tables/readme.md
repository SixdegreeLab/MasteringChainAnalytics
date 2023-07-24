# Familiar with data tables

Data platforms like Dune decode and store blockchain data in databases. Data analysts write SQL queries to analyze data from specific tables based on their analysis needs. With more and more blockchain platforms emerging in the market and a variety of projects deployed on different blockchains, it is essential for analysts to quickly locate the corresponding data tables for analysis and understand the meaning and purpose of each field in the tables. This is a crucial skill that every analyst must possess.
Currently, the structure of the basic datasets provided by several data platforms is quite similar. Here, we will focus on explaining the structure of the Dune platform. If you prefer to use other data platforms, you can refer to the corresponding documentation for details. As Dune has officially announced that it will fully switch to the Dune SQL query engine by 2023, we have upgraded all the queries in this tutorial to the Dune SQL version.

## Introduce Dune V2 data tables

There are several types of datasets on Dune:

- **Raw**: Stored unedited blockchain data, including data tables such as `blocks`, `transactions`, and `traces`. These raw data tables contain the most original on-chain data and can be used for flexible data analysis.
- **Decoded Projects**: Stored the decoded calls and events made to smart contracts . For example, tables related to Uniswap V3 and Opensea Seaport . Dune uses the ABI of smart contracts and the interface of standardized token smart contracts (ERC20, ERC721, etc.) to decode data and save the data of each event or method call separately to a data table.
- **Spells**:Spells also called Abstractions in Dune V1, is built and maintained by Dune and community through Spellbook GitHub repository, and is compiled using dbt. These data tables are typically more convenient and efficient to use.
- **Community**:This data is provided by selected third party organizations that stream their data directly to Dune. Currently there are two community datasets, `flashbots` and `reservoir`.
- **User Generated Tables**: Currently, this function is not available on Dune V2, users can only upload a custom data tables through Spellbook GitHub repository.

On the Query page , we can select or search for the required dataset through the left sidebar. The interface for this section is shown below:
![](img/image_01.png)
The text box in the middle of the image can be used to search for corresponding schemas or data tables. For example, entering `erc721` will filter out all Spells and Decoded projects tables whose names contain this string. The red box above the image is used to select the dataset to be used, "v2 Dune SQL" displayed in it is what we usually refer to as the "Dune SQL engine". Dune will fully transition to the Dune SQL engine in the second half of 2023, so for now, everyone only needs to be familiar with the syntax of Dune SQL.
The red box at the bottom shows several categories of dataset currently supported by the Dune V2 engine. Click on the bold dataset category name will take you to the next level to browse the various data schemas and table names in that category. After that, you can also see a drop-down list with a default option of "All Chains", which can be used to filter the data schemas and tables on specified blockchain . When enter table level, clicking on the table name can expand to view the list of fields in the table. Clicking the "》" icon to the right of the table name will insert the table name (in the format of `schema_name.table_name`) into the query editor at the cursor position. While browsing in a hierarchical manner, you can also enter keywords to further search and filter at the current level. Different types of data tables have different levels of depth. The following picture shows an example of browsing decoded data tables.
![](img/image_03.png)

## Raw data

Typical raw data tables in a blockchain include: `Blocks`,`Transactions`,`Traces`,`Logs`,and `Creation_traces`. The naming format for raw data tables is `blockchain_name.table_name`, such as `arbitrum.logs`, `bnb.blocks`, `ethereum.transactions`, `optimism.traces`, etc. Some blockchains may have more or fewer raw data tables. Let's take Ethereum as an example to briefly introduce them.

### ethereum.blocks

A block is the basic component of a blockchain. A block contains multiple transactions.The `ethereum.block` records information about each generated block, including the block timestamp, block number, block hash, difficulty, gas used, etc.Apart from analyzing the overall blockchain's block generation status, gas usage, etc. we generally don't need to pay close attention to or directly use the block table. The most important information is the block timestamp and block number, which are saved in almost all other data tables under different field names.

### ethereum.transactions

The `ethereum.transactions` table stores the details of every transaction that occurred on the blockchain (including both successful and failed transactions). The structure of the transaction table in Ethereum is shown below:
![](img/image_02.png)

The most commonly used fields in the transaction table include `block_time` (or `block_number`), `from`, `to`, `value`, `hash`, `success`,etc. The Dune V2 engine uses a columnar database where data in each table is stored by column. Column-stored tables cannot use indexes in the traditional sense, but rely on metadata with "min/max values" to optimize queries. For numeric or datetime columns, it's easy to calculate min/max values for a set of values. In contrast, for string columns with variable lengths, it's hard to efficiently compute min/max values. This makes string queries less efficient in the V2 engine. So we typically need to combine filters on datetime or numeric columns to improve query performance. As mentioned, the `block_time` and `block_number` fields exist in almost all data tables (under different names), so we should make full use of them for filtering to ensure efficient query execution. You can check [how the Dune V2 query engine works](https://dune.com/docs/query/#changes-in-how-the-database-works) to learn more details.

### ethereum.traces

A transaction can trigger multiple internal calls, and an internal call may further trigger more internal calls. The execution information of these calls is recorded in ethereum.traces. The main fields in this table include `block_time`, `block_number`, `tx_hash`, `success`, `from`, `to`, `value`, `type`,etc.
The `ethereum.traces` has two common use cases:

1. To track transfer details and gas usage of native blockchain tokens. For example, on Ethereum, users may transfer ETH to other address(es) via a smart contract of a DApp. In this case, the `value` field in the `ethereum.transactions` table does not contain the transferred ETH amount. The actual transfer value is only stored in the `value` field of the ethereum.traces table. Also, native tokens are not ERC20 tokens, so their transfer cannot be tracked via ERC20 Transfer events.The gas fees for blockchain transactions are also paid with native tokens. The gas usage data is stored both in the `ethereum.transactions` table and the `ethereum.traces` table. A transaction can have multiple internal calls, which can further trigger more calls. This means the `from`, `to` fields are inconsistent across these calls, implying different accounts paying for gas fees.Therefore, when calculating native token balances like ETH for an address or a group, only the `ethereum.traces` table can give accurate results. Here is an example query to calculate ETH balances for top holders: [ETH top holders' balances](https://dune.com/queries/1001498/1731554)
2. Filter contract addresses. On Ethereum, addresses are divided into two types - Externally Owned Addresses (EOAs) owned by users, and Contract Addresses created by deploying smart contracts.When a new smart contract is deployed, the `type` field in the corresponding `ethereum.traces` record would be `create`. We can use this to identify contract addresses. In Dune V2, the Dune team has extracted the internal calls for contract creations into a separate table `ethereum.creation_traces`. By querying this table directly, we can determine if an address is a contract address.

### ethereum.logs

The `ethereum.logs` stores all the event logs emitted by smart contracts. It is very useful when we need to query and analyze smart contracts that are not decoded or cannot be decoded (due to closed source code etc).In general, we recommend using the decoded data tables first for efficiency and avoiding errors in queries. However, sometimes due to latency (contract not decoded yet) or contracts not supporting decoding, we have to directly access the `ethereum.logs` table for analysis.

The main fields are `block_time`, `block_number`, `tx_hash`, `contract_address`, `topic1`, `topic2`, `topic3`,`topic4`,`data`,etc.There are some points to pay attention to when using:

- `topic1` contains the hashed signature of the event method. We can filter logs by `contract_address` and topic1` to get all logs for a specific event of a contract.
- `topic2`, `topic3`, `topic4` store indexed event parameters (topics). Each event can have up to 3 indexed topic parameters. If there are less than 3 indexed params, the remaining topic fields will not contain any value. For each specific event, the values saved in these topic params are different. We can check the logs shown on blockchain explorers like EtherScan to match and confirm what each topic param represents. Or we can also check the source code of the smart contract to understand the definitions of the event parameters.
- `data` stores the hexadecimal encoded combination of unindexed event parameters , in string format starting with `0x`. Each parameter takes up 64 characters, with 0-padding on the left if less than 64 bits. When we need to decode the data, we should split it into groups of 64 characters starting from the 3rd character, based on this structure. Then we can further process each group to convert into the actual data types (address, number, string etc.)

Here is a sample query that decode the ethereum.logs table directly: https://dune.com/queries/1510688. You can copy a tx_hash value from the query results and visit Etherscan, then switch to the "Logs" tab for comparison. Below is an example screenshot from Etherscan:
![](img/image_04.png)

## Decoded Projects

The decoded project tables make up the largest group of data tables. When a smart contract is submitted to Dune for decoding, Dune generates a dedicated table for each method call and event in the contract.In Dune's query editor sidebar, these decoded project tables are displayed hierarchically as:

```
category name -> project name (namespace) -> contract name -> function name / event name

-- Sample
Decoded projects -> uniswap_v3 -> Factory -> PoolCreated
```

The naming convention for decoded project tables is:

Events: `projectname_blockchain.contractName_evt_eventName`

Function calls: `projectname_blockchain.contractName_call_functionName`

For example, for the PoolCreated event of Uniswap V3:
The table name would be `uniswap_v3_ethereum.Factory_evt_PoolCreated`

A very useful method is to query the `ethereum.contracts` spell table to check if a contract you want has already been decoded. This table stores records of all decoded contracts.

If the query returns a result, you can use the methods described earlier to quickly browse or search for the contract's decoded tables in the editor sidebar.
If no result is returned, it means the contract has not yet been decoded. You can submit it to Dune for decoding: [Submit New Contract](https://dune.com/contracts/new?__cf_chl_rt_tk=U.qtXIi0RjaP8DToW1_sJG9luDEv4_HiZ9JleGrNyNw-1690016370-0-gaNycGzNFvs)
You can submit any valid contract address, as long as it is a decodable smart contract (Dune can auto extract the ABI or you provide it).
We have created a dashboard where you can directly [check if a contract is decoded](https://dune.com/sixdegree/decoded-projects-contracts-check)

## Spells

The Spellbook is a community-driven data transformation layer project on Dune. Spells can be used to build advanced abstract tables for common use cases like NFT trades. The Spellbook automates building and maintaining these tables, with data quality checks.

Anyone in the Dune community can contribute spells to the Spellbook by submitting PRs on GitHub, which requires basic knowledge of Git and GitHub. If you want to contribute, check the Dune Spellbook docs for details.

The Dune community is very active and has created many useful spells. Many have been widely used in our daily data analysis. Here, we will introduce some of the important spells

### The prices tables (prices.usd, prices.usd_latest)

The `prices.usd` table contains per-minute historical USD prices for major ERC20 tokens on each blockchain.When aggregating or comparing multiple tokens, we typically join with the prices table to convert everything to USD amounts first before summarizing or comparing.The price information table currently provides major ERC20 token price information for Ethereum, BNB, Solana and other chains, accurate to every minute.To get daily or hourly average prices, you can calculate the average price per day/hour.Here are two sample queries demonstrating different approaches to get daily prices for multiple tokens:

- [get daily average price](https://dune.com/queries/1507164)
- [get daily last minute price record](https://dune.com/queries/1506944)

price.usd_latest provides the latest price for the relevant ERC20 token

### The DeFi trade table(dex.trades, dex_aggregator.trades)

The `dex.trades` table provides trade data across major DEXs. Since there are many DeFi projects, the Dune community is continuously expanding the data sources. Currently integrated DEXs include Uniswap, Sushiswap, Curve, Airswap, Clipper, Shibaswap, Swapr, Defiswap, DFX, Pancakeswap, Dodo and more.The `dex.trades` table consolidates data across projects. Each project also has its own specific spell table, like `uniswap.trades`, `curvefi_ethereum.trades` etc. If analyzing a single project, its dedicated spell table is preferable.

The `dex_aggregator.trades` table contains trade records from DEX aggregators. These aggregators route trades to DEXs for execution, organize these records separately to avoid double-count with `dex.trades`.As of this writing, it currently only has data for Cow Protocol.

### The tokens table (tokens.erc20,tokens.nft)

The tokens tables currently mainly include:`tokens.erc20` and `tokens.nft`

The `tokens.erc20` table records definition info like contract address, symbol, decimals for major ERC20 tokens.

The `tokens.nft` table records basic info for NFT collections. It relies on community PRs to update so may have latency or missing data.

Since blockchain data stores amounts as raw integers without decimals, we need to join the `tokens.erc20` decimals to properly convert values.

### The ERC token tables (erc20_ethereum.evt_Transfer, erc721_ethereum.evt_Transfer,etc)

The ERC token tables contain decoded Approval and Transfer events for different token standards like ERC20, ERC721 (NFT), ERC1155 etc.We can use these spell tables when we want to analyze token transfer details, balances, etc for an address or group of addresses.

### The ENS tables (ens.view_registrations,etc)

The ENS tables contain data about ENS domains, including:ENS domain registrations,Reverse resolution records,ENS domain update,etc.

### The labels tables

The labels tables are a collection of spell tables from various sources that associate wallet/contract addresses to text labels. The data sources include ENS domains, Safe wallets, NFT projects, decoded contract addresses, etc. We can use the built-in Dune function `get_labels()` in our queries to display addresses using intuitive, more readable labels instead of raw addresses.

### The balance tables(balances_ethereum.erc20_latest,etc)

The balances tables contain hourly, daily, and latest token balances for addresses across ERC standards like ERC20, ERC721 (NFT), ERC1155. We can use these tables when we want to look up latest balances or track balance changes over time for addresses

### The NFT trade tables

The NFT trades tables contain transaction data from major NFT marketplaces like OpenSea, MagicEden, LooksRare, X2Y2, SudoSwap, Foundation, Archipelago，Cryptopunks,Element,SuperRare,Zora,Blur,and more.Similar to DeFi, each platform has its own dedicated spell table, like `opensea.trades`. When analyzing a single marketplace, its dedicated table is preferable.

### Other spell tables

In addition to the tables mentioned above, there are many other spell tables created by the Dune community. New spell tables are continually added over time.

To learn more, you can check the [Dune Spellbook documentation](https://spellbook-docs.dune.com/#!/overview)

## Community and User generated tables

As mentioned previously, the two main community-sourced datasets currently on Dune are `flashbots` and `reservoir`.The Dune documentation provides introductions to these tables:

[Dune Community-source tables](https://dune.com/docs/data-tables/community/)