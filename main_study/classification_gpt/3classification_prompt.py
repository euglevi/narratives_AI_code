from openai import OpenAI
import os
import pandas as pd

os.chdir(
    "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey/classification_occupation"
)

client = OpenAI(
    api_key="xxx"
)


def format_message(role, content):
    return {"role": role, "content": content}


def get_response(messages):
    completion = client.chat.completions.create(
        model="gpt-4o-mini", messages=messages, temperature=0.2
    )
    content = completion.choices[0].message.content
    return content

# T: prepare files with the descriptions
df_soc = pd.read_excel(
    "./OccupationalListings/Taxonomies/2010_Occupations.xlsx",
    skiprows=3,
    header=0,
)
df_soc.columns = ["soc_code", "title", "description"]
df_soc = df_soc[df_soc["soc_code"].str.endswith(".00")]
df_soc["soc_code"] = df_soc["soc_code"].str[:-3]

df_soc2 = pd.read_excel(
    "./OccupationalListings/may_2010_occs.xls", skiprows=3, header=0
)
df_soc2.columns = ["soc_code", "title", "description", "notes"]
df_soc2 = df_soc2.drop("notes", axis=1)
df_soc2 = df_soc2[df_soc2["soc_code"].notna()]

df_nace = pd.read_excel("./NACE2.1.xlsx", header=0)
df_nace = df_nace.fillna('')
df_nace["codebook"] = df_nace["ID"] + " " + df_nace["NAME"] + ": " + df_nace["Includes"] + " " + df_nace["IncludesAlso"] + " " + df_nace["Excludes"]
codebook_ind = ' ! '.join(df_nace["codebook"].tolist())
df_nace = df_nace.rename(columns={"ID": "nace_code"})

# T: merge descriptions with the vulnerability data
df_occ = pd.read_csv("occupation_vulnerability.csv")
df_int = pd.merge(
    df_occ,
    df_soc,
    on="soc_code",
    how="left",
    indicator=True,
    validate="one_to_one",
)
df_int = df_int.rename(columns={"_merge": "_merge1"})
df_int = pd.merge(
    df_int,
    df_soc2,
    on="soc_code",
    how="left",
    indicator=True,
    validate="one_to_one",
)
df_int["validate"] = [
    True if l == "both" or m == "both" else False
    for (l, m) in zip(df_int._merge, df_int._merge1)
]
df_int["description_x"] = [
    l if z == "left_only" and s == "both" else m
    for (l, z, s, m) in zip(
        df_int.description_y,
        df_int._merge1,
        df_int._merge,
        df_int.description_x,
    )
]

# T: clean and prepare codebook for job classification
df_int = df_int[
    (df_int["_merge"] != "left_only") | (df_int["_merge1"] != "left_only")
]
df_int = df_int.drop(
    ["_merge", "_merge1", "title_y", "title", "description_y", "validate"],
    axis=1,
)
df_int = df_int.rename(
    columns={"title_x": "title", "description_x": "description"}
)
df_int["job_full"] = (
    df_int["soc_code"] + " " + df_int["title"] + " " + df_int["description"]
)
codebook = '; '.join(df_int["job_full"].tolist())

# df_int.to_excel("check.xlsx", index=False)

# T: import survey data for job classification
df = pd.read_csv("jobs.csv")
df = df[(df["job_title"].notna()) | (df["job_tasks"].notna())]
df["job_full"] = df["job_title"] + " " + df["job_tasks"]
df = df[df["job_full"].notna()]

df_en = df[df["cntry"] == "US"]
df_en = df_en.reset_index(drop=True)
df_de = df[df["cntry"] == "DE"]
df_de = df_de.reset_index(drop=True)
df_it = df[df["cntry"] == "IT"]
df_it = df_it.reset_index(drop=True)

# T: do the classification for the US
class_inst_en = """
Below is the description of a coding exercise. The input consists of descriptions of job tasks collected from a survey. As these descriptions come from survey responses, they may be incomplete or poorly written. 

You will be provided with a codebook containing a list of jobs classified by O*NET Center. Each job entry includes the O*NET-SOC code, job title, and job description. Entries in the codebook are delimited by semicolons.

Your task is to assign the O*NET-SOC code that best matches the input description of job tasks based on the information in the codebook. Follow these special rules:
a) If the input describes a retired individual and does not include any job-related tasks, respond with "Retired";
b) If the input describes a housewife and does not mention any job outside the home, respond with "Housewife";
c) If the input describes a disabled person and does not mention any job outside the home, respond with "Disabled";
d) For all other cases, use the O*NET-SOC code from the codebook.

Your responses should include **only the O*NET-SOC code**. Do not include job titles, job descriptions, or any other information from the inputs or codebook.

Here is the codebook: """ + codebook
df_en["soc_code"] = ""
for idx, user_input in enumerate(df_en["job_full"]):
    messages = [
        format_message("system", class_inst_en),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_en.at[idx, "soc_code"] = response

df_backup = df_en

df_en = pd.merge(
    df_en,
    df_int,
    on="soc_code",
    how="left",
    indicator=True,
    validate="many_to_one",
)
df_en.to_excel("jobs_classified_en.xlsx", index=False)

# T: do the classification for Italy
class_inst_it = """
Below is the description of a coding exercise. The input consists of descriptions of job tasks collected from a survey. These descriptions are written in **Italian**, while the codebook is in **English**. As the inputs come from survey responses, they may be incomplete or poorly written.

You will be provided with a codebook containing a list of jobs classified by O*NET Center. Each job entry includes the O*NET-SOC code, job title, and job description. Entries in the codebook are delimited by semicolons.

Your task is to:
1. Understand the meaning of the input description in Italian.
2. Assign the O*NET-SOC code that best matches the input description of job tasks based on the information in the codebook.

Follow these special rules:
a) If the input describes a retired individual and does not include any job-related tasks, respond with "Retired."
b) If the input describes a housewife and does not mention any job outside the home, respond with "Housewife."
c) If the input describes a disabled person and does not mention any job outside the home, respond with "Disabled";
d) For all other cases, use the O*NET-SOC code from the codebook.

Your responses should include **only the O*NET-SOC code**. Do not include job titles, job descriptions, or any other information from the inputs or codebook.

Here is the codebook: """ + codebook
df_it["soc_code"] = ""
for idx, user_input in enumerate(df_it["job_full"]):
    messages = [
        format_message("system", class_inst_it),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_it.at[idx, "soc_code"] = response

df_backup = df_it

df_it = pd.merge(
    df_it,
    df_int,
    on="soc_code",
    how="left",
    indicator=True,
    validate="many_to_one",
)
df_it.to_excel("jobs_classified_it.xlsx", index=False)


# T: do the classification for Germany
class_inst_de = """
Below is the description of a coding exercise. The input consists of descriptions of job tasks collected from a survey. These descriptions are written in **German**, while the codebook is in **English**. As the inputs come from survey responses, they may be incomplete or poorly written.

You will be provided with a codebook containing a list of jobs classified by O*NET Center. Each job entry includes the O*NET-SOC code, job title, and job description. Entries in the codebook are delimited by semicolons.

Your task is to:
1. Understand the meaning of the input description in German.
2. Assign the O*NET-SOC code that best matches the input description of job tasks based on the information in the codebook.

Follow these special rules:
a) If the input describes a retired individual and does not include any job-related tasks, respond with "Retired."
b) If the input describes a housewife and does not mention any job outside the home, respond with "Housewife."
c) If the input describes a disabled person and does not mention any job outside the home, respond with "Disabled";
d) For all other cases, use the O*NET-SOC code from the codebook.

Your responses should include **only the O*NET-SOC code**. Do not include job titles, job descriptions, or any other information from the inputs or codebook.

Here is the codebook: """ + codebook
df_de["soc_code"] = ""
for idx, user_input in enumerate(df_de["job_full"]):
    messages = [
        format_message("system", class_inst_de),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_de.at[idx, "soc_code"] = response

df_backup = df_de

df_de = pd.merge(
    df_de,
    df_int,
    on="soc_code",
    how="left",
    indicator=True,
    validate="many_to_one",
)
df_de.to_excel("jobs_classified_de.xlsx", index=False)

df_it.to_csv("jobs_classified_it.csv", index=False)
df_de.to_csv("jobs_classified_de.csv", index=False)
df_en.to_csv("jobs_classified_en.csv", index=False)


# T: import survey data for industry classification
df = pd.read_csv("jobs.csv")
df = df[df["industry_category"].notna()]
df["job_tasks"]= df["job_tasks"].fillna('')
df["industry_full"] = df["industry_category"] + ": " + df["job_tasks"]

df_en = df[df["cntry"] == "US"]
df_en = df_en.reset_index(drop=True)
df_de = df[df["cntry"] == "DE"]
df_de = df_de.reset_index(drop=True)
df_it = df[df["cntry"] == "IT"]
df_it = df_it.reset_index(drop=True)

# T: do the classification for the US
class_inst_en = """
Below is the description of a coding exercise. The input consists of descriptions of **industries** where people are employed, sometimes followed by **job task descriptions** after a colon. These descriptions are collected from a survey and may be incomplete or imprecise.

You will be provided with a codebook containing a list of industries classified according to **NACE v2.1**. Each industry entry includes:
- A **NACE code** (ranging from A to V)
- The **industry name**
- (For some industries) Additional details on included or excluded activities.  
Entries in the codebook are delimited by **exclamation marks**.

### Your Task:
1. Read and understand the input industry description.
2. Use the **job task description** (after the colon) **only when necessary** to clarify the industry.
3. Assign the **NACE code** that best matches the description based on the codebook.

### Special Rules:
- If the input describes a **retired individual, a disabled person, or someone who does not work** and does not mention any industry, respond with **"None"**.
- If the input describes an activity related to **services** but cannot be classified into a specific industry from the codebook, assign it to **NACE code "T"**.
- For all other cases, use the appropriate **NACE code** from the codebook.

Your response should contain **only the NACE code**. Do not include industry names, descriptions, job tasks, or any other information from the inputs or codebook.

Here is the codebook: """ + codebook_ind
df_en["nace_code"] = ""
for idx, user_input in enumerate(df_en["industry_full"]):
    messages = [
        format_message("system", class_inst_en),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_en.at[idx, "nace_code"] = response

df_backup = df_en

df_en = pd.merge(
    df_en,
    df_nace,
    on="nace_code",
    how="left",
    indicator=True,
    validate="many_to_one",
)
df_en.to_excel("industries_classified_en.xlsx", index=False)


# T: do the classification for the IT
class_inst_it = """
Below is the description of a coding exercise. The input consists of descriptions of **industries** where people are employed, sometimes followed by **job task descriptions** after a colon. These descriptions are written in **Italian**, while the codebook is in **English**. These descriptions are collected from a survey and may be incomplete or imprecise.

You will be provided with a codebook containing a list of industries classified according to **NACE v2.1**. Each industry entry includes:
- A **NACE code** (ranging from A to V)
- The **industry name**
- (For some industries) Additional details on included or excluded activities.  
Entries in the codebook are delimited by **exclamation marks**.

### Your Task:
1. Read and understand the input industry description in Italian.
2. Use the **job task description** (after the colon) **only when necessary** to clarify the industry.
3. Assign the **NACE code** that best matches the description based on the codebook.

### Special Rules:
- If the input describes a **retired individual, a disabled person, or someone who does not work** and does not mention any industry, respond with **"None"**.
- If the input describes an activity related to **services** but cannot be classified into a specific industry from the codebook, assign it to NACE code **"T"**.
- If the industry in the input is listed as **pubblico**, **stato** or **pubblica amministrazione**, then use the code **P** related to the public administration sector. 
- For all other cases, use the appropriate **NACE code** from the codebook.

Your response should contain **only the NACE code**. Do not include industry names, descriptions, job tasks, or any other information from the inputs or codebook.

Here is the codebook: """ + codebook_ind
df_it["nace_code"] = ""
for idx, user_input in enumerate(df_it["industry_full"]):
    messages = [
        format_message("system", class_inst_it),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_it.at[idx, "nace_code"] = response

df_backup = df_it

df_it = pd.merge(
    df_it,
    df_nace,
    on="nace_code",
    how="left",
    indicator=True,
    validate="many_to_one",
)
df_it.to_excel("industries_classified_it.xlsx", index=False)


# T: do the classification for Germany
class_inst_de = """
Below is the description of a coding exercise. The input consists of descriptions of **industries** where people are employed, sometimes followed by **job task descriptions** after a colon. These descriptions are written in **German**, while the codebook is in **English**. These descriptions are collected from a survey and may be incomplete or imprecise.

You will be provided with a codebook containing a list of industries classified according to **NACE v2.1**. Each industry entry includes:
- A **NACE code** (ranging from A to V)
- The **industry name**
- (For some industries) Additional details on included or excluded activities.  
Entries in the codebook are delimited by **exclamation marks**.

### Your Task:
1. Read and understand the input industry description in German.
2. Use the **job task description** (after the colon) **only when necessary** to clarify the industry.
3. Assign the **NACE code** that best matches the description based on the codebook.

### Special Rules:
- If the input describes a **retired individual, a disabled person, or someone who does not work** and does not mention any industry, respond with **"None"**.
- If the input describes an activity related to **services** but cannot be classified into a specific industry from the codebook, assign it to NACE code **"T"**.
- For all other cases, use the appropriate **NACE code** from the codebook.

Your response should contain **only the NACE code**. Do not include industry names, descriptions, job tasks, or any other information from the inputs or codebook.

Here is the codebook: """ + codebook_ind
df_de["nace_code"] = ""
for idx, user_input in enumerate(df_de["industry_full"]):
    messages = [
        format_message("system", class_inst_de),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_de.at[idx, "nace_code"] = response

df_backup = df_de

df_de = pd.merge(
    df_de,
    df_nace,
    on="nace_code",
    how="left",
    indicator=True,
    validate="many_to_one",
)
df_de.to_excel("industries_classified_de.xlsx", index=False)
