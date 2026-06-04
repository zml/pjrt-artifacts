## Local build instructions

This repo mirrors the GitHub Actions workflow for OpenXLA builds. Use the setup script to clone the correct fork at the pinned commit, apply patches, and print the exact build commands from the workflow matrix.

1. Run the setup script.

	```bash
	./setup.sh --fork upstream
	```

	For ROCm:

	```bash
	./setup.sh --fork rocm
	```

	For oneAPI:

	```bash
	./setup.sh --fork oneapi
	```

	For MUSA:

	```bash
	./setup.sh --fork musa --target musa
	```

	MUSA builds require `MUSA_DISTRO_URL` and `MUSA_DISTRO_HASH` so the SDK archive is supplied explicitly instead of being checked into this repository.

	Optional overrides:
	- `--ref <git-ref-or-sha>` to override the pinned commit.
	- `--dir <clone-dir>` to change the clone location.

2. Copy/paste the emitted commands for the target you want to build.

The script reads the matrix in [.github/workflows/_build.yaml](.github/workflows/_build.yaml), so the printed commands are always consistent with CI.
