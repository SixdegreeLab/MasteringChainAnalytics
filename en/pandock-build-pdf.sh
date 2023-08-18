# /bin/sh

# requirements: 
# 1. docker pull pandoc/extra

sudo docker run --rm \
       --volume "$(pwd):/data" \
       --user $(id -u):$(id -g) \
       pandoc/extra \
--template 'eisvogel.tex' --listings \
--table-of-contents \
--variable colorlinks:yes \
-o books/MasteringOnchainAnalytics.pdf \
    --resource-path ch00 \
    --resource-path ch01 \
    --resource-path ch02 \
    --resource-path ch03 \
    --resource-path ch04 \
    --resource-path ch05 \
    --resource-path ch06 \
    --resource-path ch07 \
    --resource-path ch08 \
    --resource-path ch09 \
    --resource-path ch10 \
    --resource-path ch11 \
    --resource-path ch12 \
    --resource-path ch13 \
    --resource-path ch14 \
    --resource-path ch15 \
    --resource-path ch16 \
    --resource-path ch17 \
    --resource-path ch18 \
    --resource-path ch19 \
    --resource-path ch20 \
    --resource-path ch21 \
    --resource-path ch22 \
    --resource-path ch23 \
ch00/ch00-become-chain-analyst.md \
ch01/ch01-dune-platform-introduction.md \
ch02/ch02-quickstart.md \
ch03/ch03-build-first-dashboard.md \
ch04/ch04-understanding-tables.md \
ch05/ch05-sql-basics-part1.md \
ch06/ch06-sql-basics-part2.md \
ch07/ch07-practice-build-lens-dashboard-part1.md \
ch08/ch08-practice-build-lens-dashboard-part2.md \
ch09/ch09-useful-queries-part1.md \
ch10/ch10-useful-queries-part2.md \
ch11/ch11-useful-queries-part3.md \
ch12/ch12-nft-analysis.md \
ch13/ch13-lending-analysis.md \
ch14/ch14-defi-analysis.md \
ch15/ch15-dunesql-introduction.md \
ch16/ch16-blockchain-analysis-polygon.md \
ch17/ch17-mev-analysis-uniswap.md \
ch18/ch18-uniswap-multichain-analysis.md \
ch19/ch19-useful-metrics.md \
ch20/ch20-network-analysis.md \
ch21/ch21-btc-analysis.md \
ch22/ch22-how-to-build-spellbook.md \
ch23/ch23-how-to-build-app-use-dune-api.md