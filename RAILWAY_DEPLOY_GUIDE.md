# Deploying eeg_analyzer to Railway (Local Training Workflow)

## Overview

Since `reference_data.csv` is 250MB and exceeds GitHub's file size limit,
the workflow is: **train locally, commit the model files, deploy without
the training data.**

## One-time local setup

### 1. Train all models on your machine

```bash
cd eeg_analyzer
python eeg_ml.py all
```

This generates:
- `all_models.joblib` (in project root — used by the UI)
- `data/reference_model.joblib` (best single model)
- `data/cleaned_reference_data.csv` (preprocessed data)

### 2. Update your `.gitignore`

Make sure `.gitignore` includes the large CSV but DOES NOT exclude `.joblib` files:

```gitignore
# Large training data — do NOT push to GitHub
data/reference_data.csv

# Temp files
__pycache__/
*.pyc
.venv/
.env
*.results
```

**Important:** If your current `.gitignore` has `*.joblib`, remove that line.
The `.joblib` model files must be committed to the repo.

### 3. Commit the model files

```bash
git add all_models.joblib data/reference_model.joblib
git add data/cleaned_reference_data.csv   # only if needed by ui_app.py
git commit -m "Add pre-trained model files for deployment"
```

### 4. Modify `ui_app.py`

Change the `app.run(...)` line at the bottom to:

```python
import os

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5004))
    app.run(host="0.0.0.0", port=port, debug=False)
```

### 5. Add the 3 config files to repo root

- `Dockerfile`
- `railway.toml`
- `.dockerignore` (rename `dockerignore.txt` → `.dockerignore`)

### 6. Push and deploy

```bash
git add .
git commit -m "Add Railway deployment config"
git push origin master
```

Then in Railway:
1. Create new project → Deploy from GitHub repo
2. Select `mihirkodes/eeg_analyzer`
3. Railway auto-detects the Dockerfile and builds
4. Go to Settings → Networking → Generate Domain

---

## When the training data changes

Whenever `reference_data.csv` is updated, repeat the retrain-and-commit cycle:

```bash
# 1. Retrain locally with the updated CSV
python eeg_ml.py all

# 2. Commit the new model files
git add all_models.joblib data/reference_model.joblib
git commit -m "Retrain models with updated reference data"
git push origin master
```

Railway will auto-redeploy on push.

---

## What happens on each deploy

```
Build phase:
  1. Installs Python 3.11 + system deps
  2. pip installs requirements.txt
  3. Copies project files INCLUDING pre-trained .joblib models
  (No training happens in the cloud)

Run phase:
  1. Runs `python ui_app.py`
  2. Flask binds to 0.0.0.0:$PORT
  3. Railway routes your public URL to that port
```

## Troubleshooting

**`Error: Models file not found at all_models.joblib`:**
You forgot to commit the .joblib files. Run `python eeg_ml.py all` locally,
then `git add` and push the generated .joblib files.

**502 Bad Gateway after deploy:**
Check that `ui_app.py` binds to `0.0.0.0` and reads `PORT` from env vars.

**Build fails on scipy/numpy:**
The Dockerfile already installs gcc/g++. If you still see errors, try
changing the base image to `python:3.11` (full image) instead of `python:3.11-slim`.
