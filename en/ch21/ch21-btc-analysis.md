# Designing a Dashboard - Using the BTC CDD (Coin Day Destroyed) as an Example
## I. Introduction to the BTC CDD

### 1.Explanation of the Indicator

CDD stands for Coin Day Destroyed. It is an improved version of the Transaction Volume, with the improvement aimed at considering time in evaluating on-chain activities (Transfers). For tokens that have been in a HODL (Hold On for Dear Life) status for a long time (not transferred to other wallets), a larger weight is given to their movements.

Here we introduce a new concept called Coin Day. `Coin Day = Token Quantity * Number of days the Token is in HODL status`.

All BTC on-chain accumulates Coin Days every day. If a portion of BTC moves (from Wallet A to Wallet B), the accumulated Coin Days for this portion will be destroyed, which is the so-called Coin Day Destroyed.     

![historical_trend.png](img/historical_trend.png)    

# Designing a Dashboard - Using the BTC CDD (Coin Day Destroyed) as an Example
## I. Introduction to the BTC CDD

### 1.Explanation of the Indicator

CDD stands for Coin Day Destroyed. It is an improved version of the Transaction Volume, with the improvement aimed at considering time in evaluating on-chain activities (Transfers). For tokens that have been in a HODL (Hold On for Dear Life) status for a long time (not transferred to other wallets), a larger weight is given to their movements.

Here we introduce a new concept called Coin Day. `Coin Day = Token Quantity * Number of days the Token is in HODL status`.

All BTC on-chain accumulates Coin Days every day. If a portion of BTC moves (from Wallet A to Wallet B), the accumulated Coin Days for this portion will be destroyed, which is the so-called Coin Day Destroyed.     

![historical_trend.png](img/historical_trend.png)    


### 2.Underlying Logic

All indicators are designed to better depict the conditions we want to reflect. In the case of this indicator, it aims to reflect the behavior of long-term holders. From this perspective, it can be considered a Smart Money type of indicator. People tend to think that long-term holders are early participants in BTC, and thus, they have a better and more experienced understanding of BTC and the market. If their tokens (long-term HODL) move, it may very well be that some changes in the market have prompted them to take action (in many cases, this means moving to an exchange or selling through OTC, but there are other scenarios as well, so it can't be generalized).

If you frequently use Glassnode, you'll find that many indicators on Glassnode are designed based on the above logic, which can be considered one of the most important underlying logics in the current BTC on-chain data analysis.

### 3.UTXO Mechanism

Here we need to introduce a basic knowledge about BTC: the UTXO mechanism. Understanding it will help you understand how to use the several tables about BTC on Dune to complete the above calculation.

UTXO stands for Unspent Transaction Output. In the current operation mechanism of BTC, there is actually no concept of Balance. The balance of each wallet is obtained by summing the BTC amounts contained in all UTXOs owned by the wallet.

Here's a link to an article that explains it quite well: https://www.liaoxuefeng.com/wiki/1207298049439968/1207298275932480


## II. Related Tables in Dune

If you can roughly understand the concepts of Input, Output, and UTXO, it's easy to understand the two tables we need to use on Dune. Here's a brief explanation of the tables and fields we need to use.

### 2.1 bitcoin.inputs

- Explanation: Contains all data related to Input, i.e., for each address, each BTC expenditure/transfer
- Key Fields
  - `address`：Wallet address
  - `block_time`：The time when this transfer Transaction occurred
  - `tx_id`：The Tx ID of this transfer Transaction
  - `value`：The BTC amount included in this transfer Transaction
  - `spent_tx_id`：The output that generated this Input (Which incoming payment was used for this expenditure)
    
![input_info.png](img/input_info.png)       

### 2.2 bitcoin.outputs

- Explanation: Contains all data related to Output, i.e., for each address, each BTC incoming record.
- Key Fields
  - `address`：Wallet address
  - `block_time`：The time when this incoming Transaction occurred
  - `tx_id`：The Tx id of this incoming Transaction
  - `value`：The BTC amount included in this incoming Transaction
  
![output_info.png](img/output_info.png)    

## III. Dashboard Design and Implementation

### 1. How to Design a Dashboard
#### 1.1 General Approach

The design of a Dashboard depends on the final purpose of using it. The ultimate goal of a Dashboard or data is to assist in decision-making. In our view, data can aid decision-making by answering the following two questions. Only if these two questions can be effectively answered, can it be considered a qualified Dashboard.

`[a].`What is XXX? What are its characteristics?

This involves using a series of indicators to reflect the basic characteristics and current status of something (e.g., daily user volume, tx number, and new contract number for Ethereum, etc.).

`[b].`What is the cause for the change in some important indicators reflecting XXX characteristics?

When the indicators in `[a]` change, we analyze the cause of the change, or in other words, look for the reason for the data fluctuation.

#### 1.2 Fluctuation Analysis

`[a]` is relatively easy to understand, so we won't go into it. The quality of indicator system design depends on your understanding of the thing itself. Each industry or each sub-field within each industry is actually different.

We can discuss the analysis of fluctuations. In my view, analyzing fluctuations is about decomposition. In general, a fluctuation in an indicator can be decomposed from two angles. Here, taking the daily burning quantity of Ethereum as an example, suppose that the destruction of Ethereum increased by 30% one day, how should we analyze it?

**1.Process of the thing's formation**

`Today's ETH burning = Total gas fee consumed today * Burn rate`

- `Total gas fee consumed today = Average gas fee consumed per tx today * Number of tx today`
  - `Number of tx today = Number of active Ethereum users today * Average number of tx issued by active Ethereum users today`
    - `Number of active Ethereum users today = Total number of Ethereum users * Active ratio today`
- `Burn rate: Depends on EIP1559 or whether there are new proposals`    

![funnel_info.png](img/funnel_info.png)    


**2.Characteristics of the thing itself**

- Time: Distinguish by hour to see which hour of the 24 hours had an increase in gas fee consumption or if it was a general increase across all hours.
- Space: If the IP of each initiating wallet could be obtained, we could see whether gas fee consumption in a certain country increased significantly (not possible in practice).
- Other characteristics: Whether it was the gas fee consumption of EOA addresses or contract addresses that increased.
  - If it's an EOA address, whether it was caused by Bot or ordinary EOA addresses; if it's ordinary EOA addresses, whether it was caused by whales or ordinary wallets.
  - If it's a contract address, which type of project (Defi, Gamefi, etc.) had an increase in contract gas fee consumption; if it's a Gamefi project, which specific contract caused it.

The above are two categories of decomposition approaches. By decomposing the main indicator into sub-indicators layer by layer, we can better observe which fluctuations in the sub-indicators caused the fluctuation in the main indicator, and then infer the root cause.

### 2. Design of the Bitcoin - Coin Day Destroyed Dashboard

Back to the main topic, we'll start designing the Bitcoin - Coin Day Destroyed Dashboard.

#### 2.1 Overall Situation

First, we need a chart to reflect the overall situation. Since there's only the CDD as an indicator, which is quite simple, I've only included a historical trend chart.    

![historical_trend.png](img/historical_trend.png)    

However, the time period of this chart is too long, and it's difficult to clearly see recent changes in CDD from this chart. Therefore, I've added a trend for the recent period.

![recent_trend.png](img/recent_trend.png)     

P.S. Here, you can still see a significant CDD abnormality before this round of downturn.

#### 2.2 Fluctuation Analysis

Here, I only decomposed along three dimensions:

- Decomposition by time (hour), this way I know roughly when the indicator abnormality occurred. [Statistics for the latest day]  

![hour.png](img/hour.png)    

- Decomposition by the wallet address initiating the transaction, this way I know what caused the indicator abnormality: whether it was caused by a single wallet or multiple wallets, whether it was a small portion of old coins or a large number of new coins. [Statistics for the latest day] 

![wallet.png](img/wallet.png)    

- Decomposition down to the very fine granularity of the Transaction_ID, this way I know specifically which transactions caused the abnormality, and can verify this in the blockchain browser. [Statistics for the latest day]  

![transaction.png](img/transaction.png)    

- In addition, to facilitate analysis of fluctuations on any given day in history based on the wallet address, I added a tool module that allows you to find the distribution of CDD by wallet for any day in history by entering the date.

![tool.png](img/tool.png)    

### 3. Completion

And just like that, a dashboard for monitoring CDD is complete. The final effect is that you can conveniently see the historical trend and recent changes of the indicator. If an abnormality occurs one day, you can quickly pinpoint the time of the abnormality and the associated wallets, and the specific transaction_id aids further analysis.

![overview.png](img/overview.png)    

Detailed Dashboard can be found at: https://dune.com/sixdegree/bitcoin-coin-day-destroyed-matrix


Adding some more decomposition ideas：
- Try to decompose by the target address of the transaction, distinguishing between CDD of transactions deposited to exchanges and CDD of ordinary transactions. This way, you will know how much of the CDD is likely intended for selling.

- Try to decompose by the type of wallet. We can attempt to calculate the probability of a price drop following a large CDD abnormality for each wallet, then define some Smart Money. This way, CDD is decomposed into Smart Money CDD & Normal CDD.

If you're interested, you can fork the Dashboard and try to implement it yourself.

## Introduction to SixDegreeLab

SixDegreeLab ([@SixdegreeLab](https://twitter.com/sixdegreelab)) is a professional on-chain data team. Our mission is to provide users with accurate on-chain data charts, analysis, and insights, and we are committed to popularizing on-chain data analysis. Through building communities, writing tutorials, and other methods, we are training on-chain data analysts, outputting valuable analysis content, and promoting the construction of the data layer of the blockchain by the community, thereby cultivating talents for the vast future blockchain data applications.

Feel free to visit the [SixDegreeLab Dune homepage](https://dune.com/sixdegree).

Due to limitations in our knowledge and understanding, there may be inevitable shortcomings. If you find any errors, please kindly point them out.