# 使用Dune API创建应用程序

## 项目概述

这里计划从需求文件整理内容进来。这部分可以跳过

## 开发概览

创建项目，基于Next.js, CSS framework 使用 tailwindcss，fetcher 使用 Axios，前端数据操作使用 dexie，后端数据使用 prisma
```
$ yarn create next-app
$ yarn add tailwindcss autoprefixer postcss prisma -D
$ yarn add axios dexie dexie-react-hooks @prisma/client
```

初始化 schema
```
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

增加lib/dune.ts, 封装 Dune API 执行的三个步骤：
```
export const executeQuery = async (id: string, parameters: any) => {
  // 用hash生成当前执行的query key, 检查并获取sqlite中是否有对应execution_id
  // ...
};
export const executeStatus = async (id: string) => {
  // ...
};
export const executeResults = async (id: string) => {
  // ...
};
```

数据展示： 在pages目录增加对应页面中增加个递归function，判断是否有data.result节点返回用于递归调用，useEffect中触发即可。

部署：与 Next.js 项目部署方式一致，这儿已将 DB 初始化放到package.json
```
  "scripts": {
    "dev": "prisma generate && prisma migrate dev && next dev",
    "build": "prisma generate && prisma migrate deploy && next build",
    "start": "next start"
  }
```

## 为API编写SQL查询

编写相应的SQL。这部分可以跳过

## 开发环境配置
```
yarn dev  #没什么特别
```


## 重要功能点说明

1. Dune API 需要先 Execute Query ID， 获取其execution_id，才能执行后面的status/results
2. 前端需要递归调用系统 API 来获取结果


## 示例项目代码仓库

[Uniswap New Pools Watcher](https://github.com/codingtalent/watcher)

## SixDegreeLab介绍

SixDegreeLab（[@SixdegreeLab](https://twitter.com/sixdegreelab)）是专业的链上数据团队，我们的使命是为用户提供准确的链上数据图表、分析以及洞见，并致力于普及链上数据分析。通过建立社区、编写教程等方式，培养链上数据分析师，输出有价值的分析内容，推动社区构建区块链的数据层，为未来广阔的区块链数据应用培养人才。

欢迎访问[SixDegreeLab的Dune主页](https://dune.com/sixdegree)。

因水平所限，不足之处在所难免。如有发现任何错误，敬请指正。
