import pandas as pd
import numpy as np

df = pd.read_excel("20262081-Rawdata-September-2026.xlsb", engine="pyxlsb", sheet_name="Sheet1")

NOW_LABELS = {1: "New Build", 3: "Extension", 4: "Renovation"}

base = df[
    (df["BASIS_Building_Use"] == "Domestic")
    & (df["BASIS_Ownership_Sector"].str.upper() == "P")
    & (df["Total_Estimated_Cost_of_Works__c"] > 1000) & (df["Total_Estimated_Cost_of_Works__c"] < 3_000_000)
].copy()

# New Build / Extension / Renovation: floor area is a real cost driver, keep the >0 filter.
main = base[
    base["BASIS_NOW"].isin(NOW_LABELS.keys())
    & (base["Total_Floor_Area__c"] > 0) & (base["Total_Floor_Area__c"] < 1000)
].copy()
main["projectType"] = main["BASIS_NOW"].map(NOW_LABELS)

# "Outdoor Works" (BASIS_NOW == 8) is two different cost regimes, split via BCA class:
#   10a = garages / carports / sheds / roofed decks -> floor area still matters
#   10b = fences / retaining walls / pools / masts  -> floor area isn't recorded/meaningful
outdoor = base[base["BASIS_NOW"] == 8].copy()

outdoor_10a = outdoor[
    (outdoor["BASIS_BCA"] == "10a")
    & (outdoor["Total_Floor_Area__c"] > 0) & (outdoor["Total_Floor_Area__c"] < 1000)
].copy()
outdoor_10a["projectType"] = "Outdoor Structure"

outdoor_10b = outdoor[outdoor["BASIS_BCA"] == "10b"].copy()
outdoor_10b["Total_Floor_Area__c"] = 0.0  # not a meaningful feature for this class - zero it explicitly
outdoor_10b["projectType"] = "Boundary & Civil Works"

f = pd.concat([main, outdoor_10a, outdoor_10b], ignore_index=True)

out = pd.DataFrame({
    "floorAreaSqm": f["Total_Floor_Area__c"],
    "projectType": f["projectType"],
    "costOfWorks": f["Total_Estimated_Cost_of_Works__c"],
})
out = out.dropna().drop_duplicates()

out["logCost"] = np.log(out["costOfWorks"])
out.to_csv("training_data.csv", index=False)

print(out.shape)
print()
print(out.groupby("projectType").size())
print()
print(out.groupby("projectType")["costOfWorks"].describe())