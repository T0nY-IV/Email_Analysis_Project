# Email Analysis & Management System

A complete email analysis pipeline for telecom customer service that automatically processes incoming emails, classifies them using AI, and stores structured results for workflow management.

## Overview

This project provides an end-to-end solution for:

1. **Email Ingestion** - Fetches emails from an IMAP server (Gmail) and extracts content + attachments
2. **Email Analysis** - Uses RAG (Retrieval-Augmented Generation) with a local LLM to classify emails
3. **Structured Storage** - Saves analysis results in JSON and Excel formats

## Architecture

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│                  │     │                  │     │                  │
│  email_refresher │────▶│    api.py        │────▶│  dataset_telecom │
│  (IMAP fetch)    │     │  (FastAPI + RAG) │     │   (JSON storage) │
│                  │     │                  │     │                  │
└──────────────────┘     └──────────────────┘     �──────────────────┘
                                      │
                                      ▼
                            ┌──────────────────┐
                            │                  │
                            │  emails_output   │
                            │  (Excel + Attach)│
                            │                  │
                            └──────────────────┘
```

## What This Project Solves

This system automates the classification of professional emails into two workflow types:

- **Réclamation** (Complaint) - Emails expressing dissatisfaction or reporting problems
- **Demande** (Request) - Emails requesting services, information, or actions

It extracts structured attributes like contact information, product details, and location data to enable automated ticket creation or routing.

## Project Structure

```
Email__Analysis/
├── api.py                 # FastAPI server with RAG pipeline
├── api_methodes.py        # Utility functions for data processing
├── prompt.py              # LLM prompt templates
├── mail_analyser.py       # Email processing and API integration
├── email_refresher.py     # IMAP mailbox watcher
├── dataset_telecom.json   # Corpus and results storage
├── .env                   # IMAP credentials (not included)
└── emails_output/
    ├── emails.xlsx        # Processed emails index
    └── images/            # Extracted image attachments
        ├── {uid1}/
        └── {uid2}/
```

## Requirements

- Python 3.10+
- Ollama installed and running locally
- Gmail account with IMAP access enabled
- API dependencies

Install dependencies:

```bash
pip install fastapi uvicorn pydantic ollama sentence-transformers chromadb pandas python-dotenv openpyxl imaplib
```

## Setup

### 1. Configure Environment

Create a `.env` file in the project root:

```env
mail_@=your-email@gmail.com
mail_code=your-app-password
```

> **Note**: Use an App Password for Gmail (generate one in Google Account settings > Security > 2-Step Verification > App passwords).

### 2. Pull LLM Model

```bash
ollama pull qwen3:1.7b
```

### 3. Run the System

#### Option A: Run Both Components Together

```bash
python email_refresher.py
```

This will:
- Initialize the RAG system
- Check for new emails every 60 seconds
- Process each new email through the analysis API
- Save results to Excel

#### Option B: Run Components Separately

**Terminal 1 - Mail Watcher:**
```bash
python email_refresher.py
```

**Terminal 2 - API Server (optional, for direct API access):**
```bash
python api.py
# or
uvicorn api:app --host 127.0.0.1 --port 8086 --reload
```

## Usage

### Email Flow

1. **Email arrives** in Gmail inbox
2. **email_refresher.py** detects new email via IMAP
3. Email content is **extracted** and saved to `emails_output/emails.xlsx`
4. **mail_analyser.py** sends email to API for analysis
5. API returns **structured classification** and saves to `dataset_telecom.json`

### Direct API Usage

#### Initialize RAG System

```bash
curl -X POST http://127.0.0.1:8086/initialize
```

#### Analyze an Email

```bash
curl -X POST http://127.0.0.1:8086/query \
  -H "Content-Type: application/json" \
  -d "{\"email_content\": \"Email text to analyze...\"}"
```

#### Check Status

```bash
curl http://127.0.0.1:8086/health
curl http://127.0.0.1:8086/status
```

## Output Format

### Analysis Response

```json
{
  "email_id": "9885",
  "workflow_type": "Réclamation",
  "attributes": {
    "titre": "Incident lié à Forfait 4G Max",
    "date": null,
    "tel": "26555363",
    "email": "client1@mail.com",
    "etat": "Ouvert",
    "description": "Malgré plusieurs redémarrages...",
    "produit": "Forfait 4G Max",
    "site": "Gabès"
  },
  "confidence_score": 0.88
}
```

### Dataset Structure (`dataset_telecom.json`)

```json
[
  {
    "input_email": "Original email content...",
    "output": {
      "email_id": "...",
      "workflow_type": "...",
      "attributes": {...},
      "confidence_score": 0.0
    }
  }
]
```

### Excel Output (`emails_output/emails.xlsx`)

| UID  | Email Content                                  | Attachments           |
|------|------------------------------------------------|-----------------------|
| 9885 | From:...Subject:...Body:...                   | file1.jpg; file2.pdf  |

## Prompt Engineering

The system uses `prompt_orange` from `prompt.py` which:

- Classifies emails into `Réclamation` or `Demande` workflows
- Extracts workflow-specific attributes:
  - **Réclamation**: `titre`, `date`, `tel`, `email`, `etat`, `description`, `produit`, `site`
  - **Demande**: `date`, `description`, `produit`, `site`, `email`, `tel`, `type`

## Technical Details

### RAG Pipeline

1. **Embedding Model**: `all-MiniLM-L6-v2` (SentenceTransformers)
2. **Vector Database**: ChromaDB with local persistence
3. **LLM**: `qwen3:1.7b` via Ollama
4. **Chunk Size**: 500 characters
5. **Retrieval**: Top 5 similar chunks from corpus

### Attribute Extraction Rules

- Values must be extracted **exactly** from email content
- Only allowed attribute keys can be returned
- Missing attributes return `null` (not omitted)
- `confidence_score` is a float between 0.0 and 1.0

## Notes

- The `persist_dir` for ChromaDB is set to `./chroma_db` (local folder)
- `dataset_telecom.json` serves as both initial corpus and growing result log
- The system skips already-processed emails using UID tracking
- HTML content is stripped from email bodies
- Attachments (including images) are saved to `emails_output/images/{uid}/`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| API returns 400 | Call `/initialize` first |
| JSON parse error | Verify Ollama model is running |
| IMAP login failed | Check App Password settings |
| Missing UIDs | Delete Excel file and restart |

## Development

### Adding New Prompt Templates

1. Add a new prompt in `prompt.py`
2. Update `api.py` to use the new prompt
3. Update API documentation

### Modifying Attribute Schema

1. Edit `prompt_orange` in `prompt.py`
2. Adjust allowed attributes for each workflow type
3. Re-initialize the RAG system
