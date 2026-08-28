import pandas as pd
import os
import re

os.chdir(
    "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey/classification_occupation"
)

df = pd.read_excel("./occupation_vulnerability_raw.xlsx")
# Split the column into 5 columns using space as the delimiter

pattern = r"^\d+. (\d+(?:\.\d+)?)"
df["vulnerability"] = df["Rank Probability Label SOC code Occupation"].str.extract(pattern)
pattern = r"(\d+\-\d+)"
df["soc_code"] = df["Rank Probability Label SOC code Occupation"].str.extract(pattern)
pattern = r"([a-zA-Z].*)$"
df["title"] = df["Rank Probability Label SOC code Occupation"].str.extract(pattern)
df = df.drop("Rank Probability Label SOC code Occupation", axis=1)

df.to_csv("./occupation_vulnerability.csv", index=False)

