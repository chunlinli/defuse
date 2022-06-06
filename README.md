# Nonlinear Causal Discovery with Confounders 

This repository contains an implementation of the following paper 

- Li, C., Shen, X., & Pan, W. (2022+). Nonlinear causal discovery with confounders. Submitted.

The method is named **De**confounded **Fu**nctional **S**tructure **E**stimation (DeFuSE).

## Contents

The simulations of DeFuSE are in Jupyter Notebooks:

- `./example_small.ipynb`: 50 simulations (random and hub graphs) when `p, n = 30, 500`.

- `./example_large.ipynb`: 50 simulations (random and hub graphs) when `p, n = 100, 500`.

The implementation of DeFuSE is in directory  `./defuse`.

- `./defuse/defuse.py`: defines `DeFuSE` class.

- `./defuse/defusenet.py`: defines neural network structures, including `MLP` class and `AMLP` (additive MLP) class.

- `./defuse/feature.py`: defines functions for feature selection.

- `./defuse/trainer.py`: defines `Trainer` class.

- `./defuse/utils.py`: defines utility functions, including graph and data generating functions.


The code of full simulations (including other methods) is in directory `./simulation`. 

- `./simulation/data.py`: simulates data.

- `./simulation/defuse_simulation.py`: conducts simulations for DeFuSE.

- `./simulation/notears_simulation.py`: conducts simulations for NOTEARS [2].

- `./simulation/simulation.R`: conducts simulations for CAM [3], RFCI [4], and LRpS-GES [1].

- `./simulation/Python`: 

    - `./simulation/Python/notears`: contains an implementation of NOTEARS. 

- `./simulation/R`: 

    - `./simulation/R/methods`: contains R files defining a unified interface for CAM, RFCI, and LRpS-GES. 

    - `utils.R`: defines utility functions, including graph metrics. 

- `./simulation/data`: stores simulated data.

- `./simulation/results`: stores the simulation results. 

## Preliminaries
### Environments

For Python, use conda to create an environment named `defuse`.
```bash
git clone https://github.com/chunlinli/defuse.git
cd defuse
conda env create -f environment.yml
conda activate defuse
```

### Installing DeFuSE

To install DeFuSE, run the following Bash script.
```bash
pip install -e .
```

### Installing other packages

To install NOTEARS, run the following Bash script.
```bash
cd simulation/Python/notears
pip install -e .
cd ../../../ # bask to defuse directory 
```
For R, the version is 4.1.1 and the following packages are used. 
```r
pkg <- c(
    "CAM","lrpsadmm","pcalg","bnlearn","mvtnorm", # required
    "dplyr","tidyr","progress","ggplot2","tidyverse","glue","scales","kableExtra" # suggested
)
install.packages(pkg)
```
NOTE: some packages have dependencies unavailable from CRAN. The user may need to install them manually.

### System information 

The code is tested on a server with specs:
```
System Version:             Ubuntu 18.04.6 LTS 4.15.0-176-generic x86_64
Model name:                 Intel(R) Xeon(R) Gold 5218 CPU @ 2.30GHz
Total Number of Cores:      64
Memory:                     528 GB
```
No GPU is required.

## Usage



For DeFuSE simulations, run the following notebooks.

- `./example_small.ipynb` takes roughly 3 hrs to run.

- `./example_large.ipynb` takes roughly 12 hrs to run. 

For complete simulations, first run the following script to generate data.
```
python simulation/data.py
```
Then run the following scripts.
```bash
python simulation/defuse_simulation.py
python simulation/notears_simulation.py
Rscript simulation/simulation.R
```
NOTE: the complete simulations will take more than 100 hrs to complete.

## Citing information

If you find the code useful, please consider citing 
```
@article{
    author = {Chunlin Li, Xiaotong Shen, Wei Pan},
    title = {Nonlinear causal discovery with confounders},
    year = {2022}
}
```
The code is maintained on [GitHub](https://github.com/chunlinli/defuse). 
This project is in development.

Implementing the structure learning algorithms is error-prone. 
If you spot any error, please file an issue [here](https://github.com/chunlinli/defuse/issues) or contact me via [email](mailto:li000007@umn.edu) -- 
I will be grateful to be informed.

## References

[1] Frot, B., Nandy, P., & Maathuis, M. H.  (2019).
[Robust causal structure learning with some hidden variables](https://rss.onlinelibrary.wiley.com/doi/full/10.1111/rssb.12315), JRSSB. 
Open-sourced softwares: LRpS+GES is implemented by [lrpsadmm](https://github.com/benjaminfrot/lrpsadmm) and [pcalg](https://github.com/cran/pcalg).

[2] Zheng, X., Dan, C., Aragam, B., Ravikumar, P., & Xing, E. P. (2020). 
[Learning sparse nonparametric DAGs](https://proceedings.mlr.press/v108/zheng20a), AISTATS 2020. 
Open-sourced software: [NOTEARS](https://github.com/xunzheng/notears).

[3] Bühlmann, P., Peters, J., & Ernest, J. (2014).
[CAM: Causal additive models, high-dimensional order search and penalized regression](https://projecteuclid.org/journals/annals-of-statistics/volume-42/issue-6/CAM--Causal-additive-models-high-dimensional-order-search-and/10.1214/14-AOS1260.full), 
AOS. 
Open-sourced software: [CAM](https://github.com/cran/CAM).

[4] Colombo, D., Maathuis, M. H., Kalisch, M., & Richardson, T. S. (2012).
[Learning high-dimensional directed acyclic graphs with latent and selection variables](https://projecteuclid.org/journals/annals-of-statistics/volume-40/issue-1/Learning-high-dimensional-directed-acyclic-graphs-with-latent-and-selection/10.1214/11-AOS940.full), AOS. 
Open-sourced software: RFCI is implemented by [pcalg](https://github.com/cran/pcalg).

[5] Kalisch, M., Mächler, M., Colombo, D., Maathuis, M. H., & Bühlmann, P. (2012).
[Causal Inference Using Graphical Models with the R Package pcalg](https://www.jstatsoft.org/article/view/v047i11), JSS. 
Open-sourced software: [pcalg](https://github.com/cran/pcalg).

In addition, part of the simulation code is adapted from 
[Frot's code](https://github.com/benjaminfrot/lrpsadmm-examples)
and 
[Zheng's code](https://github.com/xunzheng/notears).

**I would like to thank the authors of above open-sourced softwares.**

