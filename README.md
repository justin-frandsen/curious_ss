# Curious_SS

Curious_SS is a curiosity experiment using arbitrary shapes presented in scenes to create associations within those scenes. The project is implemented in MATLAB and is organized for reproducibility and collaboration.

## Project Overview

Participants are given a visual search task to search for a previously cued target shape. In this task a set of critical distractor objects appear in each scene with regularity (e.g., they appear either on the wall, counter, or floor 100% of trials). Then after participants have successfully found the cued target participants are given a free viewing period where they can search the scene how they wish. Then in the second half of the experiment we make it so that the critical distractors become the target set. We hypothesize that participants that do more visual exploration in the scene will have better guidance to the targets that were previously distractors. (They will appear with less regularity).

## Folder Structure

- `/setup/` — Setup files and configuration scripts
- `/stimuli/` — Stimuli files (images, shapes, etc.)
- `/data/` — Output data from experiments (gitignored)
- `/figures/` — Analysis results and figures (gitignored)
- `/trial_structure_files/` - Contains output files created by the setup scripts necessary for running the experiment. 
- `curious.m` — Main experiment script

## Getting Started

1. Clone the repository:
   ```sh
   git clone https://github.com/jfran2015/curious_ss
   ```
2. Navigate to the project directory:
   ```sh
   cd curious_ss
   ```

4. Run the main script in MATLAB to start the experiment:
   ```matlab
   curious_ss
   ```

## Usage

- Modify `setupfiles/fullRandomizor.m` to configure experiment parameters (e.g., number of trials, stimuli types).
- Add or replace stimuli in the `/stimuli/` folder.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thank you to all the participants, Dr. Brian Anderson, and the Learning and Attention Lab who all made this project possible.

