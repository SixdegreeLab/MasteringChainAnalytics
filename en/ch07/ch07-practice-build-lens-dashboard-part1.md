# 07 Practice - Build Lens Dashboard (I)

In order to let everyone get started with data analysis as soon as possible, we will put some theoretical content in the subsequent part of the tutorial, and the first half will explain more about some content that can be combined with practice. In this section, let's make a data dashboard for the Lens Protocol project.

## What is the Lens Protocol?

The introduction from the [Lens website](https://docs.lens.xyz/docs/what-is-lens) is as follows: Lens Protocol (Lens Protocol, Lens for short) is a Web3 social graph ecosystem on the Polygon blockchain. It is designed to allow creators to own their connections to the community, forming a fully composable, user-owned social graph. The protocol was built with modularity in mind from the start, allowing new features to be added and bugs fixed, while ensuring the immutability of user-owned content and social connections. Lens aims to solve some of the major problems in existing social media networks. The Web2 network all reads data from its proprietary centralized database. Users' profiles, friendships, and content are locked into specific networks, and ownership of them rests with the network operator. Networks compete with each other for user attention, becoming a zero-sum game. Lens rectifies this by being an open social graph owned by the user and accessible by any application. Since users own their data, they can bring it to any application built on top of the Lens protocol. As the true owners of their content, creators no longer need to worry about losing their content, audiences, and revenue streams based on sudden changes in individual platform algorithms and policies. Furthermore, the far-reaching impact of Lens extends to the entire ecosystem. Each application utilizing the Lens protocol contributes to the collective advancement, transforming what used to be a zero-sum game into a collaborative and synergistic endeavor.

The following roles (entities) are involved in the Lens protocol: personal Profile, Publication, Comment, Mirror, Collect, Follow. At the same time, there are three types of NFTs in the protocol, namely: Profile NFT, Follow NFT, and Collect NFT.

Typical usage scenarios on Lens include:

- Creators register to create their Profile and mint their exclusive ProfileNFT. You can set a personalized name (Profile Handle Name, which can be simply compared to a domain name, that is, "Lens domain name"). At the same time, you can set the URL of the account avatar picture and the rules when you are followed (by setting special rules, you can generate revenue, for example, you can set that users need to pay a certain fee to follow the Profile). Currently only addresses on the allow list can create profile accounts.
- Creators publish Publications, including Posts, Mirrors, Comments, etc.
- In the relevant operation steps, 3 different types of NFTs are respectively minted and transferred to different user addresses.

## The main analysis content of the Lens Protocol

For a project like Lens, we can analyze its overview as a whole, or conduct data analysis from different angles and for different types of roles. Here is an overview of some of the things that can be analyzed:
- Total number of users, total number of creators, proportion of creators, etc.
- Total number of publications, total number of comments, total number of mirrors, total number of followers, total number of favorites, etc.
- User-related analysis: the number of new users per day, the number of new creators per day, the number of active users per day, the number of active creators, the trend of overall user activity, etc.
- Analysis of the personalized domain names of Lens accounts: the number of domain name registrations, the registration status of different types of domain names (pure numbers, pure letters, different lengths), etc.
- Creator activity analysis: number of publications released, number of times followed, number of times mirrored, most popular creators, etc.
- Related analysis of publications: number of published content, growth trend, number of followers, number of favorites, most popular publications, etc.
- Related analysis of followers: the number of followers and their changing trends, cost analysis of followers, users who follow creators the most, etc.
- Related analysis of favorites: daily number of favorites, popular favorites, etc.
- Creator's income analysis: income generated through attention, other income, etc.
- Relevant analysis from the perspective of NFT: daily casting quantity, costs involved (focus on fees), etc.

There is a wealth of content that can be analysed. In this dashboard, we only use some of the contents as a case. Please try to analyze other content separately.

## Data Table introduction

On the [deployed smart contract](https://docs.lens.xyz/docs/deployed-contract-addresses) page of the official Lens document, it is prompted to use the smart contract LensHub Proxy (LensHub Proxy) as the main contract for interaction. Except for a small number of NFT-related queries that need to use the data table under the smart contract FollowNFT, we basically focus on the decoded table under the smart contract LensHub. The figure below lists part of the data table under this smart contract.

![](img/ch07_image_01.png)

As mentioned in the previous tutorial, there are two types of decoded smart contract data tables: event log table (Event Log) and function call table (Function Call). The two types of tables are named in the format: `projectname_blockchain.contractName_evt_eventName` and :`projectname_blockchain.contractName_call_functionName` respectively. Browsing the list of tables under the LensHub contract, we can see the following main data tables:
- collect/collectWithSig
- comment/commentWithSig
- createProfile
- follow/followWithSig
- mirror/mirrorWithSig
- post/postWithSig
- Transfer

Except for the Transfer table, which is an event table, the remaining tables mentioned are function call tables. The data table with the `WithSig` suffix signifies operations performed through signature authorization. This allows the use of API or enables other authorized parties to perform specific operations on behalf of a user. It is important to aggregate data from related tables when analyzing types such as post tables in order to gain a comprehensive understanding.

In the provided list, there are several other data tables with different methods. These tables are all generated under the LensHub smart contract, and they interact with the LensHub address, specifically `0xdb46d1dc155634fbc732f92e853b10b288ad5a1d`. To analyze the overall user data of Lens, it is recommended to query the polygon.transactions original table to extract data associated with this contract address. This will provide a complete dataset for analysis purposes.

## Overview analysis of Lens Protocol

By looking at [the LensHub smart contract creation transaction details](https://polygonscan.com/tx/0xca69b18b7e2daf4695c6d614e263d6aa9bdee44bee91bee7e0e6e5e5e4262fca), we can see that the smart contract was deployed on May 16, 2022. When we query raw data tables such as the polygon.transactions raw table, by setting date and time filter conditions, query execution performance can be greatly improved.

### Total number of transactions and total number of users
As mentioned earlier, the most accurate data source for querying the number of users is the original `polygon.transactions table`. We can use the following query to query the current number of transactions and the total number of users of Lens. We directly query all transaction records sent to the LensHub smart contract, and use the `distinct` keyword to count the number of independent user addresses. Since we know the creation date of the smart contract, we use this date as a filter condition to optimize the query performance.

``` sql
select count(*) as transaction_count,
    count(distinct "from") as user_count    -- count unique users
from polygon.transactions
where "to" = 0xdb46d1dc155634fbc732f92e853b10b288ad5a1d   -- LensHub
    and block_time >= date('2022-05-16')  -- contract creation date
```

Create a new query using the SQL code above, run the query to get the results and save the Query. Then add two `Counter` types to the visualisation chart with the titles set to "Lens Total Transactions" and "Lens Total Users". Lens Total Users".

Reference link for this query on Dune:[https://dune.com/queries/1533678](https://dune.com/queries/1533678)

Now we can add visualization charts to the dashboard. Since this is our first query, we can create a new dashboard in the Add Visualization to Dashboard popup dialog. Switch to the first Counter, click the "Add to dashboard" button, in the dialog box, click the "New dashboard" button at the bottom, enter the name of the data dashboard, and click the "Save dashboard" button to create a blank data dashboard. I use "Lens Protocol Ecosystem Analysis" here as the name of the board. After saving, we can see the newly created data dashboard in the list, and click the "Add" button on the right to add the current Counter to the data dashboard. Switching to another Counter after closing the dialog will also add it to the newly created data dashboard.

At this point, we can click the "My Creations" link at the head of the Dune website, and then select the "Dashboards" Tab to switch to the data dashboard list. Click the name of our newly created board to enter the preview interface of the board. We can see the two Counter type visualizations we just added. Here, by clicking the "Edit" button to enter the edit mode, you can adjust the size and position of the chart accordingly, and you can click the "" button to add text components to explain or beautify the data dashboard. The figure below is an example of the interface of the adjusted data dashboard.

![](img/ch07_image_02.png)

The link to our newly created data dashboard is:[Lens Protocol Ecosystem Analysis](https://dune.com/sixdegree/lens-protocol-ecosystem-analysis)

### Number of transactions and unique users by day

To analyze the growth trend of the Lens protocol in terms of activity, we can create a query that counts the number of transactions and the number of active user addresses per day by date. By adding the `block_time` field to the query and using the `date_trunc()` function to convert it into a date (excluding the numerical part of the hour, minute, and second), combined with the `group by` query clause, we can count the daily data. The query code is shown below:

``` sql
select date_trunc('day', block_time) as block_date,
    count(*) as transaction_count,
    count(distinct "from") as user_count
from polygon.transactions
where "to" = 0xdb46d1dc155634fbc732f92e853b10b288ad5a1d   -- LensHub
    and block_time >= date('2022-05-16')  -- contract creation date
group by 1
order by 1
```

Save the query and add two visual charts of `Bar Chart` type, select `transaction_count` and `user_count` for `Y column 1`, and set the titles of the visual charts as "Lens Daily Transactions" and "Lens Daily Users" respectively. Add them to the data dashboard. The result is shown in the figure below:

![](img/ch07_image_03.png)

Often when querying statistics by date, we can summarise the relevant data by date, calculate the cumulative value and add it to the same visual chart as the daily data to have a more intuitive understanding of the overall trend of data growth. This is easily achieved by using the `sum() over ()` window function. In order to keep the logic simple and easy to understand, we always prefer to use CTEs to break down complex query logic into multiple steps. Modify the above query as:

``` sql
with daily_count as (
    select date_trunc('day', block_time) as block_date,
        count(*) as transaction_count,
        count(distinct "from") as user_count
    from polygon.transactions
    where "to" = 0xdb46d1dc155634fbc732f92e853b10b288ad5a1d   -- LensHub
        and block_time >= date('2022-05-16')  -- contract creation date
    group by 1
    order by 1
)

select block_date,
    transaction_count,
    user_count,
    sum(transaction_count) over (order by block_date) as accumulate_transaction_count,
    sum(user_count) over (order by block_date) as accumulate_user_count
from daily_count
order by block_date
```

Once the query is executed, we can adjust the two visualisation charts we added earlier. Select `accumulate_transaction_count` and `accumulate_user_count` under `Y column 2` respectively to add them as a second indicator value to the chart. The default charts do not display well because the cumulative values are often not in the same order of magnitude as the daily values. We can do this by selecting the "Enable right y-axis" option, and then setting the newly added second column to use the right axis, and modifying its "Chart Type" to " Area" (or "Line", "Scatter"), so that the chart will look better.

In order to compare the number of daily transactions with the number of daily active users, we can add another visualisation with the title "Lens Daily Transactions VS Users", and select the transaction_count and user_count columns on the Y-axis. count columns on the Y-axis. Again, since the two values are not in the same order of magnitude, we enable the right axis, set user_count to use the right axis, and choose the chart type "Line". This chart is also added to the Data Kanban board. Looking at this chart, we can see that in a few days at the beginning of November 2022, Lens saw a new peak in daily transactions, but the increase in the number of daily active users was not as pronounced.

It is important to note that because the same user may have used Lens on different days, when we aggregate data from multiple days, the cumulative number of users does not represent the actual total number of unique users, but rather is greater than the actual total number of users. If we need to count the number of new unique users per day and their total number, we can first obtain the earliest transaction records of each user, and then use the same method to aggregate statistics by day. We will not expand on the details here, please try it yourself. In addition, if you want to weekly, monthly statistics, just Fork this query, modify the `date_trunc ()` function for the first parameter "week" or "month" can be achieved. For comparison, we Forked and modified a query for monthly statistics, and only added the "" to the DataWatcher.

Once the adjustment is complete, the charts in dashoboard will automatically update to the latest display, as shown in the figure below.

![](img/ch07_image_04.png)

Reference links for the above two queries on Dune:
- [https://dune.com/queries/1534604](https://dune.com/queries/1534604)
- [https://dune.com/queries/1534774](https://dune.com/queries/1534774)

## Creator profile data analysis

Lens creator profile accounts are currently limited to users within the licence whitelist to create, and the data for creating profiles is stored in the `createProfile` table. Using the following query, we can calculate the number of profiles that have been created so far.

``` sql
select count(*) as profile_count
from lens_polygon.LensHub_call_createProfile
where call_success = true   -- Only count success calls
```

Create a visualisation chart of the Counter type with the Title set to "Total Profiles" and add it to the data dashboard.

We are also interested in how creator profiles change and grow over time. Use the following query to see how profiles are created on a daily and monthly basis.

``` sql
with daily_profile_count as (
    select date_trunc('day', call_block_time) as block_date,
        count(*) as profile_count
    from lens_polygon.LensHub_call_createProfile
    where call_success = true
    group by 1
    order by 1
)

select block_date,
    profile_count,
    sum(profile_count) over (order by block_date) as accumulate_profile_count
from daily_profile_count
order by block_date
```

Create and add visualization charts to the dashboard in a similar way. The display is shown in the figure below:

![](img/ch07_image_05.png)

Reference links for the above two queries on Dune:
- [https://dune.com/queries/1534486](https://dune.com/queries/1534486)
- [https://dune.com/queries/1534927](https://dune.com/queries/1534927)
- [https://dune.com/queries/1534950](https://dune.com/queries/1534950)

## Creator profile domain analysis

Lens is committed to building a social graph ecosystem, where each creator can set a personalised name (Profile Handle Name) for their account, which is what is usually referred to as a Lens domain name. Similar to other domain name systems such as ENS, we will pay attention to the registration status of some short domain names, plain numeric domain names, etc., and the number of domain names of different character lengths that have been registered, and other information. In the `createProfile` table, the field `vars` saves a json object in string format, which includes the user's personalised domain name. In Dune V2, we can directly access the value of the elements in the json string using the `:` sign, for example, using `vars:handle` to get the domain name information.

Using the following SQL, we can get the details of a registered Lens domain name:
``` sql
select json_value(vars, 'lax $.to') as user_address,
    json_value(vars, 'lax $.handle')  as handle_name,
    replace(json_value(vars, 'lax $.handle') , '.lens', '') as short_handle_name,
    call_block_time,
    output_0 as profile_id,
    call_tx_hash
from lens_polygon.LensHub_call_createProfile
where call_success = true
```

In order to count the number of Lens domains of different lengths and types (purely numeric, purely alphabetic, mixed) as well as the total number of registered domains under each type, we can put the above query into a CTE. The advantage of using a CTE is that it simplifies the logic (you can debug and test each CTE separately in order). At the same time, once the CTE is defined, it can be used multiple times in subsequent SQL scripts for the same query, which is very convenient. Given that the query for the total number of registered domain names and the corresponding number of registered domain names with different character lengths is based on the above query, we can put them together in the same query. Because the aforementioned statistics need to distinguish the type of domain name, we added a field `handle_type` to represent the type of domain name in this query. The modified query code is as follows:

``` sql
with profile_created as (
    select json_value(vars, 'lax $.to') as user_address,
        json_value(vars, 'lax $.handle') as handle_name,
        replace(json_value(vars, 'lax $.handle'), '.lens', '') as short_name,
        (case when regexp_like(replace(json_value(vars, 'lax $.handle'), '.lens', ''), '^[0-9]+$') then 'Pure Digits'
            when regexp_like(replace(json_value(vars, 'lax $.handle'), '.lens', ''), '^[a-z]+$') then 'Pure Letters'
            else 'Mixed'
        end) as handle_type,
        call_block_time,
        output_0 as profile_id,
        call_tx_hash
    from lens_polygon.LensHub_call_createProfile
    where call_success = true    
),

profiles_summary as (
    select (case when length(short_name) >= 20 then 20 else length(short_name) end) as name_length,
        handle_type,
        count(*) as name_count
    from profile_created
    group by 1, 2
),

profiles_total as (
    select count(*) as total_profile_count,
        sum(case when handle_type = 'Pure Digits' then 1 else 0 end) as pure_digit_profile_count,
        sum(case when handle_type = 'Pure Letters' then 1 else 0 end) as pure_letter_profile_count
    from profile_created
)

select cast(name_length as varchar) || ' Chars' as name_length_type,
    handle_type,
    name_count,
    total_profile_count,
    pure_digit_profile_count,
    pure_letter_profile_count
from profiles_summary
join profiles_total on true
order by handle_type, name_length
```

The modified query code is relatively complicated and can be interpreted as follows:
1. CTE `profile_created` extracts the profile's domain name information and the user address to which the domain belongs by using the ":" notation to extract the domain name information and user address from the json string saved in the `vars` field. Since the saved domain name includes a `.lens` suffix, we use the `replace()` method to remove the suffix and name the new field `short_name` to make it easier to calculate the character length of the domain name later. Further, we use a CASE statement in conjunction with the regular expression matching operator `rlike` to determine whether the domain name consists of pure numbers or pure letters, and assign a string name value to the field named `handle_type`. see [rlike operator](https://docs.databricks.com/sql/language-manual/functions/rlike.html) for more information on regular expression matching.
2. CTE `profiles_summary` performs summary queries based on `profile_created`. We first use the `length()` function to calculate the character length of each domain name. Because there are a small number of exceptionally long domains, we use a CASE statement to treat domains longer than 20 characters uniformly as 20. We then perform `group by` summary statistics based on the domain name length `name_length` and `handle_type` to calculate the number of various domain names.
3. In CTE `profiles_total`, we count the total number of domain names, the number of purely numeric domain names, and the number of purely alphabetic domain names.
4. Finally, we associate the two CTEs `profiles_summary` and `profiles_total` together to output the final query results. Since `profiles_total` has only one row of data, we can directly use `true` as the JOIN condition. In addition, since `name_length` is a numeric type, we convert it to a string type and concatenate it to another string to get a more readable domain length type name. We sort the output by domain type and length.

After the query is executed and saved, we add the following visualization charts to it and add them to the data dashboard:
1. Add two Counters to output the number of purely numeric domain names and the number of purely alphabetic domain names respectively. Since there was already a counter for the total number of domain name registrations before, we can place these two new counter charts on the same row as it.
2. Add a Pie Chart of domain name type distribution, set the Title to "Profiles Handle Name Type Distribution", select the `handle_type field` for "X Column", and select the `name_count` field for "Y Column 1".
3. Add a Pie Chart of domain name length distribution, set the Title to "Profiles Handle Name Length Distribution", select the `name_length_type` field for "X Column", and select the `name_count` field for "Y Column 1".
4. Add a histogram (Bar Chart) of domain name length distribution, set the Title to "Profiles Handle Name Count By Length", select the `name_length_type` field for "X Column", select the `name_count` field for "Y Column 1", and select the `handle_type` field for "Group by". Also uncheck the "Sort values" option, and then check the "Enable stacking" option.
5. Add an area chart (Area Chart) of domain name length distribution, set the Title to "Profile Handle Name Count Percentage By Type", select `the name_length_type` field for "X Column", select the `name_count` field for "Y Column 1", and select the `handle_type` field for "Group by" . Uncheck the "Sort values" option, then check the "Enable stacking" option, and then check the "Normalize to percentage" option.

Add all the above visualization charts to the data dashboard, and adjust the display order, as shown in the following figure:

![](img/ch07_image_06.png)

Reference link for this query on Dune:
- [https://dune.com/queries/1535541](https://dune.com/queries/1535541)

## Registered domain search

In addition to tracking the distribution of registered Lens domains, users are also interested in the details of registered domains. To this end, a search function can be provided that allows users to search for a detailed list of registered domains. Since there are currently about 100,000 Lens accounts registered, we limit the query below to return a maximum of 10,000 search results.

Firstly, we can define a parameter `{{name_contains}}` in the query (Dune uses two curly brackets around the parameter name, and the default parameter type is the string `Text` type). Then use the`like` keyword as well as the `%` wildcard to search for domains with specific characters in the name:

``` sql
with profile_created as (
    select json_value(vars, 'lax $.to') as user_address,
        json_value(vars, 'lax $.handle') as handle_name,
        replace(json_value(vars, 'lax $.handle'), '.lens', '') as short_name,
        call_block_time,
        output_0 as profile_id,
        call_tx_hash
    from lens_polygon.LensHub_call_createProfile
    where call_success = true    
)

select call_block_time,
    profile_id,
    handle_name,
    short_name,
    call_tx_hash
from profile_created
where short_name like '%{{name_contains}}%' -- query the name contian the input string
order by call_block_time desc
limit 1000
```

Before the query is executed, the Dune engine will replace the parameter names in the SQL statement with the input parameter values. When we enter "john", the clause `where short_name like '%{{name_contains}}%'` will be replaced by `where short_name like '%john%'`, which means to search for all domain names whose `short_name` contains the string `john`. Note that although the parameter type is a string type, the field will not add single quotes before and after the parameter replacement. Single quotes need to be entered directly into the query, and if you forget to enter them, it will cause a syntax error.

As mentioned earlier, the length of the domain name is also critical, and the shorter the domain name, the more scarce it is. In addition to searching for the characters contained in the domain name, we can add another parameter `{{name_length}}` for domain name length filtering, change its parameter type to a drop-down list type, and fill in the sequence of numbers 5-20 as a parameter value list, one per line value. Because the Lens domain name currently has at least 5 characters, and there are very few domain names exceeding 20 characters, so we choose 5 to 20 as the interval. The parameter settings are shown in the figure below.

![](img/ch07_image_08.png)

After adding the new parameters, we adjust the WHERE clause of the SQL statement as shown below. Its meaning is to search for a list of domain names whose name contains the input keyword and whose character length is equal to the selected length value. Note that although the values of our `name_length` parameter are all numbers, the default type of the List type parameter is a string, so we use the `cast()` function to convert its type to an integer type before comparing.

``` sql
where short_name like '%{{name_contains}}%' -- -- query the name contian the input string
    and length(short_name) = cast('{{name_length}}' as integer) 
```

Similarly, we can add another domain name string pattern parameter `{{name_pattern}}` to filter purely numeric domain names or purely alphabetic domain names. Here also set the parameter to List type, the list includes three options: Any, Pure Digits, Pure Letters. The WHERE clause of the SQL statement is correspondingly modified as shown below. Similar to the previous query, we use a CASE statement to determine the type of the current query domain name. If you query a purely numeric or purely alphabetic domain name, use the corresponding expression. If you query any pattern, use `1 = 1`, which always returns true The equality judgment of the value is equivalent to ignoring this filter condition.

``` sql
where short_name like '%{{name_contains}}%' -- query the name contian the input string
    and length(short_name) = cast('{{name_length}}' as integer) -- length of domain name equal to the select item 
    and (case when '{{name_pattern}}' = 'Pure Digits' then regexp_like(short_name, '^[0-9]+$')
            when '{{name_pattern}}' = 'Pure Letters' then regexp_like(short_name, '^[a-z]+$')
            else 1 = 1
        end)
```

Because we use the `and` connection condition between these search conditions, it means that all conditions must be satisfied at the same time, and such a search has certain limitations. We make appropriate adjustments, and add a default option "0" to the name_length parameter. When a filter is not entered or selected by the user, we ignore it. This makes search queries very flexible. The complete SQL statement is as follows:

``` sql
with profile_created as (
    select json_value(vars, 'lax $.to') as user_address,
        json_value(vars, 'lax $.handle') as handle_name,
        replace(json_value(vars, 'lax $.handle'), '.lens', '') as short_name,
        call_block_time,
        output_0 as profile_id,
        call_tx_hash
    from lens_polygon.LensHub_call_createProfile
    where call_success = true    
)

select call_block_time,
    profile_id,
    handle_name,
    short_name,
    '<a href=https://polygonscan.com/tx/' || cast(call_tx_hash as varchar) || ' target=_blank>Polyscan</a>' as link,
    call_tx_hash
from profile_created
where (case when '{{name_contains}}' <> 'keyword' then short_name like '%{{name_contains}}%' else 1 = 1 end)
    and (case when cast('{{name_length}}' as integer) < 5 then 2 = 2
            when cast('{{name_length}}' as integer) >= 20 then length(short_name) >= 20
            else length(short_name) = cast('{{name_length}}' as integer)
        end)
    and (case when '{{name_pattern}}' = 'Pure Digits' then regexp_like(short_name, '^[0-9]+$')
            when '{{name_pattern}}' = 'Pure Letters' then regexp_like(short_name, '^[a-z]+$')
            else 3 = 3
        end)
order by call_block_time desc
limit 1000
```

We add a Table type visualization chart to this query and add it to the data dashboard. When adding a parameter query to the data kanban, all parameters are automatically added to the kanban header. We can enter the edit mode and drag the parameter to its desired position. The rendering after adding the chart to the data dashboard is shown below.

![](img/ch07_image_07.png)

Reference link for the above query on Dune:
- [https://dune.com/queries/1535903](https://dune.com/queries/1535903)
- [https://dune.com/queries/1548540](https://dune.com/queries/1548540)
- [https://dune.com/queries/1548574](https://dune.com/queries/1548574)
- [https://dune.com/queries/1548614](https://dune.com/queries/1548614)

## Summary

So far, we have completed the analysis of the basic overview of the Lens protocol, the creator’s profile, and domain name information, and added a domain name search function. In the previous "Main Analysis Contents of Data Kanban" section, we listed more content that can be analyzed. In the second part of this tutorial, we will continue to analyze the publications, attention, favorites, NFT and other aspects released by the creator. You can also explore and create new queries on your own.

## Homework

Please combine the tutorial content to create your own Lens protocol data dashboard, and try new query analysis by referring to the content prompted in the "Main analysis content of the data dashboard". Please actively practice, create data dashboards and share them with the community. We will record the completion and quality of the homework, and then retroactively provide certain rewards for everyone, including but not limited to Dune community identity, peripheral objects, API free quota, POAP, various cooperative data product members, and blockchain data analysis Job opportunity recommendation, priority registration qualification for community offline activities, and other Sixdegree community incentives, etc.

## About Us

`Sixdegree` is a professional onchain data analysis team Our mission is to provide users with accurate onchain data charts, analysis, and insights. We are committed to popularizing onchain data analysis. By building a community and writing tutorials, among other initiatives, we train onchain data analysts, output valuable analysis content, promote the community to build the data layer of the blockchain, and cultivate talents for the broad future of blockchain data applications. Welcome to the community exchange!

- Website: [sixdegree.xyz](https://sixdegree.xyz)
- Email: [contact@sixdegree.xyz](mailto:contact@sixdegree.xyz)
- Twitter: [twitter.com/SixdegreeLab](https://twitter.com/SixdegreeLab)
- Dune: [dune.com/sixdegree](https://dune.com/sixdegree)
- Github: [https://github.com/SixdegreeLab](https://github.com/SixdegreeLab)
