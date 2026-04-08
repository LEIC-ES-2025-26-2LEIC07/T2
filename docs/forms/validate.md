## User Validation & Product Backlog Refinement

To ensure the **ClinicGO** application addresses real-world needs, we conducted a systematic validation phase involving potential target users. The insights gathered allowed us to move from theoretical assumptions to data-driven prioritization.

### 1\. Methodology

  * **Tool:** [Google Forms Survey](https://docs.google.com/forms/d/e/1FAIpQLSfJ0W-RxdD0O8oZzp9hanjeIM6f-OkzDLtyhop-8tw81LdJnw/viewform)
  * **Sample Size:** 18 participants.
  * **Target Audience:** Patients with chronic conditions, regular medication users, and caregivers.
  * **Raw Data:** [Survey Results Spreadsheet](https://docs.google.com/spreadsheets/d/1nl9EoUUBjhV8yjf6ixOjKcavvCTISLB5inaz8bBpBSM/edit?usp=sharing)

### 2\. Key Findings & Analysis

The survey results highlighted three critical areas that reshaped our development strategy:

  * **The Criticality of Reminders:** **55% of respondents** identified "Medication Reminders" as the single most important feature. This confirmed that the app's core value is its reliability as a health assistant.
  * **Trust & Credibility Gaps:** We detected significant resistance from the senior demographic (65+). Concerns regarding the source of medical information and data privacy were prominent, highlighting a need for formal disclaimers and transparent policies.
  * **Simplicity as a Requirement:** Open-ended feedback repeatedly requested a "simple and practical design" and a "calendar view" to manage long-term schedules.

### 3\. Backlog Refinement (PBL Updates)

Based on the qualitative and quantitative data, we performed a **Backlog Refinement** session to reorder our Product Backlog Items (PBIs) and add new requirements:

#### ⬆️ Elevated Priority

  * **Offline Mode ([\#65](https://www.google.com/search?q=https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/65)):** Since reminders are the top priority, they must function without internet. This was moved to the top of our technical roadmap.
  * **Medical Disclaimer ([\#71](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/71)):** Increased priority to address the trust issues identified in the survey. It will now be part of the onboarding process.

#### 🆕 New Features Added

  * **UI Accessibility & Legibility (\#72):** A new task created to implement font scaling, high-contrast modes, and a simplified "Easy Mode" for senior users.
  * **Calendar Schedule View (\#73):** Added based on direct user requests for a more visual way to track medication history and upcoming doses.

#### ⬇️ Lowered Priority

  * **AI Chat per Medication ([\#70](https://www.google.com/search?q=https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/70)):** Rated as "low utility" by the majority of respondents compared to core reminders; moved to the "Future Releases" category.

### 4\. Conclusion

> "Through a survey of 18 potential users, we confirmed that ClinicGO’s core value lies in the **reliability of reminders**. We also discovered significant resistance from senior users regarding platform trust, which led us to elevate the priority of the **Medical Disclaimer ([\#71](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/71))** and add a new task for **UI Accessibility (\#72)** to ensure the design is inclusive and extremely simple."

-----
