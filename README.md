# A Mixed-Integer Optimization Approach for Finite 2D Tiling Problems

This repository contains the MATLAB source code, benchmark datasets, and experimental results for the paper: **"A Mixed-Integer Optimization Approach for Finite 2D Tiling Problems"** by Yossi Daniel and Hillel Kugler.

## Abstract
Finite 2D tiling problems represent challenging optimization tasks due to the combinatorial explosion of valid tile arrangements. We introduce a Mixed-Integer Second-Order Cone Programming (MI-SOCP) framework to model and solve these geometric containment problems. By mapping the continuous search space to a discrete lattice grid, permissible tile configurations are represented as bounded discrete states. To ensure computational tractability over large variable spaces, the framework employs an efficient geometric preprocessing pipeline to prune symmetric, redundant, and overlapping topological states prior to optimization. Computational experiments on benchmark Tangram puzzles demonstrate that this integrated approach efficiently traverses the discretized space, yielding optimal solutions with a high success rate.

---

## Prerequisites
To run the simulations, ensure your environment meets the following requirements:

* **MATLAB**: Version R2023b (Update 1 or later) is recommended.
* **Optimization Toolbox**: Required for Genetic Algorithm (GA) and Simulated Annealing (SA) components.
* **Gurobi Optimizer**: Version 12.03. 
    * *Note:* Academic licenses are available for free via the [Gurobi Academic Program](https://www.gurobi.com/academics).

---

## Quick Start
1. **Clone the Repository**: Download or clone this repository to your local machine.
2. **Launch the Application**: Run the `mainTangramApp.m` script in the root directory.
3. **Configure Parameters**: Adjust the following variables in the script header if desired:
    * `time_limit_secs`: Maximum solver execution time in seconds.
    * `enable_ga_solver`: Toggle (0/1) to disable/enable the Genetic Algorithm.
    * `enable_sa_solver`: Toggle (0/1) to disable/enable Simulated Annealing.
4. **Interface**: Once the GUI opens, select a target shape from the menu and click **"START SOLVER"**. Use the **"NIGHT MODE"** button to trigger a batch solve of all provided challenges.

---

## Results
The `./__RESULTS` directory contains pre-generated data and figures from our paper. 
* **Re-generating Results**: You can re-run the analysis scripts by executing `show_results.m` located within the `__RESULTS` folder. 
* *Note:* Gurobi execution times may vary depending on your hardware specifications and the solver's internal randomized heuristics..

## Hardware Configuration (Benchmark Environment)
The results presented in the paper were generated on the following setup:
* **Machine**: Lenovo Workstation
* **CPU**: Intel Core i7-8565U @ 1.80 GHz (4 Cores)
* **RAM**: 16 GB
* **OS**: Windows 11 Pro (64-bit)
* **Software**: MATLAB R2023b, Gurobi Solver v12.03

---

## Contact
For questions regarding the implementation or research, please reach out to **Yossi Daniel** at [yossidaniel8@gmail.com](mailto:yossidaniel8@gmail.com).