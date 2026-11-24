-- ============================================================
-- 第2周 子任务1：数据清洗（二）—— 枚举字段标准化
-- 说明：统一性别、会员等级、订单状态、支付方式、渠道、行为类型
--       六类枚举字段，各枚举字段取值收敛到中文规范值域
-- 脏值画像（清洗前统计）：
--   gender       : 男182/女212/male110/female108/M87/F109/未知108/空84
--   member_level : 四级中文602/缩写(金卡/银卡/钻石)60/英文
--                  (gold/silver/normal)34/普通11/空14
--   order_status : 中文规范6种(14225)/数字码1-4(788)/
--                  cancelled(198)/已付款(197)/完成(192)
--   pay_type     : 中文规范4种(14949)/wechat(227)/alipay(206)/微信(218)
--   channel      : 中文规范4种(15290)/app(170)/pc(140)
--   behavior_type: pv(32945)/cart(7021)/fav(4969)/buy(11393)/
--                  PV(604)/Cart(619)/加购/购买/收藏/浏览
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_dwd;
USE ydsh_ods;

-- 1. 用户清洗表（性别、会员等级标准化；表结构含后续步骤的最终列）
DROP TABLE IF EXISTS ods_user_clean;
CREATE TABLE ods_user_clean AS
SELECT user_id,
       user_name,
       CASE gender
            WHEN '男' THEN '男'   WHEN 'M' THEN '男'   WHEN 'male' THEN '男'
            WHEN '女' THEN '女'   WHEN 'F' THEN '女'   WHEN 'female' THEN '女'
            ELSE '未知'
       END AS gender,
       age,
       city,
       province,
       register_date,
       CASE member_level
            WHEN '钻石会员' THEN '钻石会员'  WHEN '钻石' THEN '钻石会员'
            WHEN '金卡会员' THEN '金卡会员'  WHEN '金卡' THEN '金卡会员'  WHEN 'gold' THEN '金卡会员'
            WHEN '银卡会员' THEN '银卡会员'  WHEN '银卡' THEN '银卡会员'  WHEN 'silver' THEN '银卡会员'
            WHEN '普通会员' THEN '普通会员'  WHEN '普通' THEN '普通会员'  WHEN 'normal' THEN '普通会员'
            ELSE '普通会员'
       END AS member_level,
       phone,
       email
FROM ods_user;

-- 2. 订单清洗表（订单状态、支付方式、渠道标准化；含合并字段order_timestamp）
DROP TABLE IF EXISTS ods_order_clean;
CREATE TABLE ods_order_clean AS
SELECT order_id,
       user_id,
       store_id,
       order_date,
       order_time,
       concat(regexp_replace(order_date, '/', '-'), ' ', order_time) AS order_timestamp,
       pay_amount,
       discount_amount,
       CASE pay_type
            WHEN '支付宝'   THEN '支付宝'    WHEN 'alipay' THEN '支付宝'
            WHEN '微信支付' THEN '微信支付'  WHEN 'wechat' THEN '微信支付'  WHEN '微信' THEN '微信支付'
            WHEN '货到付款' THEN '货到付款'
            WHEN '银行卡'   THEN '银行卡'
            ELSE '其他'
       END AS pay_type,
       CASE order_status
            WHEN '待支付' THEN '待支付'  WHEN '1' THEN '待支付'
            WHEN '已支付' THEN '已支付'  WHEN '已付款' THEN '已支付'  WHEN '2' THEN '已支付'
            WHEN '已完成' THEN '已完成'  WHEN '完成'   THEN '已完成'  WHEN '3' THEN '已完成'
            WHEN '已取消' THEN '已取消'  WHEN 'cancelled' THEN '已取消'  WHEN '4' THEN '已取消'
            WHEN '退款中' THEN '退款中'
            ELSE '其他'
       END AS order_status,
       CASE channel
            WHEN 'APP'    THEN 'APP'     WHEN 'app' THEN 'APP'
            WHEN '小程序' THEN '小程序'
            WHEN 'PC官网' THEN 'PC官网'  WHEN 'pc'  THEN 'PC官网'
            WHEN '门店'   THEN '门店'
            ELSE '其他'
       END AS channel
FROM ods_order;

-- 3. 用户行为清洗表（行为类型标准化：浏览/加购/收藏/购买）
DROP TABLE IF EXISTS ods_user_behavior_clean;
CREATE TABLE ods_user_behavior_clean AS
SELECT behavior_id,
       user_id,
       product_id,
       CASE behavior_type
            WHEN '浏览' THEN '浏览'  WHEN 'pv'  THEN '浏览'  WHEN 'PV'  THEN '浏览'
            WHEN '加购' THEN '加购'  WHEN 'cart' THEN '加购' WHEN 'Cart' THEN '加购'
            WHEN '收藏' THEN '收藏'  WHEN 'fav' THEN '收藏'
            WHEN '购买' THEN '购买'  WHEN 'buy' THEN '购买'
            ELSE '其他'
       END AS behavior_type,
       behavior_time,
       session_id
FROM ods_user_behavior;

-- 4. 商品/门店/订单明细清洗表（本步骤直通，异常与格式在02脚本处理）
DROP TABLE IF EXISTS ods_product_clean;
CREATE TABLE ods_product_clean AS SELECT * FROM ods_product;

DROP TABLE IF EXISTS ods_store_clean;
CREATE TABLE ods_store_clean AS SELECT * FROM ods_store;

DROP TABLE IF EXISTS ods_order_item_clean;
CREATE TABLE ods_order_item_clean AS SELECT * FROM ods_order_item;

-- 5. 验证：枚举取值收敛检查（应只剩规范值域）
-- SELECT gender, COUNT(*) FROM ods_user_clean GROUP BY gender;
-- SELECT member_level, COUNT(*) FROM ods_user_clean GROUP BY member_level;
-- SELECT order_status, COUNT(*) FROM ods_order_clean GROUP BY order_status;
-- SELECT pay_type, COUNT(*) FROM ods_order_clean GROUP BY pay_type;
-- SELECT channel, COUNT(*) FROM ods_order_clean GROUP BY channel;
-- SELECT behavior_type, COUNT(*) FROM ods_user_behavior_clean GROUP BY behavior_type;
