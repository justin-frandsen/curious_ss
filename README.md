# Curious_SS

Curious_SS is a curiosity experiment using arbitrary shapes presented in scenes to create associations within those scenes. The project is implemented in MATLAB and is organized for reproducibility and collaboration.

## Project Overview

Participants are shown scenes containing various shapes. The goal is to investigate how associations are formed between shapes and their contexts, exploring curiosity-driven learning.

## Folder Structure

- `/setup/` — Setup files and configuration scripts
- `/stimuli/` — Stimuli files (images, shapes, etc.)
- `/data/` — Output data from experiments (gitignored)
- `/results/` — Analysis results and figures (gitignored)
- `/src/` — Source code and reusable functions
- `main_script.m` — Main experiment script

## Getting Started

1. Clone the repository:
   ```sh
   git clone https://github.com/jfran2015/curious_ss
   ```
2. Navigate to the project directory:
   ```sh
   cd curious_ss
   ```

4. Run the main script to start the experiment:
   ```sh
   run('curious_ss.m')
   ```

## Usage

- Modify `setupfiles/fullRandomizor.m` to configure experiment parameters (e.g., number of trials, stimuli types).
- Add or replace stimuli in the `/stimuli/` folder.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to all the participants and contributors who made this project possible.

