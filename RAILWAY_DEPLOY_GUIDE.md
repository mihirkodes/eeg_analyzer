# Deploying eeg_analyzer to Railway

## Files to add to your repo

Copy these 3 files into the root of your `eeg_analyzer` repo:

1. **`Dockerfile`** — builds the image, installs deps, trains models, runs Flask
2. **`railway.toml`** — tells Railway to use the Dockerfile
3. **`.dockerignore`** — keeps the image lean (rename `dockerignore.txt` to `.dockerignore`)

## One required code change in `ui_app.py`

Railway assigns a random port via the `PORT` environment variable and expects
your app to bind to `0.0.0.0`. Find the `app.run(...)` line at the bottom of
`ui_app.py` and change it to:

```python
import os

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5004))
    app.run(host="0.0.0.0", port=port, debug=False)
```

> **Important:** `debug=False` is required in production. Railway will not
> work if Flask is in debug/reloader mode.

## Deploy steps

1. Push the updated repo to GitHub (with the 3 new files + the `ui_app.py` change)
2. Go to [railway.app](https://railway.app) and create a new project
3. Choose **"Deploy from GitHub repo"** and select `mihirkodes/eeg_analyzer`
4. Railway will auto-detect the `Dockerfile` and start building
5. Once deployed, go to **Settings → Networking → Generate Domain** to get your public URL

## What happens on each deploy

```
Build phase (runs once per deploy):
  1. Installs Python 3.11 + system deps (gcc for scipy)
  2. pip installs everything in requirements.txt
  3. Runs `python eeg_ml.py all` → generates all_models.joblib + reference_model.joblib

Run phase (starts the server):
  1. Runs `python ui_app.py`
  2. Flask binds to 0.0.0.0:$PORT
  3. Railway routes your public URL to that port
```

## Estimated build time

The first build will take 3-5 minutes due to installing scipy, scikit-learn,
lightgbm, catboost, etc. Subsequent deploys use Docker layer caching and will
be faster unless requirements.txt changes.

## Troubleshooting

**Build fails on `eeg_ml.py all`:**
Make sure `data/reference_data.csv` is committed to your repo (not in `.gitignore`).

**App crashes with "address already in use":**
Remove any `debug=True` or `use_reloader=True` from `app.run()`.

**502 Bad Gateway after deploy:**
Check that you changed `app.run()` to bind to `0.0.0.0` and read from `PORT` env var.
Railway's health check hits `/` — make sure that route returns a response (your `index.html`).
