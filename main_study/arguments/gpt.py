from openai import OpenAI
import os
import pandas as pd

os.chdir(
    "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey/lda_arguments/"
)

client = OpenAI(
    api_key="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"
)


def format_message(role, content):
    return {"role": role, "content": content}


def get_response(messages):
    completion = client.chat.completions.create(
        model="gpt-4o-mini", messages=messages, temperature=0.2
    )
    content = completion.choices[0].message.content
    return content


# T: filter the data
df = pd.read_csv("./arguments.csv")
df["argument"] = df["argument"].astype(str)
df_it = df[df["cntry"] == "IT"]
df_it = df_it.reset_index(drop=True)
df_en = df[df["cntry"] == "US"]
df_en = df_en.reset_index(drop=True)
df_de = df[df["cntry"] == "DE"]
df_de = df_de.reset_index(drop=True)

# T: do the classification for the US
class_inst_en = """
Below is the description of a coding exercise. The input consists of answers to the following open-ended survey question:  

*"Please write down two arguments (one for each field) as to why, in your opinion, policy-makers should or should not intervene on automation and AI."*  

Since these responses come from survey participants, they may be incomplete or poorly written.

### Classification Task:
Classify each argument according to its main theme:

**Negative themes**:
- Labour: The response focuses on the negative impact of automation and AI on jobs, wages, working conditions, or other labour-related concerns.
- Security: The response concerns risks related to safety, surveillance, privacy, or broader existential threats.
- Humanity: The response focuses on considering AI/automation as fundamentally corrupting humanity and human values (e.g. making humans less intelligent, more lazy, reducing social interactions).
- Regulation: The response focuses on the need for regulation and intervention by policy-makers.
- Mistrust towards AI companies: The argument reflects distrust in AI companies (e.g., profit motives, lack of transparency, collusion).

**Positive themes**:
- Confidence in automation and AI: The argument suggests AI/automation is beneficial or at least not harmful and that, because of that, intervention is unnecessary.
- Market: The response defends market forces, suggesting they will handle issues better than policy-makers.
- Mistrust towards politicians and the government: The argument reflects distrust in politicians or institutions (e.g., inefficiency, incompetence, corruption).

### Special Cases:
- If the response is **gibberish** or **not related** to the question, classify it as: Not related.
- If the response is **I don't know** or similar, classify it as: I do not know.
Try not to classify responses as *Not related* or *I do not know* unless you really have no other possibility. Some answers may be very short or poorly written, or may not mention AI or automation explicitly—still, by interpreting their meaning, they may fall within one of the main categories.

### Hard-to-Classify Examples (Still Classifiable):
| Response | Classification |
|-------------------------------------------|----------------------------------------------|
| "The economy will decline"                | Labour                                       |
| "to set controls"                         | Security                                     |
| "It’s not good for our society"           | Humanity                                     |
| "Because there's too many policies"       | Mistrust towards politicians and the government |
| "it's not their business"                 | Mistrust towards politicians and the government |
| "Company decision"                        | Market                                       |
| "We must move forward into the future"    | Confidence in automation and AI              |
| "Spreads misinformation"                 | Security                                     |

### Regular Examples:
| Response | Classification |
|-----------------------------------------------------|----------------------------------------------|
| "Bc it's going to take everyone job"| Labour|
| "I think they let the companies do as they wish"|Market|
| "I don't know."                                     | I do not know                                |
| "Policy makers aren't engineers" | Mistrust towards politicians and the government |
| "Should: could destroy Earth and human civilization"|Security |
| "We the people are smarter and more compassionate than machines." | Humanity |

### Output Format:
Your response should contain **only the classification**, with no extra text or comments.  
**Example Output:** Labour
**Example Output:** Mistrust towards politicians and the government
"""
df_en["classification"] = ""
for idx, user_input in enumerate(df_en["argument"]):
    messages = [
        format_message("system", class_inst_en),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_en.at[idx, "classification"] = response

df_en.to_excel("arguments_classified_en.xlsx", index=False)


# T: do the classification for Italy
class_inst_it = """
Below is the description of a coding exercise. The input consists of answers in **ITALIAN** to the following open-ended survey question:  

*"Please write down two arguments (one for each field) as to why, in your opinion, policy-makers should or should not intervene on automation and AI."*  

Since these responses come from survey participants, they may be incomplete or poorly written.

### Classification Task:
Classify each argument according to its main theme:

**Negative themes**:
- Labour: The response focuses on the negative impact of automation and AI on jobs, wages, working conditions, or other labour-related concerns.
- Security: The response concerns risks related to safety, surveillance, privacy, or broader existential threats.
- Humanity: The response focuses on considering AI/automation as fundamentally corrupting humanity and human values (e.g. making humans less intelligent, more lazy, reducing social interactions).
- Regulation: The response focuses on the need for regulation and intervention by policy-makers.
- Mistrust towards AI companies: The argument reflects distrust in AI companies (e.g., profit motives, lack of transparency, collusion).

**Positive themes**:
- Confidence in automation and AI: The argument suggests AI/automation is beneficial or at least not harmful and that, because of that, intervention is unnecessary.
- Market: The response defends market forces, suggesting they will handle issues better than policy-makers.
- Mistrust towards politicians and the government: The argument reflects distrust in politicians or institutions (e.g., inefficiency, incompetence, corruption).

### Special Cases:
- If the response is **gibberish** or **not related** to the question, classify it as: Not related.
- If the response is **I don't know** or similar, classify it as: I do not know.
Try not to classify responses as *Not related* or *I do not know* unless you really have no other possibility. Some answers may be very short or poorly written, or may not mention AI or automation explicitly—still, by interpreting their meaning, they may fall within one of the main categories.

### Hard-to-Classify Examples (Still Classifiable):
| Response | Classification |
|-------------------------------------------|----------------------------------------------|
| "L'economia declinerà"                    | Labour                                       |
| "impostare controlli"                     | Security                                     |
| "Non è positivo per la nostra società"    | Humanity                                     |
| "Perché ci sono già troppe politiche"         | Mistrust towards politicians and the government |
| "non è affar loro"                        | Mistrust towards politicians and the government |
| "Decisioni aziendali"                     | Market                                       |
| "Dobbiamo andare avanti verso il futuro"  | Confidence in automation and AI              |
| "Diffonde disinformazione"                | Security                                     |

### Regular Examples:
| Response | Classification |
|-----------------------------------------------------|----------------------------------------------|
| "Perché porterà via il lavoro a tutti" | Labour |
| "Penso sia meglio che lascino fare alle aziende ciò che vogliono" | Market |
| "Non lo so."| I do not know |
| "I politici non sono ingegneri"| Mistrust towards politicians and the government |
| "Dovrebbero: potrebbe distruggere la Terra e la civiltà umana" | Security |
| "Noi persone siamo più intelligenti e compassionevoli delle macchine." | Humanity |

### Output Format:
Your response should contain **only the classification**, with no extra text or comments.  
**Example Output:** Labour
**Example Output:** Mistrust towards politicians and the government
"""
df_it["classification"] = ""
for idx, user_input in enumerate(df_it["argument"]):
    messages = [
        format_message("system", class_inst_it),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_it.at[idx, "classification"] = response

df_it.to_excel("arguments_classified_it.xlsx", index=False)


# T: do the classification for Germany
class_inst_de = """
Below is the description of a coding exercise. The input consists of answers in **GERMAN** to the following open-ended survey question:  

*"Please write down two arguments (one for each field) as to why, in your opinion, policy-makers should or should not intervene on automation and AI."*  

Since these responses come from survey participants, they may be incomplete or poorly written.

### Classification Task:
Classify each argument according to its main theme:

**Negative themes**:
- Labour: The response focuses on the negative impact of automation and AI on jobs, wages, working conditions, or other labour-related concerns.
- Security: The response concerns risks related to safety, surveillance, privacy, or broader existential threats.
- Humanity: The response focuses on considering AI/automation as fundamentally corrupting humanity and human values (e.g. making humans less intelligent, more lazy, reducing social interactions).
- Regulation: The response focuses on the need for regulation and intervention by policy-makers.
- Mistrust towards AI companies: The argument reflects distrust in AI companies (e.g., profit motives, lack of transparency, collusion).

**Positive themes**:
- Confidence in automation and AI: The argument suggests AI/automation is beneficial or at least not harmful and that, because of that, intervention is unnecessary.
- Market: The response defends market forces, suggesting they will handle issues better than policy-makers.
- Mistrust towards politicians and the government: The argument reflects distrust in politicians or institutions (e.g., inefficiency, incompetence, corruption).

### Special Cases:
- If the response is **gibberish** or **not related** to the question, classify it as: Not related.
- If the response is **I don't know** or similar, classify it as: I do not know.
Try not to classify responses as *Not related* or *I do not know* unless you really have no other possibility. Some answers may be very short or poorly written, or may not mention AI or automation explicitly—still, by interpreting their meaning, they may fall within one of the main categories.

### Hard-to-Classify Examples (Still Classifiable):
| Response | Classification |
|-------------------------------------------|----------------------------------------------|
| "Die Wirtschaft wird zurückgehen"         | Labour                                       |
| "Kontrollen einrichten"                   | Security                                     |
| "Es ist nicht gut für unsere Gesellschaft" | Humanity                                    |
| "Weil es zu viele Vorschriften gibt"      | Mistrust towards politicians and the government |
| "Das geht sie nichts an"                  | Mistrust towards politicians and the government |
| "Unternehmensentscheidung"                | Market                                       |
| "Wir müssen in die Zukunft voranschreiten" | Confidence in automation and AI             |
| "Verbreitet Fehlinformationen"            | Security                                     |

### Regular Examples:
| Response | Classification |
|-----------------------------------------------------|----------------------------------------------|
| "Weil es allen die Arbeit wegnehmen wird"          | Labour                                       |
| "Ich denke, sie sollten den Unternehmen freie Hand lassen" | Market                                 |
| "Ich weiß es nicht."                               | I do not know                                |
| "Politiker sind keine Ingenieure"                 | Mistrust towards politicians and the government |
| "Sollte: könnte die Erde und die menschliche Zivilisation zerstören" | Security                     |
| "Wir Menschen sind klüger und mitfühlender als Maschinen." | Humanity |

### Output Format:
Your response should contain **only the classification**, with no extra text or comments.  
**Example Output:** Labour
**Example Output:** Mistrust towards politicians and the government
"""
df_de["classification"] = ""
for idx, user_input in enumerate(df_de["argument"]):
    messages = [
        format_message("system", class_inst_de),
        format_message("user", user_input),
    ]
    response = get_response(messages)
    df_de.at[idx, "classification"] = response

df_de.to_excel("arguments_classified_de.xlsx", index=False)
