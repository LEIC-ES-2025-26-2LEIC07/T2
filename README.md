<!-- Template file for README.md for LEIC-ES-2025-26 -->

# _ClinicGO_ Development Report

Welcome to the documentation of _ClinicGO_!

This Software Development Report, tailored for LEIC-ES-2025-26, provides comprehensive details about _ClinicGO_, starting from an high-level vision and going into low-level implementation decisions. 

It is organised by the following activities: 

* [Development Environment](#Development-Environment)
  * [Prerequisites](#Prerequisites)
  * [Environment Variables](#Environment-Variables)
  * [Running the App](#Running-the-App)
  * [Running Tests](#Running-Tests)
* [Business modeling](#Business-Modelling) 
  * [Product Vision](#Product-Vision)
  * [Features and Assumptions](#Features-and-Assumptions)
* [Requirements](#Requirements)
  * [User stories](#User-stories)
  * [Domain model](#Domain-model)
  * [User interfaces](#User-interfaces)
* [Architecture and Design](#Architecture-And-Design)
  * [Logical architecture](#Logical-Architecture)
  * [Physical architecture](#Physical-Architecture)
  * [Functional prototype](#Functional-Prototype)
* [Project management](#Project-Management)
  * [Sprint 0](#Sprint-0)
  * [Sprint 1](#Sprint-1)
  * [Sprint 2](#Sprint-2)
  * [Sprint 3](#Sprint-3)
  * [Final Release](#Final-Release)

Contributions are expected to be made exclusively by the initial team, but we may open them to the community, after the course, in all areas and topics: requirements, technologies, development, experimentation, testing, etc.

Please contact us!

Thank you!


[David Ferreira](https://github.com/Dab1d)

[Guilherme Silva](https://github.com/guizas-LA)

[Tomás Silva](https://github.com/tomi-LA)

[João Maia](https://github.com/JoaooM26)  

[Pedro Meireles](https://github.com/JoaooM26)


---
## Development Environment

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Flutter](https://docs.flutter.dev/get-started/install) | stable channel | Framework and SDK |
| [Dart](https://dart.dev/get-dart) | ≥ 3.11.3 | Bundled with Flutter |
| [Git](https://git-scm.com/) | any recent | Version control |
| Android Studio / Xcode | latest | Android / iOS targets |
| A connected device or emulator | — | Run and debug |

> **Verify your installation** with `flutter doctor`. All required items must show a green checkmark before proceeding.

### Environment Variables

The app reads credentials at runtime from a `.env` file in the project root.

1. Create `.env` by copying the template:

```bash
cp .env.example .env   # if .env.example exists, otherwise create it manually
```

2. Fill in the two required keys:

```env
NEXT_PUBLIC_SUPABASE_URL=<your-supabase-project-url>
SB_PV_KEY=<your-supabase-anon-or-service-role-key>
```

Both values can be found in the Supabase dashboard under **Project Settings → API**.

> The `.env` file is declared as a Flutter asset in `pubspec.yaml` and loaded at startup via `flutter_dotenv`. Do **not** commit it — it is (or should be) listed in `.gitignore`.

### Running the App

```bash
# 1. Clone the repository
git clone <repo-url>
cd Application

# 2. Install Dart/Flutter dependencies
flutter pub get

# 3. Launch on a connected device or emulator (debug mode)
flutter run

# 4. Target a specific platform explicitly
flutter run -d android
flutter run -d ios
flutter run -d linux
flutter run -d web
```

### Running Tests

```bash
# All widget/unit tests (no backend required)
flutter test

# With coverage report
flutter test --coverage

# Integration tests (requires a real device/emulator and a populated .env)
flutter test --dart-define-from-file=.env integration_test/app_test.dart
```

## Business Modelling

The Goal that was proposed to us for this project was creating an app that aligns with the sustainable development goals [(SDGs)](https://www.eca.europa.eu/en/sustainable-development-goals) is a meaningful and impactful way to contribute to global challenges, in a FEUP-centric setting, that may be expanded to other faculties, possibly universities.
As such, we have arrived at a central theme:
- Tracking daily medications, accessing exam results, and simplifying the process of reading medication leaflets, all within a simple and intuitive mobile app, for example.

### Product Vision

For patients who struggle to keep **track** of their medications, exam results, and clinical history, who need a **simple** and **reliable** way to manage their health information on the go, **ClinicGO** is a mobile health **companion** app that centralizes medication reminders, exam results, and medical records in **one** place. Unlike scattered paper records or generic reminder apps, our product gives patients a clear, personalized, and accessible view of their own health **anytime, anywhere**.

### The Problem

In today's fast-paced world, patients often struggle to keep **track** of their health information. Medication schedules are missed, exam results are lost in paper folders, and accessing clinical history through official portals is often slow and unintuitive. This disorganization can lead to missed doses, delayed diagnoses, and poor health outcomes. There is currently no simple, unified solution that brings all of this together in a patient-friendly way.

ClinicGO addresses this by promoting proactive health management, aligning with two key **Sustainable Development Goals**:

- **[(SDG 3)](https://www.eca.europa.eu/en/sustainable-development-goals): Good Health and Well-being** — By helping patients stay on top of their medication schedules and health records, ClinicGO contributes to better health outcomes and improved quality of life.
- **[(SDG 10)](https://www.eca.europa.eu/en/sustainable-development-goals): Reduced Inequalities** — By simplifying access to personal health information, ClinicGO makes healthcare management more accessible to all patients, regardless of digital literacy or technical background.

#### Target Audience

ClinicGO is designed for anyone who needs to actively manage their health, including:

- Patients with chronic conditions who take multiple medications daily and need reliable reminders.
- Elderly individuals or their caregivers who need a simple way to track health records and appointments.
- Young adults who want a modern, mobile-first alternative to paper prescriptions and hospital portals.
<!-- 
The vision should provide a "high concept" of the product for marketers, developers, and managers.

A product vision describes the essential of the product and sets the direction to where a product is headed, and what the product will deliver in the future. 

**We favor a catchy and concise statement, ideally one sentence.**

We suggest you use the product vision template described in the following link:
* [How To Create A Convincing Product Vision To Guide Your Team, by uxstudioteam.com](https://uxstudioteam.com/ux-blog/product-vision/)

To learn more about how to write a good product vision, please read:
* [Vision, by scrumbook.org](http://scrumbook.org/value-stream/vision.html)
* [Product Management: Product Vision, by ProductPlan](https://www.productplan.com/glossary/product-vision/)
* [20 Inspiring Vision Statement Examples (2019 Updated), by lifehack.org](https://www.lifehack.org/articles/work/20-sample-vision-statement-for-the-new-startup.html)
-->


### Features and Assumptions
<!-- 
Indicate an  initial/tentative list of high-level features - high-level capabilities or desired services of the system that are necessary to deliver benefits to the users.
 - Feature XPTO - a few words to briefly describe the feature
 - Feature ABCD - ...
...

Optionally, indicate an initial/tentative list of assumptions that you are doing about the app and dependencies of the app to other systems.
-->
#### High-level Features
- **Medication Management (Core)**: Initial setup (Add medication), editing, and deleting medications. Manual tracking ("Mark dose as taken") and visual control of pill inventory via a progress bar (Stock).
<!-- - **AI & Vision Integration**: Use of the native camera with photo preview and sharpness verification (Blur check) to send images to an LLM/Vision API (e.g., to read prescriptions or identify medication boxes). Includes an interactive Chat per medication and the mandatory presentation of a Medical Disclaimer (AI).
-->
- **Reminders & Resilient Scheduling**: Notification system for dose reminders and missed dose alerts. Includes an offline mode (Schedule) that ensures alarms trigger locally even without internet access.
- **Health Tracking**: Functionalities to log symptoms, view the user's medical history, analyze a monthly summary (Analytics), and schedule appointments.
- **Security & Authentication**: Secure Login and Logout flows managed via Supabase Auth. Includes secure profile sharing (e.g., with family members or doctors) through a temporarily generated 6-digit code.
- **Emergency & Location**: Integrated emergency alerts and a real-time map (potentially for locating on-duty pharmacies or nearby hospitals).
- **UI/UX & Navigation**: Fluid navigation based on a Bottom Navigation Bar and intuitive screen flows (e.g., Home -> Profile navigation).
- **Auxiliary Tools**: Practical day-to-day management through a Shopping list (focused on pharmacy and health supplies).

#### Assumptions

- **Local Notification Dependency**: The application relies on the mobile operating system's capability to deliver reliable and timely push notifications, ensuring reminders work consistently even offline.
<!-- - **LLM/Vision API Availability**: It is assumed that there is a reliable external API for computer vision and LLM capabilities for the AI features context.
-->
- **Supabase Integration**: The app's authentication and secure token generation rely on Supabase backend services.
- **Location Services**: Emergency alerts and map functionality assume the user grants the app proper location tracking/GPS permissions.


## Requirements

### User Stories
<!-- 
In this section you should describe all kinds of requirements for your module: functional and non-functional requirements.

For LEIC-ES-2025-26, the requirements will be gathered and documented as user stories. 

Please add in this section a concise summary of all the user stories (not each user story!).

**User stories as GitHub Project Items**
The user stories themselves should be created and described as items in your GitHub Project with the label "user story". 

A user story is a description of a desired functionality told from the perspective of the user or customer. A starting template for the description of a user story is *As a < user role >, I want < goal > so that < reason >.*

Name the item with either the full user story or a shorter name (recommended). In the “comments” field, add relevant notes, mockup images, and acceptance test scenarios, linking to the acceptance tests when available, and finally estimate value and effort.

**INVEST in good user stories**. 
You may add more details after, but the shorter and complete, the better. In order to decide if the user story is good, please follow the [INVEST guidelines](https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/).

**User interface mockups**.
After the user story text, you should add a draft of the corresponding user interfaces, a simple mockup or draft, if applicable.

**Acceptance tests**.
For each user story you should write also the acceptance tests (textually in [Gherkin](https://cucumber.io/docs/gherkin/reference/)), i.e., a description of scenarios (situations) that will help to confirm that the system satisfies the requirements addressed by the user story.

**Value and effort**.
At the end, it is good to add a rough indication of the value of the user story to the customers (e.g. [MoSCoW](https://en.wikipedia.org/wiki/MoSCoW_method) method) and the team should add an estimation of the effort to implement it using points in a kind-of-a Fibonnacci scale (1,2,3,5,8,13,20,40, no idea).

-->



The following table provides a concise summary of all the user stories planned for the application. These are detailed individually in our **GitHub Project board.**

| ID         | User Story                   | Technical Justification                                          |
| :--------- | :--------------------------  | :--------------------------------------------------------------- |
| **#22**    | Bottom Navigation Bar       | Basic application routing structure.                             |
| **#28**    | Monthly Summary (Analytics) | Data aggregation and graphical visualization.                    |
| **#29**    | Mark Dose as Taken          | Simple update on the `medication_logs` table.                    |
| **#31**    | Shopping List               | Basic CRUD operations for a task list.                           |
| **#37**    | Home → Profile Navigation   | Simple state change in the router.                               |
| **#43**    | Missed Dose Notification    | Scheduled verification against dose logs.                        |
| **#44**    | Emergency Alerts            | Critical notification trigger with SMS/Email API integration.    |
| **#45/23** | Login (Supabase Auth)       | Standard authentication provider configuration.                  |
| **#46**    | Log Symptoms                | Simple form submission to the `symptoms` table.                  |
| **#47**    | Logout                      | Basic session termination implementation.                        |
| **#48**    | Schedule Appointments       | Integration with external calendar or appointment systems.       |
| **#49**    | Medical History             | Simple query with date-based filtering.                          |
| **#50**    | Real-Time Map               | Integration with a map/geolocation SDK.                          |
| **#51**    | Progress Bar (Stock)        | Simple calculations based on consumption logs.                   |
| **#52**    | Reminder Notification       | Local/remote push notification scheduling.                       |
| **#63**    | Add Medication (Setup)      | Complex CRUD with validations and business logic.                |
| **#64**    | Edit/Delete Medication      | Update/Delete operations with referential integrity constraints. |
| **#65**    | Offline Mode (Schedule)     | Local data synchronization (e.g., SQLite/WatermelonDB).          |
| **#66**    | 6-Digit Code (Sharing)      | Backend logic (RPC) and permission management.                   |
| **#67**    | Open Native Camera          | Standard hardware access and permission handling.                |
| **#68**    | Photo Preview (Blur Check)  | UI logic for real-time image validation.                         |
| **#69**    | Send to LLM/Vision API      | External API integration and image processing.                   |
| **#70**    | Medication Chat             | High complexity: message storage and querying.                   |

#### User Validation & Refinement

To ensure the **ClinicGO** application addresses real-world needs, we conducted a systematic validation phase involving potential target users. See more [here](docs/forms/validate.md)
### Domain model

<!-- 
To better understand the context of the software system, it is useful to have a simple UML class diagram with all and only the key concepts (names, attributes) and relationships involved of the problem domain addressed by your app. 
Also provide a short textual description of each concept (domain class). 

Example:
 <p align="center" justify="center">
  <img src="https://github.com/FEUP-LEIC-ES-2022-23/templates/blob/main/images/DomainModel.png"/>
</p>
-->
<img width="1493" height="804" alt="image" src="https://github.com/user-attachments/assets/0e53e2b7-62d6-47e2-a836-240879959088" />


The ClinicGO domain is centred around the **User** (patient), who has a personal
health profile containing their name, date of birth, and contact information.
A **User** can register multiple **Medications**, each defined by a name, dosage,
frequency, and treatment period (start and end dates). Each **Medication** can have
one or more **Reminders**, which schedule notifications at specific times and on
specific days of the week to alert the patient to take their medication.

Every time a **Reminder** fires, a **MedicationLog** entry is created, recording
whether the patient took the dose or missed it, along with the timestamp. This
allows the app to track medication adherence over time.

A **User** can also store **ExamResults**, which represent clinical documents such
as blood tests or imaging results. Each exam result contains the exam type, date,
a summary, an optional file attachment, and the name of the requesting doctor.


## Architecture and Design
<!--
The architecture of a software system encompasses the set of key decisions about its organization. 

A well written architecture document is brief and reduces the amount of time it takes new programmers to a project to understand the code to feel able to make modifications and enhancements.

To document the architecture requires describing the decomposition of the system in their parts (high-level components) and the key behaviors and collaborations between them. 

In this section you should start by briefly describing the components of the project and their interrelations. You should describe how you solved typical problems you may have encountered, pointing to well-known architectural and design patterns, if applicable.
-->


### Logical architecture
<!--
The purpose of this subsection is to document the high-level logical structure of the code (Logical View), using a UML diagram with logical packages, without the worry of allocating to components, processes or machines.

It can be beneficial to present the system in a horizontal decomposition, defining layers and implementation concepts, such as the user interface, business logic and concepts.
alvaroltor
Example of _UML package diagram_ showing a _logical view_ of the Eletronic Ticketing System (to be accompanied by a short description of each package):

![LogicalView](https://user-images.githubusercontent.com/9655877/160585416-b1278ad7-18d7-463c-b8c6-afa4f7ac7639.png)
-->
<div align="center" justify="center">
  <img width="1045" height="721" alt="image" src="https://github.com/user-attachments/assets/f1be4e62-f915-4e45-a2c2-6edd25ec6fdf" />

</div>
<br>
The logical architecture represents the high-level structure of the ClinicGO application, illustrating 
the main feature modules and their internal interactions based on the Model-View-ViewModel (MVVM) 
pattern. Each component's declarative UI (View) is strictly decoupled from data processing; 
it interacts solely with its corresponding presentation logic (ViewModel). This logic, in turn,
communicates with the core Domain Entities and Repositories. These repositories are linked to Supabase
for secure user authentication and cloud data storage, as well as to Local Storage to ensure offline 
functionality for critical features like medication reminders. For specific external integrations, 
the system relies on the Google Maps API to fetch and display real-time map data, and an LLM/Vision 
API to process images of prescriptions and medication boxes.

### Physical architecture
<!--
The goal of this subsection is to document the high-level physical structure of the software system (machines, connections, software components installed, and their dependencies) using UML deployment diagrams (Deployment View) or component diagrams (Implementation View), separate or integrated, showing the physical structure of the system.

It should describe also the technologies considered and justify the selections made. Examples of technologies relevant for ESOF are, for example, frameworks for mobile applications (such as Flutter).

Example of _UML deployment diagram_ showing a _deployment view_ of the Eletronic Ticketing System (please notice that, instead of software components, one should represent their physical/executable manifestations for deployment, called artifacts in UML; the diagram should be accompanied by a short description of each node and artifact):

![DeploymentView](https://user-images.githubusercontent.com/9655877/160592491-20e85af9-0758-4e1e-a704-0db1be3ee65d.png)
-->
<img src="docs/diagrams/physical.png">
The physical architecture outlines the main components of the ClinicGO application, illustrating 
not only how they connect with one another but also how they interact with external APIs and native 
hardware. Our application's core business logic and authentication features depend directly on Supabase
(PostgreSQL and Supabase Auth) to securely store, retrieve, and sync cloud data.
<br>
The application logic also communicates seamlessly with native OS capabilities, such as the device
camera for prescription scanning and the notification manager for local medication alerts. To guarantee our 
critical Offline Mode, a Local Storage solution (such as SQLite or Hive) is responsible for saving and retrieving 
schedule data directly on the user's device. Finally, the location services depend on the Google Maps API to
retrieve relevant geolocation data, while an external LLM/Vision API is utilized to process and analyze images of
medication boxes and clinical documents.

### Functional prototype
<!--
To help on validating all the architectural, design and technological decisions made, we usually implement a functional prototype, a thin vertical slice of the system integrating as much technologies as we can.

In this subsection please describe which feature, or part of it, you have implemented, and how, together with a snapshot of the user interface, if applicable.

At this phase, instead of a complete user story, you can simply implement a small part of a feature that demonstrates thay you can use the technology, for example, show a screen with the app credits (name and authors).
-->
To validate our architectural decisions and technology stack, we implemented a thin vertical slice of the ClinicGO application focused on Core Navigation and UI Structure.

We developed the foundational application skeleton using Flutter. This prototype successfully demonstrates the implementation of the primary routing architecture anchored on a BottomNavigationBar (addressing User Story #22). It showcases the dynamic state changes required to switch seamlessly between the main functional modules of the application (Profile, Health/Favorites, Home, Schedule, and Settings).

This prototype proves that our Flutter development environment is fully operational, cross-platform compilation is working properly, and the base View layer is structurally ready to be decoupled and connected to our ViewModels.

Below is an animated snapshot of the functional prototype in action:
<br>
<div align="center" justify="center">
<img src="docs/gifs/vertical.gif">
</div>

## Project management
<!--
Software project management is the art and science of planning and leading software projects, in which they are planned, implemented, monitored and controlled.

In the context of ESOF, we recommend each team to adopt a set of project management practices and tools capable of registering tasks, assigning tasks to team members, adding estimations to tasks, monitor tasks progress, and therefore being able to track their projects.

Common practices of managing agile software development with Scrum are: backlog management, release management, estimation, Sprint planning, Sprint development, acceptance tests, and Sprint retrospectives.

You can find below information and references related with the project management: 

* Backlog management: Product backlog and Sprint backlog in a [Github Projects board](https://github.com/orgs/FEUP-LEIC-ES-2023-24/projects/64);
* Release management: [v0](#), v1, v2, v3, ...;
* Sprint planning and retrospectives: 
  * plans: screenshots of Github Projects board at begin and end of each Sprint;
  * retrospectives: meeting notes in a document in the repository, addressing the following questions:
    * Did well: things we did well and should continue;
    * Do differently: things we should do differently and how;
    * Puzzles: things we don’t know yet if they are right or wrong;
    * list of a few improvements to implement next Sprint;

-->
***

You can find below information and references related to the project management practices and tools utilized by our team:

* **Backlog Management:** Both the Product Backlog and Sprint Backlog are actively managed within our GitHub Projects Board.
* * **Release Management:** Version tracking begins with [v0](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/releases/tag/v0), followed by v1, v2, v3...
* **Sprint Planning & Retrospectives:** Planning and retrospective documentation is maintained for Sprint 0, Sprint 1, Sprint 2, Sprint 3, and the Final Release.
* **Happiness Meters:** We track team morale using a [Happiness Meter](https://docs.google.com/spreadsheets/d/1Dd4dCzsbW1eqSfxNmsqDLT0UyNPI31Aicefy5qclR7k/edit?usp=sharing). Each member fills out the column associated with their designated number (e.g., member M3 fills the third column).
* **Changelog:** We maintain a detailed changelog to track important changes in each released version. This follows the standard format specified at [Chanellog](CHANGELOG.md)).
* **Git Workflow:** We follow a feature-branch workflow branching off `main`. Each feature or bug fix is developed on its own dedicated branch and integrated via a Pull Request (PR). Code reviews are mandatory and enforced using branch protection rules to ensure code quality and consistency.
* **CI/CD (GitHub Actions):** Every Pull Request automatically triggers a GitHub Actions workflow that verifies code formatting and enforces linting rules. This helps maintain a consistent codebase and prevents errors from reaching the main branch.

### Sprint 0

#### Project Board

<div align="center" justify="center">
  <p>Start of Sprint 0</p>
  <img src="docs/boards/sprint0/start.png">
  <p>End of Sprint 0</p>
  <img src="docs/boards/sprint0/end.png">
</div>

***

### Sprint 0 Retrospective

* **Did well:**
    * **Product Definition:** Successfully established a clear product vision and well-defined user stories for ClinicGO.
    * **Architecture Foundation:** Correctly organized the app’s structural foundations using the **MVVM pattern** and integrated **Supabase**.
    * **Tooling:** Initial setup of the GitHub Scrum board was effective for tracking technical requirements.

* **Do differently:**
    * **Team Balance & Participation:** **Improve workload distribution.** During this sprint, the team did not function at its best as the vast majority of the work was carried out by only a few members. We need to ensure everyone is actively contributing to avoid bottlenecks.
    * **Time Management:** Start iterations immediately to prevent "crunching" at the end of the sprint and to account for unexpected technical hurdles.
    * **Git Workflow:** Strictly enforce the use of feature branches and pull requests for every task to maintain code quality and visibility.
    * **Collaboration:** Schedule mandatory pair programming or sync sessions to help members who are struggling and to keep the whole team updated on progress.

* **Puzzles:**
    * **Remote Integration:** Finding the best way to coordinate and review code efficiently within our specific Git workflow.


### Sprint 1
---

<div align="center" justify="center">
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/efcaed02-e470-452a-be86-48606d606afd" />
  <p>Start of Sprint 1</p>
<img width="1856" height="956" alt="image" src="https://github.com/user-attachments/assets/9943e5f3-a8f8-446e-90d9-24363cadec65" />
  <p>End of Sprint 1</p>
</div>

* **Did well:**
  * The main user stories planned for the sprint were successfully completed, covering the core functionality of the application, including medication management, authentication improvements, and notification handling.
* **Do differently:**
  * **End-of-Sprint Pressure:** Several features were finalized close to the deadline, which led to tighter integration time and less opportunity for refinement and testing.
  * **Git Workflow Consistency:** Reinforce the consistent use of feature branches and pull requests for all changes to improve code review quality and reduce integration issues.
* **Puzzles:**
  * **Tech Stack Proficiency:** Ensuring the entire team becomes fully comfortable with **Flutter** and **Supabase**, in order to improve development speed and enable more balanced contribution across members.


### Sprint 2
---

<div align="center" justify="center">
<img width="897" height="956" alt="image" src="https://github.com/user-attachments/assets/7381f93d-c03f-42e3-891f-c2463672c3b9" />
  <p>Start of Sprint 2</p>
<img width="542" height="872" alt="image" src="https://github.com/user-attachments/assets/8264f90e-e56f-4bdd-852f-1ba0de9cf022" />
  <p>End of Sprint 2</p>
  </div>
  
* **Did well:**
    * **:** Balanced Workload: Significant improvement in team participation.
    * Task distribution was more equitable, ensuring that knowledge was shared and burnout was avoided.
    * **Enhanced Peer Review Culture:** The introduction of mandatory Pull Requests (PRs) was a success. Team members actively reviewed each other's code, leading to fewer bugs and a more unified coding style.
* **Do differently:**
  * **Persistent Time Management Issues:** We failed to avoid the "end-of-sprint crunch." Tasks were backloaded to the final days, causing unnecessary pressure and preventing thorough testing of the final features.

  * **Delayed Problem Signaling:** Because we didn't have the scheduled syncs, technical hurdles were often kept private for too long, creating bottlenecks that could have been solved through collaboration.

* **Puzzles:**
  * **Weekly Sync Session:** We will implement one 60-minute session per week dedicated to pair programming and progress alignment.


### Sprint 3

<div align="center" justify="center">
<img width="544" height="964" alt="image" src="https://github.com/user-attachments/assets/1ae3f8a4-ec18-4e7e-9f71-881ea8aff23d" />
  <p>Start of Sprint 3</p>
  <!--<p>End of Sprint 3</p> -->
  </div>


### Sprint 4

### Final Release
