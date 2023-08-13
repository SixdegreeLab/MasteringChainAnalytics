# 使用Dune API创建应用程序

## 项目概述

4月25日，Dune正式向所有用户等级开放了期待已久的API访问权限。现在，免费用户也可以访问Dune API了。本篇教程提供一个Demo，讲解如何围绕Dune API来开发应用程序。

Demo程序部署在这里：[Watcher Demo](https://dev.lentics.xyz/)。

本教程的Demo程序在3月初已经完成，由于各种其他原因，教程拖延到了现在，抱歉让大家久等了。项目程序代码由我公司同事George，Ken 和 Benny 协同完成，在此表示感谢。

由于API Key 有额度限制，以上Demo程序有可能无法一直正常工作。建议大家Fork之后自行部署，使用自己的API Key来做更多尝试。

项目运行的界面如下图所示：

![wather01.jpg](./img/watcher01.jpg)

## Dune API 使用介绍

Dune API是基于Query ID来执行和获取结果的。每一个已保存的Query，都可以自动转化为一个API的访问端点。在最新版的Query Editor 界面，只需先编写查询，测试好功能，保存查询，然后点击”API Endpoint“按钮，即可获取访问该查询结果的API端点网址。

```
https://api.dune.com/api/v1/query/2408388/results?api_key=<api_key>
```

这是通过API访问已保存的查询结果集的最简便的方法。

![wather02.jpg](./img/watcher02.jpg)

Query的执行结果默认是缓存保存的，如果不再次主动执行这个Query，那么上面的API端点获取的将是已保存的上次执行结果集。通常我们的应用程序需要主动执行查询以获取最新满足条件的数据而不是重复获取缓存的结果集，对于监控类型的应用更是如此。所以我们还需要访问执行查询（Execute）的端点和获取查询执行状态（Status）的端点，在接收到已执行完成的状态信息后，访问获取结果集（Results）的端点获取数据。

一个完整的API调用流程包括：执行查询、检查查询执行状态、获取查询结果集。Dune API的相关文档已经有详细的说明，所以这里就不再展开描述。大家可以直接看API文档：[Dune API](https://dune.com/docs/api/api-reference/#latest-results-endpoint)。


## 项目需求说明

为了尽可能完整展示使用Dune API开发项目的完整流程，我整理了以下主要需求点。

这个应用的主要功能是基于Dune 的API，针对Uniswap V3，提供一个新建流动资金池监控的纯前端应用。使用数据库来保存用户选择监控的资金池地址。使用缓存以避免重复调用API请求完全相同的数据。

功能包括三个方面：

1. New Pools 新建资金池

按选择的区块链、日期范围，返回满足条件的新建资金池列表。
调用API时，传入选择的区块链名称（全部小写），日期参数（YYYY-MM-DD，本地根据用户选择换算成具体日期）。

2. Latest Swaps 最新交易记录

从资金池列表选择一个Pool（链接），在新的界面中列出该Pool当前小时内的最新100条Swap兑换记录。
用户从第一步的各个列表点击Pool 旁边的“Latest Swap”链接进入本界面。
调用API时，传入区块链名称、Pool地址和当前的小时值（YYYY-MM-DD HH:MI:SS，本地换算成具体日期+小时值，如 “2023-02-27 09:00:00”）。
API调用参数: blockchain, pool, current hour (Unix timestamp)
用列表方式展示API调用返回结果即可。

3. Large Swap Alerts 大额交易提醒

允许用户输入一个Pool 的地址（提示用户自行从资金池列表中复制），大额交换的阈值（比如1000 USD）。设置后每隔5分钟调用因此API，当出现满足条件的Swap记录时，生成站内提醒。
用户可以设置要监控的Pool 地址和最小交换金额（USD）（暂时只提供1000，10000，10000三个选择值）。
如果API有返回数据，则加入站内提醒中。导航条红色数字badge提醒未读提醒个数，点击可以显示列表。点击单条信息后改成已读状态。


## 开发环境配置

```
yarn dev
```

其他命令可以参考项目源代码中的 readme.md 文件说明。

## 开发概览

### 创建项目

基于 Next.js, CSS framework 使用 tailwindcss，fetcher 使用 Axios，前端数据操作使用 dexie，后端数据操作使用 prisma。

``` bash
$ yarn create next-app
$ yarn add tailwindcss autoprefixer postcss prisma -D
$ yarn add axios dexie dexie-react-hooks @prisma/client
```

### 初始化 Schema

``` bash
$ yarn prisma init --datasource-provider sqlite
$ vim prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model DuneQuery {
  id           String   @unique
  execution_id String
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
}

$ yarn prisma migrate dev --name init
$ yarn prisma generate
```

### 封装API调用

增加 lib/dune.ts, 封装 Dune API 执行的三个步骤：
``` javascript
export const executeQuery = async (id: string, parameters: any) => {
  // 用 hash 生成当前执行的 query key, 检查并获取 sqlite 中是否有对应 execution_id。记得做好缓存过期处理
  // ...
};
export const executeStatus = async (id: string) => {
  // ...
};
export const executeResults = async (id: string) => {
  // ...
};
```

### 前端数据展示

在 pages 目录增加对应页面中增加个递归 function，判断是否有 data.result 节点返回用于递归调用，useEffect 中触发即可。


### 代码部署

与 Next.js 项目部署方式一致，这儿已将 DB 初始化放到 package.json

``` json
  "scripts": {
    "dev": "prisma generate && prisma migrate dev && next dev",
    "build": "prisma generate && prisma migrate deploy && next build",
    "start": "next start"
  }
```

### 为API编写SQL查询

API 调用的query 信息：

New Pools:

https://dune.com/queries/2056212

Latest Swap:

https://dune.com/queries/2056310

Alerts:

https://dune.com/queries/2056547


### 重要功能点说明

1. Dune API 需要先 Execute Query ID， 获取其 execution_id，才能执行后面的 status/results。做好缓存过期处理。
2. 前端需要递归调用系统 API 来获取结果


## Dune API 文档
- 中文文档： https://dune.com/docs/zh/api/ 
- 最新版本： https://dune.com/docs/api/


## 项目代码仓库

项目的源代码在这里： 
[Uniswap New Pools Watcher](https://github.com/codingtalent/watcher)


## SixdegreeLab介绍

SixdegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixdegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
