# MLFlow ♻️


## About
This explanation guide covers the introduction of [MLFlow][mlflow-website] into
certain steps of the workflow.


## Features
MLFlow provides a simple way to:

- Iterate over hyper-parameters.
- Keep track of consecutive ML experiment runs.
- Keep track of ML models evolution over time.


## Specification
There are three places where MLFlow is introduced.


### 1. MLProject
The _MLProject_ is the file where both the entry-points and the executions environment is defined.

The entry-points are used to specify a certain command and a set of parameters that can be 
parametrized later on. These parameters can also be logged when tracking consecutive runs of
the experiment so that each run is identified by the parameter values it used.

In terms of the environment, MLFlow offer users 3 options: _Conda_, _Docker_ or _System_.
Given that this project does not use Conda, and it is designed to run both in a developers machine,
and a Yadage engine, the right option is to use the System environment (default).

Check the [MLProject documentation][mlproject-docs] for further details.


### 2. MLFlow CLI
The MLFlow CLI is used within the shell scripts corresponding to the workflow steps that
are going to be either parametrized or tracked.

In the case of this project, those steps are:
- [Sampling][script-sample]: to parametrize.
- [Training][script-train]: to parametrize.
- [Evaluation][script-eval]: to track over time.

On those shell scripts, the default Python script execution has been substitute by
`mlflow run` command, specifying:

- A certain experiment name.
- Their corresponding `MLproject` entry-point.
- The execution backend (local).
- The execution environment (`--no-conda` = System).
- Their set of parameters.

Check the [MLFlow CLI documentation][mlflow-cli-docs] for further details.


### 3. MLFlow Python library
Finally, the `mlflow` Python package can be used within the Python scripts to define
_tags_, _params_ or _artifacts_ that gets appended to the launched run.

These elements would appear on the MLFlow _tracking server UI_, once the experiment runs
finish, making the runs easily identifiable and comparable to each other.

Check the [MLFlow tracking documentation][mlflow-track-docs] for further details.


## Execution
When running the workflow, you can specify the environment variable `MLFLOW_TRACKING_URI`
to log the experiment runs information to a MLFlow tracking server previously deployed.

To deploy the MLFlow tracking server locally:
```shell script
mlflow server
```

Depending on how the workflow is launched, a different tracking URI must be specified.
There are actually two ways of executing the workflow:

### A) Individual steps
Individual steps can be launched using their shell script. Be aware their execution may depend on 
previous step outputs, so a sequential order must be followed.

Example:
```shell script
export MLFLOW_TRACKING_URI=http://127.0.0.1:5000
scripts/1_sampling.sh \
    -p . \
    -d data/dummy_data.h5 \
    -i workflow/input.yml \
    -o .workdir
```

### B) Coordinated
The full workflow can be launched using [Yadage][yadage-repo]. Yadage is a YAML specification language
over a set of utilities that are used to coordinate workflows.

In addition, as Yadage uses Docker images as execution environments to the workflow steps,
the tracking server must be reachable from **within** the Docker container.

Therefore:
- Create experiments beforehand to avoid race conditions.
- Define `host.docker.internal` as tracking server host.

```shell script
export MLFLOW_TRACKING_URI=http://127.0.0.1:5000
mlflow experiments create --experiment-name "madminer-ml-sample"
mlflow experiments create --experiment-name "madminer-ml-train"
mlflow experiments create --experiment-name "madminer-ml-eval"
export MLFLOW_TRACKING_URI=http://host.docker.internal:5000
pip3 install yadage
make yadage-run
```


[mlflow-website]: https://mlflow.org/
[mlproject]: MLproject
[mlflow-cli-docs]: https://www.mlflow.org/docs/latest/cli.html
[mlflow-track-docs]: https://mlflow.org/docs/latest/tracking.html
[mlproject-docs]: https://www.mlflow.org/docs/latest/projects.html
[script-sample]: scripts/1_sampling.sh
[script-train]: scripts/2_training.sh
[script-eval]: scripts/3_evaluation.sh
[yadage-repo]: https://github.com/yadage/yadage
