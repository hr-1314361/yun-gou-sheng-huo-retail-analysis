import zipfile, os

base = "D:\\xmsx"
zip_path = os.path.join(base, "第1周_胡蕊.zip")

# 提交清单要求的交付物
files = [
    "README.md",
    "环境搭建笔记.md",
    ".gitignore",
    "AI协同日志.md",
    "数据质量预评估表.xlsx",
]
dirs = ["sql"]

# 排除中间产物与作业外文件（及时性不在作业五维度内，不打包）
exclude = {
    "truncate_reload.sql", "check_rows.sql",
    "dq_1_1.sql", "dq_1_2.sql", "dq_1_3.sql", "dq_1_4.sql", "dq_1_5.sql", "dq_1_6.sql",
    "dq_2_split.sql", "dq_2_split2.sql",
    "dq_5_1.sql", "dq_5_2.sql", "dq_5_timeliness.sql",
}

with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
    for f in files:
        fp = os.path.join(base, f)
        if os.path.exists(fp):
            zf.write(fp, f)
            print(f"  added: {f}")
        else:
            print(f"  MISSING: {f}")
    for d in dirs:
        dp = os.path.join(base, d)
        for root, _, fs in os.walk(dp):
            for fn in fs:
                if fn in exclude:
                    continue
                full = os.path.join(root, fn)
                arc = os.path.relpath(full, base)
                zf.write(full, arc)
                print(f"  added: {arc}")

print(f"\nDone: {zip_path} ({os.path.getsize(zip_path)} bytes)")
