import pandas as pd

df = pd.read_excel("20262081-Rawdata-September-2026.xlsb", engine="pyxlsb", sheet_name="Sheet1")

NOW_LABELS = {1: "New Build", 3: "Extension", 4: "Renovation", 8: "Outdoor Works"}

f = df[
    (df["BASIS_Building_Use"] == "Domestic")
    & (df["BASIS_Ownership_Sector"].str.upper() == "P")
    & (df["Total_Floor_Area__c"] > 0) & (df["Total_Floor_Area__c"] < 1000)
    & (df["Total_Estimated_Cost_of_Works__c"] > 1000) & (df["Total_Estimated_Cost_of_Works__c"] < 3_000_000)
    & (df["BASIS_NOW"].isin(NOW_LABELS.keys()))
].copy()

out = pd.DataFrame({
    "floorAreaSqm": f["Total_Floor_Area__c"],
    "projectType": f["BASIS_NOW"].map(NOW_LABELS),
    "costOfWorks": f["Total_Estimated_Cost_of_Works__c"],
})
out = out.dropna().drop_duplicates()
out.to_csv("training_data.csv", index=False)

print(out.shape)
print()
print(out.groupby("projectType").size())
print()
print(out.groupby("projectType")["costOfWorks"].describe())