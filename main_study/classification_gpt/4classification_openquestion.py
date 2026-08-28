from openai import OpenAI
import os
import pandas as pd

os.chdir(
    "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey/classification_gpt"
)

client = OpenAI(
)


def format_message(role, content):
    return {"role": role, "content": content}


def get_response(messages):
    completion = client.chat.completions.create(
        model="gpt-4o-mini", messages=messages, temperature=0.2
    )
    content = completion.choices[0].message.content
    return content


# T: import survey data for job classification
df = pd.read_csv("./open_opinion_autom.csv")
df = df[df["open_opinion_autom"].notna()]

df_en = df[df["cntry"] == "US"]
df_en = df_en.reset_index(drop=True)
df_de = df[df["cntry"] == "DE"]
df_de = df_de.reset_index(drop=True)
df_it = df[df["cntry"] == "IT"]
df_it = df_it.reset_index(drop=True)

# T: do the classification for the US
class_inst_en = """
Below is the description of a coding exercise. The input consists of answers to the following open-ended survey question:  

*"Now, please briefly state (max 100 words) your opinion on how automation and AI are shaping the present and future of jobs in terms of number of jobs, their quality, and average wage."*  

Since these responses come from survey participants, they may be incomplete or poorly written.

### Classification Task:
You must classify each response based on **two dimensions**:  
1. **Forecast on the present and future of jobs**:
   - **Optimistic** → The response suggests a positive impact (e.g., job creation, quality improvements, or wage increases).  
   - **Pessimistic** → The response suggests a negative impact (e.g., job losses, lower quality, or wage reductions).  
   - **Balanced** → The response acknowledges both positive and negative aspects.  
   Note: If the response does not explicitly discuss job impact but still expresses a **positive** or **negative** judgment of automation and AI, classify it as **Optimistic** (positive judgment) or **Pessimistic** (negative judgment). 

2. **Certainty Level** (how confident the respondent appears in their forecast):
   - **High** → The response expresses a strong opinion with clear reasoning.  
   - **Medium** → The response expresses an opinion but with some uncertainty.  
   - **Low** → The response is vague, hesitant, or lacks a clear stance.  

### Special Cases:
- If the response is **gibberish** or **not related** to the question, classify it as: **"Not related,low"**.
- If the response is **I don't know** or similar, classify it as: **"Uncertain, low"**.

### Examples:
| Response | Classification |
|-------------------------------------------------|-----------------|
| *"AI automatic workers are taking the jobs of humans. The future is uncertain."* | **Pessimistic, medium** |
| *"Automation is creating new jobs and increasing the quality of existing ones."* | **Optimistic, high** |
| *"I don't know."* | **Uncertain, low** |
| *"AI can benefit quality and wages, but the number of jobs may decrease."* | **Balanced, medium** |
| *"Some people will lose jobs because of AI and automation. But there will be job creation because of AI."* | **Balanced, high** |

### Output Format:
Your response should contain **only the two classifications, separated by a comma**, with no extra text or comments.  
**Example Output:** `Optimistic, high`
"""
df_en["classification"] = ""
for idx, user_input in enumerate(df_en["open_opinion_autom"]):
    messages = [
        format_message("system", class_inst_en),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_en.at[idx, "classification"] = response

df_backup = df_en
df_en["expectation"] = [x.split(",")[0] if "," in x else x for x in df_en["classification"]]
df_en["certainty"] = [x.split(",")[1] if "," in x else x for x in df_en["classification"]]

df_en.to_excel("open_opinion_classified_en.xlsx", index=False)

# T: do the classification for Italy
class_inst_it = """
Below is the description of a coding exercise. The input consists of answers in **ITALIAN** to the following open-ended survey question:  

*"Now, please briefly state (max 100 words) your opinion on how automation and AI are shaping the present and future of jobs in terms of number of jobs, their quality, and average wage."*  

Since these responses come from survey participants, they may be incomplete or poorly written.

### Classification Task:
You must classify each response based on **two dimensions**:  
1. **Forecast on the present and future of jobs**:
   - **Optimistic** → The response suggests a positive impact (e.g., job creation, quality improvements, or wage increases).  
   - **Pessimistic** → The response suggests a negative impact (e.g., job losses, lower quality, or wage reductions).  
   - **Balanced** → The response acknowledges both positive and negative aspects.  
   Note: If the response does not explicitly discuss job impact but still expresses a **positive** or **negative** judgment of automation and AI, classify it as **Optimistic** (positive judgment) or **Pessimistic** (negative judgment). 

2. **Certainty Level** (how confident the respondent appears in their forecast):
   - **High** → The response expresses a strong opinion with clear reasoning.  
   - **Medium** → The response expresses an opinion but with some uncertainty.  
   - **Low** → The response is vague, hesitant, or lacks a clear stance.  

### Special Cases:
- If the response is **gibberish** or **not related** to the question, classify it as: **"Not related,low"**.
- If the response is **I don't know** or similar, classify it as: **"Uncertain, low"**.

### Examples:
| Response | Classification |
|-------------------------------------------------|-----------------|
| *"L'intelligenza artificiale stà prendendo i posti di lavoro degli esseri umani. Il futuro è incerto."* | **Pessimistic, medium** |
| *"L'automazione sta creando nuovi posti di lavoro e migliorando la qualità di quelli esistenti."* | **Optimistic, high** |
| *"Non lo so."* | **Uncertain, low** |
| *"L'AI può migliorare la qualità e i salari, ma il numero di posti di lavoro potrebbe diminuire."* | **Balanced, medium** |
| *"Alcune persone perderanno il lavoro a causa dell'AI e dell'automazione. Ma ci sarà anche creazione di nuovi posti di lavoro grazie all'AI."* | **Balanced, high** |

### Output Format:
Your response should contain **only the two classifications, separated by a comma**, with no extra text or comments.  
**Example Output:** `Optimistic, high`
"""

df_it["classification"] = ""
for idx, user_input in enumerate(df_it["open_opinion_autom"]):
    messages = [
        format_message("system", class_inst_it),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_it.at[idx, "classification"] = response

df_backup = df_it
df_it["expectation"] = [x.split(",")[0] if "," in x else x for x in df_it["classification"]]
df_it["certainty"] = [x.split(",")[1] if "," in x else x for x in df_it["classification"]]

df_it.to_excel("open_opinion_classified_it.xlsx", index=False)

# T: do the classification for Germany
class_inst_de = """
Below is the description of a coding exercise. The input consists of answers in **GERMAN** to the following open-ended survey question:  

*"Now, please briefly state (max 100 words) your opinion on how automation and AI are shaping the present and future of jobs in terms of number of jobs, their quality, and average wage."*  

Since these responses come from survey participants, they may be incomplete or poorly written.

### Classification Task:
You must classify each response based on **two dimensions**:  
1. **Forecast on the present and future of jobs**:
   - **Optimistic** → The response suggests a positive impact (e.g., job creation, quality improvements, or wage increases).  
   - **Pessimistic** → The response suggests a negative impact (e.g., job losses, lower quality, or wage reductions).  
   - **Balanced** → The response acknowledges both positive and negative aspects.  
   Note: If the response does not explicitly discuss job impact but still expresses a **positive** or **negative** judgment of automation and AI, classify it as **Optimistic** (positive judgment) or **Pessimistic** (negative judgment). 

2. **Certainty Level** (how confident the respondent appears in their forecast):
   - **High** → The response expresses a strong opinion with clear reasoning.  
   - **Medium** → The response expresses an opinion but with some uncertainty.  
   - **Low** → The response is vague, hesitant, or lacks a clear stance.  

### Special Cases:
- If the response is **gibberish** or **not related** to the question, classify it as: **"Not related,low"**.
- If the response is **I don't know** or similar, classify it as: **"Uncertain, low"**.

### Examples:
| Response | Classification |
|-------------------------------------------------|-----------------|
| *"Künstliche Intelligenz nimmt dem Menschen die Arbeit weg. Die Zukunft ist ungewiss."* | **Pessimistic, medium** |
| *"Die Automatisierung schafft neue Arbeitsplätze und verbessert die Qualität der bestehenden."* | **Optimistic, high** |
| *"Ich weiß es nicht."* | **Uncertain, low** |
| *"KI kann die Qualität und die Löhne verbessern, aber die Zahl der Arbeitsplätze könnte sinken."* | **Balanced, medium** |
| *"Einige Menschen werden durch KI und Automatisierung ihre Arbeitsplätze verlieren. Aber es werden auch neue Arbeitsplätze durch KI geschaffen."* | **Balanced, high** |

### Output Format:
Your response should contain **only the two classifications, separated by a comma**, with no extra text or comments.  
**Example Output:** `Optimistic, high`
"""

df_de["classification"] = ""
for idx, user_input in enumerate(df_de["open_opinion_autom"]):
    messages = [
        format_message("system", class_inst_de),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_de.at[idx, "classification"] = response

df_backup = df_de
df_de["expectation"] = [x.split(",")[0] if "," in x else x for x in df_de["classification"]]
df_de["certainty"] = [x.split(",")[1] if "," in x else x for x in df_de["classification"]]

df_de.to_excel("open_opinion_classified_de.xlsx", index=False)

