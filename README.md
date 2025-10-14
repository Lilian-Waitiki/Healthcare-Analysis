<h1 align="middle">🩺 Healthcare Data Analysis (SQL Project)</h1>

## Project Overview
Hospital readmissions are a critical metric in evaluating healthcare quality, resource utilization, and patient outcomes. Frequent or short-interval readmissions often indicate gaps in post-discharge care, chronic or recurring conditions, or inefficiencies in treatment pathways. Understanding patterns in patient encounters, procedures, and readmissions can help healthcare providers improve continuity of care, optimize resource allocation, and enhance patient satisfaction.

This project focuses on analyzing hospital encounter and procedure data between **2011 - 2022** to answer key questions:
- Which patients experience readmissions within 30 days of a prior discharge?
- Who are the most frequently readmitted patients, and what procedures are associated with their care?
- What insights can be drawn from the procedures and readmission patterns to improve patient care and hospital efficiency?

By combining patient-level encounter data with procedure records, this analysis aims to identify trends, highlight high-risk patient groups, and provide actionable recommendations for reducing readmissions, supporting decision-making and improving healthcare delivery.

Original datasets used in this project can be found [here](https://mavenanalytics.io/data-playground/hospital-patient-records).

---
## Objectives
📋 **Encounters overview** - Assessing encounters in a given period of time.<br> 
💳 **Cost and coverage insights** - Average cost of given procedures and the how much the insurance can cover.<br>
🧍‍♀️ **Patient behaviour analysis** - Unique patients readmitted over time and how long each of them has stayed at the facility.<br>

---
## 🗂️Data Overview
- `encounters` - Patients encouters as they visit the hospital (27,891 entries)
- `organizations` - hospital details (1 entry)
- `patients` - patients demographic data (973 entries)
- `payers` - insurance payer data (10 entries)
- `procedures` - Patient procedure data including surgeries (47,701 entries)

---
## 📊Key Findings
- The analysis revealed important trends in hospital encounters and patient readmissions. Nearly **49% of encounters lacked payer coverage**, highlighting potential gaps in insurance access or billing processes.<br>
- About **773 unique patients experienced over 17,000 readmissions within 30 days**, suggesting chronic conditions or inadequate follow-up care. Several patients showed high-frequency readmissions, often associated with repeated procedures such as anxiety and depression assessments, dialysis, and cardiovascular treatments — pointing to ongoing health management needs.
- Overall, the results emphasize the importance of improved discharge planning, early intervention programs, and predictive monitoring to reduce preventable readmissions and enhance patient outcomes

For a detailed walkthrough of the analysis, key insights, and final recommendations, check out the notebook [here](https://github.com/Lilian-Waitiki/Healthcare-Analysis/blob/main/Analysis.ipynb) 

---
## 🛠️Tools used
![SQL](https://img.shields.io/badge/SQL-Data%20Analysis-4479A1?logo=mysql)
![Jupyter](https://img.shields.io/badge/Jupyter-Documentation-orange?logo=jupyter)
![MsExcel](https://img.shields.io/badge/Excel-Data%20Validation-217346?logo=microsoftexcel&logoColor=white)

