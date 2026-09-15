# Olist 电商运营分析

分析 10 万笔巴西电商订单,定位收入来源与运营瓶颈。

<!-- 截图待补 -->

## 背景
Brazilian E-Commerce Public Dataset by Olist
Welcome! This is a Brazilian ecommerce public dataset of orders made at Olist Store.
The dataset has information of 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil.
Its features allows viewing an order from multiple dimensions: from order status, price,
payment and freight performance to customer location, product attributes and finally reviews written by customers.
We also released a geolocation dataset that relates Brazilian zip codes to lat/lng coordinates.

This is real commercial data, it has been anonymised, and references to the companies and partners in the review text have been replaced with the names of Game of Thrones great houses.

## 关键发现
<!-- 分析完再填 -->

## 技术栈
MySQL · Python (Pandas) · Power BI

A. 销售/市场分析师 📈

关心：怎样增加收入？
问题：

哪些州最赚钱？
哪些产品类别最畅销？
月度增长怎样？
B. 物流/运营分析师 🚚

关心：怎样改进物流？
问题：

送达时间怎样？
哪些地区经常晚点？
物流成本能优化吗？
C. 产品分析师 📦

关心：哪些产品要重点推？
问题：

背景:Olist 巴西电商平台,2016-2018 订单数据
问题:平台的收入集中在哪里?有哪些运营问题在拖后腿?
产出:Power BI 仪表板 + 一页分析结论

哪些品类卖得最好？
客户满意度怎样？
品类间的对比？
D. 客户/增长分析师 👥

关心：怎样提高复购率？
问题：

有多少重复客户？
高价值客户特征？
怎样识别流失客户？

            ## 场景
运营总监季度复盘。问题:钱从哪来,哪里在漏?

## 子问题
Q1 收入按州怎么分布?
Q2 哪些品类贡献最大?
Q3 收入的月度走势?
Q4 配送延迟率多少?哪些州最严重?
Q5 延迟跟评分有关系吗?
Q6 运费占订单金额多少?

## 数据可行性
Q1 → order + customers + order_items ✓
Q4 → order(送达日期 vs 预计日期),注意排除 3000 笔缺失 ✓
...

## 产出
Power BI 仪表板 + README 关键发现