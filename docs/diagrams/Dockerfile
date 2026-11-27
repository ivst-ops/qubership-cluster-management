# The diagram generator's image (compose.yml next to this file, `task docs:diagrams`): pinned Python and Pillow, no
# fonts from the OS (the generator reads fonts/). The PNGs are the same on every host and architecture.
FROM python:3.13.18-slim-trixie@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
ENV PYTHONDONTWRITEBYTECODE=1 PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_ROOT_USER_ACTION=ignore
COPY requirements.txt /tmp/requirements.txt
RUN pip install --require-hashes --only-binary :all: -r /tmp/requirements.txt && rm /tmp/requirements.txt
# Non-root by default (distroless-style nonroot uid); compose.yml overrides it with the caller's QCM_UID:QCM_GID.
USER 65532:65532
WORKDIR /diagrams
ENTRYPOINT ["python", "build_demo_diagram.py"]
