industry_total_pattern <- "内生部門合?計"
value_added_total_pattern <- "粗付加価値部門合?計"
final_demand_total_pattern <- "[都道府県]内最終需要合?計"

export_pattern <- "([移輸]出|輸出[（\\(](普通貿易|特殊貿易|直接購入)[）\\)])$"
export_total_pattern <- "(移輸|輸移)出合?計$"

import_pattern <- "[（\\(]控除[）\\)]([移輸]入|輸入[（\\(](普通貿易|特殊貿易|直接購入)[）\\)]|関税・輸入品商品税|関税|輸入品商品税)$"
import_total_pattern <- "[（\\(]控除[）\\)](移輸|輸移)入合?計$"

total_pattern <- "[都道府県]内生産額"
