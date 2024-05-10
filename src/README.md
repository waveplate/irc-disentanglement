# System

This folder contains code for reproducing our disentanglement experiments.

## Requirements

The only dependency is the [DyNet library](http://dynet.readthedocs.io), which can usually be installed with:

```
pip3 install dynet
```

> *** Make sure to [install the latest CUDA toolkit](https://developer.nvidia.com/cuda-downloads) first if you have an Nvidia GPU

## Running

To see all options, run:

```
python3 disentangle.py --help
```

### Train

To train, provide the `--train` argument followed by a series of filenames.

The example command below will train a model with the same parameters as used in the ACL paper.
The model is a feedforward neural network with 2 layers, 512 dimensional hidden vectors, and softsign non-linearities.

```
python3 disentangle.py \
  example-train \
  --train ../data/train/*annotation.txt \
  --dev ../data/dev/*annotation.txt \
  --hidden 512 \
  --layers 2 \
  --nonlin softsign \
  --word-vectors ../data/glove-ubuntu.txt \
  --epochs 20 \
  --dynet-autobatch \
  --drop 0 \
  --learning-rate 0.018804 \
  --learning-decay-rate 0.103 \
  --seed 10 \
  --clip 3.740 \
  --weight-decay 1e-07 \
  --opt adam \ # this option is only for GPU
  --gpu \
  > example-train.out 2>example-train.err
```

### Infer

This command will run the model trained above on the development set:

```
python3 disentangle.py \
  example-run.1 \
  --model example-train.dy.model \
  --test ../data/dev/*annotation* \
  --test-start 1000 \
  --test-end 2000 \
  --hidden 512 \
  --layers 2 \
  --nonlin softsign \
  --max-dist 50 \ # default 100
  --word-vectors ../data/glove-ubuntu.txt \
  --gpu \
  > example-run.1.out 2>example-run.1.err
```

>Note - the arguments defining the network (hidden, layers, nonlin), must match those given in training.

### Running on a file

If you want to apply a model to a file, see this script for an example of how to do it: `example-running.sh`.
The script is set up so someone could call it like so (once the necessary placeholders in the script are set):

`./example-running.sh sample.txt`

This will write to several files:

```
todo.sample.0.log              # log file
todo.sample.0.txt              # copy of sample.txt
todo.sample.0.txt.tok          # tokenized version of sample.txt
todo.sample.0.links.txt        # annotations with self-links removed
todo.sample.0.annotations.txt  # annotations including self links
```

If the annotation process is interrupted, it can be resumed like so

```
./example-running.sh sample.txt --continue 0
```

This will pick up from the last annotation

### Link

Once inference has concluded, you can use `show.py` to show which lines were correlated

```
python show.py ../data/test/2005-07-06_14.annotation.txt ../data/test/2005-07-06_14.ascii.txt
```

Output:

```
[02:00] <jonbusby> well no, their java applet windows. I'm running firefox with sun-j2rel.5 java vm
[01:59] <holycow> what java applet window?

[02:00] <jonbusby> well no, their java applet windows. I'm running firefox with sun-j2rel.5 java vm
[01:59] <enrico> what's the browser?

[02:00] <holycow> okay, what site?
[02:00] <jonbusby> well no, their java applet windows. I'm running firefox with sun-j2rel.5 java vm

[02:00] <rob^> heh
[01:59] <rasputnik> rob^: as a separate note, I get very pissed off applying for unix admin jobs and having to fill in an applicatin form in word format.

[02:02] <holycow> stig_, unfortunately for now it requires a bit of work
[02:02] <stig_> how can I get access to my NTFS files from ubuntu? (fresh newbie asking) :)

[02:02] <holycow> a: you will only be able to read the ntfs files
[02:02] <holycow> stig_, unfortunately for now it requires a bit of work
```

### Evaluate

This command will run the output produced by the command above through the evaluation script:

```
python3 ../tools/evaluation/graph-eval.py --gold ../data/dev/*annotation* --auto example-run.1.out
```

The output should be something like:

```
g/a/m: 2607 2500 1855
p/r/f: 74.2 71.2 72.6
```

The first row is a count of the gold links, auto links, and matching links.
The second line is the precision, recall, and F-score.

Note - the values in the paper are an average over 10 runs, so they will differ slightly from what you get here.



## Ensemble

For the best results, we used a simple ensemble of multiple models.
We trained 10 models as described above, but with different random seeds (1 through to 10).
We combined their output using the `majority_vote.py` script in this directory.

The same script is used for all three ensemble methods, with slightly different input and arguments:

Union
```
./majority_vote.py example-run*graphs --method union > example-run.combined.union
```

Vote
```
./majority_vote.py example-run*graphs --method vote > example-run.combined.vote
```

Intersect
```
./majority_vote.py example-run*clusters --method intersect > example-run.combined.intersect
```

All of these assume the output files have been converted into our graph format.
Assuming you run `disentangle.py` above and save the output of each run as `example-run.1.out`, `example-run.2.out`, `example-run.3.out`, etc, then this command will use one of our tools to convert them to the graph format:
```
for name in example-run*out ; do ../tools/format-conversion/output-from-py-to-graph.py < $name > $name.graphs ; done
```

The intersect method also assumes they have been made into clusters, like this:
```
for name in example-run*out ; do ../tools/format-conversion/graph-to-cluster.py < $name.graphs > $name.clusters ; done
```

Note: An earlier version of the steps above didn't account for a change in the output of the main system. Apologies for the broken output this would have caused.

## C++ Model

As well as the main Python code, we also wrote a model in C++ that was used for DSTC 7 and the results in the 2018 arXiv version of the paper (the Python version was used for DSTC 8 and the 2019 ACL paper).
The python model has additional input features and a different text representation method.
The C++ model has support for a range of additional variations in both inference and modeling, which did not appear to improve performance.
For details on how to build and run the C++ code, see [this page](./old-cpp-version/).

[Go back](./../) to the main webpage.
