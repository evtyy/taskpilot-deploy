# TaskPilot — Deploy

Orchestration and deployment tooling for [TaskPilot](https://github.com/evtyy/task-board): a `docker-compose.yml` for running the full stack locally, and the pieces used to build/push/deploy it to AWS.

This deliberately lives in its own repo, separate from the app code, because the frontend and backend are versioned and deployed independently (each has its own GitHub Actions workflow — see [task-board](https://github.com/evtyy/task-board) and [task-board-api](https://github.com/evtyy/task-board-api)). This repo is the thing that wires them together.

## Layout this expects

Clone all three repos as siblings:

```
some-folder/
├── task-board/           # frontend
├── task-board-api/       # backend
└── task-board-deploy/    # this repo
```

## Local dev

```bash
cd task-board-deploy
cp .env.example .env      # fill in GROQ_API_KEY and JWT_SECRET
docker compose up --build
```

- Frontend: `http://localhost:3001`
- Backend docs: `http://localhost:8000/docs`
- MySQL: `localhost:3307` (user `root`, password `123456`)

`docker-compose.yml` builds the frontend and backend from `../task-board` and `../task-board-api` — it doesn't pull prebuilt images, so local changes to either repo are picked up on rebuild.

## Production

- `docker-compose.prod.yml` runs on the EC2 instance itself; it pulls prebuilt images from ECR rather than building locally, and points the backend at RDS instead of a local MySQL container.
- `build-and-push.sh` builds both images, tags them for ECR, and pushes. It reads `AWS_ACCOUNT_ID`, `AWS_REGION`, and `EC2_PUBLIC_IP` from `.env` — see `.env.example`. In normal use you shouldn't need this script directly, since each app repo's GitHub Actions workflow does the same build/push/deploy on every push to `main`.

## Env vars (`.env`, gitignored)

| Var | Used by | Notes |
|---|---|---|
| `GROQ_API_KEY` | backend container | free tier at console.groq.com; without it `/chat` returns 500 |
| `JWT_SECRET` | backend container | signs auth tokens — generate with `python3 -c "import secrets; print(secrets.token_hex(32))"` |
| `AWS_ACCOUNT_ID`, `AWS_REGION`, `EC2_PUBLIC_IP` | `build-and-push.sh` only | your own AWS account/instance — not needed for local dev |
