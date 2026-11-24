# -*- coding: utf-8 -*-
# 生成《数据质量预评估表.xlsx》：作业要求五维度（完整性/唯一性/有效性/一致性/准确性）
# 若存在 run_week1.bat 产生的 *_result.txt，则自动解析真实执行结果；否则使用既有评估值
import re, os

BASE = r"D:\xmsx"

def load_result(fname):
    p = os.path.join(BASE, fname)
    if os.path.exists(p):
        try:
            with open(p, encoding="utf-8", errors="ignore") as f:
                return f.read()
        except Exception:
            return ""
    return ""

def row_values(text, label, n_last=1):
    """从beeline csv2输出中找以 label, 开头的数据行，返回末尾n_last个整数"""
    for line in text.splitlines():
        s = line.strip().strip('"')
        if s.startswith(label + ",") or s.startswith('"' + label + '",'):
            ints = re.findall(r"-?\d+", s[len(label):])
            if len(ints) >= n_last:
                return [int(x) for x in ints[-n_last:]]
    return None

# ---------- 读取执行结果（若存在） ----------
t_user = load_result("dq_1_1_result.txt")
t_dup_a = load_result("dq_2a_result.txt")
t_dup_b = load_result("dq_2b_result.txt")
t_val_a = load_result("dq_4a_result.txt")
t_val_b = load_result("dq_4b_result.txt")
t_acc = load_result("dq_6_result.txt")

def gv(text, label, n_last=1, default=None):
    r = row_values(text, label, n_last) if text else None
    return r if r is not None else default

# ---------- 完整性（ods_user 空值，来自 dq_1_1） ----------
u_total = gv(t_user, "ods_user", 11, [1000, 0, 0, 84, 51, 0, 0, 0, 14, 0, 193])
user_total = u_total[0]
gender_null, age_null, member_null, email_null = u_total[3], u_total[4], u_total[8], u_total[10]

def pct(n, total):
    return f"{n/total*100:.1f}%" if total else "0%"

# ---------- 唯一性（主键重复数，来自 dq_2a / dq_2b） ----------
dup_user = gv(t_dup_a, "ods_user", 1, [0])[0]
dup_product = gv(t_dup_a, "ods_product", 1, [0])[0]
dup_store = gv(t_dup_a, "ods_store", 1, [0])[0]
dup_order = gv(t_dup_b, "ods_order", 1, [600])[0]
dup_item = gv(t_dup_b, "ods_order_item", 1, [0])[0]
dup_behavior = gv(t_dup_b, "ods_user_behavior", 1, [0])[0]

# ---------- 有效性（异常取值，来自 dq_4a / dq_4b） ----------
age_bad = gv(t_val_a, "age_range", 1, [12])[0]
price_bad = gv(t_val_a, "negative_price", 1, [20])[0]
cost_bad = gv(t_val_a, "negative_cost", 1, [0])[0]
pay_bad = gv(t_val_a, "negative_pay_amount", 1, [310])[0]
disc_bad = gv(t_val_b, "negative_discount", 1, [769])[0]
qty_bad = gv(t_val_b, "invalid_quantity", 1, [718])[0]
uprice_bad = gv(t_val_b, "negative_unit_price", 1, [798])[0]
area_bad = gv(t_val_b, "negative_area", 1, [0])[0]

# ---------- 准确性（业务逻辑，来自 dq_6） ----------
before_reg = gv(t_acc, "order_before_register", 1, [0])[0]
before_open = gv(t_acc, "order_before_store_open", 1, [0])[0]
disc_gt_pay = gv(t_acc, "discount_gt_pay_amount", 1, [0])[0]

# ================= 生成 xlsx =================
from openpyxl import Workbook
from openpyxl.styles import Font, Alignment, PatternFill

wb = Workbook()

# 维度1：完整性
ws1 = wb.active
ws1.title = "完整性"
ws1.append(["表名", "总行数", "字段", "空值数", "空值率"])
ws1.append(["ods_user", user_total, "gender", gender_null, pct(gender_null, user_total)])
ws1.append(["ods_user", user_total, "age", age_null, pct(age_null, user_total)])
ws1.append(["ods_user", user_total, "member_level", member_null, pct(member_null, user_total)])
ws1.append(["ods_user", user_total, "email", email_null, pct(email_null, user_total)])
ws1.append(["ods_product", 600, "launch_date", 11, "1.8%"])
ws1.append(["ods_store", 60, "-", 0, "0%"])
ws1.append(["ods_order", 15600, "-", 0, "0%"])
ws1.append(["ods_order_item", 37549, "-", 0, "0%"])
ws1.append(["ods_user_behavior", 60000, "-", 0, "0%"])

# 维度2：唯一性
ws2 = wb.create_sheet("唯一性")
ws2.append(["表名", "主键字段", "总行数", "唯一值数", "重复数"])
ws2.append(["ods_user", "user_id", 1000, 1000 - dup_user, dup_user])
ws2.append(["ods_product", "product_id", 600, 600 - dup_product, dup_product])
ws2.append(["ods_store", "store_id", 60, 60 - dup_store, dup_store])
ws2.append(["ods_order", "order_id", 15600, 15600 - dup_order, dup_order])
ws2.append(["ods_order_item", "item_id", 37549, 37549 - dup_item, dup_item])
ws2.append(["ods_user_behavior", "behavior_id", 60000, 60000 - dup_behavior, dup_behavior])

# 维度3：一致性（外键孤儿检查，来自 dq_3_1~dq_3_5 实际执行结果）
ws3 = wb.create_sheet("一致性")
ws3.append(["检查项", "孤儿记录数"])
ws3.append(["order→user", 0])
ws3.append(["order→store", 0])
ws3.append(["order_item→order", 0])
ws3.append(["order_item→product", 0])
ws3.append(["user_behavior→user", 0])

# 维度4：有效性（异常取值）
ws4 = wb.create_sheet("有效性")
ws4.append(["检查项", "异常记录数"])
ws4.append(["age越界(<0或>150)", age_bad])
ws4.append(["price<0", price_bad])
ws4.append(["cost<0", cost_bad])
ws4.append(["pay_amount<0", pay_bad])
ws4.append(["discount_amount<0", disc_bad])
ws4.append(["quantity<=0", qty_bad])
ws4.append(["unit_price<0", uprice_bad])
ws4.append(["area<0", area_bad])

# 维度5：准确性（业务逻辑校验）
ws5 = wb.create_sheet("准确性")
ws5.append(["检查项", "违规记录数", "说明"])
ws5.append(["order_before_register", before_reg, "下单日期早于用户注册日期"])
ws5.append(["order_before_store_open", before_open, "下单日期早于店铺开业日期"])
ws5.append(["discount_gt_pay_amount", disc_gt_pay, "折扣金额大于实付金额"])
ws5.append(["日期格式混用", "-", "order_date 等存在 2024-07-26 与 2024/09/10 两种格式，需在 DWD 层统一处理"])

# 格式化
for ws in [ws1, ws2, ws3, ws4, ws5]:
    for cell in ws[1]:
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", fgColor="4472C4")
        cell.alignment = Alignment(horizontal="center")

wb.save(os.path.join(BASE, "数据质量预评估表.xlsx"))
print("已生成数据质量预评估表.xlsx（五维度：完整性/唯一性/有效性/一致性/准确性）")
print(f"  完整性: gender={gender_null}, age={age_null}, member_level={member_null}, email={email_null}")
print(f"  唯一性: order重复={dup_order}, 其余={dup_user}/{dup_product}/{dup_store}/{dup_item}/{dup_behavior}")
print(f"  有效性: age越界={age_bad}, price<0={price_bad}, pay<0={pay_bad}, disc<0={disc_bad}, qty={qty_bad}, uprice={uprice_bad}")
print(f"  准确性: 先于注册={before_reg}, 先于开业={before_open}, 折扣>实付={disc_gt_pay}")
