# 📧 Email Analysis Project

An AI-powered pipeline for analyzing telecom industry emails using LLM prompt engineering. The project ingests a structured JSON dataset of emails, sends them through a customizable prompt layer to an external AI API, and writes structured analysis results — including extracted images — to an output directory.

> **Repository:** [github.com/T0nY-IV/Email_Analysis_Project](https://github.com/T0nY-IV/Email_Analysis_Project)

---

## 📁 Project Structure

```
Email__Analysis/
├── api.py                        # Entry point — runs the full analysis pipeline
├── api_methodes.py               # API helper methods and request utilities
├── prompt.py                     # Prompt templates for LLM-based email analysis
├── dataset_telecom.json          # Input dataset of telecom emails
└── emails_output/                # Generated output (auto-created on run)
    ├── email_9585.txt
    ├── email_9586.txt
    ├── ...
    ├── email_9599.txt
    └── images/
        └── <email_id>/           # Images extracted per email
            └── 1.jpg
```

---

## ⚙️ How It Works

The pipeline runs in three stages:

1. **Load** — `api.py` reads email records from `dataset_telecom.json`
2. **Analyze** — each email is passed through the prompt templates in `prompt.py` and sent to the LLM API via the methods in `api_methodes.py`
3. **Save** — results are written to `emails_output/email_<id>.txt`; images found in emails are saved to `emails_output/images/<id>/`

---

## 🚀 Getting Started

### Prerequisites

- Python 3.8+
- A valid API key for your LLM provider (e.g., OpenAI, Anthropic, etc.)

### Installation

```bash
git clone https://github.com/T0nY-IV/Email_Analysis_Project.git
cd Email_Analysis_Project
pip install -r requirements.txt
```

### Configuration

Set your API key as an environment variable:

```bash
export API_KEY="your_api_key_here"
```

Or place it in a `.env` file at the project root:

```
API_KEY=your_api_key_here
```

### Run

```bash
python api.py
```

---

## 📂 Dataset Format

`dataset_telecom.json` contains telecom-domain email records. Each entry should include at minimum an ID and email content. Example structure:

```json
[
  {
    "id": 9585,
    "subject": "Network outage report - Region 4",
    "body": "...",
    "attachments": []
  }
]
```

---

## 📤 Output

For each processed email, the pipeline produces:

| Output | Description |
|--------|-------------|
| `emails_output/email_<id>.txt` | LLM-generated analysis result for the email |
| `emails_output/images/<id>/*.jpg` | Images extracted from emails with attachments |

---

## 🗂️ Module Overview

### `api.py`
The main script. Loads the dataset, iterates over email records, and coordinates the full analysis and output pipeline.

### `api_methodes.py`
Contains helper functions for communicating with the external AI/LLM API — handling request formatting, response parsing, error handling, and any rate limiting logic.

### `prompt.py`
Defines the prompt templates used to instruct the LLM on how to analyze each email (e.g., summarization, classification, entity extraction, tone detection).

---

## 🤝 Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

Open source. See the repository for full license details.
