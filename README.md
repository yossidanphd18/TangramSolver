# A Mixed-Integer Optimization Approach for Finite 2D Tiling Problems

This repository contains the MATLAB source code, benchmark datasets, and experimental results for the paper: **"A Mixed-Integer Optimization Approach for Tangram Puzzles"** by Yossi Daniel and Hillel Kugler.

## Abstract
Two-dimensional (2D) polygonal tiling presents challenging optimization tasks due to the combinatorial explosion of valid arrangements. We introduce a mixed-integer second-order cone programming (MI-SOCP) framework that maps the continuous search space to a discrete lattice grid, producing initial approximate solutions with grid-restricted translations. A final fine-tuning optimization (FTO) stage then refines these discrete translations into continuous coordinates. To ensure computational tractability over large variable spaces, an efficient geometric preprocessing pipeline prunes symmetric and redundant topological states prior to optimization. Experiments on benchmark Tangram puzzles demonstrate that this approach efficiently yields high-quality approximate solutions, which are subsequently refined into continuous-coordinate configurations that satisfy a strict numerical geometric criterion.

---

## Prerequisites
To run the simulations, ensure your environment meets the following requirements:

* **MATLAB**: Version R2023b (Update 1 or later) is recommended.
* **Optimization Toolbox**: Required for Genetic Algorithm (GA) and Simulated Annealing (SA) components.
* **Global Optimization Toolbox**: Required for global optimization routines.
* **Image Processing Toolbox**: Required for image handling and visualization features.
* **Gurobi Optimizer**: Version 12.03. 
    * *Note:* See info on academic licenses at https://www.gurobi.com/academics.

---

## Quick Start
1. **Clone the Repository**: Download or clone this repository to your local machine.
2. **Launch the Application**: Run the `mainTangramApp.m` script in the root directory.
3. **Configure Parameters**: Adjust the following variables in the script header if desired:
    * `time_limit_secs`: Maximum solver execution time in seconds.
    * `enable_ga_solver`: Toggle (0/1) to disable/enable the Genetic Algorithm.
    * `enable_sa_solver`: Toggle (0/1) to disable/enable Simulated Annealing.
    * `force_disable_viz`: Set to 1 to disable extra figures and reduce graphical overhead.
4. **Interface**: Once the GUI opens, select a target shape from the menu and click **"START SOLVER"**. Use the **"NIGHT MODE"** button to trigger a batch solve of all provided challenges.

---

## Requirements
This project requires specific MATLAB toolboxes, third-party solvers, and external libraries (such as the Clipper2 C++ library used in MEX-compiled functions). Please see the `requirements.txt` file in the root directory for a complete list of dependencies.

---

## Results
The `./__RESULTS_ODS2026` directory contains the results and generated figures used for our paper. 
* *Note:* Gurobi execution times may vary depending on your hardware specifications and the solver's internal randomized heuristics.

---

## Hardware Configuration (Benchmark Environment)
The results presented in the paper were generated on the following setup:
* **Machine**: Lenovo Workstation
* **CPU**: Intel Core i7-8565U @ 1.80 GHz (4 Cores)
* **RAM**: 16 GB
* **OS**: Windows 11 Pro (64-bit)
* **Software**: MATLAB R2023b, Gurobi Solver v12.03

---

## License
This project is licensed under the GNU Affero General Public License v3.0. 
See the [LICENSE](LICENSE) file for details.

---

## Contact
For questions regarding the implementation or research, please reach out to **Yossi Daniel** at [yossidaniel8@gmail.com](mailto:yossidaniel8@gmail.com).