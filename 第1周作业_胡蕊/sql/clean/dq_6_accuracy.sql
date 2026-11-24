-- 维度5：准确性——业务逻辑校验
-- 检查订单日期与用户注册日期、店铺开业日期的逻辑合理性，以及折扣金额合理性
USE ydsh_ods;
SELECT 'order_before_register' AS check_item, COUNT(*) AS cnt
FROM ods_order o JOIN ods_user u ON o.user_id = u.user_id
WHERE o.order_date < u.register_date
UNION ALL
SELECT 'order_before_store_open', COUNT(*)
FROM ods_order o JOIN ods_store s ON o.store_id = s.store_id
WHERE o.order_date < s.open_date
UNION ALL
SELECT 'discount_gt_pay_amount', COUNT(*)
FROM ods_order
WHERE discount_amount > pay_amount;
