import pandas as pd
import os
from selenium import webdriver
from selenium.webdriver.common.by import By

os.chdir(
    "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey/classification_occupation"
)

driver = webdriver.Chrome()
driver.get("https://www.bls.gov/soc/2018/major_groups.htm")

driver.find_element(By.ID, "expand").click()

titles = []
descriptions = []
soc_codes = []

for i in range(1, 868):
    try:
        title = driver.find_element(By.ID, "q" + str(i)).text
        description = driver.find_element(By.ID, "a" + str(i)).text
        soc_code = driver.find_element(By.XPATH, "//a[@id='q" + str(i) + "']/preceding::li[1]").text[0:7]
        titles.append(title)
        descriptions.append(description)
        soc_codes.append(soc_code)
    except:
        pass

df = pd.DataFrame({"title": titles, "description": descriptions, "soc_code": soc_codes})
df.to_excel("./soc2018.xlsx", index=False)
