> 🌐 **[Versión en Español](README.md)**
# ClarVision BI — Operational Intelligence for Ophthalmology Clinic

An end-to-end Business Intelligence system designed to reduce absenteeism and optimize operations in an ophthalmology clinic. Built with **MySQL**, **Power BI**, and automation powered by **n8n**.

---

## 📋 Business Problem

An ophthalmology clinic operates without visibility into its operational performance. Management has no way of knowing how many patients miss their appointments each week, which doctors are overworked, or when demand drops abnormally.

**Direct Impact:** Every missed appointment represents lost revenue, wasted physician time, and a decline in overall service quality.

---

## 💡 Solution

**ClarVision BI** is a comprehensive operational intelligence system that transforms raw appointment data into actionable decisions. The system tracks key performance indicators (KPIs) in real-time, identifies absenteeism patterns, and triggers automated alerts whenever an indicator crosses its critical threshold.

### Dashboard Preview
![Dashboard Preview](06_docs/dashboard_clarvision.png)

---

## 🛠️ Tech Stack

| Tool | Role |
| :--- | :--- |
| **MySQL 8.0** | Relational data modeling & primary storage |
| **MySQL Workbench** | Administration & analytical SQL queries |
| **Power BI Desktop** | Interactive dashboards & data visualization |
| **n8n** | Automated alerts & scheduled reporting workflows |
| **Slack** | Notification channel for management & staff |
| **Excel** | Data validation & preliminary exploration |
| **draw.io** | Data model architecture diagramming |

---

## 🏗️ System Architecture

```text
MySQL (clarvision_db)
        │
        ├── Analytical SQL Queries
        │         │
        │         ├── Power BI Dashboard (Visual KPIs)
        │         │
        │         └── n8n Workflows
        │                   │
        │                   ├── Critical Absenteeism Alert → Slack
        │                   └── Automated Weekly Report → Slack
        │
        └── Excel (Validation & Data Exploration)
