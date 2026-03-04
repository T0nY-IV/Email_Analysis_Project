# Email Analysis API

FastAPI service for enterprise email analysis using a Retrieval-Augmented Generation (RAG) pipeline.

The system:
- reads an input email from a text file,
- retrieves relevant context from a local dataset,
- asks a local LLM (Ollama) to classify the email,
- returns a strict JSON output,
- appends result data to the dataset.

## What This Project Solves

This API classifies professional emails into workflow categories and extracts structured attributes.

Current main workflow prompt (`prompt_orange`) returns:

```json
{
  "email_id": "string",
  "workflow_type": "Réclamation|Demande|other",
  "attributes": {},
  "confidence_score": 0.0
}
```

## Project Structure

- `api.py`: FastAPI app, RAG initialization, query endpoint, health/status endpoints.
- `api_methodes.py`: utility methods for loading data, chunking text, and saving outputs.
- `prompt.py`: prompt templates (`prompt_1`, `prompt_2`, `murged_prompt`, `prompt_orange`).
- `dataset_telecom.json`: source corpus and (currently) output storage file.
- `emails_output/`: example email files used as API inputs.

## Code Walkthrough

### `api.py`

#### Global in-memory state
The API keeps these objects in memory after initialization:
- `embedding_model`
- `client`
- `collection`
- `document_text`
- `chunks`
- `embeddings`

This design avoids recomputing embeddings on each request.

#### Request model
`QueryRequest` (Pydantic) expects:

```json
{
  "email_file": "path/to/email.txt"
}
```

#### `POST /initialize`
This endpoint prepares the RAG system:
1. Load embedding model: `SentenceTransformer("all-MiniLM-L6-v2")`.
2. Load corpus from `dataset_telecom.json` using `load_document`.
3. Split text into chunks of size `500` using `chunk_text`.
4. Compute embeddings for all chunks.
5. Create a local Chroma client and recreate collection `my_docs`.
6. Insert all chunks and vectors into Chroma.

Returns status and number of chunks.

#### `POST /query`
This endpoint processes one email:
1. Verify system is initialized.
2. Build query embedding from `prompt_orange`.
3. Retrieve top `5` similar chunks from Chroma.
4. Read email text from `request.email_file`.
5. Build `augmented_prompt` with:
   - retrieved context,
   - prompt instructions,
   - email content.
6. Call Ollama:
   - model: `qwen3:1.7b`
   - API: `ollama.chat(...)`
7. Parse returned text as JSON (`json.loads`).
8. Save pair `(input_email, output_json)` into dataset via `save_to_dataset`.
9. Return JSON response directly.

#### `GET /health`
Simple online check + initialized flag.

#### `GET /status`
Debug/status info:
- embedding model loaded,
- database initialized,
- chunk count,
- document loaded.

### `api_methodes.py`

#### `load_document(path)`
Reads the whole file and returns text.

#### `chunk_text(text, chunk_size=500)`
Splits text into fixed-size sequential chunks.

#### `save_to_dataset(input_email, output_data)`
Appends one new record to `dataset_telecom.json`:

```json
{
  "input_email": "...",
  "output": {"...": "..."}
}
```

Behavior details:
- If file is missing: starts a new list.
- If JSON is invalid: resets to empty list.
- Writes full file back with `indent=2` and `ensure_ascii=False`.

### `prompt.py`

You defined multiple prompt strategies:
- `prompt_1`: single domain + single intent schema.
- `prompt_2`: multi-domain + multi-intent schema.
- `murged_prompt`: richer merged schema with strict rules.
- `prompt_orange`: workflow classification (`Réclamation` / `Demande`) with allowed attribute keys.

Current API query flow uses **`prompt_orange`**.

## Methods Used (Technical Approach)

1. Retrieval-Augmented Generation (RAG)
- Retrieve relevant context from dataset before generation.
- Helps reduce hallucination and steer output to business context.

2. Semantic Embedding
- Model: `all-MiniLM-L6-v2`.
- Converts chunks and query into vectors for similarity search.

3. Vector Search with ChromaDB
- Store chunks + embeddings in collection `my_docs`.
- Query top-k similar chunks (`n_results=5`).

4. Prompt Engineering with Strict JSON Schema
- Prompt enforces a fixed output structure.
- Includes business rules and allowed keys.

5. JSON Post-processing + Persistence
- Model output is parsed with `json.loads`.
- Parsed result is persisted for future analysis.

## Requirements

- Python 3.10+
- Ollama installed and running locally
- Pulled model:

```bash
ollama pull qwen3:1.7b
```

Install dependencies:

```bash
pip install fastapi uvicorn pydantic ollama sentence-transformers chromadb
```

## Run the API

```bash
python api.py
```

Or:

```bash
uvicorn api:app --host 127.0.0.1 --port 8086 --reload
```

Base URL: `http://127.0.0.1:8086`

## API Usage

### 1) Initialize

```bash
curl -X POST http://127.0.0.1:8086/initialize
```

### 2) Query one email

```bash
curl -X POST http://127.0.0.1:8086/query \
  -H "Content-Type: application/json" \
  -d "{\"email_file\":\"emails_output/email_9599.txt\"}"
```

### 3) Check service

```bash
curl http://127.0.0.1:8086/health
curl http://127.0.0.1:8086/status
```

## Important Notes

- `persist_dir` in `api.py` is hard-coded to:
  - `D:\studying\3eme info(DSI33)\PFE\chroma_db`
- `dataset_telecom.json` is used both as:
  - initialization corpus,
  - output log of new predictions.
- `/query` fails if Ollama returns non-JSON content.
- CORS allows all origins (`*`).

## Quick End-to-End Flow

1. Start Ollama and pull model.
2. Start API.
3. Call `/initialize` once.
4. Call `/query` with an email file path.
5. Output JSON is returned and appended to `dataset_telecom.json`.
